<#

    .SYNOPSIS
    Create a health report

    .DESCRIPTION
    Create a health report with HostUptime, Raminfo, Diskinfo, LastEventCodes, StoppedServices, TopProcesses, LastHotfixes

    .PARAMETER ThresholdUptimeDays
    Threshold Uptime Days

    .PARAMETER ThresholdMemoryPercent
    Threshold Free Memory Percent

    .PARAMETER ThresholdTopProcesses
    Threshold Top Processes Allocated Memory

    .PARAMETER ThresholdCountProcesses
    Threshold Count Processes

    .PARAMETER ThresholdFreeSpacePercent
    Threshol Free DiskSpace Percent

    .PARAMETER ThresholdFreeSpacePercent
    Threshol Free DiskSpace Percent

    .PARAMETER ThresholdLastHotfixes
    Threshold last installed Hotfixes

    .PARAMETER OutputToJson
    Switch, save all failed objects to an JSON file

    .PARAMETER InputFromJson
    Switch, import failed objects from an JSON file

    .NOTES
    Author: Martin Walther
    Date created: 12.10.2014

    .EXAMPLE
    Get-HostUptime -threshold $ThresholdUptimeDays -Verbose
    Get-Raminfo -threshold $ThresholdMemoryPercent -Verbose
    Get-TopProcesses -threshold $ThresholdTopProcesses -Verbose
    Get-Diskinfo -threshold $ThresholdFreeSpacePercent -Verbose
    foreach($item in @('System','Setup','Application'){
        Get-LastEventCodes -Logname $item -day $ThresholdLastEventDays -Verbose
    }
    Get-StoppedServices -Verbose
    Get-InstalledHotfixes -threshold $ThresholdLastHotfixes -Verbose

#>
[CmdletBinding()]
param()

#region PSCode

function Get-HostUptime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][Int]$threshold
    )
    $function = $($MyInvocation.MyCommand.Name)
    Write-verbose $function
    $ret = @()
    $Uptime = Get-WmiObject -Class Win32_OperatingSystem
    if(-not([String]::IsNullOrEmpty($Uptime))){
        $LastBootUpTime = $Uptime.ConvertToDateTime($Uptime.LastBootUpTime)
        $Time = (Get-Date) - $LastBootUpTime
        #if($Time.Days -ge $threshold){
            $obj = [PSCustomObject]@{
                Days    = "{0:00}" -f $Time.Days
                Hours   = "{0:00}" -f $Time.Hours
                Minutes = "{0:00}" -f $Time.Minutes
                Seconds = "{0:00}" -f $Time.Seconds
            }
            $ret += $obj
        #}
    }
    return $ret
}

function Get-Raminfo{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][Int]$threshold
    )
    $function = $($MyInvocation.MyCommand.Name)
    Write-verbose $function
    $ret = @()
    $wmiobj = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop | Select-Object TotalVisibleMemorySize,FreePhysicalMemory,FreeSpaceInPagingFiles
    if(-not([String]::IsNullOrEmpty($wmiobj))){
        $wmiobj | ForEach-Object{
            $TotalRamGB     = [math]::round(($_.TotalVisibleMemorySize/(1024*1024)),2)
            $FreeRamGB      = [math]::round(($_.FreePhysicalMemory/(1024*1024)),2)
            $FreeRamPercent = [math]::round((($FreeRamGB / $TotalRamGB) * 100),2)
            $UsedRamGB      = [math]::round(($TotalRamGB - $FreeRamGB),2)
            #if($FreeRamPercent -lt $threshold){
                $obj = [PSCustomObject]@{
                    Name           = 'RAM'
                    'Total(GB)' = "{0:0.00}" -f $TotalRamGB
                    'Used(GB)'  = "{0:0.00}" -f $UsedRamGB
                    'Free(GB)'  = "{0:0.00}" -f $FreeRamGB
                    'Free(%)'   = "{0:0}"    -f $FreeRamPercent
                }
                $ret += $obj
            #}
        }
    }
    return $ret
}

function Get-Diskinfo{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][Int]$threshold
    )
    $function = $($MyInvocation.MyCommand.Name)
    Write-verbose $function
    $ret = @()
    $wmiobj = Get-WMIObject Win32_LogicalDisk -ErrorAction Stop| Where-Object{$_.DriveType -eq 3} # | Where-Object{ ($_.freespace/$_.Size)*100 -lt $threshold}
    if(-not([String]::IsNullOrEmpty($wmiobj))){
        $wmiobj | ForEach-Object{
            $obj = [PSCustomObject]@{
                Name        = $_.Name
                VolumeName  = $_.VolumeName
                FileSystem  = $_.FileSystem
                Description = $_.Description
                'Total(GB)' = "{0:0.00}" -f [math]::round(($_.size/1gb),2)
                'Free(GB)'  = "{0:0.00}" -f [math]::round(($_.freespace/1gb),2)
                'Free(%)'   = "{0:0}"    -f [math]::round(($_.freespace/$_.size*100),2)
            }
            $ret += $obj
        }
    }
    return $ret
}

