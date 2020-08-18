#!/bin/sh 

# Check for root privileges
if ! [ $(id -u) = 0 ]
then
   echo "This script must be run with root privileges"
   exit 1
fi

if ! mv /root/.profile /root/.profile_old
then 
	echo "mv error" 
	exit 1 
fi
if ! cat /root/.profile_old | sed 's@PATH='"${PATH}"'@PATH='"${PATH}"':/usr/local/go/bin@g' >> /root/.profile_tmp 
then 
	echo "sed 1" 
	exit 1 
fi
if ! cat /root/.profile_tmp | sed 's@PATH.*@&OS="FreeBSD"@g' | sed 's@PATH.*@&SHELL="/bin/bash"@g'>> /root/.profile 
then 
	echo "sed 2" 
	exit 1 
fi

exit 0 
