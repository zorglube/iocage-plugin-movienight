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
ENV_VAR_UPDATE="env_var_update.sh"
TARGET=""
ARCH=""
MN_REPO=""

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")

# Check for mn-config and set configuration
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  echo "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi

# Load conf vars
. "${SCRIPTPATH}"/"${CONFIG_NAME}"

INCLUDES_PATH="${SCRIPTPATH}"/includes

JAILS_MOUNT=$(zfs get -H -o value mountpoint $(iocage get -p)/iocage)
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g" | sed "s/-p[0-9]*//")

#####
#
# Delete old Jail
#
#####
iocage stop ${JAIL_NAME} 
iocage destroy ${JAIL_NAME} 

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
if [ -z "${TARGET}" ]; then
  echo 'Configuration error: TARGET must be set'
  exit 1
fi
if [ -z "${ARCH}" ]; then
  echo 'Configuration error: ARCH must be set'
  exit 1
fi
if [ -z "${MN_REPO}" ]; then
  echo 'Configuration error: ARCH must be set'
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
SHELL="/bin/bash"
OS=`uname`

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

cat "${INCLUDES_PATH}/${ENV_VAR_UPDATE}_base" | sed 's@GO_PATH@'"${GO_PATH}"'@g' | sed 's@OS_VAL@'"${OS}"'@g' > "${INCLUDES_PATH}/${ENV_VAR_UPDATE}"

INCLUDE_JAIL="/mnt/includes"
iocage exec "${JAIL_NAME}" mkdir -p ${INCLUDE_JAIL}
iocage fstab -a "${JAIL_NAME}" "${INCLUDES_PATH}" ${INCLUDE_JAIL} nullfs rw 0 0

if ! iocage exec "${JAIL_NAME}" chmod 775 ${INCLUDE_JAIL}/${ENV_VAR_UPDATE}
then 
    echo "Failed to update chmod 775"
    exit 1
fi
if ! iocage exec "${JAIL_NAME}" chmod +x ${INCLUDE_JAIL}/${ENV_VAR_UPDATE}
then 
    echo "Failed to update chmod +x"
    exit 1
fi
if ! iocage exec "${JAIL_NAME}" ${INCLUDE_JAIL}/${ENV_VAR_UPDATE}
then 
    echo "Failed to update enviroment vars"
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
MN_URL=${MN_REPO}
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
if ! iocage exec "${JAIL_NAME}" link ${GO_PATH}/go ${USR_LOCAL}/bin/go
then 
    echo "Failed link to GO"
    exit 1
fi
if ! iocage exec "${JAIL_NAME}" link ${GO_PATH}/gofmt ${USR_LOCAL}/bin/gofmt
then 
    echo "Failed link to GOFMT"
    exit 1
fi
if ! iocage exec "${JAIL_NAME}" make TARGET=${TARGET} ARCH=${ARCH} -C ${MN_HOME}
then
	echo "Failed to make Movie Night"
	exit 1
fi 

if ! iocage exec ${JAIL_NAME} chown -R ${UID}:${GID} ${MN_HOME}
then
	echo "Failed to chown ${MN_HOME}"
	exit 1
fi 

iocage exec "${JAIL_NAME}" rm /tmp/"${GO_DL_VERSION}"

# Copy pre-written config files
iocage exec "${JAIL_NAME}" cp ${INCLUDE_JAIL}/movienight /usr/local/etc/rc.d/
iocage exec "${JAIL_NAME}" chmod +x /usr/local/etc/rc.d/movienight
iocage exec "${JAIL_NAME}" sysrc movienight_enable="YES"

iocage restart "${JAIL_NAME}"

# Don't need /mnt/includes any more, so unmount it
iocage fstab -r "${JAIL_NAME}" "${INCLUDES_PATH}" ${INCLUDE_JAIL} nullfs rw 0 0
iocage exec "${JAIL_NAME}" rmdir ${INCLUDE_JAIL}