function Get-LastEventCodes{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][String]$Logname,
        [Parameter(Mandatory=$true)][Int]   $day
    )
    $function = $($MyInvocation.MyCommand.Name)
    Write-verbose $function
    $ret = @()
    [DateTime]$now    = Get-Date
    [DateTime]$after  = $now.AddDays(-$day)
    [DateTime]$before = $now
    $wmiobj = Get-EventLog $Logname -EntryType Error, Warning -After $after -Before $before -ErrorAction Stop
    if(-not([String]::IsNullOrEmpty($wmiobj))){
            $wmiobj | ForEach-Object{
                if($ret.EventID -notcontains $_.EventID){
                    $obj = [PSCustomObject]@{
                        Logname       = $Logname
                        TimeGenerated = $_.TimeGenerated
                        EventID       = $_.EventID
                        EntryType     = $_.EntryType
                        Message       = $_.Message
                    }
                    $ret += $obj
                }
            }
        }
    return $ret
}

function Get-StoppedServices{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][Object]$ExceptionList = @('gpsvc','sppsvc')
    )
    $function = $($MyInvocation.MyCommand.Name)
    Write-verbose $function
    $ret = @()
    $wmiobj = Get-WmiObject Win32_Service -ErrorAction Stop | Where-Object StartMode -eq 'Auto' | Where-Object State -eq 'Stopped'
    if(-not([String]::IsNullOrEmpty($wmiobj))){
        $wmiobj | ForEach-Object{
            if($ExceptionList -notcontains $_.Name){
                $obj = [PSCustomObject]@{
                    Name        = $_.Name
                    DisplayName = $_.DisplayName
                    Status      = $_.Status
                    State       = $_.State
                    StartMode   = $_.StartMode
                    StartName   = $_.StartName
                    Description = $_.Description
                }
                $ret += $obj
            }
        }
    }
    return $ret
}

function Get-TopProcesses{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][Int]$threshold
    )
    $function = $($MyInvocation.MyCommand.Name)
    Write-verbose $function
    $ret = @()
    $wmiobj = Get-Process -ErrorAction Stop | Where-Object StartTime -ne $null | Sort-Object WorkingSet64 -Descending | Select-Object -First $threshold
    if(-not([String]::IsNullOrEmpty($wmiobj))){
        $wmiobj | ForEach-Object{
            $obj = [PSCustomObject]@{
                ProcessName     = $_.ProcessName
                PID             = $_.Id
                'CPU(s)'        = "{0:0,0}" -f $_.CPU
                Threads         = $_.Threads.Count
                StartTime       = $_.StartTime
                'Allocated(KB)' = "{0:0,0}" -f ($_.WorkingSet64/(1024))
                Path            = $_.Path
                Description     = $_.Description
                MainWindowTitle = $_.MainWindowTitle
            }
            $ret += $obj
        }
    }
    return $ret
}

function Get-MostProcesses{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][Int]$threshold
    )
    $function = $($MyInvocation.MyCommand.Name)
    Write-verbose $function
    $ret = @()
    $wmiobj = Get-Process | Select-Object ProcessName | Group-Object ProcessName | Sort-Object Count -Descending | Select-object -First $threshold
    if(-not([String]::IsNullOrEmpty($wmiobj))){
        $wmiobj | ForEach-Object{
            $obj = [PSCustomObject]@{
                Name  = $_.Name
                Count = $_.Count
            }
            $ret += $obj
        }
    }
    return $ret
}

function Get-InstalledHotfixes{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][Int]$threshold
    )
    $function = $($MyInvocation.MyCommand.Name)
    Write-verbose $function
    $ret = @()
    $wmiobj = Get-HotFix | Select-Object HotfixId,InstalledOn,InstalledBy,Description,Caption -Last $threshold | Sort-Object InstalledOn -Descending
    if(-not([String]::IsNullOrEmpty($wmiobj))){
        $wmiobj | ForEach-Object{
            $obj = [PSCustomObject]@{
                HotfixId    = $_.HotfixId
                InstalledOn = $_.InstalledOn
                InstalledBy = $_.InstalledBy
                Description = $_.Description
                Caption     = $_.Caption
            }
            $ret += $obj
        }
    }
    return $ret
}

function Get-MemberOfLocalAdmins{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][Object]$ExceptionList
    )
    $function = $($MyInvocation.MyCommand.Name)
    Write-verbose $function
    $ret = @()
    $admins = Get-LocalGroupMember -SID 'S-1-5-32-544'
    if(-not([String]::IsNullOrEmpty($admins))){
        $admins | ForEach-Object{
            if($ExceptionList -notcontains $_.Name){
                $obj = [PSCustomObject]@{
                    Name            = $_.Name
                    SID             = $_.SID
                    PrincipalSource = $_.PrincipalSource
                    ObjectClass     = $_.ObjectClass
                }
                $ret += $obj
            }
        }
    }
    return $ret
}
