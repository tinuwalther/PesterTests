<#
    
    .SYNOPSIS
     Create Pester-Testscript

    .DESCRIPTION
     Create Pester-Testscript with a configfile

    .PARAMETER ScriptName
     The name of the Testscript without any extensions   

    .NOTES
     Author: Martin Walther
     Link:   https://it.martin-walther.ch

    .EXAMPLE
     Start it from the create-pesterconfig.ps1:
     Import-Module .\create-pestertestscript.psm1 
     New-TestScript -ScriptName $ConfigName
     It creates a file at ..\Tests\$($ConfigName).Tests.ps1

#>

<#
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
    [String]$ScriptName
)

$pesterconfig = Get-Content -Path $configfile | ConvertFrom-Json
if($pesterconfig.Services){
    $Testname    = $pesterconfig.Services
    $scriptblock = "
    Describe -Name $($Testname) {  

        BeforeAll{
            if($Error){$Error.Clear()}
            Write-Host End $Testname
        }
    
        AfterAll{
            if($Error){$Error.Clear()}
            Write-Host End $Testname
        }
    }
    "
}
#>

function New-TestScript{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [String]$ScriptName,

        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [String]$ConfigName
    )

    $pesterconfig = Get-Content -Path $ConfigName | ConvertFrom-Json

    $scriptblock = {
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
    [String]$configfile
)

$pesterconfig = Get-Content -Path $configfile | ConvertFrom-Json

#region Services
if($pesterconfig.Services){
    Describe -Name "$($pesterconfig.Services.Describe)" {  
        BeforeAll{
            if($Error){$Error.Clear()}
        }
        foreach($item in $pesterconfig.Services){
            Context "$($item.Context) $($item.Name)" {
                # -- Arrange
                # -- Act
                $Actual = (
                    Get-WmiObject -Class win32_service -Filter "name='$($item.Name)'" -ErrorAction SilentlyContinue
                )
                if($Actual.StartMode -eq $item.Mode -and $Actual.State -eq $item.State){
                    $ServiceStauts = $true
                }
                else{
                    $ServiceStauts = $false
                }
                # -- Assert
                It "Should get Servicestate $($item.Mode) and $($item.State) $($item.Expect)" {
                    $ServiceStauts | Should Be $Result
                }
            }
        }
    }    
}
#endregion

#region Connectivity
if($pesterconfig.Connectivity){
    Describe -Name "$($pesterconfig.Connectivity.Describe)" {  
        BeforeAll{
            if($Error){$Error.Clear()}
        }
        foreach($item in $pesterconfig.Connectivity) {
            Context "$($item.Context) $($item.Name)" {
                # -- Arrange
                # -- Act
                $Actual = (
                    Test-NetConnection -ComputerName $item.Name -Port $item.TcpPort -ErrorAction SilentlyContinue
                )
                # -- Assert
                It "Should get TcpTest succeeded" {
                    $Actual.TcpTestSucceeded | Should Be $item.Expect
                }
            }
        }
    }    
}
#endregion

#region ScheduledTasks
if($pesterconfig.ScheduledTasks){
    Describe -Name "$($pesterconfig.ScheduledTasks.Describe)" {  
        BeforeAll{
            if($Error){$Error.Clear()}
        }
        foreach($item in $pesterconfig.ScheduledTasks) {
            Context "$($item.Context) $($item.Name)" {
                # -- Arrange
                # -- Act
                $Actual = (
                    Get-ScheduledTask -TaskName $item.Name -ErrorAction SilentlyContinue
                )
                if($Actual.State -eq 'Ready' -or $Actual.State -eq 'Running'){
                    $Status = $true
                }
                else{
                    $Status = $false
                }
                # -- Assert
                It "Should get TaskName $($item.Name)" {
                    $Actual.TaskName | Should Be $item.Name
                }
                It "Should get TaskState Ready or Running" {
                    $Status | Should Be $item.Expect
                }
            }
        }
    }
}
#endregion

#region Files
if($pesterconfig.Files){
    Describe -Name "$($pesterconfig.Files.Describe)" {  
        BeforeAll{
            if($Error){$Error.Clear()}
        }
        foreach($item in $pesterconfig.Files){
            Context "$($item.Context) $($item.Name)" {
                # -- Arrange
                # -- Act
                $Actual = (
                    Test-Path -Path $item.Name -ErrorAction SilentlyContinue
                )
                # -- Assert
                It 'Should be Exists' {
                    $Actual | Should Be $item.Expect
                }
            }
        }
    }
}
#endregion

#region Folder
if($pesterconfig.Folder){
    Describe -Name "$($pesterconfig.Folder.Describe)" {  
        BeforeAll{
            if($Error){$Error.Clear()}
        }
        foreach($item in $pesterconfig.Folder){
            Context "$($item.Context) $($item.Name)" {
                # -- Arrange
                # -- Act
                $Actual = (Test-Path -Path $item.Name -ErrorAction SilentlyContinue)
                # -- Assert
                It 'Should be Exists' {
                    $Actual | Should Be $item.Expect
                }
            }
        }
    }
}
#endregion

#region Registry
if($pesterconfig.Registry){
    Describe -Name "$($pesterconfig.Registry.Describe)" {  
        BeforeAll{
            if($Error){$Error.Clear()}
        }
        foreach($item in $pesterconfig.Registry){
            Context "$($item.Context) $($item.Property)" {
                # -- Arrange
                # -- Act
                $Actual = (
                    Get-ItemProperty -Path $item.Name -Name $item.Property -ErrorAction SilentlyContinue | `
                     Select-Object -ExpandProperty $item.Property
                )
                # -- Assert
                It "Should be $($item.Expect)" {
                    $Actual | Should Be $item.Expect
                }
            }
        }
    }
}
#endregion
}
$scriptblock | Out-File "..\Tests\$($ScriptName).Tests.ps1" -Force
}