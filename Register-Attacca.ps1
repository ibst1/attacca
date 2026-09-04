# Registers Attacca for the current user (HKCU only, no admin rights needed).
#
#   .\Register-Attacca.ps1              -> right-click "Open in Obsidian" + Send to + make Attacca the default for .md
#   .\Register-Attacca.ps1 -NoDefault   -> same, but leave the double-click default for .md untouched
#
# Undo with .\Unregister-Attacca.ps1

param([switch]$NoDefault)

$ErrorActionPreference = "Stop"
$ScriptPath = Join-Path $PSScriptRoot "Attacca.ps1"
$Obsidian   = Join-Path $env:LOCALAPPDATA "Programs\Obsidian\Obsidian.exe"
$ProgId     = "Attacca.Markdown"
$Command    = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`" `"%1`""
$Classes    = "HKCU:\Software\Classes"

function Set-Key([string]$Path, [string]$Default) {
    # New-Item -Force would wipe an existing key's values, so only create when missing
    if (-not (Test-Path $Path)) { $null = New-Item -Path $Path -Force }
    if ($null -ne $Default) { Set-ItemProperty -Path $Path -Name "(default)" -Value $Default }
}

# 1. ProgId with icon and open command
Set-Key "$Classes\$ProgId" "Markdown file (Obsidian)"
Set-Key "$Classes\$ProgId\DefaultIcon" "$Obsidian,0"
Set-Key "$Classes\$ProgId\shell\open" "Open in Obsidian"
Set-ItemProperty "$Classes\$ProgId\shell\open" -Name "Icon" -Value "$Obsidian,0"
Set-ItemProperty "$Classes\$ProgId\shell\open" -Name "FriendlyAppName" -Value "Attacca (Obsidian, right vault)"
Set-Key "$Classes\$ProgId\shell\open\command" $Command

# 2. Associate .md with the ProgId (visible in "Open with", and default unless -NoDefault)
Set-Key "$Classes\.md" $(if ($NoDefault) { $null } else { $ProgId })
Set-Key "$Classes\.md\OpenWithProgids" $null
Set-ItemProperty "$Classes\.md\OpenWithProgids" -Name $ProgId -Value ([byte[]]@()) -Type None

# 3. Right-click entry "Open in Obsidian" on every .md, regardless of default program
Set-Key "$Classes\SystemFileAssociations\.md\shell\Attacca" "Open in Obsidian"
Set-ItemProperty "$Classes\SystemFileAssociations\.md\shell\Attacca" -Name "Icon" -Value "$Obsidian,0"
Set-Key "$Classes\SystemFileAssociations\.md\shell\Attacca\command" $Command

# 4. If the user picked the app "Obsidian" as default in Windows (Applications\Obsidian.exe),
#    Windows runs Obsidian.exe "%1", which Obsidian ignores. Redirect that entry to Attacca.
#    The original command is saved so Unregister can restore it.
$AppKey = "$Classes\Applications\Obsidian.exe\shell\open\command"
if (Test-Path $AppKey) {
    $orig = (Get-ItemProperty $AppKey)."(default)"
    if ($orig -and $orig -notlike "*Attacca.ps1*") {
        Set-ItemProperty "$Classes\$ProgId" -Name "OriginalObsidianAppCommand" -Value $orig
    }
    Set-ItemProperty $AppKey -Name "(default)" -Value $Command
}

# 5. Send to shortcut (works for any file type, several files at once)
$SendTo = Join-Path ([Environment]::GetFolderPath("SendTo")) "Obsidian.lnk"
$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($SendTo)
$lnk.TargetPath   = "powershell.exe"
$lnk.Arguments    = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
$lnk.IconLocation = "$Obsidian,0"
$lnk.Description  = "Open in the right Obsidian vault"
$lnk.Save()

# Ask Explorer to reload file associations
Add-Type -Namespace Win32 -Name Shell -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int eventId, int flags, IntPtr i1, IntPtr i2);'
[Win32.Shell]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)

Write-Host "Attacca registered."
Write-Host "  Right-click .md  -> Open in Obsidian"
Write-Host "  Send to          -> Obsidian"
if (-not $NoDefault) {
    $uc = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.md\UserChoice" -ErrorAction SilentlyContinue).ProgId
    if ($uc -eq "Applications\Obsidian.exe") {
        Write-Host "  Double-click .md -> Obsidian (the Windows entry 'Obsidian' is redirected through Attacca)"
    } elseif ($uc -and $uc -ne $ProgId) {
        Write-Host "  Double-click .md -> governed by an earlier choice ($uc), which Windows protects from scripts."
        Write-Host "     Change it manually: right-click a .md -> Open with -> Choose another app -> 'Obsidian' or 'Attacca' -> Always."
    } else {
        Write-Host "  Double-click .md -> Obsidian"
    }
}
