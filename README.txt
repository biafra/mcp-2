INTRODUCTION

This is an implementation of MCP v2.1 which is only available on a few MOOs.
If your moo has a $mcp with a $mcp.version = {2, 1}, this package is for you.
You can always find the latest version by going to:

	http://www.ben.com/MOO/

If you have MCP v1 there is an older macro package available from the same
location with similar functionality.

INSTALLATION

This package includes an MCP v2.1 implementation in the form of TF macros as
well as a client-side implementation of dns-org-mud-moo-simpleedit v1.0.  To
support the simpleedit package there is a set of macros for doing asynchronous
(meaning TF keeps running and you keep chatting) local editing.  Here are the
steps you'll need to get going:

	1.  MAKE SURE that your MOO worlds have `-Ttiny.moo' on the /addworld
	    lines.  Only tiny.moo worlds will use the MCP package.  If you
	    see MCP messages even after installing this package this is
	    probably what you forgot!

	2.  Copy the .tf files somewhere.

	3.  Add the lines from `for-tfrc' to your .tfrc.  You may need to add
	    paths to wherever you put the .tf files in step 2.

	4.  Restart TF or execute the lines you added to your .tfrc by hand.

	5.  If necessary, disconnect from the MOO world where you want local
	    editing.  MAKE SURE YOU DID STEP #1!  Now connect to the world.

	6.  Check to see that ;me.out_of_band_session is a valid object.

	7.  Turn on local editing with `@edit-o +local'.

	8.  Try editing a program, a property or sending mail.

TIPS

The local-edit.tf package supports async editing with screen and X Windows.
For best results start TF under one of those environments.  If you examine
local-edit.tf you can probably figure out how to support other environments
like virtual consoles.

UPDATES

I keep finding parsing quirks in TF5 that break code originally written
for TF4.1, but no one seems to be complaining!  When in doubt, try fewer
backslashes!

AUTHOR

This TF macro package was written by Ben Jackson <ben@ben.com>.
