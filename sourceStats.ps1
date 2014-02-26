function FileInfo($name, $lines) {
	$this = "" | Select Lines, Name
	$this.Name = $name
	$this.Lines = $lines
	return $this
}
$files = (gci source -r -include *.cs)
$infos = @()
foreach ($file in $files) {
	$lines = (Get-Content $file).count
	if ($lines -gt 100) {
		$infos += FileInfo $file.FullName.Replace("C:\Projects\Dba\Work\source\", "") $lines
	}
}

$infos | Sort Lines -descending