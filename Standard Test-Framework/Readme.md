# Automated Testframework for Pester-Tests

Startscript Start-TestEnvironment.ps1

## Config
Configurationfile with all needed settings.   

## Internals
Assert-SystemCompliance.psm1 contains all the functions to test an environment.  
ReportUnit.exe to generate the Html-Report.   

## Logs
This is the Logfolder.  

## Reports
Reports as HTML-File

## Tests
Scriptfiles and their PesterTestfiles.   

## Usage
Create a new Scriptfile with the functions and create a new PesterTestfile.   
New-Fixture -Path '.\Test-Framework\Tests' -Name Get-Something    

Run Start-TestEnvironment.ps1