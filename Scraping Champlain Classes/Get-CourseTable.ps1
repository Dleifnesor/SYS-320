function Get-CourseTable {
    param(
        [string]$Url = "http://localhost/Courses2026SP.html"
    )

    $response = Invoke-WebRequest -Uri $Url
    $table    = $response.ParsedHtml.getElementsByTagName("table") | Select-Object -First 1

    # @() forces COM collection into a real PS array so integer indexing works
    $rows = @($table.getElementsByTagName("tr"))

    # Extract headers as plain strings
    $headers     = @()
    $headerCells = @($rows[0].getElementsByTagName("th"))
    if ($headerCells.Count -eq 0) {
        $headerCells = @($rows[0].getElementsByTagName("td"))
    }
    foreach ($cell in $headerCells) {
        $headers += $cell.innerText.Trim()
    }

    $courses = @()
    for ($i = 1; $i -lt $rows.Count; $i++) {
        $comCells = @($rows[$i].getElementsByTagName("td"))
        if ($comCells.Count -eq 0) { continue }

        # Extract all innerText into a plain string array before any manipulation
        $vals = @()
        foreach ($cell in $comCells) {
            $vals += $cell.innerText.Trim()
        }

        # TBA rows omit Times column (9 strings instead of 10)
        # Insert empty string at index 5 to realign columns
        if ($vals.Count -eq 9) {
            $vals = $vals[0..4] + @("") + $vals[5..8]
        }

        $obj = [PSCustomObject]@{}
        for ($j = 0; $j -lt $headers.Count; $j++) {
            $v = if ($j -lt $vals.Count) { $vals[$j] } else { "" }
            $obj | Add-Member -NotePropertyName $headers[$j] -NotePropertyValue $v
        }

        # Rename Number -> Class Code
        $obj | Add-Member -NotePropertyName "Class Code" -NotePropertyValue $obj.Number
        $obj.PSObject.Properties.Remove("Number")

        # Split Times -> Time Start / Time End
        $times = $obj.Times
        if ($times -match "^(.+?)-(.+)$") {
            $obj | Add-Member -NotePropertyName "Time Start" -NotePropertyValue $Matches[1]
            $obj | Add-Member -NotePropertyName "Time End"   -NotePropertyValue $Matches[2]
        } else {
            $obj | Add-Member -NotePropertyName "Time Start" -NotePropertyValue $times
            $obj | Add-Member -NotePropertyName "Time End"   -NotePropertyValue ""
        }
        $obj.PSObject.Properties.Remove("Times")

        $courses += $obj
    }

    return $courses
}


function Translate-Days {
    param(
        [Parameter(Mandatory)][array]$CourseTable
    )

    foreach ($course in $CourseTable) {
        $raw      = $course.Days
        $dayArray = @()

        # R = Thursday to avoid clash with T = Tuesday
        if ($raw -like "*M*") { $dayArray += "Monday"    }
        if ($raw -like "*T*") { $dayArray += "Tuesday"   }
        if ($raw -like "*W*") { $dayArray += "Wednesday" }
        if ($raw -like "*R*") { $dayArray += "Thursday"  }
        if ($raw -like "*F*") { $dayArray += "Friday"    }

        $course.Days = $dayArray
    }

    return $CourseTable
}
