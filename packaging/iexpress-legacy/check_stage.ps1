param([Parameter(Mandatory=$true)][string]$Stage)

$ErrorActionPreference = "SilentlyContinue"
$bs = [char]0x5C
$rootPattern = "D:" + $bs + "STUDY"
$rootPatternSlash = "D:" + "/" + "STUDY"
$bad = @()
$forbidden = @()
$textExt = @(".bat", ".cmd", ".ps1", ".json", ".txt", ".md", ".yaml", ".yml", ".ini", ".cfg", ".toml", ".xml", ".js", ".mjs", ".conf", ".properties")

Get-ChildItem -LiteralPath $Stage -Recurse -File | ForEach-Object {
    $ext = $_.Extension.ToLower()
    $isText = ($textExt -contains $ext)
    $isPluginPy = ($ext -eq ".py") -and ($_.FullName -match "astrbot_plugin_")
    if ($_.Length -lt 5MB -and ($isText -or $isPluginPy)) {
        $m = Select-String -LiteralPath $_.FullName -SimpleMatch -Pattern $rootPattern, $rootPatternSlash
        if ($m) { $bad += $_.FullName }
    }
}

$dbPath = Join-Path $Stage "runtime\astrbot\data\data_v4.db"
if (Test-Path -LiteralPath $dbPath) {
    $m = Select-String -LiteralPath $dbPath -SimpleMatch -Pattern $rootPattern, $rootPatternSlash
    if ($m) { $bad += $dbPath }
}

$forbidden += Get-ChildItem -LiteralPath $Stage -Recurse -File | Where-Object {
    $_.Name -like "*.key" -or $_.Name -like "*.pem" -or $_.Name -like "*.pfx" -or
    $_.Name -like "*.log" -or $_.Name -like "*.pyc" -or
    $_.Name -like "qrcode*.png" -or $_.Name -like "qrcode*.jpg" -or
    $_.Name -like "qrcode*.jpeg" -or $_.Name -like "qrcode*.gif" -or
    $_.Name -like "*.db-wal" -or $_.Name -like "*.db-shm"
}
$forbidden += Get-ChildItem -LiteralPath $Stage -Recurse -Directory | Where-Object {
    $_.Name -eq ".git" -or $_.Name -eq "__pycache__" -or $_.Name -eq ".venv"
}

$required = @(
    "启动.bat",
    "停止.bat",
    "runtime\python\python.exe",
    "runtime\napcat\napcat.bat",
    "runtime\astrbot\data\data_v4.db",
    "runtime\astrbot\data\cmd_config.json",
    "runtime\secrets\napcat-webui-token.txt",
    "runtime\secrets\onebot-token.txt",
    "docs\customer\README-客户.md",
    "docs\customer\客户手册-填key.md",
    "docs\customer\post-login.md",
    "docs\customer\AI教学手册-第一册-安装.md",
    "docs\customer\AI教学手册-第二册-配置.md",
    "docs\templates\onebot11-template.json",
    "docs\templates\人设-小满.md"
)
$missing = @()
foreach ($r in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $Stage $r))) { $missing += $r }
}

if ($bad.Count -gt 0) {
    "ABS_PATH_HITS=" + $bad.Count
    $bad | ForEach-Object { "  " + $_ }
}
if ($forbidden.Count -gt 0) {
    "FORBIDDEN_COUNT=" + $forbidden.Count
    $forbidden | ForEach-Object { "  " + $_.FullName }
}
if ($missing.Count -gt 0) {
    "MISSING_REQUIRED:"
    $missing | ForEach-Object { "  " + $_ }
}
if ($bad.Count -gt 0 -or $forbidden.Count -gt 0 -or $missing.Count -gt 0) {
    exit 1
}
"STAGE_CHECK_OK"
exit 0
