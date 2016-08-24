$baseBranch = "main"

function GetAge($date){
	$age = new-timespan -start $date -end (get-date)
	return $age
}

function GetAgeOfFirstCommit($branch) {
	$dates = git log --reverse $baseBranch..$branch --oneline --format=%ad --date=iso
	if (!$dates){
		return
	}
	
	$first = [DateTime]$dates[0]
	return GetAge $first
}

function GetAgeOfLastCommit($branch) {
	$date = git log -1 $baseBranch..$branch --oneline --format=%ad --date=iso
	if (!$date){
		return
	}
	
	$last = [DateTime]$date
	return GetAge $last
}

function GetActiveBranches {
	$branches = git for-each-ref --sort=-committerdate --format='%(refname)' refs/remotes/origin
	foreach ($branch in $branches) {
		if ($branch.Contains("spike")) { continue }

		$branchName = $branch.Replace("refs/remotes/", "")
		$lastCommit = GetAgeOfLastCommit($branchName)
		if (!$lastCommit) { continue }
		
		$lastChangedHoursAgo = [int]$lastCommit.TotalHours
		if ($lastChangedHoursAgo -gt 24*20) { break }
		
		$firstCommit = GetAgeOfFirstCommit($branchName)
		$firstChangedHoursAgo = [int]$firstCommit.TotalHours
		"Last changed $lastChangedHoursAgo hours ago, first changed $firstChangedHoursAgo hours ago: $branchName"
	}
}

GetActiveBranches