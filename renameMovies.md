REQUIRED :
Must be root or admin to launch script (from ssh/telnet)
Does NOT support multi files (i.e : CD1 / cd2) . You must join them with program like mkvmerge/virtualdub before starting the script
Make sure ALL your files are correctly set in videostation (I have found several movies under the same jacket, but files were totally different, I had to separate them)

Informations :
Spaces within movie names are replaced by dots (.), and the year is added at the end
Asks for rename before renaming it
Removes accents, special caracters
Handles sub-folders
Generates a log "rename.log" in the folder of the script (will be wiped before each run, make sure you move it somewhere else if needed)


Tested with a very large library, but bugs can appear, make sure you keep the log

If you only want to run the script, without modifying (to check your files) comment the lines 49/50/51/55/56/57 by adding a # at the start of the line