#!/bin/sh

wget https://github.com/zorglube/MovieNight/releases/download/2021-02-16/MovieNight -P /usr/local/movienight --verbose

chmod +x /usr/local/movienight/MovieNight

# Create MN log file

# Enable the service
sysrc -f /etc/rc.conf movienight_enable="YES"

# Start the service
service movienight start 2>/dev/null
