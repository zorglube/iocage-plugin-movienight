#!/usr/bin/env bash

## Who will run the jail's primary service
service_port="8089"        # service_port == UID
service_name="movienight"  # service_name == username
service_config="/usr/local/etc/${service_name}/settings.json"
service_directory="/usr/local/share/${service_name}"

## Add the service_name user
pw adduser -u "${service_port}" -n "${service_name}" -d /nonexistent -w no -s /nologin

## Configure the jail's primary service
sysrc ${service_name}_user="${service_name}"
sysrc ${service_name}_group="${service_name}"
sysrc ${service_name}_app_dir="${service_directory}"
sysrc ${service_name}_settings="${service_config}"

## Install the jail's primary service, Movie Night
echo -e "\nInstalling Movie Night..."
git clone "https://github.com/zorchenhimer/MovieNight.git" "${service_directory}"
make TARGET=freebsd ARCH=amd64 -f "${service_directory}/Makefile.BSD" -C "${service_directory}"

## Enable and start the Movie Night service
chmod +x "/usr/local/etc/rc.d/${service_name}"
sysrc -f /etc/rc.conf ${service_name}_enable="YES"
service "${service_name}" start
