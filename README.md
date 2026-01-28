# PRTG-Abacus-AbaWrapService-SubservicesMonitoring
Monitors the Subservices in EPR Software Abacus Abawrapservice

The Abawrapservices is a classic Windows registered service but his subservices are integratet services and only visible on servicemanagerconsole of abacus.
Due to the fact that there is no API Rest connection this is a sensor that grabs the logfile of Abacus Server

## Preperation
1. locate the log folder of your Abacusinstallation and search for abawrap folder
EXAMPLE: C:\PROGRAMFILES\ABACCUS\log\abawrapservice

2. Download the script AbacusWrapMonitor.ps1 and place it on your PRTG probe under:
C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML

## Script Usage

1. In PRTG, add an **EXE/Script Advanced Sensor** to your probe.
2. Name the sensor, e.g., *Abacus Wrap Service Monitoring*.
3. In the **EXE/Script** dropdown, select the script.
4. Set the following parameters:
| Parameter   | Example                                | Description                                      |
|-------------|----------------------------------------|--------------------------------------------------|
| Minutes     | 10                                   | Timespan from now to back to search inside log files for the services     |
| LogFolder    | `\\yourabacusserver\c$\programfiles\abacus\log\abawrapservice` | UNC Path to the Logfolder                           |

### Example usage in PRTG:
> -Minutes 1 -LogFolder "\\yourabacusserver\c$\programfiles\abacus\log\abawrapservice"

## PRTG Settings
- Set Security Context to Use Windows credentials from parent device - that user needs access to the UNC Path you defined
- Set preferred timeout and interval (recommended: 5 Min)

# Example Screenshot
<img width="1468" height="968" alt="image" src="https://github.com/user-attachments/assets/ba2b2bc4-d56c-4fe1-b72d-d721aa0ebe7b" />
