#!/bin/sh

# Synology synoindexd service only add Show name but
# will not add Episode name from filename

#---------------------------------------------
#function to set the environment
#---------------------------------------------
set_environment(){
    ALL_EXT="ASF AVI DIVX FLV IMG ISO M1V M2P M2T M2TS M2V M4V MKV MOV MP4 MPEG4 MPE MPG MPG4 MTS QT RM TP TRP TS VOB WMV XVID"

    CONFIG_DIR=$(dirname $0)"/config"

    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir "$CONFIG_DIR"
    fi

    FICH_CONF="$CONFIG_DIR/update-synoindex-conf.txt"

    if [[ ! -f "$FICH_CONF" ]]; then
        #insert into file default values
        echo "#extensions
        $ALL_EXT
        #Modified time --> none or \"command find time\" --> 24 hours example = \"-mtime 0\" ----> 1 hour = \"-mmin -60\"
        none
        #user: none, root, transmission, ftp, etc.
        none
        #directories to treat --> 0 recursive, 1 no recursive
        1 /volume1
        1 /volume1
        1 /volume1" > "$FICH_CONF"
        exit
    fi

    #flag for read extensions, time for find and user for find from file FICH_CONF
    READ_EXT=0
    READ_TIME=0
    READ_USER=0
}

#---------------------------------------------
#function to extract the extension of a path
#---------------------------------------------
extension(){
    FICH_EXT=${FICH_MEDIA##*.}

    #convert to uppercase the extension
    FICH_EXT=$(echo $FICH_EXT | tr 'a-z' 'A-Z')
}


#---------------------------------------------
#function to check it is a treatable extension
#---------------------------------------------
check_extension(){
if echo "$ALL_EXT" | grep -q "$FICH_EXT"; then
    TREATABLE=1
else
    TREATABLE=0
fi

}


#---------------------------------------------
#function to check if directory is in the DB
#---------------------------------------------
search_directory_DB(){
    PATH_MEDIA=${FICH_MEDIA%/*}
    PATH_MEDIA=$(echo $PATH_MEDIA | tr 'A-Z' 'a-z')

    #replace "'" with "\'"
    PATH_MEDIA_SQL=${PATH_MEDIA//"'"/"\'"}
    TOTAL=0
    FIRST=1
    CREATE_DIR=0

while : ; do
    TOTAL=`/usr/syno/pgsql/bin/psql mediaserver admin -tA -c "select count(1) from directory where lower(path) like '%$PATH_MEDIA_SQL%'"`

if [ "$TOTAL" = 0 ]; then
if [ "$FIRST" = 1 ]; then
    FIRST=0
else
    PATH_MEDIA=${PATH_MEDIA%/*}
fi
    CREATE_DIR=1
fi

    PATH_MEDIA_SQL=${PATH_MEDIA_SQL%/*}
if [ -z $PATH_MEDIA_SQL ]; then
    break
fi
done

}


#---------------------------------------------
# check if file is in the DB
#---------------------------------------------
search_file_DB(){

    #replace " with \"
    VIDEO_PATH_SQL=${$1//'"'/'\"'}
    TOTAL=$(/usr/syno/pgsql/bin/psql mediaserver admin -tA -c "select count(1) from video_file where path like '% like '%$VIDEO_PATH_SQL'")
}

#---------------------------------------------
# check if Episode Name is already in DB
#---------------------------------------------
search_file_DB(){

    #replace " with "\'"
    FICH_MEDIA_SQL=${FICH_MEDIA//"'"/"\'"}

    SHOWTITLE=$(/usr/syno/pgsql/bin/psql mediaserver admin -tA -c \
    "select tag_line from video_file v,tvshow_episode t where v.mapper_id=t.mapper_id and path like '%$VIDEO_PATH_SQL'")

}



regex=".+S[0-9]+.?E[0-9]+.? ?(.*)\.(mp4|mkv)"
showName_from_filename(){
  [[ $1 =~ $regex ]] && echo "File $1; Name: ${BASH_REMATCH[1]}"
}



#---------------------------------------------
#function to add directory to DB
#---------------------------------------------
add_directory_DB(){
    synoindex -A "$PATH_MEDIA"
    echo "added directory: $PATH_MEDIA to DB" >> $PATH_LOG
}


#---------------------------------------------
#function to add file to DB
#---------------------------------------------
add_file_DB(){
    synoindex -a "$FICH_MEDIA"
    echo "added file: $FICH_MEDIA to DB" >> $PATH_LOG
}


#---------------------------------------------
#function to treat directories
#---------------------------------------------
treat_directories(){
CREATE_FILE=1

search_directory_DB
SEARCH_RETVAL=$?

if [ "$SEARCH_RETVAL" == 1 ]; then
add_directory_DB
CREATE_FILE=0
fi

return $CREATE_FILE
}


#---------------------------------------------
#function to treat files
#---------------------------------------------
treat_files(){
    extension
    check_extension

    EXT_RETVAL=$?
    if [ "$EXT_RETVAL" == 1 ]; then
        search_file_DB
        SEARCH_RETVAL=$?

        if [ "$SEARCH_RETVAL" == 0 ]; then
            treat_directories

            EXT_RETVAL=$?

            if [ "$EXT_RETVAL" == 1 ]; then
                add_file_DB
            fi
        fi
    fi
}


#---------------------------------------------
#function for the main program
#---------------------------------------------
treatment(){
    #read file FICH_CONF
    while read LINE || [ -n "$LINE" ]; do

        #skip comment and blank lines
        case "$LINE" in
            \#*)
             continue ;;
        esac
        [ -z "$LINE" ] && continue

        #read the extensions from file
        if [[ "$READ_EXT" -eq 0 ]]; then

            ALL_EXT=$LINE

            #convert to uppercase
            ALL_EXT=$(echo $ALL_EXT | tr 'a-z' 'A-Z')

            READ_EXT=1
            continue
        fi

        #read the update time from file
        if [[ "$READ_TIME" -eq 0 ]]; then
             LINE=$(echo $LINE | tr 'A-Z' 'a-z')

            if [ "$LINE" == "none" ]; then
                TIME_UPD=""
            else
                TIME_UPD="$LINE"
            fi

            READ_TIME=1
            continue
        fi

        #read the user from file
        if [[ "$READ_USER" -eq 0 ]]; then
            LINE=$(echo $LINE | tr 'A-Z' 'a-z')

            if [ "$LINE" == "none" ]; then
                USER_OWN=""
            else
                USER_OWN="-user $LINE"
            fi

            READ_USER=1
            continue
        fi

        #read the paths from file
        RECURSIVE=$(echo $LINE | awk -F" " '{print $1}')
        PATH_FILE=$(echo $LINE | awk -F" " '{print $2}')

        #delete last / if exists
        PATH_FILE="${PATH_FILE%/}"

        if [[ "$RECURSIVE" -eq 0 ]]; then
            #recursive find
            RECURSIVE=""
        else
            #no recursive find
            RECURSIVE="-maxdepth $RECURSIVE"
        fi

        PARAMETERS="$PATH_FILE $RECURSIVE $TIME_UPD -type f $USER_OWN"

        find $PARAMETERS |
        while read FICH_MEDIA
        do
            treat_files
        done

    done < $FICH_CONF
}


#---------------------------------------------
#main
#---------------------------------------------
PATH_LOG="/volume1/public/log/update-synoindex.log"
echo "program executed at: " `date +"%Y-%m-%d %H:%M:%S` >> $PATH_LOG
set_environment
treatment