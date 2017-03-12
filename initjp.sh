#!/bin/bash

# initjp
# m option: initialize a maven project in the current folder
# i option: create a GitHub local repo and do the first commit
# g option: create a GitHub remote repo and sync the local repo
# the v flags make the operations verbose

CMD_USAGE="Usage: initjp [-mig:] [repo-name]"
DO_CREATE_MVN_PROJ=false
DO_CREATE_LOCAL_REPO=false
DO_CREATE_REMOTE_REPO=false

if [[ $# -lt 1 ]]; then
	echo $CMD_USAGE
	exit 1
fi

while getopts ":mig:" opt; do
	case $opt in
		m) 
			DO_CREATE_MVN_PROJ=true
			;;
		i)
			DO_CREATE_LOCAL_REPO=true
			;;
		g) 
			DO_CREATE_REMOTE_REPO=true
			REPO_NAME="$OPTARG"
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		:) 
			if [[ $OPTARG == "g" ]]; then
				if ! $DO_CREATE_MVN_PROJ; then
					echo "Option -$OPTARG requires an argument" >&2
					exit 1
				fi
				DO_CREATE_REMOTE_REPO=true
			fi
			;;
	esac
done


if $DO_CREATE_MVN_PROJ; then 
	echo -n "Create a new project in $(pwd)? (y/n): "
	read USERCONFIRMATION

	if [[ $USERCONFIRMATION != "y" ]]; then
		exit 1
	fi

	while [[ -z "${PROJ_GROUPID// }" ]]; do
		echo -n "Project groupId: "
		read PROJ_GROUPID
	done

	while [[ -z "${PROJ_ARTIFACTID// }" ]]; do
		echo -n "Project artifactId: "
		read PROJ_ARTIFACTID
	done

	echo -n "Project main class: "
	read PROJ_MAINCLASS

	if [[ -z "${PROJ_MAINCLASS// }" ]]; then
		PROJ_MAINCLASS=Main
	fi

	echo "Select a maven archetype"
	echo "	[1] maven-archetype-archetype"
	echo "	[2] maven-archetype-quickstart"
	echo "	[3] maven-archetype-webapp"
	echo "	[4] java8-archetype"
	echo "	[5] fxml-app-archetype"
	echo "	[6] pom-root"
	echo -n "Archetype number: "
	read ARCHETYPE_NUMBER

	case $ARCHETYPE_NUMBER in
		1)
			ARCH_GROUPID="org.apache.maven.archetypes"
			ARCH_ARTIFACTID="maven-archetype-archetype"
			;;
		2)
			ARCH_GROUPID="org.apache.maven.archetypes"
			ARCH_ARTIFACTID="maven-archetype-quickstart"
			;;
		3)
			ARCH_GROUPID="org.apache.maven.archetypes"
			ARCH_ARTIFACTID="maven-archetype-webapp"
			;;
		4)
			ARCH_GROUPID="com.vibridi"
			ARCH_ARTIFACTID="java8-archetype"
			;;
		5)
			ARCH_GROUPID="com.vibridi"
			ARCH_ARTIFACTID="fxml-app-archetype"
			;;
		6)
			ARCH_GROUPID="org.codehaus.mojo.archetypes"
			ARCH_ARTIFACTID="pom-root"
			;;
		*)
			echo "Invalid archetype"
			exit 1
			;;
	esac

	PROJ_PACKAGE="$PROJ_GROUPID.${PROJ_ARTIFACTID//-/.}"

	echo "Creating maven project..."
	mvn -q archetype:generate -DgroupId=$PROJ_GROUPID -DartifactId=$PROJ_ARTIFACTID -DentryPoint=$PROJ_MAINCLASS -Dpackage=$PROJ_PACKAGE -DarchetypeGroupId=$ARCH_GROUPID -DarchetypeArtifactId=$ARCH_ARTIFACTID -DinteractiveMode=false
	echo "Maven project $PROJ_ARTIFACTID created"
	cd "$PROJ_ARTIFACTID"
fi

if $DO_CREATE_LOCAL_REPO; then

	if ! $DO_CREATE_MVN_PROJ; then
		echo -n "Create a new repo in $(pwd)? (y/n): "
		read USERCONFIRMATION

		if [[ $USERCONFIRMATION != "y" ]]; then
			exit 1
		fi
	fi

	echo "Creating GitHub local repository..."
	git init > /dev/null
	cp /usr/local/git/master-files/gitignore ./.gitignore
	cp /usr/local/git/master-files/mit.txt ./LICENSE
	git add -A . > /dev/null
	git commit -m "First commit" > /dev/null
	echo "Local repository created"
fi

if $DO_CREATE_REMOTE_REPO; then

	if [[ ! -z "$PROJ_ARTIFACTID" ]]; then
		REPO_NAME="$PROJ_ARTIFACTID"
	fi

	echo "Creating GitHub remote repository..."
	HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -u 'vibridi' https://api.github.com/user/repos -d '{"name":"'"$REPO_NAME"'"')

	if [[ $? -ne 0 || $HTTP_STATUS -ne 201 ]]; then
		echo "[ERROR] Failed to create remote repository"
		exit 1
	fi

	git remote add origin https://github.com/vibridi/"$REPO_NAME".git > /dev/null
	if [[ $? -ne 0 ]]; then
		echo "[ERROR] Failed to create origin"
		exit 1
	fi

	echo "Remote repository $REPO_NAME created"

	git push origin master > /dev/null 2>&1
	echo "Sync completed"
fi

