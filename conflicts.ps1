function Conflict ($branch, $otherBranch, $files = @()) {
    $this = "" | Select Branch, OtherBranch, Files
    $this.Branch = $branch
    $this.OtherBranch = $otherBranch
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

$startBranch = "main"
$workBranch = "MergeScriptWork"

$branches = (git branch -r --no-merge $startBranch)
$conflicts = @()
$noConflicts = @()

$relevantBranches = @()

Write-Host "Finding relevant branches..."
foreach ($branch in $branches) {
    $trimmed = $branch.Trim()
    if (!$trimmed.StartsWith("origin")) { continue }
    
    $lastCommit = (git log $trimmed --oneline --since="7.days.ago" -1)
    if (!$lastCommit) { continue }

    $relevantBranches += $trimmed
    Write-Host " - $trimmed"
}

Write-Host "Merging relevant branches and finding conflicts..."
$firstIndex = 0
foreach ($branch in $relevantBranches)
{
    git checkout $startBranch
    git branch -D $workBranch
    git checkout -b $workBranch $branch
    $sha = (git rev-parse HEAD)

    for ($i = $firstIndex + 1; $i -le $relevantBranches.count-1; $i++) {
        $otherBranch = $relevantBranches[$i]
        Write-Host "Finding conflicts between '$branch' - '$otherBranch':"
        $output = (git merge $otherBranch)
        $conflictingFiles = (HasConflict $output)
        if ($conflictingFiles.count -gt 0) {
            Write-Host "Conflict between branches '$branch' - '$otherBranch'"
            $conflicts += Conflict $branch $otherBranch $conflictingFiles
        }
        else {
            $noConflicts += Conflict $branch $otherBranch
        }
    
        git reset --hard $sha
        git clean -d -f -x
    }
    
    $firstIndex++
}

git checkout $startBranch
git branch -D $workBranch

Write-Host ""
Write-Host " * * *"
Write-Host ""
Write-Host "Conflicting branches:"

$xml = "<root>"

foreach ($conflict in $conflicts) {
    $branch = $conflict.Branch
    $otherBranch = $conflict.OtherBranch
    $files = $conflict.Files
    Write-Host " - $branch - $otherBranch"
    $xml += "
  <branches branch='$branch' otherBranch='$otherBranch'>"
    foreach ($file in $files) {
        Write-Host "   - $file"
        $xml += "
    <conflict>$file</conflict>"
    }
    $xml += "
    </branches>"
}

Write-Host ""
Write-Host "No-conflict branches:"
foreach ($conflict in $noConflicts) {
    $branch = $conflict.Branch
    $otherBranch = $conflict.OtherBranch
    Write-Host " - $branch - $otherBranch"
    $xml += "
  <branches branch='$branch' otherBranch='$otherBranch' />"
}

$xml += "
</root>"
$xmlFile = "C:\Temp\conflicts.xml"
Set-Content $xmlFile $xml