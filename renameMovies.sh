#!/bin/ash
###########################################################################################
#........... Script to renames movies from Video Station..................................#
#Version=8 #
# thanks to bud77 on synology forums #
###########################################################################################
###########################################################################################
# Renaming function declaration #
###########################################################################################
start_rename () {
    LOCATION=$(pwd)
###########################################################################################
# Getting informations from DB
# ###########################################################################################
$SUCMD '/usr/syno/pgsql/bin/psql -d video_metadata -q -A -t -c "select c.id,title,path,year from movie a, video_file c where c.mapper_id=a.mapper_id ;"' | \
while read ENTRY do
 DB_ID=$(echo $ENTRY|cut -f1 -s -d"|")
 TITRE=$(echo $ENTRY|cut -f2 -s -d"|")
 CHEMIN=$(echo $ENTRY|cut -f3 -s -d"|")
 YEAR=$(echo $ENTRY|cut -f4 -s -d"|")
###########################################################################################
# Define new name (remplace space by "." ) and set current folder
# ###########################################################################################
NEW_TITRE=$(echo $TITRE |sed 's/,//g' |sed 's/://g' |sed 's/;//g' |sed -e 's/ /./g' | \
sed -e 's/?//g'|sed -e 's/\*/-/g').$YEAR DOSSIER=$(dirname "$CHEMIN") EXTENSION=${CHEMIN##*.}
###########################################################################################
# Cleaning up final name : accents, "&" , "," , ":" #
###########################################################################################
NEW_NAME=$(echo $NEW_TITRE.$EXTENSION |sed 's/&/Et/g' |sed -e 's/\$//g' |sed "s/'/./g" | \
sed 's/à/a/g' |sed 's/â/a/g' |sed 's/ç/c/g' |sed 's/é/e/g' |sed 's/è/e/g' |sed 's/ê/e/g' | \
sed 's/ë/e/g' |sed 's/î/i/g' |sed 's/ï/i/g' |sed 's/ô/o/g' |sed 's/ö/o/g' |sed 's/œ/oe/g' | \
sed 's/Œ/oe/g' |sed 's/ù/u/g' |sed 's/ü/u/g' |sed 's/Â/A/g' |sed 's/Ç/C/g' | \
sed 's/É/E/g' |sed 's/È/E/g' |sed 's/Ê/E/g' |sed 's/Ë/E/g' |sed 's/Î/I/g' |sed 's/Ï/I/g' | \
sed 's/Ô/O/g' |sed 's/Ö/O/g' |sed 's/Ù/U/g' |sed 's/Ü/U/g' |sed -e 's/À/A/g' |sed -e 's/·/./g')
NEW_PATH=$DOSSIER/$NEW_NAME NEW_PATH2=\'$NEW_PATH\'
###########################################################################################
# Check if name needs to me modified
# ###########################################################################################
if [ "$CHEMIN" == "$NEW_PATH" ] then
    echo $CHEMIN deja OK, pas de MaJ
else
###########################################################################################
# Update approval
# ###########################################################################################
    echo -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
    echo "Rename $CHEMIN <-- to --> $NEW_PATH"
    read -p 'Uupdate file ? (y/n)' MAJ </dev/tty if [ "$MAJ" == "y" ] then
    ##########################################################################################
    # Rename file and update DB #
    ##########################################################################################
    mv "$CHEMIN" "$NEW_PATH"
    SQLCMD='/usr/syno/pgsql/bin/psql -d video_metadata -q -A -t -c "UPDATE video_file SET path = '$NEW_PATH2' WHERE id= '$DB_ID';"' $SUCMD $SQLCMD fi fi done }
    ###########################################################################################
    # Check of user = admin or root #
    ###########################################################################################
    CHECK_USER=$(whoami)
    case $CHECK_USER in
        admin)
            SUCMD=eval start_rename |tee rename.log;;
        root)
            SUCMD="su - admin -c" start_rename |tee rename.log;;
        *)
        echo "This script needs to be run as root or admin" exit
    esac