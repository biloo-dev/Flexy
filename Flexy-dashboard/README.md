# 🌐 FLEXY Admin Dashboard (Vue 3 + Vuetify 3)

> **Enterprise Web Management Console for Fleet Monitoring, License Lifecycle Management, and Real-Time Business Analytics.**

Built with **Vue 3 (Composition API + `<script setup>`)**, **TypeScript**, **Vite**, **Vuetify 3 (Material Design 3)**, **Pinia**, and **Apache ECharts**.

[![Live Production](https://img.shields.io/badge/Live%20Dashboard-flexy--license.web.app-brightgreen?logo=firebase&logoColor=white)](https://flexy-license.web.app)
[![API Backend](https://img.shields.io/badge/API-Render%20Live-46E3B7?logo=render&logoColor=white)](https://flexy-api-efsc.onrender.com/api/docs)

---

### 🌐 Live Hosted Dashboard:
- **Production URL**: **[https://flexy-license.web.app](https://flexy-license.web.app)**
- **Firebase Mirror**: **[https://flexy-license.firebaseapp.com](https://flexy-license.firebaseapp.com)**

## 📑 Table of Contents
- [Overview](#-overview)
- [Key Features](#-key-features)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)
- [Running in Development Mode](#-running-in-development-mode)
- [Building for Production](#-building-for-production)
- [Deployment Options](#-deployment-options)
  - [Firebase Hosting](#firebase-hosting)
  - [Render Static Site](#render-static-site)
- [Environment Configuration](#-environment-configuration)
- [Project Architecture & Views](#-project-architecture--views)
- [Tech Stack](#-tech-stack)

---

## 🚀 Overview

The **FLEXY Admin Dashboard** provides centralized command and control over all distributed point-of-sale terminals. System administrators and business owners can issue cryptographic software licenses, track device heartbeats in real-time, monitor SIM card states, and analyze revenue trends across Algerian telecom operators (Djezzy, Mobilis, Ooredoo).

---

## ✨ Key Features

1. **Real-Time Fleet & Telemetry Monitoring**:
   - Live tracking of connected POS desktop terminals.
   - Heartbeat monitoring with online/offline status indicators.
   - Remote device inspection (Hardware Fingerprint, Hostname, OS version, app version).

2. **Cryptographic License Management**:
   - Issue, renew, suspend, and revoke Ed25519 digital signature licenses.
   - Two-Level SIM authorization: bind licenses to specific SIM ICCID hashes and modem IMEIs.
   - Expiring licenses dashboard with proactive alert tags.

3. **Multi-Operator Analytics & Visualizations**:
   - Visual charts powered by **Apache ECharts**:
     - Daily/Monthly revenue distribution.
     - Operator share breakdown (Mobilis, Djezzy, Ooredoo).
     - Transaction activity heatmaps and success rates.

4. **Security & Comprehensive Audit Logs**:
   - Security overview and anomaly detection view.
   - Detailed event log tracking every admin action, device registration, and payment transaction.

5. **Customer & Debt Oversight**:
   - Global view of customer accounts, debts, and transaction histories across all terminals.

6. **Responsive Material Design 3 UI**:
   - Light and dark theme modes with fluid transitions.
   - Global search dialog (`Ctrl + K`).
   - Granular permission gates protecting admin routes.

---

## ⚙️ Prerequisites

- **Node.js**: `18.0.0+` (LTS recommended)
- **Package Manager**: `npm`, `pnpm`, or `yarn`

Verify your Node version:
```powershell
node -v
npm -v
```

---

## 📥 Installation & Setup

1. **Navigate to the dashboard directory**:
   ```powershell
   cd "G:\Flutter Projects\Flexy\Flexy-dashboard"
   ```

2. **Install all dependencies**:
   ```powershell
   npm install
   ```

---

## 💻 Running in Development Mode

To start the Vite development server with Hot Module Replacement (HMR):

```powershell
npm run dev
```

The application will be accessible at:
```text
http://localhost:5173
```

---

## 📦 Building for Production

To create an optimized production build:

```powershell
npm run build
```

The output will be generated in the `dist/` folder ready for static hosting.

To preview the production build locally:
```powershell
npm run preview
```

---

## 🚀 Deployment Options

### Firebase Hosting
The project includes pre-configured `firebase.json` and `.firebaserc` files targeting Single-Page Application (SPA) routing:

```powershell
# 1. Login to Firebase CLI
firebase login

# 2. Deploy to hosting
firebase deploy --only hosting
```

### Render Static Site
1. Connect your GitHub repository to Render.
2. Create a new **Static Site**.
3. Set the following build settings:
   - **Build Command**: `npm run build`
   - **Publish Directory**: `dist`
4. Add environment variable:
   - `VITE_API_BASE_URL` = `https://flexy-api-efsc.onrender.com/api/v1`

---

## 🔧 Environment Configuration

Create or update the `.env` file in the root of `Flexy-dashboard`:

```env
# Backend REST API Base URL
VITE_API_BASE_URL=https://flexy-api-efsc.onrender.com/api/v1

# Application Title
VITE_APP_TITLE=FLEXY Management Console
```

For local development against a local NestJS server:
```env
VITE_API_BASE_URL=http://localhost:10000/api/v1
```

---

## 📁 Project Architecture & Views

```text
src/
├── components/
│   ├── common/             # Reusable UI chips, avatars, metric cards, search dialog
│   ├── dashboard/          # ECharts widgets (RevenueChart, OperatorDistribution, SimStatusChart)
│   └── operations/         # Operation timelines & status indicators
├── composables/            # Theme, directions, permissions, export utilities
├── layouts/
│   ├── AppLayout.vue       # Main admin shell with sidebar, topbar, and notifications
│   └── AuthLayout.vue      # Clean layout for login and authentication
├── plugins/
│   ├── echarts.ts          # Apache ECharts registration
│   └── vuetify.ts          # Vuetify 3 theme and icon configuration
├── router/
│   └── index.ts            # Route definitions with auth and permission guards
├── stores/                 # Pinia state stores
│   ├── auth.store.ts       # Admin authentication & token storage
│   ├── device.store.ts     # Connected device fleet state
│   ├── license.store.ts    # License inventory & generation
│   ├── modem.store.ts      # Modem hardware tracking
│   ├── sim.store.ts        # SIM card inventory
│   └── audit.store.ts      # System audit logs
└── views/                  # Application views
    ├── auth/               # LoginView
    ├── dashboard/          # Main KPI DashboardView
    ├── devices/            # DevicesListView, DeviceDetailView
    ├── licenses/           # LicensesListView, ExpiringLicensesView
    ├── modems/             # ModemsListView, ModemDetailView
    ├── sims/               # SimsListView, SimDetailView
    ├── operations/         # OperationsListView, OperationDetailView
    ├── monitoring/         # HeartbeatMonitorView
    ├── security/           # SecurityOverviewView, SecurityEventsListView
    ├── audit/              # AuditLogsListView
    └── settings/           # UsersManagementView, KeyManagementView
```

---

## 🛠️ Tech Stack

- **Framework**: Vue 3 (Composition API)
- **Build Tool**: Vite
- **UI Framework**: Vuetify 3 (Material Design 3)
- **State Management**: Pinia
- **Routing**: Vue Router 4
- **Charts & Data Visualization**: Apache ECharts & `vue-echarts`
- **HTTP Client**: Axios
- **Icons**: Material Design Icons (`@mdi/font`)
