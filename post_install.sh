#!/bin/sh
# This script is the post install of the MovieNight FreeNAS plugin.
# It's main purpose is to download GoLang SDK and MovieNight sources, then it build MovieNight and run it.
# git clone https://github.com/zorglube/freenas-iocage-movienight

#####
#
# Create user that run the MN process into the jail
#
#####
# UID:GID is 'movien' because 'movienight' is to long
UID=movien
GID=${UID}
UID_GID_ID=850
pw user add ${UID} -c ${GID} -u ${UID_GID_ID} -d /nonexistent -s /usr/bin/nologin

#####
#
# MovieNight Download and build
#
#####
TARGET=freebsd
ARCH=amd64
MN_REPO=https://github.com/zorglube/MovieNight.git
MN_HOME=/usr/local/movienight
MN_MAKEFILE=${MN_HOME}/Makefile.BSD
mkdir ${MN_HOME}
echo "=> Git Clonning "
git clone ${MN_REPO} ${MN_HOME} && echo "=> Cloned "
echo "=> Building "
make TARGET=${TARGET} ARCH=${ARCH} -f ${MN_MAKEFILE} -C ${MN_HOME} && echo " Build end "
chown -R ${UID}:${GID} ${MN_HOME}
# Set the MovieNight config
rm ${MN_HOME}/settings.json
mv ${MN_HOME}/settings-freebsd.json ${MN_HOME}/settings.json
chmod 755 ${MN_HOME}
chmod +x ${MN_HOME}/MovieNight
# Create MN log file
touch /var/log/movienight.log
# Enable the service
sysrc -f /etc/rc.conf movienight_enable="YES"
# Start the service
service movienight start 2>/dev/null
