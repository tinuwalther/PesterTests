<#
    .SYNOPSIS
    MasterScript for Pester-Tests
#>

#region functions
function Start-PesterTests{
    [CmdletBinding()]
    param()
    $function = $($MyInvocation.MyCommand.Name)
    Write-verbose $function
    try{
        $ScriptsToTest = Get-ChildItem -Path $script:Scriptfolder -Filter '*.Tests.ps1'
        $PesterReturn  = @()    
        
        foreach($script in $ScriptsToTest){
            "$(Get-Date -DisplayHint DateTime) [INFORMATION] Running $($script.Name)." | Out-File -FilePath $($script:Logfile) -Append -Encoding default    
            $PesterConfig  = $($script.FullName) -replace '.ps1','.json'
            $PesterReturn += Invoke-Pester -Script @{
                Path = $script.FullName
                Parameters = @{
                    configfile = $PesterConfig
                }
            } -PassThru -OutputFormat NUnitXml -OutputFile $($script:Xmlfile)
        }
    }
    catch{
        Write-verbose "$($function): $($_.Exception.Message)"
        $Error.Clear()
    }
    return $PesterReturn
}
#endregion

#region scriptglobals
$script:Scriptpath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:Scriptname = $MyInvocation.MyCommand.ToString()

$script:config           = Get-Content -Path "$($script:Scriptpath)\Config\config.json" | ConvertFrom-Json
$script:Version          = $script:config.general.Version

$Logfolder               = "$($script:Scriptpath)\$($script:config.startscript.Logfolder)"
$Reportfolder            = "$($script:Scriptpath)\$($script:config.startscript.Reportfolder)"
$Scriptfolder            = "$($script:Scriptpath)\$($script:config.startscript.Scriptfolder)"
$ConfigFolder            = "$($script:Scriptpath)\$($script:config.startscript.ConfigFolder)"
$Internalfolder          = "$($script:Scriptpath)\$($script:config.startscript.Internals)"

$script:PesterConfigFile = "$($ConfigFolder)\$($script:config.startscript.PesterConfig)"
$script:Logfile          = "$($Logfolder)\$($script:config.startscript.Logfile)"
$script:Jsonfile         = "$($Reportfolder)\$($script:config.startscript.JsonFile)"
$script:Xmlfile          = "$($Reportfolder)\$($script:config.startscript.Xmlfile)"
$script:Xmlfile          = "$($Reportfolder)\$($script:config.startscript.Xmlfile)"
$script:Htmlfile         = "$($Reportfolder)\$($script:config.startscript.Htmlfile)"
#endregion

"$(Get-Date -DisplayHint DateTime) [INFORMATION] Run $($script:Scriptname), Version $($script:Version)" | Out-File -FilePath $($script:Logfile) -Encoding default

$PesterReturn = Start-PesterTests 

#region output
$PesterReturn.TestResult | Select-Object Describe,Context,Name,Result | Format-Table -AutoSize
$PesterReturn.TestResult | Select-Object * | ConvertTo-Json | Out-File -FilePath $($script:Jsonfile)

$InstallArgs = @{}
$InstallArgs.FilePath     = "$($Internalfolder)\ReportUnit.exe"
$InstallArgs.ArgumentList = @()
$InstallArgs.ArgumentList += "$($Reportfolder)"
$InstallArgs.ArgumentList += "$($Reportfolder)"
$InstallArgs.Wait         = $true
$InstallArgs.NoNewWindow  = $true
(Start-Process @InstallArgs -PassThru).ExitCode

"$(Get-Date -DisplayHint DateTime) [INFORMATION] Tests completed in: $($PesterReturn.Time)" | Out-File -FilePath $($script:Logfile) -Append -Encoding default
"$(Get-Date -DisplayHint DateTime) [INFORMATION] Total: $($PesterReturn.TotalCount), Passed: $($PesterReturn.PassedCount), Failed: $($PesterReturn.FailedCount), Skipped: $($PesterReturn.SkippedCount), Pending: $($PesterReturn.PendingCount)"   | Out-File -FilePath $($script:Logfile) -Append -Encoding default
"$(Get-Date -DisplayHint DateTime) [INFORMATION] More details could be fond at: $($script:Jsonfile)" | Out-File -FilePath $($script:Logfile) -Append -Encoding default
#endregion

"$(Get-Date -DisplayHint DateTime) [INFORMATION] End $($script:Scriptname)" | Out-File -FilePath $($script:Logfile) -Append -Encoding default