#!/bin/sh -x
# This script is the post install of the MovieNight FreeNAS plugin. 
# It's main purpose is to download GoLang SDK and MovieNight sources, then it build MovieNight and run it.   
# git clone https://github.com/zorglube/freenas-iocage-movienight

# Check for root privileges
if ! [ $(id -u) = 0 ]; 
then
   echo "This script must be run with root privileges"
   exit 1
fi

#####
#
# General configuration
#
#####

# Initialize defaults
UID="movienight"
GID=${UID}
UID_GID_ID="850"
TARGET="freebsd"
ARCH="amd64"
MN_REPO="https://github.com/zorglube/MovieNight.git"

#SCRIPT=$(readlink -f "$0")
#SCRIPTPATH=$(dirname "${SCRIPT}")

##
#
# Create user that run the MN process into the jail
#
##
pw user add ${UID} -c ${GID} -u ${UID_GID_ID} -d /nonexistent -s /usr/bin/nologin

#####
#
# MovieNight Download and Setup
#
#####
MN_URL=${MN_REPO}
MN_HOME="/usr/local/movienight"
MN_MAKEFILE=${MN_HOME}"/Makefile.BSD"
if ! mkdir ${MN_HOME}
then
	echo "Failed to create download temp dir"
	exit 1
fi
cd ${MN_HOME}
if ! git clone ${MN_URL} ${MN_HOME}
then
	echo "Failed to clone Movie Night"
	exit 1
fi
if ! make TARGET=${TARGET} ARCH=${ARCH} -f ${MN_MAKEFILE} -C ${MN_HOME}
then
	echo "Failed to make Movie Night"
	exit 1
fi 

if ! chown -R ${UID}:${GID} ${MN_HOME}
then
	echo "Failed to chown ${MN_HOME}"
	exit 1
fi 

#####
#
# Set the MovieNight config
#
#####

rm ${MN_HOME}/settings.json
mv ${MN_HOME}/settings-freebsd.json ${MN_HOME}/settings.json

# Create MN log file
touch /var/log/movienight.log
# Enable the service
sysrc -f /etc/rc.conf movienight_enable="YES"
# Start the service
service movienight start 2>/dev/null
