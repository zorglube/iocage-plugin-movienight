#!/bin/sh

MN_HOME=/usr/local/movienight

wget https://github.com/zorglube/MovieNight/releases/download/2021-02-16/MovieNight -P ${MN_HOME} --verbose

chmod +x ${MN_HOME}/MovieNight

# Create MN log file
touch /var/log/movienight.log

# Enable the service
sysrc -f /etc/rc.conf movienight_enable="YES"

# Start the service
service movienight status
service movienight start 2>/dev/null
