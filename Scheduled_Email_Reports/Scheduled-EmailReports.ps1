# Scheduled-EmailReports.ps1
# SYS-320-01 | Scheduled Email Reports of At Risk Users
# Reads configuration.txt, evaluates logs over the configured day window,
# identifies at-risk users, generates a report, emails it, and installs
# a Windows Scheduled Task for automatic daily execution.
#
# Usage:
#   .\Scheduled-EmailReports.ps1 -Mode Report
#   .\Scheduled-EmailReports.ps1 -Mode Schedule
#   .\Scheduled-EmailReports.ps1 -Mode SetupConfig

[CmdletBinding()]
param(
    [ValidateSet('Report','Schedule','SetupConfig')]
    [string]$Mode = 'Report',

    [string]$ConfigFile  = "$PSScriptRoot\configuration.txt",
    [string]$LogFile     = "$PSScriptRoot\user_activity.log",
    [string]$SmtpServer  = "smtp.yourdomain.com",
    [int]   $SmtpPort    = 587,
    [string]$FromAddress = "reports@yourdomain.com",
    [string]$ToAddress   = "admin@yourdomain.com",
    [int]   $FailedLoginThreshold = 3
)

$ErrorActionPreference = 'Stop'
$ReportFile = "$PSScriptRoot\report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

################################################################################
# A. Configuration Management
################################################################################

function Read-Config {
    if (-not (Test-Path $ConfigFile)) {
        Write-Error "configuration.txt not found at: $ConfigFile`nRun: .\Scheduled-EmailReports.ps1 -Mode SetupConfig"
    }

    $lines = Get-Content $ConfigFile | Where-Object { $_.Trim() -ne '' }

    if ($lines.Count -lt 2) {
        Write-Error "configuration.txt must contain exactly 2 lines: number of days, then HH:MM time"
    }

    $script:Days     = [int]$lines[0].Trim()
    $script:ExecTime = $lines[1].Trim()

    Write-Host "[*] Config loaded: evaluate $($script:Days) days | run daily at $($script:ExecTime)"
}

function Set-Config {
    @"
7
13:12
"@ | Set-Content $ConfigFile

    Write-Host "[*] configuration.txt written to: $ConfigFile"
    Write-Host "    Line 1: 7      (evaluate last 7 days of logs)"
    Write-Host "    Line 2: 13:12  (schedule daily execution at 1:12 PM)"
    Get-Content $ConfigFile
}

################################################################################
# B. Sample Log Generation
################################################################################

function New-SampleLog {
    Write-Host "[*] Writing sample user_activity.log to: $LogFile"

    $today = Get-Date
    @"
$($today.AddDays(-9).ToString('yyyy-MM-dd')) 08:00:00 jsmith LOGIN SUCCESS
$($today.AddDays(-9).ToString('yyyy-MM-dd')) 08:05:12 bjones LOGIN FAILED
$($today.AddDays(-9).ToString('yyyy-MM-dd')) 08:05:45 bjones LOGIN FAILED
$($today.AddDays(-9).ToString('yyyy-MM-dd')) 08:06:01 bjones LOGIN FAILED
$($today.AddDays(-9).ToString('yyyy-MM-dd')) 08:06:30 bjones LOGIN FAILED
$($today.AddDays(-8).ToString('yyyy-MM-dd')) 09:10:00 cwhite LOGIN FAILED
$($today.AddDays(-8).ToString('yyyy-MM-dd')) 09:10:22 cwhite LOGIN FAILED
$($today.AddDays(-8).ToString('yyyy-MM-dd')) 09:11:00 cwhite LOGIN SUCCESS
$($today.AddDays(-3).ToString('yyyy-MM-dd')) 07:55:00 agreen LOGIN FAILED
$($today.AddDays(-3).ToString('yyyy-MM-dd')) 07:55:10 agreen LOGIN FAILED
$($today.AddDays(-3).ToString('yyyy-MM-dd')) 07:55:20 agreen LOGIN FAILED
$($today.AddDays(-3).ToString('yyyy-MM-dd')) 07:55:30 agreen LOGIN FAILED
$($today.AddDays(-3).ToString('yyyy-MM-dd')) 07:55:40 agreen LOGIN FAILED
$($today.AddDays(-1).ToString('yyyy-MM-dd')) 10:00:00 jsmith LOGIN SUCCESS
"@ | Set-Content $LogFile
}

################################################################################
# C. At-Risk User Identification
################################################################################

