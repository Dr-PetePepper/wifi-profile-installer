# Copy this file to a local/private configuration if you want
# to maintain your network list separately.
#
# IMPORTANT: Never commit real passwords to a public GitHub repository.

$wifiNetworks = @(
    @{
        SSID     = "Home-WiFi"
        Password = "YOUR-PASSWORD-HERE"
    },
    @{
        SSID     = "Office-WiFi"
        Password = "YOUR-PASSWORD-HERE"
    }
)
