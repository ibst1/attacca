# Attacca - open files in the right Obsidian vault straight from Windows Explorer.
#
# Usage:  powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File Attacca.ps1 "C:\...\file.md" [...more files]
#
# Obsidian picks the vault itself from the path (obsidian://open?path=...).
# Files outside every registered vault are opened in the fallback editor.

# ---------- Settings ----------
$FallbackEditor = "C:\Program Files\Notepad++\notepad++.exe"   # for .md outside the vaults; missing or "" = Notepad
$VaultRegistry  = Join-Path $env:APPDATA "Obsidian\obsidian.json"
# ------------------------------

function Get-VaultPaths {
    try {
        $json = Get-Content -LiteralPath $VaultRegistry -Raw -Encoding UTF8 | ConvertFrom-Json
        $json.vaults.PSObject.Properties | ForEach-Object { $_.Value.path.TrimEnd('\') }
    } catch { @() }
}

function Get-VaultFor([string]$Path) {
    $best = ""
    foreach ($v in (Get-VaultPaths)) {
        if ($Path.StartsWith("$v\", [System.StringComparison]::OrdinalIgnoreCase) -and $v.Length -gt $best.Length) { $best = $v }
    }
    $best
}

function Open-InObsidian([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $full)) { return }

    if (Get-VaultFor $full) {
        Start-Process ("obsidian://open?path=" + [uri]::EscapeDataString($full))
        return
    }
    # Outside every vault. Never hand a .md to the Windows default program: that
    # is Attacca itself once registered, which would start itself over and over.
    # The same goes for any file when Attacca is already the one that launched
    # this run (the marker below is inherited by child processes).
    if ($full -match '\.md$' -or $env:ATTACCA_RUNNING) {
        $editor = if ($FallbackEditor -and (Test-Path -LiteralPath $FallbackEditor)) { $FallbackEditor } else { "notepad.exe" }
        Start-Process -FilePath $editor -ArgumentList ('"' + $full + '"')
    } else {
        $env:ATTACCA_RUNNING = "1"
        Start-Process -FilePath $full
    }
}

foreach ($p in $args) { Open-InObsidian $p }
