$F = "mdlint_smoke.md"
@"
**Fake Heading**

- one
- two
"@ | Set-Content $F -Encoding utf8
Start-Sleep -Milliseconds 300
$txt = Get-Content $F -Raw
if ($txt -match '^\#\# Fake Heading' -and $txt -match '^\* one' -and $txt -match '^\* two') { "PASS" } else { "FAIL"; exit 1 }
