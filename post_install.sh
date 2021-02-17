#!/bin/sh

wget https://github.com/zorglube/MovieNight/releases/download/2021-02-16/MovieNight -P ${MN_HOME} --verbose

chmod +x ${MN_HOME}/MovieNight

sysrc -f /etc/rc.conf movienight_enable="YES"

# Start the service
service movienight start 2>/dev/null
