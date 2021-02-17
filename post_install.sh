#!/bin/sh

chmod +x /usr/local/movienight/MovieNight

# Create MN log file

# Enable the service
sysrc -f /etc/rc.conf movienight_enable="YES"

# Start the service
service movienight start 2>/dev/null
