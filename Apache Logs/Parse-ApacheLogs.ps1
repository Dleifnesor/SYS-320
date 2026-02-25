function Parse-ApacheLogs {
    # Define the function parameters
    param (
        # Define the log path
        [string]$LogPath = ".\access.log"
    )
# Get the logs from the log file
    $logs = Get-Content -Path $LogPath
    # Create an empty array to store the parsed logs
    $parsedLogs = @()

    # Parse the logs
    foreach ($line in $logs) {
        # Split the line into words
        $words = $line.Split(' ')
        # Create a custom object for the log entry
        $entry = [PSCustomObject]@{
            IP        = $words[0] # The IP address of the request
            Ident     = $words[1] # The ident of the request
            AuthUser  = $words[2] # The user that authenticated to the server
            Date      = $words[3].TrimStart('[') # The date of the request
            Time      = $words[4].TrimEnd(']') # The time of the request
            Method    = $words[5].TrimStart('"') # The method of the request
            Page      = $words[6] # The page requested
            Protocol  = $words[7].TrimEnd('"') # The protocol of the request
            Status    = $words[8] # The status of the request
            Size      = $words[9] # The size of the request
            Referrer  = $words[10].Trim('"') # The referrer of the request
            UserAgent = $words[11].TrimStart('"') # The user agent of the request
        }
        # Add the log entry to the parsed logs
        $parsedLogs += $entry
    }
    # Return the parsed logs as a custom object
    return $parsedLogs
}