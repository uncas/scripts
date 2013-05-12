param(
	$ref
)
$merges = (git log --reverse --oneline --merges "$ref..")
foreach ($merge in $merges) {
	if ($merge.Contains("main'")) { continue }
	if (!$merge.Contains("into main")) { continue }
	$parts = $merge.Split(' ')
	$sha = $parts[0]
	git merge-base --is-ancestor $ref $sha
	if ($LASTEXITCODE -ne 0) { continue }
	$merge
	git log $sha -1
	break
}