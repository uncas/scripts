param($projectName = "DBA", $databaseName = "NugetPackages")

cls

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

function Download ($url) {
    $webClient = New-Object System.Net.WebClient
    return $webClient.DownloadString($url)
}

function DownloadAndConvertFromJson ($url) {
    [string]$json = Download($url)
    return $json | ConvertFrom-JSON
}

function GetAvailableVersions ($id) {
    $url = "http://nuget.org/api/v2/package-versions/$id"
    return DownloadAndConvertFromJson $url
}

function SqlNonQuery($sql, $db = $databaseName, $connectionString = "Server=.\SqlExpress;Database=$db;Integrated Security=true;"){
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString);
    $command = new-object system.data.sqlclient.sqlcommand($sql, $connection);
    $connection.Open();
    $rowsAffected = $command.ExecuteNonQuery()
    $connection.Close();
}

function SqlQuery($sql, $db = $databaseName, $connectionString = "Server=.\SqlExpress;Database=$db;Integrated Security=true;") {
    $ds = new-object "System.Data.DataSet"
    $da = new-object "System.Data.SqlClient.SqlDataAdapter" ($sql, $connectionString)
    $record_count = $da.Fill($ds)
    return $ds
}

function SqlAddPackage($packageName, $version) {
    $sql = "IF NOT EXISTS (SELECT 0 FROM NugetPackage WHERE Name = '$packageName') INSERT INTO NugetPackage (Name) VALUES ('$packageName')"
    SqlNonQuery $sql
    
    $sql = "IF NOT EXISTS (SELECT 0 FROM NugetPackageVersion WHERE PackageName = '$packageName' AND Version = '$version')
    INSERT INTO NugetPackageVersion (PackageName, Version) VALUES ('$packageName', '$version')"
    SqlNonQuery $sql
    
    $sql = "IF EXISTS
    (
        SELECT 0 FROM ProjectNugetPackage
        WHERE ProjectName = '$projectName' AND PackageName = '$packageName' AND PackageVersion = '$version'
    )
    UPDATE ProjectNugetPackage SET IncludedInLastCheck = 1
    WHERE ProjectName = '$projectName' AND PackageName = '$packageName' AND PackageVersion = '$version'
    ELSE INSERT INTO ProjectNugetPackage
    (ProjectName, PackageName, PackageVersion, IncludedInLastCheck)
    VALUES ('$projectName', '$packageName', '$version', 1)"
    SqlNonQuery $sql
}

function CreateDatabaseAndTables {
    SqlNonQuery "IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '$databaseName') CREATE DATABASE $databaseName" "master"
    
    SqlNonQuery "IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NugetPackage')
    CREATE TABLE NugetPackage
    (
        Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_NugetPackage PRIMARY KEY CLUSTERED
        , RecordCreated datetime NOT NULL CONSTRAINT DF_NugetPackage_RecordCreated DEFAULT GETDATE()
        , Name nvarchar(100) NOT NULL CONSTRAINT UK_NugetPackage_Name UNIQUE
        , LastChecked datetime NULL
    )"
    
    SqlNonQuery "IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NugetPackageVersion')
    CREATE TABLE NugetPackageVersion
    (
        Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_NugetPackageVersion PRIMARY KEY CLUSTERED
        , RecordCreated datetime NOT NULL CONSTRAINT DF_NugetPackageVersion_RecordCreated DEFAULT GETDATE()
        , PackageName nvarchar(100) NOT NULL
        , Version nvarchar(50) NOT NULL
        , CONSTRAINT UK_NugetPackageVersion_PackageNameVersion UNIQUE (PackageName, Version)
        , VersionDate datetime NULL
    )"
    
    SqlNonQuery "IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ProjectNugetPackage')
    CREATE TABLE ProjectNugetPackage
    (
        Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ProjectNugetPackage PRIMARY KEY CLUSTERED
        , RecordCreated datetime NOT NULL CONSTRAINT DF_ProjectNugetPackage_RecordCreated DEFAULT GETDATE()
        , ProjectName nvarchar(50) NOT NULL
        , PackageName nvarchar(100) NOT NULL
        , PackageVersion nvarchar(50) NOT NULL
        , CONSTRAINT UK_ProjectNugetPackage_ProjectNamePackageNameVersion UNIQUE (ProjectName, PackageName, PackageVersion)
        , IncludedInLastCheck bit NOT NULL CONSTRAINT DF_ProjectNugetPackage_IncludedInLastCheck DEFAULT 1
    )"
}