function Get-AtRiskUsers {
    param([int]$Days)

    $cutoff = (Get-Date).AddDays(-$Days).Date
    Write-Host "[*] Evaluating logs from $($cutoff.ToString('yyyy-MM-dd')) to today ($Days-day window)"

    if (-not (Test-Path $LogFile)) {
        Write-Warning "Log file not found: $LogFile — generating sample data"
        New-SampleLog
    }

    # Parse log: YYYY-MM-DD HH:MM:SS USERNAME ACTION STATUS
    $failedCounts = @{}

    Get-Content $LogFile | ForEach-Object {
        $parts = $_ -split '\s+'
        if ($parts.Count -lt 5) { return }

        $entryDate = [datetime]::ParseExact($parts[0], 'yyyy-MM-dd', $null)
        $username  = $parts[2]
        $action    = $parts[3]
        $status    = $parts[4]

        if ($entryDate -ge $cutoff -and $action -eq 'LOGIN' -and $status -eq 'FAILED') {
            if (-not $failedCounts.ContainsKey($username)) {
                $failedCounts[$username] = 0
            }
            $failedCounts[$username]++
        }
    }

    # Return users exceeding threshold as objects
    $atRisk = $failedCounts.GetEnumerator() |
        Where-Object { $_.Value -gt $FailedLoginThreshold } |
        Select-Object @{N='Username'; E={$_.Key}}, @{N='FailedAttempts'; E={$_.Value}} |
        Sort-Object FailedAttempts -Descending

    return $atRisk
}

################################################################################
# D. Report Generation
################################################################################

function New-Report {
    param([int]$Days)

    $atRiskUsers = Get-AtRiskUsers -Days $Days

    $reportLines = @()
    $reportLines += "=" * 50
    $reportLines += "  At-Risk User Report"
    $reportLines += "  Generated : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $reportLines += "  Window    : Last $Days days"
    $reportLines += "  Threshold : > $FailedLoginThreshold failed logins"
    $reportLines += "=" * 50
    $reportLines += ""

    if ($atRiskUsers) {
        $reportLines += "  At-Risk Users:"
        $reportLines += ""
        foreach ($u in $atRiskUsers) {
            $reportLines += "  {0,-20} {1} failed attempts" -f $u.Username, $u.FailedAttempts
        }
    } else {
        $reportLines += "  No at-risk users identified in this window."
    }

    $reportLines += ""
    $reportLines += "=" * 50
    $reportLines += "  End of Report"
    $reportLines += "=" * 50

    $reportLines | Set-Content $ReportFile
    Write-Host "[*] Report written: $ReportFile"

    return $atRiskUsers
}

################################################################################
# E. Email Delivery
################################################################################

function Send-Report {
    param([string]$ReportPath)

    $subject  = "At-Risk User Report — $(Get-Date -Format 'yyyy-MM-dd')"
    $body     = Get-Content $ReportPath -Raw

    $mailParams = @{
        SmtpServer = $SmtpServer
        Port       = $SmtpPort
        From       = $FromAddress
        To         = $ToAddress
        Subject    = $subject
        Body       = $body
        UseSsl     = $true
    }

    # If SMTP credentials are needed, load from a secure file or prompt
    # $cred = Get-Credential
    # $mailParams['Credential'] = $cred

    try {
        Send-MailMessage @mailParams
        Write-Host "[*] Report emailed to: $ToAddress via $SmtpServer"
    } catch {
        Write-Warning "Email send failed: $_"
        Write-Host "[*] Report saved locally at: $ReportPath"
        Write-Host "[*] To send manually: Send-MailMessage -To '$ToAddress' -From '$FromAddress' -Subject '$subject' -Body (Get-Content '$ReportPath' -Raw) -SmtpServer '$SmtpServer'"
    }
}

################################################################################
# F. Scheduled Task Installation
################################################################################

function Install-ScheduledTask {
    $timeParts = $script:ExecTime -split ':'
    if ($timeParts.Count -ne 2) {
        Write-Error "ExecTime in configuration.txt must be HH:MM format (got: $($script:ExecTime))"
    }

    $hour   = [int]$timeParts[0]
    $minute = [int]$timeParts[1]
    $triggerTime = "{0:D2}:{1:D2}" -f $hour, $minute

    $taskName   = "SYS320-AtRiskUserReport"
    $scriptPath = $PSCommandPath
    $action     = New-ScheduledTaskAction `
                    -Execute "powershell.exe" `
                    -Argument "-NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`" -Mode Report"

    $trigger    = New-ScheduledTaskTrigger -Daily -At $triggerTime

    $settings   = New-ScheduledTaskSettingsSet `
                    -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
                    -StartWhenAvailable

    # Register (overwrites if already exists)
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action   $action `
        -Trigger  $trigger `
        -Settings $settings `
        -RunLevel Highest `
        -Force | Out-Null

    Write-Host "[*] Scheduled task registered: $taskName"
    Write-Host "    Runs daily at: $triggerTime"
    Write-Host "    Script: $scriptPath"
    Write-Host ""
    Write-Host "[*] Current task definition:"
    Get-ScheduledTask -TaskName $taskName | Format-List TaskName, State
    (Get-ScheduledTask -TaskName $taskName).Triggers | Format-List
}

################################################################################
# Main
################################################################################

switch ($Mode) {
    'Report' {
        Read-Config
        New-Report -Days $script:Days
        Send-Report -ReportPath $ReportFile
    }
    'Schedule' {
        Read-Config
        Install-ScheduledTask
    }
    'SetupConfig' {
        Set-Config
    }
}
