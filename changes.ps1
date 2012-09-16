function Stat($commits, $files, $insertions, $deletions) {
    $this = "" | Select Commits, Files, Insertions, Deletions
    $this.Commits = $commits
    $this.Files = $files
    $this.Insertions = $insertions
    $this.Deletions = $deletions
    return $this
}

$authorLines = (git shortlog -s)

foreach ($authorLine in $authorLines) {
    $files = 0
    $insertions = 0
    $deletions = 0
    $parts = $authorLine.Trim().Split()
    $commits = $parts[0]
    $author = $authorLine.Replace($commits, "").Trim()
    if ($author.Contains("Mahon")) { $author = "Mahon" }
    if ($author.Contains("Martin")) { $author = "Martin" }
    $stats = (git log --author="$author" --oneline --shortstat)
    #  1 files changed, 0 insertions(+), 2 deletions(-)
    foreach ($stat in $stats) {
        if (!$stat -or !$stat.Contains("files changed")) { continue }
        $statParts = $stat.Trim().Split()
        $files += $statParts[0]
        $insertions += $statParts[3]
        $deletions += $statParts[5]
    }
    "$author - $commits commits - $files files - $insertions insertions - $deletions deletions"
}