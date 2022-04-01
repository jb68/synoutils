!/bin/sh

###########################################################################################
# Script to find and list Errors Movies / Files with Video Station............ #
# Copyright ® 2014 #
# Author : Pierre-Jean BELLAVOINE - pierrejean75@gmail.com #
# Version 1.00 #
###########################################################################################

echo ""
echo ""
echo "This script will test in your Video Station databases all incoherences"
echo "double movies, movies not found by Video Station scrappers etc ... "
echo "This process will go trough 4 differents steps "
echo "and will create in the same directory of the script a CSV file"
echo "This file will contain all movies with potential errors"
echo ""
echo "Step 1 : Double Movies"
echo "Step 2 : Movies with not French Informations or "
echo "Step 3 : Movies with empty informations"
echo "Step 4 : Movies with different Video Station Title and file name "
echo ""
echo "Name of the created file : VideoStation_Error.csv"
echo ""
echo "You can open it with Excel or any Text Editor"
echo ""
echo ""
read -p 'Do you want to launch the script ? (y/n)' LAUNCH </dev/tty
if [ "$LAUNCH" != "y" ]; then exit; fi


###########################################################################################
# Inititialisation
###########################################################################################

MAPP_ID0=0
CHEMIN0=""
echo $CHEMIN > VideoStation_Error.csv

###########################################################################################
# Step 1 : double movies
###########################################################################################


echo "----------------------------------------------------------------------"
echo " STEP 1 : Double movies "
echo "----------------------------------------------------------------------"

echo " ---------------------------------------------------------------------" >> VideoStation_Error.csv
echo " STEP 1 : Double movies " >> VideoStation_Error.csv
echo " ---------------------------------------------------------------------" >> VideoStation_Error.csv
echo " "
echo "Step 1 - Ref.;TITLE MOVIE;TITLE DOUBLE MOVIE" >> VideoStation_Error.csv
echo " "


/usr/bin/psql -U postgres -d video_metadata -q -A -t -c "select mapper_id,path from video_file order by mapper_id asc;" | while read ENTRY

do

MAPP_ID=$(echo $ENTRY|cut -f1 -s -d"|")
CHEMIN=$(echo $ENTRY|cut -f2 -s -d"|")

if [ "$MAPP_ID" == "$MAPP_ID0" ]
then
echo "Step 1 - KO : " $MAPP_ID " - " $CHEMIN0 " --> " $CHEMIN
echo "Step 1 - "$MAPP_ID";"$CHEMIN0";"$CHEMIN >> VideoStation_Error.csv
else
echo "Step 1 - OK : " $MAPP_ID " - " $CHEMIN0
fi

MAPP_ID0=$MAPP_ID
CHEMIN0=$CHEMIN

done


###########################################################################################
# Step 2 : movies with not French information in the resume
###########################################################################################



echo "----------------------------------------------------------------------"
echo " STEP 2 : Movies with not French information in the resume "
echo "----------------------------------------------------------------------"

echo "----------------------------------------------------------------------" >> VideoStation_Error.csv
echo " STEP 2 : Movies with not French information in the resume " >> VideoStation_Error.csv
echo "----------------------------------------------------------------------" >> VideoStation_Error.csv
echo " "
echo "Step 2 - Ref.;TITLE;RESUME" >> VideoStation_Error.csv
echo " "

/usr/bin/psql -U postgres -d video_metadata -q -A -t -c "select a.id,a.title,a.sort_title,c.summary from movie a, summary c where c.mapper_id=a.mapper_id order by a.id desc;" | while read ENTRY

do

MAPP_ID=$(echo $ENTRY|cut -f1 -s -d"|")
TITRE=$(echo $ENTRY|cut -f2 -s -d"|")
SORTTITRE=$(echo $ENTRY|cut -f3 -s -d"|")
RESUME=$(echo $ENTRY|cut -f4 -s -d"|")

# we are looking for the some words which are very often present in French "Un " "Une " "Le " "La "... Les " in the RESUME because there are usually present in French langage
Test=`echo $RESUME | grep -c "Un \| un \|Une \| une \|Les \| les \|Le \| le \|La \| la \|Les \| les \|l'\|L'\| est \| et \| sont \| deux \|Deux \|Trois \| trois \| dans \| pour \| son \| des \| du \|beaucoup \| histoire"`

