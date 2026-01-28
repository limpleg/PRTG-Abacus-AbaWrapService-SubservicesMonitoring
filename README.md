# PRTG-Abacus-AbaWrapService-SubservicesMonitoring
Monitors the Subservices in EPR Software Abacus Abawrapservice

The Abawrapservices is a classic Windows registered service but his subservices are integratet services and only visible on servicemanagerconsole of abacus.
Due to the fact that there is no API Rest connection this is a sensor that grabs the logfile of Abacus Server

## Preperation
locate the log folder of your Abacusinstallation and search for abawrap folder
EXAMPLE: C:\PROGRAMFILES\ABACCUS\log\abawrapservice

