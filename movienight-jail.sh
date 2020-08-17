#!/bin/sh
# Build an iocage jail under FreeNAS 11.3 using the current release of Movie Night
# git clone https://github.com/zorglube/freenas-iocage-movienight

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

#####
#
# General configuration
#
#####

# Initialize defaults
JAIL_IP=""
JAIL_INTERFACES=""
DEFAULT_GW_IP=""
INTERFACE="vnet0"
VNET="on"
JAIL_NAME="movienight"
CONFIG_NAME="mn-config"
GO_DL_VERSION=""
UID="movienight"
GID=${UID}
UID_GID_ID="850"

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
# Check for mn-config and set configuration
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  echo "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
. "${SCRIPTPATH}"/"${CONFIG_NAME}"
INCLUDES_PATH="${SCRIPTPATH}"/includes

JAILS_MOUNT=$(zfs get -H -o value mountpoint $(iocage get -p)/iocage)
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g" | sed "s/-p[0-9]*//")

#####
#
# Input/Config Sanity checks
#
#####

# Check that necessary variables were set by nextcloud-config
if [ -z "${JAIL_IP}" ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z "${JAIL_INTERFACES}" ]; then
  echo 'JAIL_INTERFACES not set, defaulting to: vnet0:bridge0'
  JAIL_INTERFACES="vnet0:bridge0"
fi
if [ -z "${DEFAULT_GW_IP}" ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi
if [ -z "${GO_DL_VERSION}" ]; then
  echo 'Configuration error: GO_DL_VERSION must be set'
  exit 1
fi

# Extract IP and netmask, sanity check netmask
IP=$(echo ${JAIL_IP} | cut -f1 -d/)
NETMASK=$(echo ${JAIL_IP} | cut -f2 -d/)
if [ "${NETMASK}" = "${IP}" ]
then
  NETMASK="24"
fi
if [ "${NETMASK}" -lt 8 ] || [ "${NETMASK}" -gt 30 ]
then
  NETMASK="24"
fi

#####
#
# Jail Creation
#
#####

# List packages to be auto-installed after jail creation
# Certaily useless
cat <<__EOF__ >/tmp/pkg.json
	{
  "pkgs":[
  	"nano","bash","gzip","ca_root_nss","git","sed"
  ]
}
__EOF__

# Create the jail and install previously listed packages
if ! iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r "${RELEASE}" interfaces="${JAIL_INTERFACES}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"
then
	echo "Failed to create jail"
	exit 1
fi
rm /tmp/pkg.json

##
#
# Create user that run the MN process into the jail
#
##
iocage exec "${JAIL_NAME}" "pw user add ${UID} -c ${GID} -u ${UID_GID_ID} -d /nonexistent -s /usr/bin/nologin"

#####
#
# GO Download and Setup
#
#####
USR_LOCAL="/usr/local"
GO_URL="https://golang.org/dl/${GO_DL_VERSION}"
GO_PATH=${USR_LOCAL}"/go/bin"
ROOT_PROFILE="/root/.profile"
if ! iocage exec "${JAIL_NAME}" fetch -o /tmp "${GO_URL}"
then
	echo "Failed to download GO"
	exit 1
fi
if ! iocage exec "${JAIL_NAME}" tar xzf /tmp/"${GO_DL_VERSION}" -C "${USR_LOCAL}"
then
	echo "Failed to extract GO"
	exit 1
fi
if ! iocage exec "${JAIL_NAME}" sed '/PATH=${PATH}/ c PATH=${PATH}:${GO_PATH}' "${ROOT_PROFILE}" >> "${ROOT_PROFILE}"
then 
    echo "Failed to sed PATH /root/.profile"
    exit 1
fi
if ! iocage exec "${JAIL_NAME}" sed '/PATH/ a GO_VERSION=${GO_PATH}' "${ROOT_PROFILE}" >> "${ROOT_PROFILE}"
then 
    echo "Failed to sed GO_VERSION /root/.profile"
    exit 1
fi
OS=`uname`
if ! iocage exec "${JAIL_NAME}" sed '/GO_VERSION/ a OS=${OS}' "${ROOT_PROFILE}" >> "${ROOT_PROFILE}"
then 
    echo "Failed to sed OS /root/.profile"
    exit 1
fi
if ! iocage exec "${JAIL_NAME}" sed '/SHELL=${SHELL}/ c SHELL=/bin/bash' "${ROOT_PROFILE}" >> "${ROOT_PROFILE}"
then 
    echo "Failed to sed SHELL /root/.profile"
    exit 1
fi
if ! iocage restart "${JAIL_NAME}"
then 
    echo "Fail to restart Jail"
    exit 1
fi

#####
#
# MovieNight Download and Setup
#
#####
MN_URL="https://github.com/zorchenhimer/MovieNight.git"
MN_HOME="/usr/local/movienight"
MN_MAKEFILE="${MN_HOME}"/MakeFile
if ! iocage exec "${JAIL_NAME}" mkdir "${MN_HOME}"
then
	echo "Failed to create download temp dir"
	exit 1
fi
iocage exec "${JAIL_NAME}" cd "${MN_HOME}"
if ! iocage exec "${JAIL_NAME}" git clone "${MN_URL}" "${MN_HOME}"
then
	echo "Failed to download Movie Night"
	exit 1
fi
#if ! iocage exec "${JAIL_NAME}" sed '/SHELL=${SHELL}/ c SHELL=/bin/bash' "${MN_MAKEFILE}" >> "${MN_MAKEFILE}"
#then 
#    echo "Failed to customise MovieNght ${MN_MAKEFILE}"
#    exit 1
#fi
if ! iocage exec "${JAIL_NAME}" make
then
	echo "Failed to make Movie Night"
	exit 1
fi 

#iocage exec "${JAIL_NAME}" rm "${MN_TMP_DIR}"/master.zip
#iocage exec "${JAIL_NAME}" rm /tmp/"${GO_DL_VERSION}"

# Copy pre-written config files
iocage fstab -a "${JAIL_NAME}" "${INCLUDES_PATH}" /tmp/includes nullfs rw 0 0
iocage exec "${JAIL_NAME}" cp /tmp/includes/movinight /usr/local/etc/rc.d/
iocage exec "${JAIL_NAME}" sysrc movinight_enable="YES"

iocage restart "${JAIL_NAME}"

# Don't need /mnt/includes any more, so unmount it
#iocage fstab -r "${JAIL_NAME}" "${INCLUDES_PATH}" /tmp/includes nullfs rw 0 0
#iocage exec "${JAIL_NAME}" rmdir /tmp/includes