# For other languages just change the words to be find, here an example for English test
# we are looking for the following words very often present in English "is " "the " "The " "are "... Les " in the RESUME because there are usually present in French langage
# for other languages just change the words to be find
# Just templace the precedent ligne begining with Test= by the following line
# Test=`echo $RESUME | grep -c "The \| the \|They \| they \|In \| in \| are \| is \| et \| two \|Three \| many \| history"`
#


# Control if one condition of the test has been found
if [ $Test -gt 0 ]
then
echo "Step 2 - OK : " $MAPP_ID " - " $TITRE
else
echo "Step 2 - KO : " $MAPP_ID " - " $TITRE
echo "Step 2 - "$MAPP_ID";"$TITRE";"$RESUME >> VideoStation_Error.csv
fi



done



###########################################################################################
# Step 3 : Movies with empty information
###########################################################################################


echo "----------------------------------------------------------------------"
echo " STEP 3 : Movies with empty informations "
echo "----------------------------------------------------------------------"


echo "----------------------------------------------------------------------" >> VideoStation_Error.csv
echo " STEP 3 : Movies with empty informations " >> VideoStation_Error.csv
echo "----------------------------------------------------------------------" >> VideoStation_Error.csv
echo " "
echo "Step 3 - Ref.;TITLE;RESUME" >> VideoStation_Error.csv
echo " "

/usr/bin/psql -U postgres -d video_metadata -q -A -t -c "select a.id,a.title,a.sort_title,c.summary from movie a, summary c where c.mapper_id=a.mapper_id order by a.id desc;" | while read ENTRY

do

MAPP_ID=$(echo $ENTRY|cut -f1 -s -d"|")
TITRE=$(echo $ENTRY|cut -f2 -s -d"|")
SORTTITRE=$(echo $ENTRY|cut -f3 -s -d"|")
RESUME=$(echo $ENTRY|cut -f4 -s -d"|")


#
if [ -z "${RESUME}" ]
then
echo "Step 3 - KO : " $MAPP_ID " - " $TITRE
echo "Step 3 - "$MAPP_ID";"$TITRE";"$RESUME >> VideoStation_Error.csv
else
echo "Step 3 - OK : " $MAPP_ID " - " $TITRE
fi

done





###########################################################################################
# Step 4 : Movies with different "Video Station Title" and "file name"
###########################################################################################


echo "----------------------------------------------------------------------"
echo " STEP 4 : Movies with different 'Video Station Title' and 'file name "
echo "----------------------------------------------------------------------"

echo " ---------------------------------------------------------------------" >> VideoStation_Error.csv
echo " STEP 4 : Movies with different 'Video Station Title' and 'file name " >> VideoStation_Error.csv
echo " ---------------------------------------------------------------------" >> VideoStation_Error.csv
echo " "
echo " Step 4 - Ref.;TITLE VIDEO STATION;NAME OF THE FILE" >> VideoStation_Error.csv
echo " "

/usr/bin/psql -U postgres -d video_metadata -q -A -t -c "select c.id,title,path from movie a, video_file c where c.mapper_id=a.mapper_id order by c.id desc;" | while read ENTRY
do
MAPP_ID=$(echo $ENTRY|cut -f1 -s -d"|")
TITRE=$(echo $ENTRY|cut -f2 -s -d"|")
CHEMIN=$(echo $ENTRY|cut -f3 -s -d"|")

# DOSSIER=$(dirname "$CHEMIN")
# FILES1=$(basename "$DOSSIER")
# FILES2=$(basename "$CHEMIN")


#example of result :
# $MAPP_ID = 44184
# $TITRE = Flicka
# $CHEMIN = /volume1/video/Films/Flicka (2006).avi
# $DOSSIER = /volume1/video/Films
# $FILES1 = Films
# $FILES2 = Flicka (2006).avi


# Step 1 : to eliminate the last character if it's a blank space
# Step 2 : eliminate the ponctuations characters
# Step 3 : eliminate the accents
# Step 4 : eliminate the arabian character like I II III IV V...
# Step 5 : eliminate double or triple continuous space character
# Step 6 : lower case to upper case

