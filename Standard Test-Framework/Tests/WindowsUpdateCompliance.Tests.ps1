﻿
<#
    .SYNOPSIS
     Test some things with pester

    .DESCRIPTION
     Test Windows Update

    .NOTES
     Author: Martin Walther
     Link:   https://it.martin-walther.ch
     https://github.com/pester/Pester/wiki/Invoke-Pester

    .EXAMPLE
     $PesterReturn += Invoke-Pester -Script @{
        Path = $script.FullName
    } -PassThru -OutputFormat NUnitXml -OutputFile $($Xmlfile)

#>
[CmdletBinding()]
param()

#region scriptglobals
$script:Scriptpath       = (Split-Path -Parent $MyInvocation.MyCommand.Path) -replace '\\Tests'
$script:Scriptname       = $MyInvocation.MyCommand.ToString()
#endregion

Import-Module "$($Internalfolder)\Assert-SystemCompliance.psm1" -Force

Describe -Name "Windows Update Compliance Test" {  

    BeforeAll{
        if($Error){$Error.Clear()}
    }

    Context "Test Windows Update Service" {
        # -- Arrange
        # -- Act
        $Actual = Get-ServiceProperties -ServiceName 'wuauserv'
        # -- Assert
        It "Windows Update Service should be Auto" {
            $Actual.StartMode | Should Be 'Auto'
        }
    }

    Context "Test Windows Update Hotfixes" {
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
    }

    Context "Test Windows Update Server" {
        # -- Arrange
        $RegPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\WUServer'
        $RegName = 'WUServer'
        # -- Act
        $Actual = Get-RegistryProperty -Path $RegPath -Property $RegName
        # -- Assert
        It "Windows Update Server should be configured" {
            $Actual | Should Be 'windowsupdate.microsoft.com:80'
        }
    }

    Context "Test Windows Update Server Connectivity" {
        # -- Arrange
        $WuServer = 'windowsupdate.microsoft.com'
        $WuPort   = '80'
        # -- Act
        $Actual = Test-NetConnection -ComputerName $WuServer -Port $WuPort
        # -- Assert
        It "Connectivity to $WuServer over $WuPort should be true" {
            $Actual.TcpTestSucceeded | Should Be $true
        }
    }

}
