$sha = (git rev-parse HEAD)
$branches = (git branch -r --no-merge main)
$conflicts = @()
$noConflicts = @()

function HasConflict ($output) {
    $result = @()
    $conflictPattern = "CONFLICT (content): Merge conflict in"
    foreach ($line in $output) {
        if ($line.Contains("conflict")) {
            $file = $line.Replace($conflictPattern, "").Trim()
            $result += $file
        }
    }
    
    return $result
}

foreach ($branch in $branches) {
    $trimmed = $branch.Trim()
    if (!$trimmed.StartsWith("origin")) { continue }

    Write-Host $trimmed
    $output = (git merge $trimmed)
    $conflictingFiles = (HasConflict $output)
    if ($conflictingFiles.count -gt 0) {
        Write-Host "Conflicting branch: $trimmed"
        $conflicts += $trimmed
    }
    else {
        $noConflicts += $trimmed
    }
    
    git reset --hard $sha
    git clean -d -f -x
    
    if ($noConflicts.count -eq 2) { break }
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