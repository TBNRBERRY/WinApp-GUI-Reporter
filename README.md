# AppScout
A lightweight, standalone PowerShell script that audits your Windows system for installed software. It bypasses the "noise" of system drivers and SDKs, providing a clean, categorized list of your actual applications and games.

![License](https://img.shields.io/github/license/TBNRBERRY/AppScout?color=blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)

## 🌓 Modern Theming
AppScout features a dynamic theming engine. Switch between **Dark Mode** (default) and **Light Mode** instantly using the custom-drawn icon in the bottom-left corner.

<img src="https://github.com/TBNRBERRY/AppScout/blob/main/Screenshots/DarkMode%20Main.png" width="48%" /> <img src="https://github.com/TBNRBERRY/AppScout/blob/main/Screenshots/LightMode%20Main.png" width="48%" />

## Features
- **Smart Categorization**: Automatically groups items into `STEAM GAMES`, `DEV TOOLS`, `DRIVERS`, and `APPLICATIONS`.
- **Built-in Editor**: A GUI window allows you to live-edit the list before saving or copying.
- **Advanced Tools**: 
  - `Ctrl + F` to Find.
  - `Ctrl + H` to Find and Replace.
  - `Copy All` to clipboard functionality.
- **Dual-Architecture Scanning**: Scans both 64-bit and 32-bit registry hives (`HKLM` and `HKCU`).
- **Clean Output**: Automatically excludes Windows updates, redistributables, and development "packs."

## How to Use
1. Download the `AppScout.ps1` file.
2. Right-click the file and select **Run with PowerShell**.
3. (Optional) If you get an execution policy error, run this command in PowerShell first:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
