function diffstat ($from, $to) {
	$range = "$from..$to"
	$stat = (git diff $range --shortstat)
	if (!$stat) { return }
	$range
	$statParts = $stat.Trim().Split()
	$files = $statParts[0]
	$insertions = $statParts[3]
	$deletions = $statParts[5]
	"$to, $files, $insertions, $deletions" >> "..\diffchanges.csv"
	"$files files"
	"$insertions insertions"
	"$deletions deletions"
}

$file = "..\commits.txt"

$commits = Get-Content $file

foreach ($commit in $commits) {
	if (!$commit) { continue }
	if ($previous) {
		diffstat $previous $commit
	}
	$previous = $commit
}