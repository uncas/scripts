$from = "release0125"
$to = "HEAD"

$range = "$from..$to"

function Stat ($author, [int]$commits, [int]$files, [int]$insertions, [int]$deletions) {
    $this = "" | Select Author, Commits, Files, Insertions, Deletions, `
        DeletionsPerInsertion, ChangesPerCommit
    $this.Author = $author
    $this.Commits = $commits
    $this.Files = $files
    $this.Insertions = $insertions
    $this.Deletions = $deletions
    $this.DeletionsPerInsertion = $deletions / $insertions
    $this.ChangesPerCommit = ($insertions + $deletions) / $commits
    return $this
}

$authorLines = (git shortlog -s $range)
$authorStats = @()

foreach ($authorLine in $authorLines) {
    $files = 0
    $insertions = 0
    $deletions = 0
    $parts = $authorLine.Trim().Split()
    $commits = $parts[0]
    $fullAuthor = $authorLine.Replace($commits, "").Trim()
    $author = $fullAuthor
    if ($author.Contains("Mahon")) { $author = "Mahon" }
    if ($author.Contains("Martin")) { $author = "Martin" }
    $stats = (git log --author="$author" --oneline --shortstat $range)
    #  1 files changed, 0 insertions(+), 2 deletions(-)
    foreach ($stat in $stats) {
        if (!$stat -or !$stat.Contains("files changed")) { continue }
        $statParts = $stat.Trim().Split()
        $files += $statParts[0]
        $insertions += $statParts[3]
        $deletions += $statParts[5]
    }
    $authorStats += Stat $fullAuthor $commits $files $insertions $deletions
    Write-Host "$fullAuthor - $commits commits - $files files - $insertions insertions - $deletions deletions"
}

Write-Host "Most files:"
foreach ($authorStat in $authorStats | sort Files -desc) {
    $number = $authorStat.Files
    $author = $authorStat.Author
    Write-Host "    $number - $author"
}

Write-Host "Most commits:"
foreach ($authorStat in $authorStats | sort Commits -desc) {
    $number = $authorStat.Commits
    $author = $authorStat.Author
    Write-Host "    $number - $author"
}

Write-Host "Most insertions:"
foreach ($authorStat in $authorStats | sort Insertions -desc) {
    $number = $authorStat.Insertions
    $author = $authorStat.Author
    Write-Host "    $number - $author"
}

Write-Host "Most deletions:"
foreach ($authorStat in $authorStats | sort Deletions -desc) {
    $number = $authorStat.Deletions
    $author = $authorStat.Author
    Write-Host "    $number - $author"
}

Write-Host "Cleaner: Most deletions per insertion:"
foreach ($authorStat in $authorStats | sort DeletionsPerInsertion -desc) {
    $number = $authorStat.DeletionsPerInsertion
    $author = $authorStat.Author
    Write-Host "    $number - $author"
}

Write-Host "Bulk-changer: Most changes per commit:"
foreach ($authorStat in $authorStats | sort ChangesPerCommit -desc) {
    $number = [int]$authorStat.ChangesPerCommit
    $author = $authorStat.Author
    Write-Host "    $number - $author"
}
