# checkcoroner
Used to check coroners for AMS renewal

Originally this checked and potentially failed for  the following:
coredumps 
watchdog errors (reset.log) 
powerfaults ( reset.log) 
carrier errors (ifconfig) 
frame errors (ifconfig)

temperature / fan speeds ( tempmon / sysmon) 


Currently we still check the values, but only fail for the following: 

watchdog errors 
temperature VALUE (not fan speeds) 
carrier errors (no frame errors) 
