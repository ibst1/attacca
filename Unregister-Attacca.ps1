# Removes everything Register-Attacca.ps1 created (HKCU keys + Send to shortcut).

$ErrorActionPreference = "SilentlyContinue"
$Classes = "HKCU:\Software\Classes"
$ProgId  = "Attacca.Markdown"

# Restore the Windows entry "Obsidian" (Applications\Obsidian.exe) if Register redirected it
$orig = (Get-ItemProperty "$Classes\$ProgId")."OriginalObsidianAppCommand"
if (-not $orig) { $orig = '"' + (Join-Path $env:LOCALAPPDATA "Programs\Obsidian\Obsidian.exe") + '" "%1"' }
$AppKey = "$Classes\Applications\Obsidian.exe\shell\open\command"
if ((Test-Path $AppKey) -and ((Get-ItemProperty $AppKey)."(default)" -like "*Attacca.ps1*")) {
    Set-ItemProperty $AppKey -Name "(default)" -Value $orig
}

Remove-Item "$Classes\$ProgId" -Recurse -Force
Remove-Item "$Classes\SystemFileAssociations\.md\shell\Attacca" -Recurse -Force
Remove-ItemProperty "$Classes\.md\OpenWithProgids" -Name $ProgId
# Remove-ItemProperty cannot delete a key's default value; use the .NET API instead
if ((Get-ItemProperty "$Classes\.md")."(default)" -eq $ProgId) {
    $k = (Get-Item $Classes).OpenSubKey(".md", $true)
    if ($k) { $k.DeleteValue("", $false); $k.Close() }
}
# Clean up empty leftovers (a key counts as empty if it only has a blank default value)
foreach ($k in "$Classes\.md\OpenWithProgids", "$Classes\.md") {
    $i = Get-Item $k
    if (-not $i) { continue }
    $named = @($i.GetValueNames() | Where-Object { $_ -ne "" })
    $blankDefault = [string]::IsNullOrEmpty($i.GetValue(""))
    if ($i.SubKeyCount -eq 0 -and $named.Count -eq 0 -and $blankDefault) { Remove-Item $k -Force }
}
Remove-Item (Join-Path ([Environment]::GetFolderPath("SendTo")) "Obsidian.lnk") -Force

Add-Type -Namespace Win32 -Name Shell -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int eventId, int flags, IntPtr i1, IntPtr i2);'
[Win32.Shell]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
Write-Host "Attacca unregistered."
