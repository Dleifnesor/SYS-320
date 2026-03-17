. .\Get-CourseTable.ps1
#this pulls the course table from the website and translates the days of the week from the other script
$courses    = Get-CourseTable
$translated = Translate-Days -CourseTable $courses


# 1) All classes taught by Furkan Paligu
Write-Host "`n--- i) Furkan Paligu's Classes ---`n"
$courses | Where-Object { $_.Instructor -eq "Furkan Paligu" }


# 2) FREE 105 sections on Wednesdays — display Class Code and Times only
Write-Host "`n--- ii) FREE 105 on Wednesdays (Class Code + Times) ---`n"
$translated | Where-Object {
    $_."Class Code" -like "*FREE 105*" -and
    $_.Days -contains "Wednesday"
} | Select-Object "Class Code", Times


# 3) Unique instructors teaching at least one SYS/NET/SEC/FOR/CSI/DAT course
Write-Host "`n--- iii) CIS-track Instructors (sorted, unique) ---`n"
# this gets the classes that are SYS/NET/SEC/FOR/CSI/DAT and then gets the instructors of those classes
$courses | Where-Object {
    $_."Class Code" -like "SYS*" -or
    $_."Class Code" -like "NET*" -or
    $_."Class Code" -like "SEC*" -or
    $_."Class Code" -like "FOR*" -or
    $_."Class Code" -like "CSI*" -or
    $_."Class Code" -like "DAT*"
} | Select-Object -ExpandProperty Instructor | Sort-Object -Unique


# 4) All instructors grouped by class count, sorted descending
Write-Host "`n--- iv) Instructors by Number of Classes ---`n"
$courses |
    Group-Object Instructor |
    Select-Object Name, Count |
    Sort-Object Count -Descending