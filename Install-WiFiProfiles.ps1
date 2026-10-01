#requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs Windows Wi-Fi profiles and enables automatic connection.

.DESCRIPTION
    Creates temporary WLAN profile XML files and imports them with netsh.
    Profiles are configured to connect automatically when the specified
    wireless networks are available.

.NOTES
    Requires Windows 10/11 and Administrator privileges.
    WPA2-Personal (WPA2-PSK/AES) networks are supported by this version.

    SECURITY:
    Do not commit real Wi-Fi passwords to GitHub. Keep credentials in a
    local/private configuration file or supply them through a secure process.
#>

$wifiNetworks = @(
    @{
        SSID     = "SSID-NAME-HERE"
        Password = "PASSWORD-HERE"
    }
)

$tempDir = Join-Path $env:TEMP "WiFiProfiles"

function Escape-XmlValue {
    param([Parameter(Mandatory)][string]$Value)

    [System.Security.SecurityElement]::Escape($Value)
}

# Ensure the temporary directory exists.
if (-not (Test-Path -LiteralPath $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

try {
    foreach ($wifi in $wifiNetworks) {
        $ssid = [string]$wifi.SSID
        $password = [string]$wifi.Password

        if ([string]::IsNullOrWhiteSpace($ssid) -or
            [string]::IsNullOrWhiteSpace($password)) {
            Write-Warning "Skipping a network with an empty SSID or password."
            continue
        }

        $escapedSSID = Escape-XmlValue $ssid
        $escapedPassword = Escape-XmlValue $password

        $xml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$escapedSSID</name>
    <SSIDConfig>
        <SSID>
            <name>$escapedSSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$escapedPassword</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@

        # Use a filesystem-safe temporary filename while retaining the SSID
        # inside the WLAN XML profile.
        $safeName = ($ssid -replace '[^\w\-. ]', '_')
        $xmlFile = Join-Path $tempDir "$safeName.xml"

        try {
            $xml | Set-Content -LiteralPath $xmlFile -Encoding UTF8

            Write-Host "Adding Wi-Fi profile: $ssid" -ForegroundColor Cyan

            $result = & netsh wlan add profile "filename=$xmlFile" "user=all" 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Successfully added." -ForegroundColor Green
            }
            else {
                Write-Host "  Failed to add profile." -ForegroundColor Red
                Write-Host "  $result" -ForegroundColor Yellow
            }
        }
        finally {
            Remove-Item -LiteralPath $xmlFile -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host ""
    Write-Host "Wi-Fi profile installation complete." -ForegroundColor Green
    Write-Host ""
    Write-Host "Installed Wi-Fi profiles:" -ForegroundColor Cyan

    & netsh wlan show profiles
}
finally {
    Remove-Item -LiteralPath $tempDir -Force -Recurse -ErrorAction SilentlyContinue
}