TITRE1=`echo "$TITRE" |sed -e "s/ *$//"`
TITRE1=$(echo $TITRE1 |sed 's/ et /&/g' |sed 's/ and /&/g' |sed 's/?//g' |sed 's/\// /g' |sed -e 's/\$//g' |sed 's/!//g' |sed 's/:/ /g' |sed 's/-/ /g' |sed 's/,/ /g' |sed 's/?//g' |sed 's/·/ /g' |sed "s/\’/ /g" |sed "s/\'/ /g")
TITRE1=$(echo $TITRE1 |sed 's/à/a/g' |sed 's/â/a/g' |sed 's/ç/c/g' |sed 's/é/e/g' |sed 's/è/e/g' |sed 's/ê/e/g' |sed 's/ë/e/g' |sed 's/î/i/g' |sed 's/ï/i/g' |sed 's/ô/o/g' |sed 's/ö/o/g' |sed 's/œ/oe/g' |sed 's/Œ/oe/g' |sed 's/ù/u/g' |sed 's/ü/u/g' |sed 's/Â/A/g' |sed 's/Ç/C/g' |sed 's/É/E/g' |sed 's/È/E/g' |sed 's/Ê/E/g' |sed 's/Ë/E/g' |sed 's/Î/I/g' |sed 's/Ï/I/g' |sed 's/Ô/O/g' |sed 's/Ö/O/g' |sed 's/Ù/U/g' |sed 's/Ü/U/g' |sed -e 's/À/A/g' )
TITRE1=$(echo $TITRE1 |sed "s/II/2/g" |sed "s/ III /3/g" |sed "s/ IV /4/g" |sed "s/ V /5/g" |sed "s/ VI /6/g" |sed "s/ VII /7/g" )
TITRE1=$(echo $TITRE1 |sed "s/ / /g"|sed "s/ / /g")
TITRE1=$(echo $TITRE1 |sed 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/')


# Step 1 : to eliminate the last character if it's a blank space
# Step 2 : eliminate the ponctuations characters
# Step 3 : eliminate the accents
# Step 4 : eliminate the arabian character like I II III IV V...
# Step 5 : eliminate double or triple continuous space character
# Step 6 : lower case to upper case

CHEMIN1=`echo "$CHEMIN" |sed -e "s/ *$//"`
CHEMIN1=$(echo $CHEMIN1 |sed 's/ et /&/g' |sed 's/ and /&/g' |sed 's/?//g' |sed 's/\// /g' |sed -e 's/\$//g' |sed 's/!//g' |sed 's/:/ /g' |sed 's/-/ /g' |sed 's/,/ /g' |sed 's/?//g' |sed 's/·/ /g' |sed "s/\’/ /g" |sed "s/\'/ /g")
CHEMIN1=$(echo $CHEMIN1 |sed 's/à/a/g' |sed 's/â/a/g' |sed 's/ç/c/g' |sed 's/é/e/g' |sed 's/è/e/g' |sed 's/ê/e/g' |sed 's/ë/e/g' |sed 's/î/i/g' |sed 's/ï/i/g' |sed 's/ô/o/g' |sed 's/ö/o/g' |sed 's/œ/oe/g' |sed 's/Œ/oe/g' |sed 's/ù/u/g' |sed 's/ü/u/g' |sed 's/Â/A/g' |sed 's/Ç/C/g' |sed 's/É/E/g' |sed 's/È/E/g' |sed 's/Ê/E/g' |sed 's/Ë/E/g' |sed 's/Î/I/g' |sed 's/Ï/I/g' |sed 's/Ô/O/g' |sed 's/Ö/O/g' |sed 's/Ù/U/g' |sed 's/Ü/U/g' |sed -e 's/À/A/g' )
CHEMIN1=$(echo $CHEMIN1 |sed "s/II/2/g" |sed "s/ III /3/g" |sed "s/ IV /4/g" |sed "s/ V /5/g" |sed "s/ VI /6/g" |sed "s/ VII /7/g" )
CHEMIN1=$(echo $CHEMIN1 |sed 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/')
CHEMIN1=$(echo $CHEMIN1 |sed "s/ / /g"|sed "s/ / /g")

if echo "$CHEMIN1" | grep -q -F "$TITRE1";
then
echo "Step 4 - OK : " $MAPP_ID " - " $TITRE
else
echo "Step 4 - KO : " $MAPP_ID " - " $TITRE
echo "Step 4 - "$MAPP_ID ";"$TITRE";"$CHEMIN >> VideoStation_Error.csv
fi

done


###########################################################################################
# Fin
###########################################################################################


echo " "
echo " "
echo "**********************************************************************"
echo "End of the process "
echo " "
echo "Created file : VideoStation_Error.csv"
echo " "
echo "Location of the created file : same directory as the script "
echo "**********************************************************************"
echo " "
echo "Copyright ® 2014. Pierre-Jean BELLAVOINE"
echo " "