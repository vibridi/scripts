#!/bin/bash

# tronco
# -a: add new service credentials
# -e: edit existing service credentials
# -s: show existing service credentials
# -r: remove existing service credentials
# -c: copy password to clipboard (use only with -s)
# -m: add comment (for now use only with -a)
# -u: add a new user shortcut
# -v: edit an existing user shortcut
# -t: list existing user shortcuts
# TODO -w: remove an existing user shortcut
# more?

CMD_USAGE="Usage: tronco [-a|e|s|rcm|h] <service_name> [-tuv]"

DO_HELP=false
DO_EDIT=false
DO_ADD=false
DO_COPY=false
DO_SHOW=false
DO_RM=false
ADD_COMMENT=false
ADD_USER=false
EDIT_USER=false
LIST_USERS=false
RESTART_SVC=false

if [[ $# -lt 1 ]]; then
	echo $CMD_USAGE
	exit 1
fi

while getopts ":a:e:ms:cr:khuv:t" opt; do
	case $opt in
		a) 
			DO_ADD=true
			SERVICE_NAME="$OPTARG"
			;;
		e)
			DO_EDIT=true
			SERVICE_NAME="$OPTARG"
			;;
		c)
			DO_COPY=true
			;;
		h)
			DO_HELP=true
			;;
		s)
			DO_SHOW=true
			SERVICE_NAME="$OPTARG"
			;;
		m)
			ADD_COMMENT=true
			;;
		r)
			DO_RM=true
			SERVICE_NAME="$OPTARG"
			;;
		u)
			ADD_USER=true
			;;
		v)
			EDIT_USER=true
			SHORTCUT_USER="$OPTARG"
			;;
		t)
			LIST_USERS=true
			;;
		k)
			RESTART_SVC=true
			;;

		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument" >&2
			exit 1
			;;
	esac
done

# -h show help
if $DO_HELP; then
	echo "Tronco - credentials management utility"
	echo "Options:"
	echo "-a <service_name> [-m] -- add new service with user and password; -m and a comment"
	echo "-e <service_name> -- edit credentials of an existing service"
	echo "-s <service_name> [-c] -- show credentials of an existing service; -c copies pwd to clipboard"
	echo "-r <service_name> -- remove an existing service"
	echo "-u -- add user shortcut"
	echo "-v <user> -- edit user shortcut"
	echo "-t -- list existing user shortcuts"
	echo "-k -- restart gpg-agent"
	exit 0
fi

cd ~/.tronco

if [ ! -e "signature.sig" ]; then
	echo "Welcome to Tronco, a credentials management utility based on GPG."
	echo "Before starting, please make sure you have GPG installed and included in your path."
	echo "Do you have GPG installed and included in your path? (y/n): "
	read GPG_YN
	if [ $GPG_YN != 'y' ]; then
		exit 1
	fi
	echo -n "Type the user id name you wish to use to encrypt your data: "
	read GPG_SIGNATURE_ID
	echo "$GPG_SIGNATURE_ID" > signature.sig
	echo "The user id name has been recorded. You can now start using Tronco"
	exit 0
else 
	SIGNATURE=$(cat "./signature.sig")
fi

# -a 
if $DO_ADD; then
	if [ -e "./keys/$SERVICE_NAME.txt.gpg" ]; then
		echo "Service already exists"
		exit 1
	fi

	echo -n "Username: "
	read SERVICE_USER
	echo -n "Password: "
	read SERVICE_PASS

	if [ -e "./users/$SERVICE_USER" ]; then
		SERVICE_USER=$(cat "./users/$SERVICE_USER")
	fi

	echo "$SERVICE_USER|$SERVICE_PASS" > "$SERVICE_NAME.txt"
	gpg -r "$SIGNATURE" -e "$SERVICE_NAME.txt"
	mv "$SERVICE_NAME.txt.gpg" "./keys/"  
	rm "$SERVICE_NAME.txt"

	if $ADD_COMMENT; then
		echo "Additional comments (ctrl+C to confirm): "
		cat > "./comments/$SERVICE_NAME.txt"
	fi

	exit 0
