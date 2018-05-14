<#
    .SYNOPSIS
    MasterScript for Pester-Tests

    .NOTES
    https://github.com/reportunit/reportunit
    reportunit "Result.xml" "generated.html" 

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
            $XmlOutputFile = "$($ConfigFolder)\$($script.Name)" -replace '.Tests.ps1','.xml'
            $PesterReturn += Invoke-Pester -Script @{
                Path = $script.FullName
            } -PassThru -OutputFormat NUnitXml -OutputFile $($XmlOutputFile)
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
$script:Jsonfile         = "$($ConfigFolder)\$($script:config.startscript.JsonFile)"
$script:Xmlfile          = "$($ConfigFolder)\$($script:config.startscript.Xmlfile)"
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
$InstallArgs.ArgumentList += "$($ConfigFolder)"
$InstallArgs.ArgumentList += "$($Reportfolder)"
$InstallArgs.Wait         = $true
$InstallArgs.NoNewWindow  = $true
(Start-Process @InstallArgs -PassThru).ExitCode

Start-Process "$($Reportfolder)\Index.html"

"$(Get-Date -DisplayHint DateTime) [INFORMATION] Tests completed in: $($PesterReturn.Time)" | Out-File -FilePath $($script:Logfile) -Append -Encoding default
"$(Get-Date -DisplayHint DateTime) [INFORMATION] Total: $($PesterReturn.TotalCount), Passed: $($PesterReturn.PassedCount), Failed: $($PesterReturn.FailedCount), Skipped: $($PesterReturn.SkippedCount), Pending: $($PesterReturn.PendingCount)"   | Out-File -FilePath $($script:Logfile) -Append -Encoding default
"$(Get-Date -DisplayHint DateTime) [INFORMATION] More details could be fond at: $($script:Jsonfile)" | Out-File -FilePath $($script:Logfile) -Append -Encoding default
#endregion

"$(Get-Date -DisplayHint DateTime) [INFORMATION] End $($script:Scriptname)" | Out-File -FilePath $($script:Logfile) -Append -Encoding default