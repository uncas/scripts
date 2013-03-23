function OutputMergedBranches () {
    $branches = (git branch -r --merge release0172)
    $count = 0
    foreach ($branch in $branches) {
        $branchShort = $branch.Replace("origin/", "").Trim()
        if ($branchShort -eq "current") { continue }
        if ($branchShort -eq "master") { continue }
        if ($branchShort -eq "SYI-API") { continue }
        if ($branchShort -eq "feature-QA") { continue }
        if ($branchShort.Contains("/")) { continue }
        Write-Host "git push origin :$branchShort"
        $count++
        if ($count % 9 -eq 0) {
            Write-Host "start-sleep -seconds 120"
        }
    }
}

function OutputLastCommitterPerBranch () {
    $days = 5
    Write-Host ""
    $branches = (git branch -r --no-merge main)
    $selected = @()
    Write-Host "Changes per branch since $days days ago:"
    foreach ($branch in $branches) {
        $branchShort = $branch.Trim()
        if ($branchShort.Contains("origin/HEAD")) { continue }
        $author = (git log $branchShort -1 --format=%an)
        $logs = git log --oneline $branchShort --since="$days days ago"
        $changes = 0
        if ($logs) { $changes = 1 }
        if ($logs -and $logs.count) { $changes = $logs.count }
        Write-Host "$changes - $branch"
        if ($changes -gt 0) { continue }
        $selected += "$author - $branch"
    }

    Write-Host "Last committer for branches that have not been changed in the last $days days:"
    foreach ($branch in ($selected | Sort)) { Write-Host $branch }
}

OutputMergedBranches
#OutputLastCommitterPerBranch
