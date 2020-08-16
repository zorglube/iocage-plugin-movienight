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
  "nano","bash","gzip","ca_root_nss","git"
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
iocage exec "${JAIL_NAME}" "pw user add movienight -c movienight -u 850 -d /nonexistent -s /usr/bin/nologin"


#####
#
# GO Download and Setup
#
#####
GO_URL="https://golang.org/dl/${GO_DL_VERSION}"
if ! iocage exec "${JAIL_NAME}" fetch -o /tmp "${GO_URL}"
then
	echo "Failed to download GO"
	exit 1
fi
if ! iocage exec "${JAIL_NAME}" tar xzf /tmp/"${GO_DL_VERSION}" -C /usr/local/
then
	echo "Failed to extract GO"
	exit 1
fi
PATH=$PATH":/usr/local/go/bin"
export PATH
GO_VERSION="/usr/local/go/bin"
export GO_VERSION

#####
#
# MovieNight Download and Setup
#
#####
MN_URL="https://github.com/zorchenhimer/MovieNight/archive/master.zip"
MN_TMP_DIR="/tmp/movienight"
MN_HOME="/usr/local/movienight"
if ! iocage exec "${JAIL_NAME}" mkdir "${MN_TMP_DIR}"
then
	echo "Failed to create download temp dir"
	exit 1
fi
if ! iocage exec "${JAIL_NAME}" fetch -o "${MN_TMP_DIR}" "${MN_URL}"
then
	echo "Failed to download Movie Night"
	exit 1
fi
if ! iocage exec "${JAIL_NAME}" mkdir "${MN_HOME}"
then
	echo "Failed to create download temp dir"
	exit 1
fi
if ! iocage exec "${JAIL_NAME}" gunzip -d "${MN_TMP_DIR}"/master.zip -r "${MN_HOME}" 
then
	echo "Failed to extract Movie Night"
	exit 1
fi
cd "{MN_HOME}"
if ! iocage exec "${JAIL_NAME}" make
then
	echo "Failed to make Movie Night"
	exit 1
fi 

#iocage exec "${JAIL_NAME}" rm "${MN_TMP_DIR}"/master.zip
#iocage exec "${JAIL_NAME}" rm /tmp/"${GO_DL_VERSION}"

# Copy pre-written config files
iocage exec "${JAIL_NAME}" cp /tmp/includes/movinight /usr/local/etc/rc.d/

iocage exec "${JAIL_NAME}" sysrc movinight_enable="YES"

iocage restart "${JAIL_NAME}"

# Don't need /mnt/includes any more, so unmount it
#iocage exec "${JAIL_NAME}" rmdir /tmp/includes
