param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)
$envFile = Join-Path $Root "shared\parameters.env"
$out = Join-Path $Root "ios\Config.xcconfig"
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("// Generated from shared/parameters.env")
$lines.Add("// Run: powershell -File scripts/sync-parameters.ps1")
$lines.Add("")
Get-Content $envFile | ForEach-Object {
  $t = $_.Trim()
  if ($t -and -not $t.StartsWith("#") -and $t.Contains("=")) {
    $i = $t.IndexOf("=")
    $k = $t.Substring(0, $i).Trim()
    $v = $t.Substring($i + 1).Trim()
    $lines.Add("$k = $v")
  }
}
$lines.Add("PRODUCT_BUNDLE_IDENTIFIER = app.lovecards.fiftytwo")
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($out, ($lines -join "`n") + "`n", $utf8)
Write-Output "Wrote $out"
