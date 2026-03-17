. .\Get-CourseTable.ps1

$courses    = Get-CourseTable
$translated = Translate-Days -CourseTable $courses
$translated