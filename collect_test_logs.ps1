param(
    [string]$OutputFolder = (Join-Path $PSScriptRoot "test_logs"),
    [string]$HoiRoot
)

$ErrorActionPreference = "Stop"

if (Test-Path -LiteralPath $OutputFolder) {
    Get-ChildItem -LiteralPath $OutputFolder -Force | Remove-Item -Recurse -Force
} else {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$profileFolder = [Environment]::GetFolderPath("UserProfile")
$documentCandidates = @(
    [Environment]::GetFolderPath("MyDocuments"),
    (Join-Path $profileFolder "Documents"),
    (Join-Path $profileFolder "OneDrive\Documents"),
    (Join-Path $profileFolder "OneDrive\Documenten")
) | Select-Object -Unique

if (-not $HoiRoot) {
    foreach ($documents in $documentCandidates) {
        $candidate = Join-Path $documents "Paradox Interactive\Hearts of Iron IV"
        if (Test-Path -LiteralPath (Join-Path $candidate "logs")) {
            $HoiRoot = $candidate
            break
        }
    }
}

if (-not $HoiRoot) {
    $message = @(
        "No HOI4 log folder was found."
        "Run Hearts of Iron IV once, close it, and run collect_test_logs.bat again."
        ""
        "Locations checked:"
        ($documentCandidates | ForEach-Object { "- $(Join-Path $_ 'Paradox Interactive\Hearts of Iron IV\logs')" })
    )
    Set-Content -LiteralPath (Join-Path $OutputFolder "collection_info.txt") -Value $message
    throw "HOI4 log folder was not found. See test_logs\collection_info.txt."
}

$liveLogs = Join-Path $HoiRoot "logs"
$crashesRoot = Join-Path $HoiRoot "crashes"

$requiredLogs = @(
    "error.log",
    "game.log",
    "setup.log",
    "text.log",
    "system.log",
    "memory.log"
)

foreach ($name in $requiredLogs) {
    $source = Join-Path $liveLogs $name
    if (Test-Path -LiteralPath $source) {
        Copy-Item -LiteralPath $source -Destination (Join-Path $OutputFolder $name)
    }
}

$latestCrash = $null
if (Test-Path -LiteralPath $crashesRoot) {
    $latestCrash = Get-ChildItem -LiteralPath $crashesRoot -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

if ($latestCrash) {
    foreach ($name in @("exception.txt", "meta.yml", "minidump.dmp")) {
        $source = Join-Path $latestCrash.FullName $name
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $OutputFolder $name)
        }
    }
}

$manifest = @(
    "Collected: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss zzz'))"
    "HOI4 folder: $hoiRoot"
    "Latest crash: $(if ($latestCrash) { $latestCrash.FullName } else { 'none found' })"
    ""
    "Included files:"
)

$included = Get-ChildItem -LiteralPath $OutputFolder -File |
    Sort-Object Name |
    ForEach-Object { "- $($_.Name) ($($_.Length) bytes)" }

Set-Content -LiteralPath (Join-Path $OutputFolder "collection_info.txt") -Value ($manifest + $included)

Write-Host ""
Write-Host "Test logs collected in:"
Write-Host $OutputFolder
Write-Host ""
Write-Host "Send the entire test_logs folder for diagnosis."
