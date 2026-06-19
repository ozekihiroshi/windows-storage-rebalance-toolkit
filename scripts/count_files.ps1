param(
[Parameter(Mandatory = $true)]
[string]$Path
)

if (-not (Test-Path -LiteralPath $Path)) {
Write-Error "Path not found: $Path"
exit 1
}

$count = (
Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
Measure-Object
).Count

[PSCustomObject]@{
Path  = $Path
Files = $count
}
