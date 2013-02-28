$sha = (git rev-parse HEAD)
$branches = (git branch -r --no-merge main)
$conflicts = @()
$noConflicts = @()

function Conflict ($branch, $files) {
    $this = "" | Select Branch, Files
    $this.Branch = $branch
    $this.Files = $files
    return $this
}

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
    
    $lastCommit = (git log $trimmed --oneline --since="7.days.ago" -1)
    if (!$lastCommit) { continue }

    Write-Host $trimmed
    $output = (git merge $trimmed)
    $conflictingFiles = (HasConflict $output)
    if ($conflictingFiles.count -gt 0) {
        Write-Host "Conflicting branch: $trimmed"
        $conflicts += Conflict $trimmed $conflictingFiles
    }
    else {
        $noConflicts += $trimmed
    }
    
    git reset --hard $sha
    git clean -d -f -x
    
    #if ($noConflicts.count -eq 2) { break }
}

Write-Host ""
Write-Host " * * *"
Write-Host ""
Write-Host "Conflicting branches:"

foreach ($conflict in $conflicts) {
    $branch = $conflict.Branch
    $files = $conflict.Files
    Write-Host " - $branch"
    foreach ($file in $files) {
        Write-Host "   - $file"
    }
}

Write-Host ""
Write-Host "No-conflict branches:"
foreach ($branch in $noConflicts) {
    Write-Host " - $branch"
}