fi

# -e
if $DO_EDIT; then
	if [ ! -e "./keys/$SERVICE_NAME.txt.gpg" ]; then
		echo "Unknown service"
		exit 1
	fi

	echo -n "Username: "
	read SERVICE_USER
	echo -n "Password: "
	read SERVICE_PASS

	DECRYPTED=$(gpg -d "./keys/$SERVICE_NAME.txt.gpg" 2>/dev/null)
	STORED_USER=$(echo $DECRYPTED | cut -d '|' -f 1)
	STORED_PASS=$(echo $DECRYPTED | cut -d '|' -f 2)

	if [ -z $SERVICE_USER ]; then
		SERVICE_USER=$STORED_USER
	else 
		if [ -e "./users/$SERVICE_USER" ]; then
			SERVICE_USER=$(cat "./users/$SERVICE_USER")
		fi
	fi

	if [ -z $SERVICE_PASS ]; then
		SERVICE_PASS=$STORED_PASS
	fi

	echo "$SERVICE_USER|$SERVICE_PASS" > "$SERVICE_NAME.txt"
	gpg -r "$SIGNATURE" -e "$SERVICE_NAME.txt" 
	mv "$SERVICE_NAME.txt.gpg" "./keys/"  
	rm "$SERVICE_NAME.txt"

	if $ADD_COMMENT; then
		echo "Additional comments (ctrl+C to confirm): "
		if [ -e "./comments/$SERVICE_NAME.txt" ]; then
			cat >> "./comments/$SERVICE_NAME.txt"
		else
			cat > "./comments/$SERVICE_NAME.txt"
		fi
	fi

	echo "Entry modified."

	exit 0
fi

# -s
if $DO_SHOW; then
	if [ ! -e "./keys/$SERVICE_NAME.txt.gpg" ]; then
		echo "Unknown service"
		exit 1
	fi

	DECRYPTED=$(gpg -d "./keys/$SERVICE_NAME.txt.gpg" 2>/dev/null)
	STORED_USER=$(echo $DECRYPTED | cut -d '|' -f 1)
	STORED_PASS=$(echo $DECRYPTED | cut -d '|' -f 2)

	echo "Username: $(tput bold)$STORED_USER$(tput sgr0)"
	echo "Password: $(tput bold)$STORED_PASS$(tput sgr0)"

	if $DO_COPY; then
		echo $STORED_PASS | pbcopy
	fi

	if [ -e "./comments/$SERVICE_NAME.txt" ]; then
		echo "Additional comments: "
		cat "./comments/$SERVICE_NAME.txt"
	fi

	exit 0
fi

# -r
if $DO_RM; then 
	if [ -e "./keys/$SERVICE_NAME.txt.gpg" ]; then
		rm "./keys/$SERVICE_NAME.txt.gpg"
	fi

	if [ -e "./comments/$SERVICE_NAME.txt" ]; then
		rm "./comments/$SERVICE_NAME.txt"
	fi

fi

# -u 
if $ADD_USER; then
	echo "Add a shortcut name for a user"
	echo -n "Shortcut: "
	read SHORTCUT_USER
	echo -n "Username: "
	read FULL_USER

	if [ -e "./users/$SHORTCUT_USER" ]; then
		echo "Shortcut already exists"
		exit 1
	fi

	echo $FULL_USER > "./users/$SHORTCUT_USER"
fi

# -v
if $EDIT_USER; then
	if [ ! -e "./users/$SHORTCUT_USER" ]; then
		echo "Shortcut user not found"
		exit 1
	fi
	echo -n "New shortcut: "
	read NEW_SHORTCUT
	mv "./users/$SHORTCUT_USER" "./users/$NEW_SHORTCUT"
fi

# -t
if $LIST_USERS; then
	cd users
	ALL_USERS="*"
	for USER_FILE in $ALL_USERS; do
		echo "$(tput bold)$USER_FILE$(tput sgr0) -> $(cat $USER_FILE)"
	done
fi

# -k
if $RESTART_SVC; then
	gpgconf --kill gpg-agent
	echo "gpg has been rebooted"
fi





