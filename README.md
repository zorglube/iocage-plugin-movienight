# iocage-plugin-movienight
This project is the [TreuNAS](https://www.truenas.com) / [FreeNAS](https://www.freenas.org) plugin deployement of [MovieNight](https://github.com/zorglube/MovieNight). 
It will create a jail, with [Golang](https://golang.org/dl/), `Git` and `Bash` inside. 
`Git` will be used to download (git clone) the MovieNight (MN) code, after that that the MN binaray will le build wit Go.  

## Status
This script has been built under TrueNAS 12.1. 
It should work for FreeNAS 11.X and supperior, and it should also work with TrueNAS 12.X and supperior. 
Feel free to report any bad operation or purpose any improvement through the [issues](https://github.com/zorglube/iocage-plugin-movienight/issues) page.

### Prerequisites
MovieNight don't need to access any data outside of the jail. At this point MovieNight need a GO runtime, the runtime will be installed into the Jail by the deployement script. 

### Installation
Normally you should find MovieNight into the Plugin list from the TureNAS mangement. If you can't use this solution, you may try the manual installation of the plugin [ref](https://github.com/freenas/iocage-ix-plugins).

### Execution
Once you've install the GUI should be accessible buy opening `http://JAIL_IP:8089`.

## Movie Night running configuration
I strongly recommend you to read the MovieNight manual and update the settings, by opening an console into the jail an editing `nano /usr/local/movienight/setting.json` and restart the Jail. 

## Support and Discussion
Useful sources of support include the [MovieNight](https://github.com/zorchenhimer/MovieNight). 

Questions or issues about this resource can be raised in [issues](https://github.com/zorglube/iocage-plugin-movienight/issues).  
 
## Disclamer 
This plugin deploy this [MovieNight repo](https://github.com/zorglube/MovieNight), witch an fork of the official [MovieNight repo](https://github.com/zorchenhimer/MovieNight). 
This plugin had recieved the permission of [Zorchenhimer](https://github.com/zorchenhimer). 
