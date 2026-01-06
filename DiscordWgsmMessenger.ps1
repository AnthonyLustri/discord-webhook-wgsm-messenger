# PowerShell script to send multiple messages to a Discord channel using a Webhook
# Designed to be run manually or via Windows Task Scheduler

# --- Console Window Configuration ---

# Set the title of the PowerShell console window
$Host.UI.RawUI.WindowTitle = "Discord Webhook Messenger"

# Attempt to bring the PowerShell window to the foreground and restore it if minimized.
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WindowManager {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    public const int SW_RESTORE = 9;
}
"@

$consoleHandle = [WindowManager]::GetConsoleWindow()
[void][WindowManager]::ShowWindow($consoleHandle, [WindowManager]::SW_RESTORE)
[void][WindowManager]::SetForegroundWindow($consoleHandle)

# --- Configuration ---

# IMPORTANT: Replace with your actual Discord webhook URL
$webhookUrl = "YOUR_WEBHOOK_URL_HERE"

# Bot/webhook display name
$webhookUsername = "BOTNAMEHERE"

# Optional avatar URL (leave blank to avoid image links)
$avatarImageUrl = ""

# --- Headers for the HTTP Request ---
$headers = @{
    "Content-Type" = "application/json"
}

# --- Messages for "wgsm stop" series (5-second delay) ---
$stopMessages = @(
    "wgsm stop 1","wgsm stop 2","wgsm stop 3","wgsm stop 4","wgsm stop 5",
    "wgsm stop 6","wgsm stop 7","wgsm stop 8","wgsm stop 9","wgsm stop 10","wgsm stop 11"
)

# --- Messages for "wgsm update" series (30-second delay) ---
$updateMessages = @(
    "wgsm update 1","wgsm update 2","wgsm update 3","wgsm update 4","wgsm update 5",
    "wgsm update 6","wgsm update 7","wgsm update 8","wgsm update 9","wgsm update 10","wgsm update 11"
)

# --- Messages for "wgsm start" series (5-second delay) ---
$startMessages = @(
    "wgsm start 1","wgsm start 2","wgsm start 3","wgsm start 4","wgsm start 5",
    "wgsm start 6","wgsm start 7","wgsm start 8","wgsm start 9","wgsm start 10","wgsm start 11"
)

function Send-WebhookMessages {
    param (
        [string]$WebhookUrl,
        [string]$WebhookUsername,
        [string]$AvatarImageUrl,
        [array]$Messages,
        [int]$DelaySeconds,
        [int]$MaxRetries = 5,
        [int]$RetryDelaySeconds = 10
    )

    Write-Host "Attempting to send $($Messages.Count) messages with a $($DelaySeconds)-second delay."
    $successfulSends = 0
    $failedSends = 0

    foreach ($messageContent in $Messages) {
        Write-Host "Preparing to send: '$messageContent'"
        $attempt = 0
        $sentSuccessfully = $false

        while ($attempt -lt $MaxRetries -and -not $sentSuccessfully) {
            $attempt++
            Write-Host "Attempt $attempt/$MaxRetries for: '$messageContent'"

            # Build JSON body
            $payload = @{
                content  = $messageContent
                username = $WebhookUsername
            }

            # Only include avatar_url if one is provided
            if (-not [string]::IsNullOrWhiteSpace($AvatarImageUrl)) {
                $payload.avatar_url = $AvatarImageUrl
            }

            $body = $payload | ConvertTo-Json

            try {
                Invoke-RestMethod -Method Post -Uri $WebhookUrl -Headers $headers -Body $body -ErrorAction Stop | Out-Null
                Write-Host "Sent successfully."
                $successfulSends++
                $sentSuccessfully = $true
            }
            catch {
                Write-Error "Send failed (Attempt $attempt): $($_.Exception.Message)"

                if ($_.Exception.Response) {
                    $errorResponse = $_.Exception.Response.GetResponseStream()
                    $reader = New-Object System.IO.StreamReader($errorResponse)
                    $responseContent = $reader.ReadToEnd()
                    Write-Error "Discord API response: $responseContent"
                }

                if ($attempt -lt $MaxRetries) {
                    Write-Host "Retrying in $RetryDelaySeconds seconds..."
                    Start-Sleep -Seconds $RetryDelaySeconds
                }
                else {
                    Write-Error "Max retries reached. Skipping: '$messageContent'"
                    $failedSends++
                }
            }
        }

        Write-Host "Waiting $DelaySeconds seconds..."
        Start-Sleep -Seconds $DelaySeconds
    }

    Write-Host "--- Series Complete ---"
    Write-Host "Attempted: $($Messages.Count) | Sent: $successfulSends | Failed: $failedSends"
    Write-Host "------------------------`n"
}

# --- Main Script Execution ---
try {
    Write-Host "Starting Discord webhook message routine..."

    Write-Host "--- 'wgsm stop' series ---"
    Send-WebhookMessages -WebhookUrl $webhookUrl `
                         -WebhookUsername $webhookUsername `
                         -AvatarImageUrl $avatarImageUrl `
                         -Messages $stopMessages `
                         -DelaySeconds 5

    Write-Host "--- 'wgsm update' series ---"
    Send-WebhookMessages -WebhookUrl $webhookUrl `
                         -WebhookUsername $webhookUsername `
                         -AvatarImageUrl $avatarImageUrl `
                         -Messages $updateMessages `
                         -DelaySeconds 30

    # Wait 5 minutes before sending the first start message (with countdown)
    $delayMinutes = 5
    $delaySecondsTotal = $delayMinutes * 60
    Write-Host "Waiting $delayMinutes minutes before sending 'wgsm start 1'..."

    for ($i = $delaySecondsTotal; $i -ge 0; $i--) {
        $minutes = [Math]::Floor($i / 60)
        $seconds = $i % 60
        Write-Host "`rTime remaining: $($minutes.ToString("00")):$($seconds.ToString("00"))" -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host ""

    # Send first start message (single)
    $firstStartMessage = "wgsm start 1"
    Send-WebhookMessages -WebhookUrl $webhookUrl `
                         -WebhookUsername $webhookUsername `
                         -AvatarImageUrl $avatarImageUrl `
                         -Messages @($firstStartMessage) `
                         -DelaySeconds 0

    # Send remaining start messages (skip the first)
    $remainingStartMessages = $startMessages | Select-Object -Skip 1
    if ($remainingStartMessages.Count -gt 0) {
        Write-Host "--- Remaining 'wgsm start' messages ---"
        Send-WebhookMessages -WebhookUrl $webhookUrl `
                             -WebhookUsername $webhookUsername `
                             -AvatarImageUrl $avatarImageUrl `
                             -Messages $remainingStartMessages `
                             -DelaySeconds 5
    }

    Write-Host "All message series complete."
}
catch {
    Write-Error "Critical error: $($_.Exception.Message)"
    Write-Error "Stack Trace: $($_.ScriptStackTrace)"
}
finally {
    Write-Host "Script execution finished."
    exit
}
