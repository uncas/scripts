function GetLineType ($line) {
  if ($line.StartsWith("diff")) { return "header" }
  if ($line.StartsWith("index")) { return "header" }
  if ($line.StartsWith("---")) { return "header" }
  if ($line.StartsWith("+++")) { return "header" }
  if ($line.StartsWith("@@")) { return "section" }
  if ($line.StartsWith("+")) { return "added" }
  if ($line.StartsWith("-")) { return "removed" }
  return "unknown"
}

function GetLogsHtml ($logs) {
  foreach ($log in $logs) {
    $result += "<p>$log</p>"
  }
  return $result
}

function GetLineDiffHtml ($line, $lineType) {
  $encoded = $line.Replace("<", "&lt;")
  if ($encoded -eq "") { $encoded = "&nbsp;" }
  return "<p class='$lineType'>$encoded</p>"
}

function GetFileDiffHtml ($file, $from, $to, $nextFile) {
  $fileDiff = (git diff "$from...$to" $file)
  $result = "<li><p><a class='filename' name='$file'>$file</a></p>"
  if ($nextFile) {
    $result += "<p><a class='nextFile' href='#$nextFile'>next</a></p>"
  }
  $result += "<pre class='diff'>"
  if (!$fileDiff) { 
    $showArgument = "$to" + ":" + "$file"
    $addedFile = (git show "$showArgument")
	$result += "<p class='header'>New file:</p>"
	foreach ($line in $addedFile) {
      $result += GetLineDiffHtml "+$line" "added"
	}
  }
  else {
    foreach ($line in $fileDiff) {
      if (!$line) { continue }
	  $lineType = GetLineType $line
      $result += GetLineDiffHtml $line $lineType
	}
  }
  $result += "</pre></li>"
  return $result
}

$from = $args[0]
$to = $args[1]

$range = "$from...$to"

$stats = (git diff $range --stat)
$logs = (git log --oneline $range)
$files = (git diff $range --name-only)

foreach ($file in $files) {
  if ($file) {
    $fileIndex = [array]::IndexOf($files, $file)
  }
  $file
  $fileIndex
  $nextFile = $files[$fileIndex + 1]
  $toc += "<li><a href='#$file'>$file</a></li>"
  $contents += GetFileDiffHtml $file $from $to $nextFile
}
$logsHtml = GetLogsHtml $logs
$html = "<html>
<head>
  <title>$range</title>
  <style type='text/css'>
    a.filename { background-color: black; color: white; padding: 0.2em; font-size: 115%; }
    pre.diff { line-height: 90%; border: solid 1px #666666; padding: 0.2em; }
	pre.diff p { padding: 0; margin: 0; }
	pre.diff p.header { background-color: #EEEEEE; margin-bottom: 0.2em; }
	pre.diff p.section { background-color: #CCFFCC; margin: 0.2em 0; padding: 0.2em 0; }
	pre.diff p.added { background-color: #CCCCFF; }
	pre.diff p.removed { background-color: #FFCCCC; }
	div.logs { border: solid 1px #999999; padding: 0.5em; }
	div.logs p { margin: 0; padding: 0; }
   </style>
</head>
<body>
<div>
  <h1>$range</h1>
  <ul id='index'>
    <li><a href='#files'>Files</a>
    <li><a href='#commits'>Commits</a>
    <li><a href='#diffs'>Diffs</a>
  </ul>
</div>
<div>
  <a name='files' />
  <h2>Files</h2>
  <ul id='toc'>
    $toc
  </ul>
</div>
<div class='logs'>
  <a name='commits' />
  <h2>Commits</h2>
  $logsHtml
</div>
<div>
  <a name='diffs' />
  <h2>Diffs</h2>
  <ul id ='fileDiffs'>
    $contents
  </ul>
</div>
</body>
</html>"

Set-Content review.html $html

.\review.html