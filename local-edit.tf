/eval /set le_editor=%{EDITOR-%{VISUAL-vi}}
/set le_xterm=xterm -name tf-localedit -e

/if (DISPLAY !~ "") \
	/def le_do_edit = \
		/quote -0 -dexec -w%1 !%{le_xterm} %{le_editor} %2; echo '/le_edit_done $[replace("'", "'\"'\"'", {*})]'%;\
/endif

; We try to grab TTY here if we have async editing, since screen needs to
; know our tty, and /sh is ugly.  If this doesn't work for you, try using
; /sh in the async case of /le_edit_invoke.
;
/if (STY !~ "" & TTY =~ "") \
	/echo % Trying to determine tty...%;\
	/test h:=tfopen('tty', 'p')%;\
	/test tfread(h, TTY)%;\
	/test tfclose(h)%;\
	/eval /setenv TTY=%{TTY}%;\
	/if (TTY =~ "") \
		/echo % Unable to determine tty.  Using /dev/tty -- screen won't switch automatically when you invoke the editor.%;\
		/echo % Try adding "setenv TTY `tty`" to your .login or "TTY=`tty`; export TTY" to your .profile.%;\
		/setenv TTY /dev/tty%;\
	/endif%;\
/endif

; Ok, now if we have STY (screen), TTY and not DISPLAY, use screen bg editing
;
/if (STY !~ "" & TTY !~ "" & DISPLAY =~ "") \
	/def le_do_edit = \
		/quote -0 -dexec -w%1 !exec 2>/dev/null ;  sleep 99999999 & PID=$$!; screen < %{TTY} -t 'tf edit' sh -c " %{le_editor} %2; kill $$PID "; wait; echo '/le_edit_done %*'%;\
/endif

; delete edit files 5 minutes after we upload them.  nothing gets deleted
; if it's the last thing to be uploaded (for /reedit)
;
/set le_edit_rm_delay=300

;;
;; END OF USER CONFIGURATION
;;

; /le_edit_invoke file done_command....
;
/def le_edit_invoke = \
	/eval /set le_world=${world_name}%;\
	/le_do_edit %{le_world} %* %;\

; /le_edit_done [le_edit_invoke args]
; called by /le_do_edit when its blocking edit completes.
;
/def le_edit_done = \
	/eval /set le_world=%1%;\
	/eval /set le_file=%2%;\
	/eval /set le_reedit_${world_name}=%*%;\
	/eval %-2

; re-edit the last thing we uploaded
;
/def le_reedit = \
	/if /eval /test '\%\{le_reedit_${world_name}}' !~ "" %;\
	/then \
		/eval /le_do_edit \%\{le_reedit_${world_name}}%;\
	/else \
		/echo %% Nothing to re-edit in world ${world_name}.%;\
	/endif

; an alias
/def reedit = /le_reedit
