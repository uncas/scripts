param ($hostName = "127.0.0.1")

$hostEntry = [Net.DNS]::GetHostEntry($hostName)
$ip = $hostEntry.AddressList[0].IPAddressToString

Write-Host "Host '$hostName' at IP '$ip'."

$openPorts = @()
$ping = New-Object System.Net.Networkinformation.Ping
$pingStatus = $ping.Send($ip, 100)

if ($pingStatus.Status -eq "TimedOut") {
    Write-Host "Timed out"
    return
}

Write-Host "Pinged OK."

for ($port = 80; $port -lt 1024*64; $port++) {
    $client = New-Object System.Net.Sockets.TCPClient
    $begin = $client.BeginConnect($pingStatus.Address, $port, $null, $null)
    Write-Host $port
    if($client.Connected) {
        $openPorts += $port
        Write-Host "$port open"
    }
    else {
        Start-Sleep -Milli 1000
        if ($client.Connected) {
            $openPorts += $port
            Write-Host "$port open"
        }
    }
    $client.Close()
}
