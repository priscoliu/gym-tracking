# Power BI Modeling MCP Server Installation Script for Claude Code
# Version: 0.2.2
# Platform: win32-x64

$ErrorActionPreference = "Stop"

# Configuration
$version = "0.2.2"
$platform = "win32-x64"
$publisher = "analysis-services"
$extensionName = "powerbi-modeling-mcp"
$installDir = "C:\MCP\powerbi-modeling-mcp"
$claudeConfigDir = "$env:USERPROFILE\.claude"

Write-Host "Power BI Modeling MCP Server Installation" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Download VSIX package
Write-Host "[1/5] Downloading VSIX package..." -ForegroundColor Yellow
$vsixUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$publisher/vsextensions/$extensionName/$version/vspackage?targetPlatform=$platform"
$vsixPath = "$env:TEMP\$extensionName-$version.vsix"

try {
    Invoke-WebRequest -Uri $vsixUrl -OutFile $vsixPath -UseBasicParsing
    Write-Host "  Downloaded to: $vsixPath" -ForegroundColor Green
} catch {
    Write-Host "  Error downloading VSIX: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create installation directory
Write-Host "[2/5] Creating installation directory..." -ForegroundColor Yellow
if (Test-Path $installDir) {
    Write-Host "  Directory already exists, removing..." -ForegroundColor Yellow
    Remove-Item -Path $installDir -Recurse -Force
}
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Write-Host "  Created: $installDir" -ForegroundColor Green

# Step 3: Extract VSIX (it's a ZIP file)
Write-Host "[3/5] Extracting VSIX package..." -ForegroundColor Yellow
$zipPath = "$env:TEMP\$extensionName-$version.zip"
Copy-Item -Path $vsixPath -Destination $zipPath -Force
Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
Write-Host "  Extracted to: $installDir" -ForegroundColor Green

# Step 4: Locate the MCP executable
Write-Host "[4/5] Locating MCP executable..." -ForegroundColor Yellow
$exePath = Get-ChildItem -Path $installDir -Filter "powerbi-modeling-mcp.exe" -Recurse | Select-Object -First 1
if ($null -eq $exePath) {
    Write-Host "  Error: Could not find powerbi-modeling-mcp.exe" -ForegroundColor Red
    exit 1
}
Write-Host "  Found executable: $($exePath.FullName)" -ForegroundColor Green

# Step 5: Configure Claude Code
Write-Host "[5/5] Configuring Claude Code..." -ForegroundColor Yellow
$settingsPath = "$claudeConfigDir\settings.json"

if (-not (Test-Path $settingsPath)) {
    Write-Host "  Error: Claude Code settings.json not found at $settingsPath" -ForegroundColor Red
    exit 1
}

# Read existing settings
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

# Add mcpServers configuration if it doesn't exist
if (-not $settings.PSObject.Properties['mcpServers']) {
    $settings | Add-Member -MemberType NoteProperty -Name 'mcpServers' -Value @{}
}

# Add Power BI MCP server configuration
$mcpConfig = @{
    command = $exePath.FullName
    args = @("--start")
    env = @{
        PBI_MODELING_MCP_CLIENT_ID = "ea0616ba-638b-4df5-95b9-636659ae5121"
    }
}

$settings.mcpServers | Add-Member -MemberType NoteProperty -Name 'powerbi-modeling' -Value $mcpConfig -Force

# Save updated settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "  Configuration added to: $settingsPath" -ForegroundColor Green

# Cleanup
Write-Host ""
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item -Path $vsixPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
Write-Host "Done!" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "Installation Summary" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host "MCP Server: Power BI Modeling MCP v$version"
Write-Host "Executable: $($exePath.FullName)"
Write-Host "Configuration: $settingsPath"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Restart Claude Code (close and reopen VS Code)"
Write-Host "2. Look for the hammer icon in the chat input area"
Write-Host "3. You can now use natural language to interact with Power BI models!"
Write-Host ""
