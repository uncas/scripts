function Package ($id, $version) {
    $this = "" | Select Id, Version, FullName
    $this.Id = $id
    $this.Version = $version
    $this.FullName = "$id.$version"
    return $this
}

function PackageVersionComparison ($id, $currentVersion, $availableVersion) {
    $this = "" | Select Id, CurrentVersion, AvailableVersion
    $this.Id = $id
    $this.CurrentVersion = $currentVersion
    $this.AvailableVersion = $availableVersion
    return $this
}

function GetAvailableVersions ($id) {
    $url = "http://nuget.org/api/v2/package-versions/$id"
    $webClient = New-Object System.Net.WebClient
    [string]$json = $webClient.DownloadString($url)
    return $json | ConvertFrom-JSON
}

Write-Host "Getting available packages" -nonewline
$packageFiles = (gci -r -include packages.config) 
$packages = @{}
foreach ($packageFile in $packageFiles) {
    [xml]$packagesXml = Get-Content $packageFile
    foreach ($packageXml in $packagesXml.packages.package) {
        $id = $packageXml.id
        $version = $packageXml.version
        $package = Package $id $version
        if (!$packages.ContainsKey($package.FullName)) {
            $packages.Add($package.FullName, $package)
        }
    }
    Write-Host "." -nonewline
}

$sorted = $packages.GetEnumerator() | Sort-Object Name
#Write-Host ""
#Write-Host "Available packages:"
#$sorted

Write-Host ""
Write-Host "Checking newest available versions" -nonewline
$uptodate = @()
$outdated = @()
$noinfo = @()
foreach ($package in $sorted) {
    $id = $package.Value.Id
    $version = $package.Value.Version
    $versions = GetAvailableVersions $id
    if (!$versions) {
        $noinfo += $package.Value
        continue
    }
    $newestVersion = $versions[-1]
    $comparison = PackageVersionComparison $id $version $newestVersion
    if ($version -ne $newestVersion) {
        $outdated += $comparison
    }
    else {
        $uptodate += $comparison
    }
    Write-Host "." -nonewline
}

Write-Host ""
Write-Host ""
Write-Host "Up-to-date packages:"
$uptodate

Write-Host ""
Write-Host "Out-dated packages:"
Write-Host ""
$outdated

Write-Host ""
Write-Host "No version info found:"
Write-Host ""
$noinfo

