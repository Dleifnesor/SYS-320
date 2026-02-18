# main.ps1
# Uses dot notation to load functions from functions.ps1

. "$PSScriptRoot\functions.ps1"

# Call Get-LoginLogoff and print results
Write-Host "=== Login and Logoff Events (All Time) ===" -ForegroundColor Cyan
$loginResults = Get-LoginLogoff -days 0
$loginResults | Format-Table -AutoSize

# Call Get-StartupShutdown and print results
Write-Host "=== System Startup and Shutdown Events (All Time) ===" -ForegroundColor Cyan
$startupResults = Get-StartupShutdown -days 0
$startupResults | Format-Table -AutoSize
