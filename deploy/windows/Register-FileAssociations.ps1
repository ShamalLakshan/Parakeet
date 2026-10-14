<#
.SYNOPSIS
    Registers or unregisters Parakeet audio file type associations in Windows.
.DESCRIPTION
    Associates supported audio and playlist file extensions with Parakeet in HKCU:\Software\Classes,
    adding Explorer context menu verbs for "Play with Parakeet" and "Enqueue in Parakeet".
.PARAMETER ExePath
    Path to Parakeet.exe. Defaults to the executable in the current directory or build folder.
.PARAMETER Unregister
    If specified, removes all file associations and context menu verbs.
#>

param(
    [string]$ExePath = "",
    [switch]$Unregister
)

$ErrorActionPreference = "Stop"

$SupportedExtensions = @(
    ".flac", ".wav", ".aiff", ".aif", ".mp3", ".m4a", ".alac", ".mp4",
    ".m4b", ".aac", ".ogg", ".oga", ".opus", ".spx", ".dsf", ".dff",
    ".ape", ".wv", ".wma", ".cue", ".m3u", ".m3u8", ".pls"
)

$ProgId = "Parakeet.AudioFile"
$RootKey = "HKCU:\Software\Classes"

if ($Unregister) {
    Write-Host "Unregistering Parakeet file associations..." -ForegroundColor Yellow

    # Remove ProgID
    if (Test-Path "$RootKey\$ProgId") {
        Remove-Item -Recurse -Force "$RootKey\$ProgId"
    }

    # Clean up extension mappings
    foreach ($ext in $SupportedExtensions) {
        $extPath = "$RootKey\$ext\OpenWithProgids"
        if (Test-Path $extPath) {
            Remove-ItemProperty -Path $extPath -Name $ProgId -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Parakeet file associations unregistered successfully." -ForegroundColor Green
    return
}

# Find Parakeet.exe
if (-not $ExePath) {
    $candidates = @(
        "$PSScriptRoot\Parakeet.exe",
        "$PSScriptRoot\..\..\build\app\Release\Parakeet.exe",
        "$PSScriptRoot\..\..\build\app\Parakeet.exe",
        "$PSScriptRoot\..\..\build\bin\Parakeet.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $ExePath = (Resolve-Path $c).Path
            break
        }
    }
}

if (-not $ExePath -or -not (Test-Path $ExePath)) {
    Write-Error "Parakeet.exe not found. Please provide -ExePath pointing to Parakeet.exe"
}

Write-Host "Registering Parakeet file associations for $ExePath..." -ForegroundColor Cyan

# 1. Create ProgID with shell verbs
New-Item -Path "$RootKey\$ProgId" -Force | Out-Null
Set-ItemProperty -Path "$RootKey\$ProgId" -Name "(default)" -Value "Audio Track"
Set-ItemProperty -Path "$RootKey\$ProgId" -Name "FriendlyTypeName" -Value "Parakeet Audio Track"

# Default icon
New-Item -Path "$RootKey\$ProgId\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "$RootKey\$ProgId\DefaultIcon" -Name "(default)" -Value "`"$ExePath`",0"

# Open Verb: "Play with Parakeet"
New-Item -Path "$RootKey\$ProgId\shell\open" -Force | Out-Null
Set-ItemProperty -Path "$RootKey\$ProgId\shell\open" -Name "(default)" -Value "&Play with Parakeet"
New-Item -Path "$RootKey\$ProgId\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$RootKey\$ProgId\shell\open\command" -Name "(default)" -Value "`"$ExePath`" `"%1`""

# Enqueue Verb: "Enqueue in Parakeet"
New-Item -Path "$RootKey\$ProgId\shell\enqueue" -Force | Out-Null
Set-ItemProperty -Path "$RootKey\$ProgId\shell\enqueue" -Name "(default)" -Value "&Enqueue in Parakeet"
New-Item -Path "$RootKey\$ProgId\shell\enqueue\command" -Force | Out-Null
Set-ItemProperty -Path "$RootKey\$ProgId\shell\enqueue\command" -Name "(default)" -Value "`"$ExePath`" --enqueue `"%1`""

# 2. Register OpenWithProgids for each extension
foreach ($ext in $SupportedExtensions) {
    $extKey = "$RootKey\$ext"
    New-Item -Path $extKey -Force | Out-Null
    $openWithKey = "$extKey\OpenWithProgids"
    New-Item -Path $openWithKey -Force | Out-Null
    New-ItemProperty -Path $openWithKey -Name $ProgId -PropertyType Binary -Force | Out-Null
}

Write-Host "Successfully registered Parakeet file associations!" -ForegroundColor Green
