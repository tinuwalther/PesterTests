<#
    
    .SYNOPSIS
     Create Pester-Testscript and the configurationfile

    .DESCRIPTION
     Create Pester-Testscript and the configurationfile

    .PARAMETER ConfigName
     The name of the Configfile without any extensions   

    .NOTES
     Author: Martin Walther
     Link:   https://it.martin-walther.ch

    .EXAMPLE
     create-pesterconfig -ConfigName 'Test-Something'
     It creates a file at ..\Tests\$($ConfigName).Tests.json
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
    [String]$ConfigName
)

#region scriptglobals
$script:Scriptpath = (Split-Path -Parent $MyInvocation.MyCommand.Path) -replace 'Internals'
$script:Scriptname = $MyInvocation.MyCommand.ToString()

$script:config           = Get-Content -Path "$($script:Scriptpath)\Config\config.json" | ConvertFrom-Json
$script:Version          = $script:config.general.Version

$Logfolder               = "$($script:Scriptpath)\$($script:config.startscript.Logfolder)"
$Reportfolder            = "$($script:Scriptpath)\$($script:config.startscript.Reportfolder)"
$ConfigFolder            = "$($script:Scriptpath)\$($script:config.startscript.ConfigFolder)"
$Scriptfolder            = "$($script:Scriptpath)\$($script:config.startscript.Scriptfolder)"
$Internalfolder          = "$($script:Scriptpath)\$($script:config.startscript.Internalfolder)"

$script:PesterConfigFile = "$($ConfigFolder)\$($script:config.startscript.PesterConfig)"
$script:Logfile          = "$($Logfolder)\$($script:config.startscript.Logfile)"
$script:Jsonfile         = "$($Reportfolder)\$($script:config.startscript.JsonFile)"
$script:Xmlfile          = "$($Reportfolder)\$($script:config.startscript.Xmlfile)"
#endregion

@{

    Services = @(
        [PSCustomObject] @{
            Describe  = 'Windows Update'
            Context   = 'Test service'
            Name      = 'wuauserv'
            Mode      = 'Auto'
            State     = 'Running'
            Assert    = 'Should Be'
            Expect    = 'True'
        },
        [PSCustomObject] @{
            Context   = 'Test service' 
            Name      = 'Netlogon'
            Mode      = 'Manual'
            State     = 'Stopped'
            Assert    = 'Should Be'
            Expect    = 'True'
        }
    )

    Connectivity = @(
        [PSCustomObject] @{
            Describe  = 'Windows Update'
            Context   = 'Test connectivity to'
            Name      = 'wsus.company.comm'
            TcpPort   = '8530'
            Assert    = 'Should Be'
            Expect    = 'True'
        },
        [PSCustomObject] @{
            Context   = 'Test connectivity to'
            Name      = 'windowsupdate.microsoft.com' 
            TcpPort   = '80'
            Assert    = 'Should Be'
            Expect    = 'True'
        }

    )

    ScheduledTasks = @(
        [PSCustomObject] @{
            Describe  = 'Windows Update'
            Context   = 'Test Scheduled Task'
            Name      = 'PolicyConverter'
            Assert    = 'Should Be'
            Expect    = 'True'
        },
        [PSCustomObject] @{
            Context   = 'Test Scheduled Task' 
            Name      = 'SynchronizeTime'
            Assert    = 'Should Be'
            Expect    = 'True'
        },
        [PSCustomObject] @{
            Context   = 'Test Scheduled Task'
            Name      = 'SystemSoundsService' 
            Assert    = 'Should Be'
            Expect    = 'True'
        }
    )

    Files = @(
        [PSCustomObject] @{
            Describe  = 'Windows Update'
            Context   = 'Test File' 
            Name      = 'C:\Windows\System32\drivers\etc\hosts'
            Assert    = 'Should Be'
            Expect    = 'True'
        },
        [PSCustomObject] @{
            Context   = 'Test File'
            Name      = 'C:\Temp\Test.log'
            Assert    = 'Should  Be'
            Expect    = 'True'
        }
    )

    Registry = @(
        [PSCustomObject] @{
            Describe  = 'Windows Update'
            Context   = 'Test Registry path for'
            Name      ='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\WUServer'
            Property  ='WUServer'
            Assert    = 'Should Be'
            Expect    ='http://wsus.company.com:8530'
        },
        [PSCustomObject] @{
            Context   = 'Test Registry path for'
            Name      ='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\WUStatusServer'
            Property  ='WUStatusServer'
            Assert    = 'Should Be'
            Expect    ='http://wsus.company.com:8530'
        }
    )

} | ConvertTo-Json | Out-File "$($Scriptfolder)\$($ConfigName).Tests.json" -Force
Import-Module "$($Internalfolder)\create-pestertestscript.psm1"
New-TestScript -ScriptName $ConfigName -ConfigName "$($Scriptfolder)\$($ConfigName).Tests.json"