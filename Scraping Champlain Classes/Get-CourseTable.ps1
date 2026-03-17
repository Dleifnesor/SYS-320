function Get-CourseTable {
    param(
        [string]$Url = "http://localhost/Courses2026SP.html"
    )

    $response = Invoke-WebRequest -Uri $Url
    $table    = $response.ParsedHtml.getElementsByTagName("table") | Select-Object -First 1
    $rows     = $table.getElementsByTagName("tr")

    # Pull headers from <th> tags; fall back to first row <td> if no <th> present
    $headers = @()
    $firstRow = $rows[0]
    $headerCells = $firstRow.getElementsByTagName("th")
    if ($headerCells.length -eq 0) {
        $headerCells = $firstRow.getElementsByTagName("td")
    }
    foreach ($cell in $headerCells) {
        $headers += $cell.innerText.Trim()
    }

    $courses = @()
    for ($i = 1; $i -lt $rows.length; $i++) {
        $cells = $rows[$i].getElementsByTagName("td")
        if ($cells.length -eq 0) { continue }

        $obj = [PSCustomObject]@{}
        for ($j = 0; $j -lt $headers.Count; $j++) {
            $val = if ($j -lt $cells.length) { $cells[$j].innerText.Trim() } else { "" }
            $obj | Add-Member -NotePropertyName $headers[$j] -NotePropertyValue $val
        }
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

        # Wildcards per lab hint — R = Thursday to avoid clash with T = Tuesday
        if ($raw -like "*M*") { $dayArray += "Monday"    }
        if ($raw -like "*T*") { $dayArray += "Tuesday"   }
        if ($raw -like "*W*") { $dayArray += "Wednesday" }
        if ($raw -like "*R*") { $dayArray += "Thursday"  }
        if ($raw -like "*F*") { $dayArray += "Friday"    }

        $course.Days = $dayArray
    }

    return $CourseTable
}