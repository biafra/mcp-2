; /mcp21_add_package packagename
;
; Add a new package.  It should define variables mcp21_packagename_min_version
; and _max_version
/def mcp21_add_package = \
	/set mcp21_packages=$(/unique %{mcp21_packages} %1)

/def mcp21_send_packages = \
	/while (shift(), {#}) \
		/let vname=$[replace('-','_',{1})]%;\
		/eval /mcp21_send mcp-negotiate-can package: \%1 min-version: \%{mcp21_%{vname}_min_version} max-version: \%{mcp21_%{vname}_max_version}%;\
	/done

/def mcp21_send_negotiation = \
	/eval /mcp21_set_world ${world_name}%;\
	/mcp21_send_packages x %{mcp21_packages}%;\
	/mcp21_send mcp-negotiate-end

/def mcp21_begin_negotiation =

/def mcp21_mcp-negotiate-can = \
	/test nothing
;	/eval /echo -e \% ${world_name} CAN \%{mcp_tag_package} from \%{mcp_tag_min_version} to \%{mcp_tag_max_version}

/def mcp21_mcp-negotiate-end =
