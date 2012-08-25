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
  $result = ""
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

function GetFileDiffHtml ($file, $from, $to) {
  $fileDiff = (git diff "$from...$to" $file)
  $result = "<li>
  <p>
    <a class='filename' name='$file'>$file</a>
  </p>
  <pre class='diff'>"
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
  $result += "  </pre>
</li>"
  return $result
}

$from = $args[0]
$to = $args[1]
$range = "$from...$to"
$stats = (git diff $range --stat)
$logs = (git log --oneline $range)
$files = (git diff $range --name-only)
$toc += "<ul id='toc'>"
$contents += "<ul id ='diffs'>"
foreach ($file in $files) {
  $file
  $toc += "<li><a href='#$file'>$file</a></li>"
  $contents += GetFileDiffHtml $file $from $to
}
$toc += "</ul>"
$contents += "</ul>"
$logsHtml = GetLogsHtml $logs
$html = "<html>
<head>
  <style type='text/css'>
    a.filename { background-color: black; color: white; padding: 0.2em; font-size: 125%; }
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
$toc
<div class='logs'>
$logsHtml
</div>
$contents
</body>
</html>"

Set-Content review.html $html

.\review.html