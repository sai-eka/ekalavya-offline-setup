# Cross-platform GitHub Container Registry login helper for Windows PowerShell
# Auto-elevate to Administrator if not already running as admin

# --- Auto-Elevation Section ---
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Requesting administrative privileges..."
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Load .env variables
$envPath = ".env"
if (-Not (Test-Path $envPath)) {
    Write-Host ".env file not found!"
    exit 1
}

# Read and set environment variables
Get-Content $envPath | ForEach-Object {
    if ($_ -match '^\s*#') { return }  # skip comments
    if ($_ -match '^\s*$') { return }  # skip empty lines
    $parts = $_ -split '=', 2
    if ($parts.Length -eq 2) {
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        [Environment]::SetEnvironmentVariable($key, $value)
    }
}

# Verify required variables
if (-not $env:GITHUB_USERNAME -or -not $env:GITHUB_PAT) {
    Write-Host "GITHUB_USERNAME or GITHUB_PAT is missing in .env"
    exit 1
}

# Login to ghcr.io
$env:GITHUB_PAT | docker login ghcr.io -u $env:GITHUB_USERNAME --password-stdin

# Add hosts entry
$hostEntry = "127.0.0.1 ekalavya-files-service"
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"

$existing = Get-Content $hostsFile -ErrorAction SilentlyContinue
if ($existing -match [regex]::Escape($hostEntry)) {
    Write-Host "Hosts entry already exists."
} else {
    Write-Host "Adding hosts entry: $hostEntry"
    # Needs admin privileges
    if (-not ([bool](net session 2>$null))) {
        Write-Host "Please run PowerShell as Administrator."
        exit 1
    }
    Add-Content -Path $hostsFile -Value $hostEntry
}

Write-Host "Done!"
