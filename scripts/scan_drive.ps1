param(
[Parameter(Mandatory = $false)]
[string]$Path = "C:",

```
[Parameter(Mandatory = $false)]
[int]$Top = 50
```

)

function Convert-ToGB {
param(
[Nullable[double]]$Bytes
)

```
if ($null -eq $Bytes) {
    return 0
}

return [math]::Round($Bytes / 1GB, 2)
```

}

function Get-ItemSize {
param(
[Parameter(Mandatory = $true)]
[System.IO.FileSystemInfo]$Item
)

```
if (-not $Item.PSIsContainer) {
    return $Item.Length
}

$sum = (
    Get-ChildItem -LiteralPath $Item.FullName -Recurse -Force -File -ErrorAction SilentlyContinue |
    Measure-Object Length -Sum
).Sum

if ($null -eq $sum) {
    return 0
}

return $sum
```

}

if (-not (Test-Path -LiteralPath $Path)) {
Write-Error "Path not found: $Path"
exit 1
}

Write-Host "Scanning: $Path"
Write-Host "This may take some time..."
Write-Host ""

Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue |
ForEach-Object {
$size = Get-ItemSize -Item $_

```
[PSCustomObject]@{
    Name = $_.FullName
    GB   = Convert-ToGB -Bytes $size
}
```

} |
Sort-Object GB -Descending |
Select-Object -First $Top |
Format-Table -AutoSize
