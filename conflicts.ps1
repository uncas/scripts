function Conflict ($branch, $files) {
    $this = "" | Select Branch, Files
    $this.Branch = $branch
    $this.Files = $files
    return $this
}

function HasConflict ($output) {
    $result = @()
    $conflictPattern = "CONFLICT (content): Merge conflict in"
    $info = "Automatic merge failed; fix conflicts and then commit the result."
    foreach ($line in $output) {
        if ($line.Trim().Contains($info)) { continue }
        if ($line.Contains("conflict")) {
            $file = $line.Replace($conflictPattern, "").Trim()
            $result += $file
        }
    }
    
    return $result
}

$sha = (git rev-parse HEAD)
$branches = (git branch -r --no-merge main)
$conflicts = @()
$noConflicts = @()

$relevantBranches = @()

Write-Host "Finding relevant branches..."
foreach ($branch in $branches) {
    $trimmed = $branch.Trim()
    if (!$trimmed.StartsWith("origin")) { continue }
    
    $lastCommit = (git log $trimmed --oneline --since="2.hours.ago" -1)
    if (!$lastCommit) { continue }

    $relevantBranches += $trimmed
    Write-Host " - $trimmed"
}

Write-Host "Merging relevant branches and finding conflicts..."
foreach ($branch in $relevantBranches)
{    
    Write-Host $branch
    $output = (git merge $branch)
    $conflictingFiles = (HasConflict $output)
    if ($conflictingFiles.count -gt 0) {
        Write-Host "Conflicting branch: $branch"
        $conflicts += Conflict $branch $conflictingFiles
    }
    else {
        $noConflicts += $branch
    }
    
    git reset --hard $sha
    git clean -d -f -x
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