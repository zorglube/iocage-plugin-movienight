# freenas-iocage-movienight
This is a simple script to automate the installation of MovieNight in a FreeNAS jail. 
It will create a jail, download and install GO from [Golang](https://golang.org/dl/), 
install `git` and download (git clone) compile and install the latest version of 
MovieNight from a fork of the [MovieNight](https://github.com/zorglube/MovieNight) 
project. 

## Status
This script has been built under FreeNAS 11.3 U4.1 with FreeBSD 11.3-Release-P11. 
It should work for FreeNAS 11.3, and it should also work with TrueNAS CORE 12.0. 
Feel free to report any bad operation or purpose any improvement through the [issues](https://github.com/zorglube/freenas-iocage-movienight/issues) 
page.

### Arch version
This will deploy an `x86` version of MovieNight. I'm still thinking about making an 
`x86_64` version. 

## Usage
Since the COVID-19 has locked down everyone at home, we couldn't go to movie theater 
together. MovieNight is an solution to overcome that. Quoting the MovieNight developer: 
"This is a single-instance streaming server with chat. [...] platform for watching movies with a group of people online." 
If you wonder how to use after installation, have an look into the MovieNight manual [MovieNight](https://github.com/zorchenhimer/MovieNight). 

### Prerequisites
MovieNight don't need to access any data outside of the jail. At this point, since 
MovieNight need an GO runtime, the runtime will be stored into the jail. 

### Installation
Normally you should find MovieNight into the Plugin list from the FreeNAS menu. If you 
can't use this solution, you may try the manual installation of the plugin [ref](https://github.com/freenas/iocage-ix-plugins).

### Execution
Once you've install the GUI should be accessible buy opening `http://JAIL_IP:8089`.

## Movie Night running configuration
I strongly recommend you to read the MovieNight manual and update the settings, by opening 
an console into the jail an editing `nano /usr/local/movienight/setting.json` and restart 
the Jail. 

## Support and Discussion
Useful sources of support include the [MovieNight](https://github.com/zorchenhimer/MovieNight). 

Questions or issues about this resource can be raised in [issues](https://github.com/zorglube/freenas-iocage-movienight/issues).  
 
