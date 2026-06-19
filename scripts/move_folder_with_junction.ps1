param(
[Parameter(Mandatory = $true)]
[string]$Source,

```
[Parameter(Mandatory = $true)]
[string]$Target,

[Parameter(Mandatory = $false)]
[string]$BackupSuffix = $(Get-Date -Format "yyyyMMdd_HHmmss")
```

)

function Count-Files {
param(
[Parameter(Mandatory = $true)]
[string]$Path
)

```
if (-not (Test-Path -LiteralPath $Path)) {
    return -1
}

return (
    Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
    Measure-Object
).Count
```

}

function Assert-PathIsNotDriveRoot {
param(
[Parameter(Mandatory = $true)]
[string]$Path,

```
    [Parameter(Mandatory = $true)]
    [string]$Label
)

$fullPath = [System.IO.Path]::GetFullPath($Path)
$rootPath = [System.IO.Path]::GetPathRoot($fullPath)

if ($fullPath.TrimEnd('\') -eq $rootPath.TrimEnd('\')) {
    Write-Error "$Label must not be a drive root: $Path"
    exit 1
}
```

}

function Assert-UnsafeSystemPath {
param(
[Parameter(Mandatory = $true)]
[string]$Path
)

```
$normalized = [System.IO.Path]::GetFullPath($Path).TrimEnd('\').ToLowerInvariant()

$blocked = @(
    "c:\windows",
    "c:\program files",
    "c:\program files (x86)",
    "c:\programdata"
)

foreach ($blockedPath in $blocked) {
    if ($normalized -eq $blockedPath) {
        Write-Error "Refusing to move unsafe system path: $Path"
        exit 1
    }
}

if ($normalized -match "\\users\\[^\\]+\\appdata$") {
    Write-Error "Refusing to move AppData as a whole: $Path"
    exit 1
}

if ($normalized -match "\\users\\[^\\]+\\appdata\\local$") {
    Write-Error "Refusing to move AppData\Local as a whole: $Path"
    exit 1
}

if ($normalized -match "\\users\\[^\\]+\\appdata\\roaming$") {
    Write-Error "Refusing to move AppData\Roaming as a whole: $Path"
    exit 1
}
```

}

Write-Host "=== Safe Folder Relocation with Junction ==="
Write-Host ""
Write-Host "Source: $Source"
Write-Host "Target: $Target"
Write-Host ""

Assert-PathIsNotDriveRoot -Path $Source -Label "Source"
Assert-PathIsNotDriveRoot -Path $Target -Label "Target"
Assert-UnsafeSystemPath -Path $Source

if (-not (Test-Path -LiteralPath $Source)) {
Write-Error "Source folder not found: $Source"
exit 1
}

$sourceItem = Get-Item -LiteralPath $Source -Force

if (-not $sourceItem.PSIsContainer) {
Write-Error "Source must be a folder: $Source"
exit 1
}

if ($sourceItem.LinkType) {
Write-Error "Source appears to be a link or junction already: $Source"
exit 1
}

if (Test-Path -LiteralPath $Target) {
$targetItem = Get-Item -LiteralPath $Target -Force

```
if (-not $targetItem.PSIsContainer) {
    Write-Error "Target exists but is not a folder: $Target"
    exit 1
}

Write-Host "[Notice] Target already exists."
Write-Host "robocopy will update missing or different files."
```

} else {
$targetParent = Split-Path -Parent $Target

```
if (-not (Test-Path -LiteralPath $targetParent)) {
    Write-Host "Creating target parent folder: $targetParent"
    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
}
```

}

Write-Host ""
Write-Host "Important:"
Write-Host "- Close applications that may use the source folder."
Write-Host "- This script does not delete the original data."
Write-Host "- The original folder will be renamed as a backup."
Write-Host "- Delete the backup later only after confirming the application works."
Write-Host ""

$answer = Read-Host "Type YES to continue"
if ($answer -ne "YES") {
Write-Host "Cancelled."
exit 0
}

Write-Host ""
Write-Host "[1/5] Copying with robocopy..."

robocopy $Source $Target /E /COPY:DAT /DCOPY:DAT /R:2 /W:2
$robocopyExitCode = $LASTEXITCODE

if ($robocopyExitCode -gt 7) {
Write-Error "robocopy failed. Exit code: $robocopyExitCode"
exit 1
}

Write-Host ""
Write-Host "[2/5] Verifying file counts..."

$sourceCount = Count-Files -Path $Source
$targetCount = Count-Files -Path $Target

Write-Host "Source file count: $sourceCount"
Write-Host "Target file count: $targetCount"

if ($sourceCount -ne $targetCount) {
Write-Error "File counts do not match. Stop here and inspect manually."
exit 1
}

Write-Host ""
Write-Host "[3/5] Renaming original folder as backup..."

$sourceParent = Split-Path -Parent $Source
$sourceLeaf = Split-Path -Leaf $Source
$backupLeaf = "${sourceLeaf}*backup*${BackupSuffix}"
$backupPath = Join-Path $sourceParent $backupLeaf

if (Test-Path -LiteralPath $backupPath) {
Write-Error "Backup path already exists: $backupPath"
exit 1
}

Rename-Item -LiteralPath $Source -NewName $backupLeaf

Write-Host "Backup created:"
Write-Host $backupPath

Write-Host ""
Write-Host "[4/5] Creating junction..."

try {
New-Item -ItemType Junction -Path $Source -Target $Target -ErrorAction Stop | Out-Null
} catch {
Write-Error "Failed to create junction: $($_.Exception.Message)"
Write-Host ""
Write-Host "Manual rollback may be needed:"
Write-Host "1. Ensure this path does not exist: $Source"
Write-Host "2. Rename backup back to original:"
Write-Host "   $backupPath"
exit 1
}

Write-Host ""
Write-Host "[5/5] Verifying junction..."

$linkCount = Count-Files -Path $Source
$targetCountAfter = Count-Files -Path $Target

Write-Host "Source path via junction file count: $linkCount"
Write-Host "Target file count: $targetCountAfter"

if ($linkCount -ne $targetCountAfter) {
Write-Error "Junction verification failed. Manual inspection required."
exit 1
}

Write-Host ""
Write-Host "Completed successfully."
Write-Host ""
Write-Host "Original data is still kept as backup:"
Write-Host $backupPath
Write-Host ""
Write-Host "Do not delete the backup immediately."
Write-Host "Test the application first, then delete the backup later if everything works."
