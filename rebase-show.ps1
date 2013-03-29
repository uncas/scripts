function Cleanup {
    if (Test-Path gamma) { rmdir -force -recurse gamma }
    if (Test-Path beta) { rmdir -force -recurse beta }
    if (Test-Path alpha) { rmdir -force -recurse alpha }
    if (Test-Path mother) { rmdir -force -recurse mother }
}

function PrepareClone ($name) {
    git clone mother $name
    cd $name
    git config user.email "$name@example.com"
    git config user.name $name
    cd ..
}

function InitializeBranch {
    cd alpha
    Set-Content readme.txt "Readme"
    git add .
    git commit -m "Add readme."
    git push
    cd ..
}

function AddCommit ($name) {
    $fileName = "todo-$name.txt"
    if (Test-Path $fileName) {
        $content = Get-Content $fileName
    }
    $content += "More stuff.
"
    Set-Content $fileName $content
    git add .
    git commit -m "Update todo."
}

function AddCommitsPullPush ($name) {
    cd $name
    #AddCommit $name
    AddCommit $name
    git pull
    git push
    cd ..
}

function AddCommitsPullRebasePush ($name) {
    cd $name
    #AddCommit $name
    AddCommit $name
    git pull --rebase
    git push
    cd ..
}

function AnalyzeResult {
    cd mother
    $commitCount = (git log --oneline).count
    $mergeCount = (git log --oneline --merges).count
    $mergePercentage = $mergeCount / $commitCount * 100
    Write-Host "$commitCount commits, $mergeCount merges ($mergePercentage %)"
    cd ..
}

Cleanup
git init mother --bare
PrepareClone "alpha"
InitializeBranch
PrepareClone "beta"
PrepareClone "gamma"
for ($i = 0; $i -lt 3; $i++) {
    AddCommitsPullPush "alpha"
    AddCommitsPullPush "beta"
    AddCommitsPullPush "gamma"
}
AnalyzeResult