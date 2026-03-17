. .\Get-CourseTable.ps1

$FullTable  = Get-CourseTable
$translated = Translate-Days -CourseTable $FullTable


# i) List all the classes of the instructor Furkan Paligu
Write-Host "`n--- i) Furkan Paligu's Classes ---`n"
$FullTable | Where-Object { $_.Instructor -eq "Furkan Paligu" } |
    Select-Object "Class Code", Instructor, Location, Days, "Time Start", "Time End"


# ii) List all the classes in FREE 105 on Wednesdays, only display Class Code and Times
Write-Host "`n--- ii) FREE 105 on Wednesdays (Class Code + Times) ---`n"
$translated | Where-Object {
    $_.Location -eq "FREE 105" -and
    $_.Days -contains "Wednesday"
} | Select-Object "Time Start", "Time End", "Class Code"


# iii) Make a list of all instructors that teach at least 1 SYS/NET/SEC/FOR/CSI/DAT course
# Sort by name and make it unique
Write-Host "`n--- iii) CIS-track Instructors (sorted, unique) ---`n"
$ITSInstructors = $FullTable | Where-Object {
    $_."Class Code" -like "SYS*" -or
    $_."Class Code" -like "NET*" -or
    $_."Class Code" -like "SEC*" -or
    $_."Class Code" -like "FOR*" -or
    $_."Class Code" -like "CSI*" -or
    $_."Class Code" -like "DAT*"
} | Select-Object Instructor | Sort-Object Instructor -Unique
$ITSInstructors


# iv) Group all instructors by number of classes, sort by class count
Write-Host "`n--- iv) Instructors by Number of Classes ---`n"
$FullTable |
    Where-Object { $_.Instructor -in $ITSInstructors.Instructor } |
    Group-Object Instructor |
    Select-Object Count, Name |
    Sort-Object Count -Descending
