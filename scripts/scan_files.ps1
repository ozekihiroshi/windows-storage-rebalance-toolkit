param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [int]$Top = 50,

    [Parameter(Mandatory = $false)]
    [int]$MinimumSizeMB = 100
)

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "Path not found: $Path"
    exit 1
}

if ($Top -lt 1) {
    Write-Error "Top must be at least 1."
    exit 1
}

if ($MinimumSizeMB -lt 0) {
    Write-Error "MinimumSizeMB must be 0 or greater."
    exit 1
}

$minimumBytes = $MinimumSizeMB * 1MB

Write-Host "Scanning files under: $Path"
Write-Host "Minimum file size: $MinimumSizeMB MB"
Write-Host ""

Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
Where-Object { $_.Length -ge $minimumBytes } |
Sort-Object Length -Descending |
Select-Object -First $Top @{
    Name = "SizeGB"
    Expression = { [math]::Round($_.Length / 1GB, 2) }
}, @{
    Name = "SizeMB"
    Expression = { [math]::Round($_.Length / 1MB, 1) }
}, LastWriteTime, FullName |
Format-Table -AutoSize