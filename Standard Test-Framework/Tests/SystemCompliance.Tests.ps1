
<#
    .SYNOPSIS
     Test some things with pester

    .DESCRIPTION
     Test System

    .NOTES
     Author: Martin Walther
     Link:   https://it.martin-walther.ch
     https://github.com/pester/Pester/wiki/Invoke-Pester

    .EXAMPLE
     $PesterReturn += Invoke-Pester -Script @{
        Path = $script.FullName
    } -PassThru -OutputFormat NUnitXml -OutputFile $($Xmlfile)

#>

#region scriptglobals
$script:Scriptpath       = (Split-Path -Parent $MyInvocation.MyCommand.Path) -replace '\\Tests'
$script:Scriptname       = $MyInvocation.MyCommand.ToString()
#endregion

Import-Module "$($Internalfolder)\Assert-SystemCompliance.psm1" -Force

Describe -Name "System Compliance Test" {  

    BeforeAll{
        if($Error){$Error.Clear()}
    }

    Context "Test HostUptime" {
        # -- Arrange
        $ThresholdUptimeDays = 10
        # -- Act
        $Actual = Get-HostUptime -threshold $ThresholdUptimeDays
        # -- Assert
        It "Current Uptime should be less than $($ThresholdUptimeDays) days" {
            [Int]$Actual.Days | Should BeLessThan $ThresholdUptimeDays
        }
    }

    Context "Test Services" {
        # -- Arrange
        $ServiceExceptions = @('gpsvc','MapsBroker','sppsvc','WbioSrvc')
        # -- Act
        $Actual = Get-StoppedServices -ExceptionList $ServiceExceptions
        # -- Assert
        It "Stopped Services with StartMode automatic should be NullOrEmpty" {
            $Actual | Should BeNullOrEmpty 
        }
    }

}