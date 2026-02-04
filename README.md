# 🎮 Game Performance Optimizer

Automatically closes configured applications when you start gaming (e.g., Steam) and reopens them when you're done. Designed to improve gaming performance by freeing up system resources.

![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue.svg)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## 📖 What is it?

Game Performance Optimizer is a lightweight PowerShell-based tool that runs silently in the background and automatically:

1. **Detects** when you launch a gaming application (Steam, Epic Games, etc.)
2. **Closes** resource-heavy applications (browsers, Discord, Spotify, etc.)
3. **Stops** unnecessary Windows services (optional)
4. **Reopens** everything automatically when you quit gaming

No manual intervention needed - it just works! 🚀

---

## ✨ Key Features

- **🔍 Smart Process Detection** - Automatically extracts startup info from Windows Startup folder shortcuts
- **🎯 Multi-Trigger Support** - Monitor multiple applications (Steam, Epic Games, Photoshop, etc.)
- **⚙️ Service Management** - Optionally stops Windows services during gaming (DiagTrack, SysMain, BITS, etc.)
- **🔄 Auto-Restart** - Reopens closed applications with correct arguments when you quit
- **📊 Robust Logging** - Detailed logs for troubleshooting
- **🖥️ Easy Management** - Interactive menu-based manager for installation, updates, and configuration
- **🛡️ Generic Shortcut Detection** - Works with ANY app that has a shortcut in the Startup folder

---

## 📦 Installation

### Option 1: Quick Install (Recommended)

1. Download the latest release: **[GamePerformanceOptimizer-v1.0.zip](../../releases/latest)**
2. Extract the ZIP file
3. Run `Setup.ps1` (right-click → Run with PowerShell)
4. Follow the interactive wizard to select which apps to manage

### Option 2: Using the Manager Interface

1. Download and extract the ZIP
2. Run `GameOptimizer-Manager.bat`
3. Select option **[1] Install Game Optimizer**
4. Follow the configuration wizard

---

## 🎮 How It Works

### Example Scenario

**Before Gaming:**
- You have Chrome (50 tabs), Discord, Spotify, and other apps running
- Your system has ~8GB RAM used

**You Launch Steam:**
1. Game Optimizer detects Steam starting
2. Automatically closes Chrome, Discord, Spotify
3. Stops unnecessary Windows services (if enabled)
4. Your system now has ~4GB RAM available for gaming

**You Quit Steam:**
1. Game Optimizer detects Steam closed
2. Automatically reopens Chrome, Discord, Spotify with correct arguments
3. Restarts Windows services
4. Everything is back to normal

---

## 🛠️ Management Interface

Run `GameOptimizer-Manager.bat` for easy access to:

```
========================================
 Game Performance Optimizer v3.5
========================================

  Status: INSTALADO
  Estado: Running

  [1] Ver Status Detalhado
  [2] Atualizar/Reiniciar Servico
  [3] Reconfigurar (mudar apps)
  [4] Ver Logs
  [5] Desinstalar
  [0] Sair

========================================
  Escolha uma opcao:
```

---

## ⚙️ Configuration

The `config.json` file (created during setup) contains all settings:

```json
{
  "triggerProcess": ["steam"],
  "processesToManage": [
    "chrome",
    "msedge",
    "discord",
    "spotify",
    "slack"
  ],
  "processesToReopenOnly": [
    "chrome",
    "discord",
    "spotify"
  ],
  "servicesToManage": [
    "DiagTrack",
    "SysMain",
    "BITS",
    "DoSvc"
  ],
  "settings": {
    "steamCheckInterval": 5,
    "enableLogging": true,
    "enableServiceManagement": true,
    "reopenDelay": 3
  }
}
```

### Configuration Options

| Setting | Description |
|---------|-------------|
| `triggerProcess` | Apps that trigger optimization (e.g., `steam`, `epicgames`) |
| `processesToManage` | Apps to close during gaming |
| `processesToReopenOnly` | Apps that should be reopened after gaming |
| `servicesToManage` | Windows services to stop during gaming |
| `steamCheckInterval` | How often to check if trigger is running (seconds) |
| `enableLogging` | Enable/disable logging |
| `enableServiceManagement` | Enable/disable Windows service management |
| `reopenDelay` | Delay before reopening apps (seconds) |

---

## 📋 Requirements

- **OS:** Windows 10 or Windows 11
- **PowerShell:** 5.1 or higher (pre-installed on Windows 10/11)
- **Privileges:** Administrator (only for installation)

---

## 🐛 Troubleshooting

### Apps not closing?

1. Check logs: `GameOptimizer-Manager.bat` → Option **[4]**
2. Verify the process name matches exactly (e.g., `chrome` not `chrome.exe`)
3. Ensure you have permission to close the process
4. Check if the app is running with elevated privileges

### Apps not reopening?

- **Shortcut detection** automatically extracts startup info for apps in the Startup folder
- For apps **not** in Startup folder, WMI fallback is used to capture arguments
- Check logs for **"Extracted from Startup shortcut"** messages
- If reopening fails, check if the app requires specific arguments

### Service management errors?

- Run installation as **Administrator**
- Ensure services are not critical to Windows operation
- Disable service management in `config.json` if needed:
  ```json
  "settings": {
    "enableServiceManagement": false
  }
  ```

### Task not running?

1. Open Task Scheduler
2. Look for **"GamePerformanceOptimizer"**
3. Right-click → **Run** to test manually
4. Check **History** tab for errors

---

## 🔧 Uninstallation

1. Run `GameOptimizer-Manager.bat`
2. Select option **[5] Desinstalar**
3. Confirm removal

**Or** run `Uninstall-GameOptimizer.bat` directly.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Clone the repository
2. Copy `config.sample.json` to `config.json`
3. Modify scripts as needed
4. Test using `GameOptimizer.ps1` directly

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

## 📞 Support

For issues, questions, or feature requests:
- 🐛 [Open an issue](../../issues)
- 💬 [Start a discussion](../../discussions)

---

## ⭐ Show Your Support

If you find this project useful, please consider giving it a star on GitHub!

---

**Made with ❤️ to help gamers get the best performance**
