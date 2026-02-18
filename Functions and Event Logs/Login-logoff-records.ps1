# Get login and logoff records from the event log

#the Get-Date command is used to get the current date and time.
#the AddDays(-1) command is used to get the date and time from the previous day.
#the Get-EventLog command is used to get the event log records.
#the source command is used to get the source of the event log records.
#the LogName command is used to get the log name of the event log records.
#the After command is used to get the event log records after the specified date and time.
#the -14 is used to get the event log records from the previous 14 days.
$loginouts = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624,4625,4634,4648,4649; StartTime=(Get-Date).AddDays(-14)}
    
$loginoutsTable = @() # Empty array to store the login and logoff records
for($i = 0; $i -lt $loginouts.Count; $i++) {

    #creating event property value
    $loginEvent = ""
    if($loginouts[$i].EventID -eq 4624) {$loginEvent = "Login"}
    elseif ($loginouts[$i].EventID -eq 4625) {$loginEvent = "Failed Login"}
    elseif ($loginouts[$i].EventID -eq 4634) {$loginEvent = "Logoff"}

    #creating user property value
    #the 5 in replacement strings is the user name
    #$user = $loginouts[$i].ReplacementStrings is the entire replacement strings array which appends the user name to the array
    $user = $loginouts[$i].ReplacementStrings[5]

    #adding each new line to the empty array
    $loginoutsTable += New-Object PSObject -Property @{"Time" = $loginouts[$i].TimeGenerated;
    "Event" = $loginEvent;
    "User" = $user}
}

#displaying the login and logoff records
$loginoutsTable | Format-Table -AutoSize

#exporting the login and logoff records to a csv file
$loginoutsTable | Export-Csv -Path "$env:USERPROFILE\Desktop\login-logoff-records.csv" -NoTypeInformation

#exporting the login and logoff records to a json file
$loginoutsTable | ConvertTo-Json | Out-File -FilePath "$env:USERPROFILE\Desktop\login-logoff-records.json"