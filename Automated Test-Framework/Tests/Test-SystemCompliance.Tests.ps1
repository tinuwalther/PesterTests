
<#
    .SYNOPSIS
     Test some things with pester

    .DESCRIPTION
     Test services, connectivity, files and registry for windows update configuration

    .PARAMETER configfile
     Fullpath to the configfile   

    .NOTES
     Author: Martin Walther
     Link:   https://it.martin-walther.ch

     https://github.com/pester/Pester/wiki/Invoke-Pester

    .EXAMPLE
     $PesterReturn += Invoke-Pester -Script @{
        Path = $script.FullName
        Parameters = @{
            configfile = $pesterconfig
        }
    } -PassThru -OutputFormat NUnitXml -OutputFile $($Xmlfile)

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]
    [String]$ConfigName
)

#region scriptglobals
$script:Scriptpath = (Split-Path -Parent $MyInvocation.MyCommand.Path) -replace '\\Tests'
$script:Scriptname = $MyInvocation.MyCommand.ToString()

$script:config           = Get-Content -Path "$($script:Scriptpath)\Config\config.json" | ConvertFrom-Json
$script:Version          = $script:config.general.Version

$Logfolder               = "$($script:Scriptpath)\$($script:config.startscript.Logfolder)"
$Reportfolder            = "$($script:Scriptpath)\$($script:config.startscript.Reportfolder)"
$ConfigFolder            = "$($script:Scriptpath)\$($script:config.startscript.ConfigFolder)"
$Internalfolder          = "$($script:Scriptpath)\$($script:config.startscript.Internalfolder)"

$script:PesterConfigFile = "$($ConfigFolder)\$($script:config.startscript.PesterConfig)"
$script:Logfile          = "$($Logfolder)\$($script:config.startscript.Logfile)"
$script:Jsonfile         = "$($Reportfolder)\$($script:config.startscript.JsonFile)"
$script:Xmlfile          = "$($Reportfolder)\$($script:config.startscript.Xmlfile)"
#endregion

Import-Module "$($Internalfolder)\Assert-SystemCompliance.psm1" -Force

Describe -Name "System Compliance Test" {  

    BeforeAll{
        if($Error){$Error.Clear()}
    }

    #region System
    # -- Arrange
    $ThresholdUptimeDays = 10
    # -- Act
    $Actual = Get-HostUptime -threshold $ThresholdUptimeDays
    # -- Assert
    It "Current Uptime should be less than $($ThresholdUptimeDays) days" {
        [Int]$Actual.Days | Should BeLessThan $ThresholdUptimeDays
    }

    # -- Arrange
    $ServiceExceptions = @('gpsvc','MapsBroker','sppsvc','WbioSrvc')
    # -- Act
    $Actual = Get-StoppedServices -ExceptionList $ServiceExceptions
    # -- Assert
    It "Stopped Services with StartMode automatic should be NullOrEmpty" {
        $Actual | Should BeNullOrEmpty 
    }

    # -- Arrange
    $ThresholdLastHotfixes = 1
    $ThresholdInstalledOn  = 45
    # -- Act
    $Actual = Get-InstalledHotfixes -threshold $ThresholdLastHotfixes
    $StartDate = $Actual.InstalledOn
    $EndDate   = get-date
    $Expect    = New-TimeSpan –Start $StartDate –End $EndDate | Select-Object -ExpandProperty Days
    # -- Assert
    It "The last installed updates should be within $ThresholdInstalledOn days" {
        $Expect | Should BeLessThan $ThresholdInstalledOn
    }
    #endregion

    #region Resource usage
    # -- Arrange
    $ThresholdMemoryPercent = 30
    # -- Act
    $Actual = Get-Raminfo -threshold $ThresholdMemoryPercent
    # -- Assert
    It "Free Memory in percent should be greather than $($ThresholdMemoryPercent)%" {
        [Int]$Actual.'Free(%)' | Should BeGreaterThan $ThresholdMemoryPercent
    }

    # -- Arrange
    $ThresholdFreeSpacePercent = 30
    # -- Act
    $Actual = Get-Diskinfo -threshold $ThresholdFreeSpacePercent
    # -- Assert
    It "Free Disk space in percent should be greather than $($ThresholdFreeSpacePercent)%" {
        [Int]$Actual.'Free(%)' | Should BeGreaterThan $ThresholdFreeSpacePercent
    }
    #endregion
    
    #region Eventlogs
    # -- Arrange
    $ThresholdLastEventDays  = 3
    $ThresholdErrorOrWarning = 6
    # -- Act
    $Actual = Get-LastEventCodes -Logname System -day $ThresholdLastEventDays
    # -- Assert
    It "The Systemlog should have less than $ThresholdErrorOrWarning Errors or Warnings in the last $ThresholdLastEventDays days" {
        $Actual.Count | Should BeLessThan $ThresholdErrorOrWarning
        #$Actual | Should BeNullOrEmpty 
    }

    # -- Arrange
    $ThresholdLastEventDays  = 3
    $ThresholdErrorOrWarning = 6
    # -- Act
    $Actual = Get-LastEventCodes -Logname Application -day $ThresholdLastEventDays
    # -- Assert
    It "The Applicationlog should have less than $ThresholdErrorOrWarning Errors or Warnings in the last $ThresholdLastEventDays days" {
        $Actual.Count | Should BeLessThan $ThresholdErrorOrWarning
        #$Actual | Should BeNullOrEmpty 
    }
    #endregion

    #region Accounts
    # -- Arrange
    $ExceptionList = @("$($env:computername)\Admin","$($env:computername)\Administrator")
    # -- Act
    $Actual = Get-MemberOfLocalAdmins -ExceptionList $ExceptionList
    # -- Assert
    It "Local Administrators should have only Administrator as Member" {
        $Actual | Should BeNullOrEmpty
    }
    #endregion

}    
