#!/usr/bin/bash

TORID=()
WORKING_DIR="$(pwd)"
TORFILES="$WORKING_DIR/torfiles"
HDB_UID_FILE="$WORKING_DIR/.hdb_uid"
COOKIES_FILE="$WORKING_DIR/.cookies"
PASSKEY_FILE="$WORKING_DIR/.passkey"

#check_env(){
#}
#check_cookies(){
#}

get_uid(){
        if [ ! -f "$HDB_UID_FILE" ]; then
                echo 'ERROR :: UserID not found!'
                read -p 'UserID: ' HDB_UID_TMP
                touch "$HDB_UID_FILE" && echo "$HDB_UID_TMP" > "$HDB_UID_FILE"
        fi
        HDB_UID="$(cat $HDB_UID_FILE)"
	echo "UserID loaded..."
}

get_cookies(){
        if [ ! -f "$COOKIES_FILE" ]; then
                echo 'ERROR :: Cookies not found!'
		echo "Path should be: $COOKIES_FILE" 
                echo "Use browser to download cookies"
		exit 1
        fi
}

get_passkey(){
	if [ ! -f "$PASSKEY_FILE" ]; then
		echo 'ERROR :: Passkey not found!'
		echo "Get your passkey here ---> https://hdbits.org/userdetails.php?id=$HDB_UID"
		read -sp 'Passkey: ' PASSKEY_TMP
		touch "$PASSKEY_FILE" && echo "$PASSKEY_TMP" > "$PASSKEY_FILE"
	fi
        PASSKEY="$(cat $PASSKEY_FILE)"
        echo 'Passkey loaded...'
}

get_unseeded(){
	UNSEEDED_URL="https://hdbits.org/userdetails.php?id=$HDB_UID&completed_notseeding=1"
	echo "Gathering unseeded torrents..."
	IFS=$'\n' read -r -d '' -a \
		TORID < <( curl -sb "$COOKIES_FILE" "$UNSEEDED_URL" \
		| grep -Eoi '<a [^>]+>' \
		| grep -v "$HDB_UID" \
		| grep -Eo 'id=(.*?)\&' | cut -d \& -f1 \
		| cut -d = -f2- \
		&& printf '\0')
}

get_torrents(){
	cd "$TORFILES"
	for ID in "${TORID[@]}"; do
                echo "Torrent ID :: $ID"
		echo "Downloading file...." && sleep 1.25
		curl -O -J -L -b "$COOKIES_FILE" --progress-bar "https://hdbits.org/download.php?id=$ID&passkey=$PASSKEY"
		if [[ "$(ls -1Atr $TORFILES | tail -1)" =~ ^download.php* ]]
		then
			echo "ERROR :: Problem downloading torrent file!"
			exit 1
		else
                	echo "Filename :: $(ls -1Atr $TORFILES | tail -1)" && echo "" && echo ""
		fi
		((c++)) && ((c==35)) && c=0 && sleep 900
	done
}

get_uid
get_passkey
get_unseeded
get_torrents

