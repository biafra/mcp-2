;/set mcp21_tmpdir=/tmp
/set mcp21_tmpdir=/homes/bjj/tmp

;;
;; END OF USER CONFIGURATION
;;

/require lisp.tf
/loaded mcp21.tf

; generate an auth key named mcp_${world_name}_auth_key
;
/def mcp_gen_auth_key =\
	/eval /set mcp_${world_name}_auth_key=$[rand()]
/def mcp_show_auth_key =\
	/eval /eval /echo \%{mcp_${world_name}_auth_key}
/def mcp_check_auth_key =\
	/eval /test {mcp_${world_name}_auth_key} =~ {1}

; also need send hook to quote OUTGOING? #$# lines?  per the spec...
;
/def -Ttiny.moo -p20002 -aGg -mregexp -t'^#\$"(.*)' mcp21_quote = \
	/echo -w %{P1}

; Catch the plain mcp message with the trailing space
;
/def -Ttiny.moo -p20001 -aGg -mregexp -t'^#\$#mcp ' mcp21_hook = \
	/mcp21_extract_tags%;\
	/mcp21_login_internal %{mcp_tag_version} %{mcp_tag_to}

/def mcp21_login_internal = \
	/mcp_gen_auth_key%;\
	/mcp21_begin_negotiation%;\
	/send -w #\$#mcp authentication-key: $(/mcp_show_auth_key) version: 2.1 to: 2.1%;\
	/mcp21_send_negotiation

/def mcp21_login = /mcp21_login_internal 2.1 2.1

; take the end of a server request and parse the tag/value pairs per the
; spec.  note that you can't use `\' to escape arbitrary characters in the
; values, only `"'.  The spec is ambiguous on this point.
;
/def mcp21_extract_tags =\
	/while (mcp_tags !~ "") \
		/eval /unset $(/car %{mcp_tags})%;\
		/set mcp_tags=$(/cdr %{mcp_tags})%;\
	/done%;\
	/mcp21_extract_tags_internal %{*}%;\
	/let l=%{mcp_tags}

; watch out!  I'm recursive.  also be careful about eval'ing tag values,
; since URLs (in particular) include %'s...
;
/def mcp21_extract_tags_internal = \
	/while ({#}) \
		/test regmatch('(.*):', {1})%;\
		/let name=mcp_tag_$[replace('*','_',replace('-','_',{P1}))]%;\
		/if (0 == strchr({2}, '"')) \
			/test regmatch(strcat('^"(([^"]|', char(92), char(92),'")*)(?<!', char(92), char(92), ')"(.*)'), {-1})%;\
			/let val=%{P1}%;\
			/let rest=%{P3}%;\
			/while (regmatch(strcat('(.*)',char(92),char(92),'"(.*)'), val)) \
				/let val=%P1"%P2%;\
			/done%;\
			/eval /set %{name}=\%{val}%;\
			/eval /set mcp_tags=%{mcp_tags} %{name}%;\
			/mcp21_extract_tags_internal %{rest}%;\
			/break%;\
		/else \
			/eval /set %{name}=\%2%;\
			/eval /set mcp_tags=%{mcp_tags} %{name}%;\
			/shift 2%;\
		/endif %;\
	/done

; receive a line of oob data from the MOO.  check the authentication string,
; parse the tag/value pairs into mcp_tag_*, then call a handler based on
; the message request, eg #$#edit calls /mcp_edit.  At the moment we ignore
; the server-supplied `*' to indicate additional lines of data.
; 
/def -Ttiny.moo -mregexp -t'^#\$#([^:* ]*) [^ ]* ' -agG -p20000 mcp21_rec_oob =\
	/let request=%{P1}%;\
	/if /mcp_check_auth_key %2%;\
	/then \
		/eval /mcp21_set_world ${world_name}%;\
		/mcp21_extract_tags %-2%;\
		/mcp21_expect_multiline_values %{request} %{mcp_tags}%;\
	/endif

/def -Ttiny.moo -mregexp -t'^#\$#([^:* ]*) [^ ]*$' -agG -p19999 mcp21_rec_oob_nokeyvals =\
	/let request=%{P1}%;\
	/if /mcp_check_auth_key %2%;\
	/then \
		/eval /mcp21_set_world ${world_name}%;\
		/mcp21_extract_tags%;\
		/mcp21_expect_multiline_values %{request}%;\
	/endif


; open files for any incoming multiline values.  when they're all received
; or if there are none, fire off the handler
;
/def mcp21_expect_multiline_values = \
	/let request=%1%;\
	/let multiline=0%;\
	/let fhs=%;\
	/while (shift(), {#}) \
		/if (strrchr({1}, "_") == strlen({1})-1) \
			/mcp_gen_tempfile%;\
			/test h:=tfopen({mcp_tempfile}, "w")%;\
			/eval /set %1=\%\{mcp_tempfile}%;\
			/let fhs %{fhs} %{h}%;\
			/mcp21_init_multiline %{mcp_tag__data_tag} $[substr({1}, 8, strlen({1})-9)] %{h}%;\
			/let multiline=$[multiline + 1]%;\
		/endif%;\
	/done%;\
	/set mcp21_mlfh_${world_name}=%{fhs}%;\
	/if (multiline < 1) \
		/eval /mcp21_%{request}%;\
	/else \
		/def -p20004 -n1 -mregexp -aGg -t'^#\\\$#\\: %{mcp_tag__data_tag} *\$' mcp21_rec_multiline_${world_name}_%2 = \
			/eval /mcp21_close_all x %{fhs}%%;\
			/eval /mcp21_%{request}%;\
	/endif

/def mcp21_close_all = \
	/while (shift(), {#}) \
		/test tfclose({1})%;\
	/done

/def mcp21_init_multiline = \
	/def -p20003 -mregexp -aGg -t'^#\\\$#\\* %1 %2: (.*)\$' mcp21_rec_multiline_${world_name}_%2 = /test tfwrite(%3,{P1})

; make up a temporary file name.
;
/def mcp_gen_tempfile =\
	/set mcp_tempfile_seq=$[mcp_tempfile_seq + 1]%;\
	/eval /set mcp_tempfile=%{mcp21_tmpdir}/.tfmcp2-$[getpid()].%{mcp_tempfile_seq}

/def mcp21_set_world = \
	/eval /set mcp21_fg_world=%1

; (message tag: value ...)
;
/def mcp21_send = \
	/send -w%{mcp21_fg_world} #\$#%1 $(/mcp_show_auth_key) %-1

; (key tag filename)
;
/def mcp21_send_file = \
	/quote -dsend -S -w%{mcp21_fg_world} \\#\$\\#* %1 %2: '%3

; (key)
;
/def mcp21_send_end = \
	/send -w%{mcp21_fg_world} #\$#: %1
