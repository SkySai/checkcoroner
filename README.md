# checkcoroner
Used to check coroners for AMS renewal

Originally this checked and potentially failed for  the following:
* coredumps 
* watchdog errors (reset.log) 
* powerfaults ( reset.log) 
* carrier errors (ifconfig) 
* frame errors (ifconfig)
* temperature / fan speeds ( tempmon / sysmon) 
* watchdog errors 
* temperature VALUE (not fan speeds) 
* carrier errors (no frame errors) 

Currently we still check the values, but only fail reporting false in any of the /status/ready fields. 

/local/var/status/ready/audio = "true"
/local/var/status/ready/comm = "FALSE"   <<<< 
/local/var/status/ready/decoder = "true"
/local/var/status/ready/encoder = "true"
/local/var/status/ready/license = "true"
/local/var/status/ready/system = "false" <<<< 

The icons don't have this data to awk for in the logs yet. 
