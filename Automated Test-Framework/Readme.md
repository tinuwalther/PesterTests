# Automated Testframework for Pester-Tests

Startscript Start-TestEnvironment.ps1

## Config
Configurationfile with all needed settings.   

## Internals
Assert-SystemCompliance.psm1 contains all the functions to test an environment.   
create-config.ps1, this script create a new config.json in the Config folder.   
create-pesterconfig.ps1, create a new config-file for the environment test.  
create-pestertestscript.psm1, create a new testscript.  

## Logs
This is the Logfolder.  

## Reports
Reports as JSON-File
Reports as XML-File
Reports as HTML-File

## Tests
Testscript and the config-file.   

## Usage
1. run create-config.ps1
2. run create-pesterconfig.ps1
3. run Start-TestEnvironment.ps1