#!/bin/bash

# Copyright (C) 2019 Ayush Dubey <ayushdubey70@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


source bot_config.conf

export BUILD_FINISHED=false

sendMessage() {
MESSAGE=$1

curl -s "https://api.telegram.org/bot${BOT_API_KEY}/sendmessage" --data "text=$MESSAGE&chat_id=$CHAT_ID" 1> /dev/null

echo -e;
}

sendMessage "Starting build for $DEVICE"

#start build
lunch $ROM\_$DEVICE-userdebug | tee lunch.log
# catch lunch error
if [ $? -eq 0 ]
then
   echo "Starting Build\(brunch\)"
	 sendMessage "Starting Real build."
   source build/envsetup.sh
	 brunch $DEVICE -j$CPU_INFO | tee build.log
	if [ $? -eq 0 ]
	then
		echo "Build Done for $ROM $DEVICE"
		sendMessage "Build Completed Successfully"
    BUILD_FINISHED=true
    if [ $BUILD_FINISHED = true  ] ; then

		#upLoading
		  OUTPUT_FILE=$(grep -o -P '(?<=Package\ Complete).*(?=.zip)' build.log)'.zip'
		  OUTPUT_LOC=$(echo $OUTPUT_FILE | cut -f2 -d":")
		  echo $OUTPUT_LOC
			sendMessage "Uploading to GDrive"
			gdrive upload $OUTPUT_LOC | tee upload.log
			sed -e 's/.*Uploaded\(.*\)at.*/\1/' upload.log >> fileid.txt
			sendMessage "Upload Finished."
			sed -e 'id' fileid.txt >> final.txt
			FILE_ID=$(cat final.txt)
			gdrive share $FILE_ID
			URL='https://drive.google.com/open?id='$FILE_ID
			FILE="$(echo -e "${URL}" | tr -d '[:space:]')"
			echo $FILE >> file.txt
			echo $FILE
			sendMessage $FILE

			BUILD_FINISHED=true
		fi
	else
    LOG_BUILD=$(curl --upload-file ./build.log https://transfer.sh/build.log)
		sendMessage "BUILD FAILED WITH AN ERROR :( Check build.log"
    sendMessage $LOG_BUILD
		echo "BUILD FAILED :("
	fi
else
   LOG_LUNCH=$(curl --upload-file ./lunch.log https://transfer.sh/lunch.log)
   sendMessage "LUNCH FAILED WITH AN ERROR :( Check lunch.log"
   sendMessage $LOG_LUNCH
	 echo "LUNCH MENU FAILED :0"
fi

if [ $BUILD_FINISHED = true  ] ; then
MD5=`md5sum ${OUTPUT_LOC} | awk '{ print $1 }'`

read -r -d '' BUILD INFO << INFO
ROM: $ZIPNAME
Build: $BUILD_TYPE
LINK: $FILE
Size: $ZIP_SIZE
MD5: $MD5
INFO
    curl -s "https://api.telegram.org/bot${BOT_API_KEY}/sendmessage" --data "text=$INFO&chat_id=$CHAT_ID" 1> /dev/null
echo -e;

fi

exit 1