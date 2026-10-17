# 🖥️ FLEXY Desktop (Flutter Windows)

> **High-Performance Multi-SIM GSM Point-of-Sale (POS) & Telecom Automation Client for Windows.**

Built with **Flutter 3.x (Windows Desktop Native)**, **SQLite (sqflite_common_ffi)**, **libserialport**, and **Socket.IO Client**.

---

## 📑 Table of Contents
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)
- [Running in Development Mode](#-running-in-development-mode)
- [Running Automated Tests](#-running-automated-tests)
- [Building for Production (Release)](#-building-for-production-release)
- [Configuration](#-configuration)
  - [Backend API & Licensing Endpoint](#backend-api--licensing-endpoint)
  - [Hardware Filtering & Serial Port Detection](#hardware-filtering--serial-port-detection)
- [Directory Structure](#-directory-structure)
- [Troubleshooting & FAQs](#-troubleshooting--faqs)

---

## ✨ Key Features

1. **Multi-SIM & Multi-Operator Support**:
   - Simultaneous management of Algerian operators: **Mobilis**, **Djezzy**, and **Ooredoo**.
   - Automatic assignment of default SIM cards per operator.
   - Live signal strength indicator (`CSQ`) and real-time balance queries (`*222#`, `*710#`, `*200#`).

2. **Hardware AT Modem Engine**:
   - Ultra-fast native communication via C++ `flutter_libserialport`.
   - Windows Plug-and-Play (PnP) auto-detection of USB GSM modems (Huawei, ZTE, Quectel).
   - Smart port filtering: automatically filters out motherboard communications ports (`COM1`) and non-modem diagnostic interfaces.

3. **Customer Credit & Debt Ledger (Clients & Dettes)**:
   - Full point-of-sale customer ledger with credit tracking.
   - Quick search by customer phone number or name.
   - Partial or complete debt repayment history.

4. **Cryptographic License Verification**:
   - Offline verification of Ed25519 digital signature serials (`FX1....`).
   - Background real-time synchronization with cloud licensing server via Socket.IO.
   - 48-hour offline operation grace period token cache.

5. **Role-Based Access Control (RBAC)**:
   - 6 Predefined roles: **Super Admin**, **Administrator**, **Manager**, **Seller/Agent**, **Cashier**, and **Accountant**.
   - 20+ fine-grained permissions protecting sensitive actions (transfers, debt settlement, role modification, AT terminal).
   - Fast account switching for shared point-of-sale terminals.

6. **Full Audit Logging**:
   - Comprehensive local SQLite audit log of every operation (logins, transfers, debt settlements, settings updates).

7. **Multilingual & Modern UI**:
   - Trilingual support: **French (FR)**, **Algerian Arabic (DZ AR)**, and **English (GB EN)**.
   - Premium Dark Mode interface optimized for all-day POS workstation use.
   - Text-To-Speech (TTS) audio feedback for completed recharges.

---

## ⚙️ Prerequisites

Before running or building the project, ensure you have:

- **Windows 10 / 11 (64-bit)**
- **Flutter SDK**: `3.22+` (Ensure `flutter` is added to your system `PATH`)
- **Visual Studio 2022**: With the **"Desktop development with C++"** workload installed (required for Windows desktop compilation)
- **Git**

Verify your environment with:
```powershell
flutter doctor
```
Ensure `[√] Windows Version` and `[√] Visual Studio` show checkmarks.

---

## 🚀 Installation & Setup

1. **Clone the repository and enter the directory**:
   ```powershell
   cd "g:\Flutter Projects\Flexy\flexy_flutter"
   ```

2. **Fetch dependencies**:
   ```powershell
   flutter pub get
   ```

3. **Verify analyzer status (0 errors expected)**:
   ```powershell
   flutter analyze
   ```

---

## 💻 Running in Development Mode

To start the desktop application with Hot Reload and debug console output:

```powershell
flutter run -d windows
```

### Hot Reload / Hot Restart:
- Press `r` in the terminal to Hot Reload.
- Press `R` to Hot Restart.
- Press `q` to quit the session.

---

## 🧪 Running Automated Tests

The application includes unit tests for authorization, permissions, and widget guards:

```powershell
flutter test
```

To run a specific test suite:
```powershell
flutter test test/authorization_service_test.dart
flutter test test/permission_guard_test.dart
```

---

## 📦 Building for Production (Release)

To compile the standalone, Ahead-Of-Time (AOT) optimized native Windows executable:

```powershell
flutter build windows --release
```

### Production Output:
The compiled executable and required runtime libraries will be generated at:
```text
build\windows\x64\runner\Release\
├── flexy_flutter.exe                    # Main executable
├── flutter_windows.dll                  # Flutter engine runtime
├── flutter_libserialport_plugin.dll     # Serial port plugin
├── serialport.dll                       # Native serialport library
├── sqlite3.dll                          # Native SQLite library
└── data/                                # App assets & compiled Dart AOT binary
```

### Launching the Production Build:
```powershell
& ".\build\windows\x64\runner\Release\flexy_flutter.exe"
```

---

## 🔧 Configuration

### Backend API & Licensing Endpoint
The backend URL is configured in `lib/services/license_service.dart`:

```dart
// Points to the live cloud server on Render or local backend:
String _baseUrl = 'https://flexy-api-efsc.onrender.com/api/v1';
```

And the Socket.IO real-time client in `lib/services/license_socket_service.dart` automatically connects to the root host:
```dart
https://flexy-api-efsc.onrender.com
```

### Hardware Filtering & Serial Port Detection
Port filtering and exclusion logic is located in:
- `lib/services/gsm_service.dart`: Filters out motherboard COM ports (`COM1`), standard serial, and diagnostics interfaces.
- `lib/providers/gsm_provider.dart`: Performs live `testPortAtResponse` AT handshakes before accepting ports into the active Multi-SIM pool.

---

## 📂 Directory Structure

```text
lib/
├── main.dart                               # App entrypoint & Provider tree
├── core/
│   ├── authorization/
│   │   ├── app_permissions.dart            # Granular permission definitions
│   │   ├── app_roles.dart                  # System roles & permission bindings
│   │   ├── authorization_service.dart      # Singleton access verification
│   │   └── permission_guard.dart           # Declarative widget access guard
│   ├── localization/
│   │   ├── language_provider.dart          # Language state (FR, AR, EN)
│   │   ├── translations_fr.dart            # French translation dictionary
│   │   ├── translations_ar.dart            # Arabic translation dictionary
│   │   └── translations_en.dart            # English translation dictionary
│   └── theme/
│       └── app_colors.dart                 # Color palette & styling
├── database/
│   └── database_helper.dart                # SQLite schema, migrations, audit logging
├── models/
│   ├── license_model.dart                  # License DTOs & token models
│   ├── settings_model.dart                 # Modem configuration model
│   └── user_model.dart                     # User & role entities
├── providers/
│   ├── auth_provider.dart                  # User session, login, fast switcher
│   ├── flexy_provider.dart                 # Flexy transfers, transaction history
│   ├── gsm_provider.dart                   # Multi-SIM detection & monitoring
│   ├── license_provider.dart               # License activation & socket sync
│   └── settings_provider.dart              # Operator settings persistence
├── services/
│   ├── gsm_service.dart                    # Low-level AT commands & USSD engine
│   ├── license_service.dart                # HTTP REST license client
│   ├── license_socket_service.dart         # Socket.IO Gateway client
│   └── tts_service.dart                    # Text-to-speech audio service
└── views/
    ├── access_denied_view.dart             # 403 Forbidden screen
    ├── activation_sim_view.dart            # Multi-SIM activation screen
    ├── audit_logs_view.dart                # Security audit log view
    ├── clients_dette_view.dart             # Customer credit & debt view
    ├── flexy_view.dart                     # Main POS flexy recharge screen
    ├── login_view.dart                     # Login & credentials screen
    ├── main_layout.dart                    # App scaffold, sidebar, header
    ├── modem_terminal_view.dart            # AT command terminal & console
    ├── roles_management_view.dart          # RBAC matrix editor
    ├── settings_view.dart                  # Hardware settings view
    └── users_management_view.dart          # User directory & CRUD
```

---

## ❓ Troubleshooting & FAQs

### 1. Modem Not Detected
- Ensure your USB GSM modem is plugged in and recognized in Windows Device Manager.
- Open the **Terminal AT Modem** screen in Flexy and click **Détecter Ports OS**.
- If your modem is in mass-storage mode, install the modem's USB driver to enable serial COM port mode.

### 2. COM1 Shows as Inactive
- This is by design: `COM1` is typically the physical serial port on the PC's motherboard. Flexy automatically ignores it to avoid communication lockups.

### 3. SQLite Database Location
- On Windows, the local database file `flexy.db` is stored at:
  `%APPDATA%\com.example\flexy_flutter\flexy.db`