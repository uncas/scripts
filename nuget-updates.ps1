function Package ($id, $version) {
    $this = "" | Select Id, Version, FullName
    $this.Id = $id
    $this.Version = $version
    $this.FullName = "$id.$version"
    return $this
}

function GetVersion ($versionString) {
    $this = "" | Select Major, Minor, Revision, Build
    $parts = $versionString.Split('.')
    $this.Major = $parts[0]
    $this.Minor = $parts[1]
    $this.Revision = $parts[2]
    $this.Build =  $parts[3]
    return $this
}

function GetVersionDiff ($v1, $v2) {
    $this = "" | Select Major, Minor, Revision, Build
    if ($v1.Major -ne $v2.Major) {
        $this.Major = $v2.Major - $v1.Major
        return $this
    }
    $this.Major = 0
    if ($v1.Minor -ne $v2.Minor) {
        $this.Minor = $v2.Minor - $v1.Minor
        return $this
    }
    $this.Minor = 0
    if ($v1.Revision -ne $v2.Revision) {
        $this.Revision = $v2.Revision - $v1.Revision
        return $this
    }
    $this.Revision = 0
    if ($v1.Build -ne $v2.Build) {
        $this.Build = $v2.Build - $v1.Build
        return $this
    }
    $this.Build = 0
    return $this
}

function PackageVersionComparison ($id, $currentVersion, $availableVersion) {
    $this = "" | Select Id, CurrentVersion, AvailableVersion, VersionDiff, VersionDiffNumber
    $this.Id = $id
    $this.CurrentVersion = $currentVersion
    $this.AvailableVersion = $availableVersion
    $this.VersionDiff = GetVersionDiff (GetVersion $currentVersion) (GetVersion $availableVersion)
    $this.VersionDiffNumber = 
        1000000000 * $this.VersionDiff.Major + 
        1000000 * $this.VersionDiff.Minor + 
        1000 * $this.VersionDiff.Revision + 
        $this.VersionDiff.Build
    return $this
}

function GetAvailableVersions ($id) {
    $url = "http://nuget.org/api/v2/package-versions/$id"
    $webClient = New-Object System.Net.WebClient
    [string]$json = $webClient.DownloadString($url)
    return $json | ConvertFrom-JSON
}

cls
Write-Host "Getting current packages" -nonewline
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
Write-Host "Out-dated packages:"
$outdated | Sort-Object VersionDiffNumber, CurrentVersion -descending | Select Id, CurrentVersion, AvailableVersion

Write-Host ""
Write-Host "Up-to-date packages:"
Write-Host ""
$uptodate

Write-Host ""
Write-Host "No version info found:"
Write-Host ""
$noinfo