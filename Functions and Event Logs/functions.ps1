# functions.ps1
# Contains two functions: Get-LoginLogoff and Get-StartupShutdown

function Get-LoginLogoff {
    param([int]$days)

    $loginouts = Get-EventLog -LogName System -Source "Microsoft-Windows-Winlogon"

    $loginoutsTable = @()

    for ($i = 0; $i -lt $loginouts.Count; $i++) {

        $event = ""
        if ($loginouts[$i].EventID -eq 7001) { $event = "Logon" }
        if ($loginouts[$i].EventID -eq 7002) { $event = "Logoff" }

        $rawUser = $loginouts[$i].ReplacementStrings[1]

        $user = try {
            $sid = New-Object System.Security.Principal.SecurityIdentifier($rawUser)
            $sid.Translate([System.Security.Principal.NTAccount]).Value
        } catch {
            $rawUser
        }

        $loginoutsTable += [PSCustomObject]@{
            "Time"  = $loginouts[$i].TimeGenerated
            "Id"    = $loginouts[$i].EventID
            "Event" = $event
            "User"  = $user
        }
    }

    return $loginoutsTable
}

function Get-StartupShutdown {
    param([int]$days)

    $startups = Get-EventLog -LogName System -Source "Microsoft-Windows-Kernel-General" -InstanceId 1, 13 -ErrorAction SilentlyContinue

    $startupsTable = @()

    for ($i = 0; $i -lt $startups.Count; $i++) {

        $event = ""
        if ($startups[$i].EventID -eq 1)  { $event = "System Startup" }
        if ($startups[$i].EventID -eq 13) { $event = "System Shutdown" }

        $startupsTable += [PSCustomObject]@{
            "Time"  = $startups[$i].TimeGenerated
            "Id"    = $startups[$i].EventID
            "Event" = $event
            "User"  = "System"
        }
    }

    return $startupsTable
}
