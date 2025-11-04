param([string]$Path = "truth_engine_manifesto.md")
$lines = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

# Emphasis-as-heading to ## Heading
$lines = $lines -creplace '^(?m)\s*\*{2}([^\*\r\n][^\r\n]*?)\*{2}\s*$', '## $1'
$lines = $lines -creplace '^(?m)\s*\*([^\*\r\n][^\r\n]*?)\*\s*$',     '## $1'
$lines = $lines -creplace '^(?m)\s*_{2}([^_\r\n][^\r\n]*?)_{2}\s*$', '## $1'
$lines = $lines -creplace '^(?m)\s*_([^_\r\n][^\r\n]*?)_\s*$',       '## $1'

# Dash bullets -> asterisk
$lines = $lines -creplace '^(?m)(\s*)-\s+', '$1* '

Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8
Write-Host "Markdown fixes applied to $Path"