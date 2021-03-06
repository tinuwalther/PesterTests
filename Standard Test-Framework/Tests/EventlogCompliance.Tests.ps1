
<#
    .SYNOPSIS
     Test some things with pester

    .DESCRIPTION
     Test Eventlogs

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

Describe -Name "Eventlogs Compliance Test" {  

    BeforeAll{
        if($Error){$Error.Clear()}
    }

    Context "Test Systemlog" {
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
    }

    Context "Test Applicationlog" {
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
    }

}