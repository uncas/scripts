$sha = (git rev-parse HEAD)
$branches = (git branch -r --no-merge main)
$conflicts = @()
$noConflicts = @()

function HasConflict ($output) {
    #$conflictPattern = "CONFLICT (content): Merge conflict in"
    foreach ($line in $output) {
        if ($line.Contains("conflict")) {
            return $True
        }
    }
    
    return $False
}

foreach ($branch in $branches) {
    $trimmed = $branch.Trim()
    if (!$trimmed.StartsWith("origin")) { continue }

    Write-Host $trimmed
    $output = (git merge $trimmed)
    if (HasConflict $output) {
        Write-Host "Conflicting branch: $trimmed"
        $conflicts += $trimmed
    }
    else {
        $noConflicts += $trimmed
    }
    
    git reset --hard $sha
    git clean -d -f -x
}

Write-Host ""
Write-Host " * * *"
Write-Host ""
Write-Host "Conflicting branches:"

foreach ($branch in $conflicts) {
    Write-Host " - $branch"
}

Write-Host ""
Write-Host "No-conflict branches:"
foreach ($branch in $noConflicts) {
    Write-Host " - $branch"
}