#!/bin/sh
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
ARCH="386"
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
# GO Download and Setup
#
#####
USR_LOCAL="/usr/local"
GO_DL_VERSION="go1.15.freebsd-amd64.tar.gz"
GO_URL="https://golang.org/dl/${GO_DL_VERSION}"
GO_PATH=${USR_LOCAL}"/go/bin"
ROOT_PROFILE="/root/.profile"
SHELL="/bin/bash"
OS=`uname`

if ! fetch -o /tmp ${GO_URL}
then
	echo "Failed to download GO"
	exit 1
fi
if ! tar xzf /tmp/${GO_DL_VERSION} -C ${USR_LOCAL}
then
	echo "Failed to extract GO"
	exit 1
fi

echo "setenv  OS  ${OS}" >> /root/.cshrc
echo "setenv  GO  ${GO_PATH}" >> /root/.cshrc
echo "setenv  PATH    ${PATH}:${GO_PATH}" >> /root/.cshrc
setenv  OS  ${OS}
setenv  GO  ${GO_PATH}
setenv  PATH    ${PATH}:${GO_PATH}

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
#if ! link ${GO_PATH}/go ${USR_LOCAL}/bin/go
#then 
#    echo "Failed link to GO"
#    exit 1
#fi
#if ! link ${GO_PATH}/gofmt ${USR_LOCAL}/bin/gofmt
#then 
#    echo "Failed link to GOFMT"
#    exit 1
#fi
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

rm /tmp/${GO_DL_VERSION}

# Enable the service
sysrc -f /etc/rc.conf movienight_enable="YES"
# Start the service
service movienight start 2>/dev/null
