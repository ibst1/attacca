# Attacca

Opens `.md` files (and other files) from Windows Explorer in the **right Obsidian vault**.
Obsidian picks the vault itself from the file path via `obsidian://open?path=...`, so every vault
registered in `%APPDATA%\Obsidian\obsidian.json` works automatically (S, M, F, ...).

No Obsidian plugin needed. No admin rights. Only the HKCU registry hive and one shortcut.

*Attacca*: the score marking that means "go straight on to the next movement, without a pause".

## Installation

Double-click **`Register.cmd`**. (Or from a PowerShell prompt:
`powershell -ExecutionPolicy Bypass -File .\Register-Attacca.ps1`.)

Note: double-clicking a `.ps1` file opens it in an editor, and "Run with PowerShell" is stopped by
the execution policy on locked-down machines. The `.cmd` launchers bypass that for the single run.

This gives you:

| Where | What |
|---|---|
| Right-click a `.md` | **Open in Obsidian** |
| Right-click any file | **Send to → Obsidian** (several files at once) |
| Double-click a `.md` | See below |

**Double-click:** Windows protects the user's default choice (UserChoice) from scripts, so the
switch is made once by hand: right-click a `.md` → *Open with* → *Choose another app* → pick
**Obsidian** or **Attacca (Obsidian, right vault)** → *Always*. Both work. Picking the app "Obsidian"
directly would otherwise make Windows run `Obsidian.exe "file.md"`, which Obsidian ignores (wrong
vault), so the registration redirects that entry (`Applications\Obsidian.exe` in HKCU) to Attacca.
The original is saved and restored by Unregister. Use `-NoDefault` to leave `.md` unassociated.

Undo everything: double-click **`Unregister.cmd`** (or run `Unregister-Attacca.ps1` the same way).

## Behaviour

| File | Result |
|---|---|
| Inside a registered vault | Opens in Obsidian, in that vault (new window if the vault is closed) |
| `.md` outside every vault | Opens in the fallback editor (Notepad++, else Notepad) |
| Other file outside every vault | Opens with the Windows default program |

Change the fallback editor at the top of `Attacca.ps1` (`$FallbackEditor`). If it is missing or `""`,
`.md` files open in Notepad - never in the Windows default program, which is
Attacca itself and would start it again in a loop. No re-registration needed.

## Files

- `Attacca.ps1` - the opener itself
- `Register-Attacca.ps1` / `Unregister-Attacca.ps1` - installation into HKCU + Send to

Note: the `.ps1` files are saved with a UTF-8 BOM. Windows PowerShell 5.1 otherwise misreads non-ASCII characters.
