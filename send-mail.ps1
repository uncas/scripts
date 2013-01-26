$smtp = "SMTP.DMZDK.LOCAL"
$from = "osoerensen@ebay.com"
$defaultContent = "To: ...
Subject: ...

Hej ...

Best regards,
Ole Lynge Sørensen
Software Development, C2C Denmark | eBay Classifieds Group 
Phone: +45 87 31 32 92 | osoerensen@ebay.com"

$tempFile = "$env:temp\ollsmail.txt"

Set-Content -Path $tempFile -Value $defaultContent

notepad $tempFile | Out-Null

$contents = Get-Content $tempFile

if (!$contents) { return }

$to = ($contents | Select -first 1).Replace("To: ", "")
$subject = ($contents | Select -skip 1 -first 1).Replace("Subject: ", "")
$body = ($contents | Select -skip 3 ) -join [Environment]::NewLine

if (!$to) { return }
if (!$subject) { return }
if (!$body) { return }

$utf8 = [System.Text.Encoding]::UTF8
Send-MailMessage -From $from -To $to -Bcc $from -SmtpServer $smtp -Subject $subject -Body $body -Encoding $utf8
Write-Host "Mail sent to $to"