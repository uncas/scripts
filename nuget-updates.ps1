function Package ($id, $version) {
    $this = "" | Select Id, Version, FullName
    $this.Id = $id
    $this.Version = $version
    $this.FullName = "$id.$version"
    return $this
}

function GetVersion ([string]$versionString) {
    $this = "" | Select Major, Minor, Revision, Build, VersionString
    $parts = $versionString.Split('.')
    $this.Major = [int]$parts[0]
    $this.Minor = [int]$parts[1]
    $this.Revision = [int]$parts[2]
    $this.Build = [int]$parts[3]
    $this.VersionString = $versionString
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
    $unsorted = ($json | ConvertFrom-JSON)
    $sorted = @()
    foreach ($item in $unsorted) {
        $sorted += (GetVersion ([string]$item))
    }
    return $sorted | Sort-Object Major, Minor, Revision, Build | Select -ExpandProperty VersionString
}

# To exclude packages/versions from being suggested,
# put a file named 'nuget-rules.xml' in the root of your project.
# See example in current directory/nuget-rules.xml.
$rulesFile = "nuget-rules.xml"
if (Test-Path $rulesFile) {
    [xml]$rules = (Get-Content $rulesFile)
    $badVersions = $rules.rules.badVersions.package
}

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

function GetNewestGoodVersion($id, $versions) {
    $index = $versions.count - 1
    while ($index -ge 0) {
        $candidate = $versions[$index]
        $badVersion = $badVersions | Where-Object { ($_.id -eq $id) -and ($_.version -eq $candidate) }
        if (!$badVersion) {
            return $candidate
        }
        $index--;
    }
    
    return ""
}

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
    $newestVersion = GetNewestGoodVersion $id $versions
    $comparison = PackageVersionComparison $id $version $newestVersion
    if ($version -ne $newestVersion) {
        $outdated += $comparison
    }
    else {
        $uptodate += $comparison
    }
    Write-Host "." -nonewline
}

if ($outdated) {
    ""
    ""
    "Out-dated packages:"
    $outdated | Sort-Object VersionDiffNumber, CurrentVersion -descending | Select Id, CurrentVersion, AvailableVersion
}

if ($uptodate) {
    ""
    "Up-to-date packages:"
    ""
    $uptodate
}

if ($noinfo) {
    ""
    "No version info found:"
    ""
    $noinfo
}