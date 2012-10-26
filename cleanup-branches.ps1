$branches = (git branch -r --merge release0139)
foreach ($branch in $branches) {
    $branchShort = $branch.Replace("origin/", "").Trim()
    Write-Host "git push origin :$branchShort"
}



return



#branches where I'm the last committer:
$branches = (git branch -r)
$selected = @()
foreach ($branch in $branches) {
    $branchShort = $branch.Trim()
    if ($branchShort.Contains("origin/HEAD")) { continue }
    $author = (git log $branchShort -1 --format=%an)
    "$author - $branch"
    if (!$author.Contains("Hebsgaard")) { continue }
    $selected += $branch
}

foreach ($branch in $selected) { Write-Host $branch }
