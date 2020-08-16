# freenas-iocage-movienight
This is a simple script to automate the installation of MovieNight in a FreeNAS jail. It will create a jail, download 
and install GO from [Golang](https://golang.org/dl/) and download compile and install the latest version of MovieNight from [MovieNight](https://github.com/zorchenhimer/MovieNight). 

## Status
This script has been built under FreeNAS 11.3 U4.1 with FreeBSD 11.3-Release-P11. It 
should work for FreeNAS 11.3, and it should also work with TrueNAS CORE 12.0. Feel free 
to report any bad operation or purpose any improvement.

## Usage
Since the COVID-19 has locked down everyone at home, we couldn't go to movie theater 
together. MovieNight is an solution to overcome that. Quoting the MovieNight developer: 
"This is a single-instance streaming server with chat. [...] platform for watching movies with a group of people online." If 
you wonder how to use after installation, have an look into the MovieNight manual [MovieNight](https://github.com/zorchenhimer/MovieNight). 

### Prerequisites
MovieNight don't need to access any data outside of the jail. At this point, since MN  
need an GO runtime, the runtime will be stored into the jail. 

### Installation
Download the repository to a convenient directory on your FreeNAS system by changing to that directory and running `git clone https://github.com/zorglube/freenas-iocage-movienight`. Then change into the new freenas-iocage-movienight directory and create a file called `mn-config` with your favorite text editor. In its minimal form, it would look like this: 
`` 
JAIL_IP="10.1.1.3"
DEFAULT_GW_IP="10.1.1.1"
`` 

Many of the options are self-explanatory, and all should be adjusted to suit your needs, but only a few are mandatory. The mandatory options are:

- JAIL_IP is the IP address for your jail. You can optionally add the netmask in CIDR notation (e.g., 192.168.1.199/24). If not specified, the netmask defaults to 24 bits. Values of less than 8 bits or more than 30 bits are invalid.
- DEFAULT_GW_IP is the address for your default gateway
- POOL_PATH is the path for your data pool.

In addition, there are some other options which have sensible defaults, but can be adjusted if needed. These are:

- JAIL_NAME: The name of the jail, defaults to `rslsync`
- CONFIG_PATH: Client configuration data is stored in this path; defaults to `$POOL_PATH/apps/rslsync/config`.
- DATA_PATH: Selective backups are stored in this path; defaults to `$POOL_PATH/apps/rslsync/data`.
- INTERFACE: The network interface to use for the jail. Defaults to `vnet0`.
- VNET: Whether to use the iocage virtual network stack. Defaults to `on`.

### Execution
Once you've downloaded the script and prepared the configuration file, run this script (`./movienight-jail.sh`). The script will run for several minutes. When it finishes, your jail will be created and `movienight` will be installed.

### Test
To test your installation, enter your Movie Night jail IP address and port `8089` e.g. `10.1.1.3:8089` in a browser. If the installation was successful, you should see a Movie 
Night home page.

## Support and Discussion
Useful sources of support include the [MovieNight](https://github.com/zorchenhimer/MovieNight). 

Questions or issues about this resource can be raised in [issues](https://github.com/zorglube/freenas-iocage-movienight/issues).  