function ClearChecksForProject {
    SqlNonQuery "UPDATE ProjectNugetPackage SET IncludedInLastCheck = 0 WHERE ProjectName = '$projectName'"
}

function DownloadDateForVersion($packageName, $version) {
    $url = "http://www.nuget.org/api/v2/Packages()?`$filter=Id eq '$packageName' and Version eq '$version'&`$select=Id,Version,Created"
    [xml]$result = Download $url
    $items = $result.feed.entry
    foreach ($item in $items) {
        return $item.properties.created.innerxml
    }
}

function UpdatePackageVersionCreated {
    $packageVersionsWithoutDate = SqlQuery "SELECT PackageName, Version FROM NugetPackageVersion WHERE VersionDate IS NULL"
    foreach ($packageVersion in $packageVersionsWithoutDate.Tables[0].Rows) {
        $packageName = $packageVersion["PackageName"]
        $version = $packageVersion["Version"]
        $created = DownloadDateForVersion $packageName $version
        "$packageName $version $created"
        if ($created) {
            SqlNonQuery "UPDATE NugetPackageVersion SET VersionDate = '$created' WHERE PackageName = '$packageName' AND Version = '$version'"
        }
    }
}

function GetNewestVersion($packageName) {
    $url = "http://www.nuget.org/api/v2/Packages()?`$filter=Id eq '$packageName'&`$orderby=Created desc&`$select=Id,Version,Created"
    [xml]$result = Download $url
    $items = $result.feed.entry
    foreach ($item in $items) {
        $version = $item.properties.version
        if (!$version.Contains("-")) {
            return $version
        }
    }
}

function GetNewestVersions {
    $packagesToCheck = SqlQuery "SELECT Name FROM NugetPackage WHERE LastChecked IS NULL OR DATEDIFF(DAY, LastChecked, GETDATE()) > 1"
    foreach ($package in $packagesToCheck.Tables[0].Rows) {
        $packageName = $package["Name"]
        $newestVersion = GetNewestVersion $packageName
        if (!$newestVersion) { continue }
        "$packageName $newestVersion"
        SqlNonQuery "IF NOT EXISTS (SELECT 0 FROM NugetPackageVersion WHERE PackageName = '$packageName' AND Version = '$newestVersion') INSERT INTO NugetPackageVersion(PackageName, Version) VALUES ('$packageName', '$newestVersion')"
        SqlNonQuery "UPDATE NugetPackage SET LastChecked = GETDATE() WHERE Name = '$packageName'"
    }
}

CreateDatabaseAndTables
ClearChecksForProject

Write-Host "Getting current packages" -nonewline
$packageFiles = (gci -r -include packages.config)
$packages = @{}
foreach ($packageFile in $packageFiles) {
    [xml]$packagesXml = Get-Content $packageFile
    foreach ($packageXml in $packagesXml.packages.package) {
        $id = $packageXml.id
        $version = $packageXml.version
        $package = Package $id $version
        SqlAddPackage $id $version
        if (!$packages.ContainsKey($package.FullName)) {
            $packages.Add($package.FullName, $package)
        }
    }
    Write-Host "." -nonewline
}

GetNewestVersions
UpdatePackageVersionCreated

return

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

""

if ($outdated) {
    ""
    "Out-dated packages:"
    ""
    $outdated | Sort-Object VersionDiffNumber, CurrentVersion -descending | Select Id, CurrentVersion, AvailableVersion
}

if ($uptodate) {
    ""
    "Up-to-date packages:"
    ""
    $uptodate | Select Id, CurrentVersion, AvailableVersion
}

if ($noinfo) {
    ""
    "No version info found:"
    ""
    $noinfo
}