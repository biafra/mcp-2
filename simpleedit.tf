/def mcp21_dns-org-mud-moo-simpleedit-content = \
	/le_edit_invoke %{mcp_tag_content_} /simpleedit_done reference: "%{mcp_tag_reference}" type: %{mcp_tag_type}

/def simpleedit_done = \
	/let key=$[rand()]%;\
	/mcp21_set_world %{le_world}%;\
	/mcp21_send  dns-org-mud-moo-simpleedit-set %* content*: "" _data-tag: %{key}%;\
	/mcp21_send_file %{key} content %{le_file}%;\
	/mcp21_send_end %{key}

/set mcp21_dns_org_mud_moo_simpleedit_min_version=1.0
/set mcp21_dns_org_mud_moo_simpleedit_max_version=1.0
/mcp21_add_package dns-org-mud-moo-simpleedit
