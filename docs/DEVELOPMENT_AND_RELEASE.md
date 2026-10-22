# MONEY — Development, Testing & Release Guide

This guide provides copy-paste ready commands for setting up, running, testing, building, and deploying the **MONEY** application across supported platforms.

---

## 1. Prerequisites & Toolchain Requirements

Ensure your workstation has the following toolchains installed:

| Toolchain | Minimum Supported Version | Verified Local Version |
| :--- | :--- | :--- |
| **Flutter SDK** | `>= 3.22.0` | `3.24.5 (Channel stable)` |
| **Dart SDK** | `>= 3.4.0` | `3.5.4` |
| **Python** | `>= 3.9` | `3.10+` |
| **Android SDK** | `API Level 34` | `Android SDK 36.0.0` |
| **Java JDK** | `Version 17` | `OpenJDK 17 (Java HotSpot)` |
| **Google Chrome** | Latest Stable | `Version 120+` |

---

## 2. Environment Configuration

### AI Backend Microservice (`server/.env`)
Create a file named `.env` inside the `server/` directory:

```bash
# server/.env
AI_PROVIDER=gemini           # Options: gemini | groq | hybrid
GEMINI_API_KEY=your_google_gemini_api_key_here
GROQ_API_KEY=your_groq_cloud_api_key_here
GEMINI_MODEL=gemini-1.5-flash
GROQ_MODEL=llama-3.3-70b-versatile
PORT=8000
HOST=0.0.0.0
```

> [!NOTE]
> If external API keys are not supplied, the backend automatically engages its built-in heuristic rule engine, ensuring all endpoints continue to return valid zero-based allocations and coaching feedback.

---

## 3. Dependency Installation

### Step A: Flutter Frontend
```bash
cd My-Money
flutter pub get
```

### Step B: Python AI Backend
```bash
cd server
pip install -r requirements.txt
```

---

## 4. Running the Application Locally

### Step 1: Start the AI Backend Server
```bash
# From workspace root
cd server
python server.py
# Server starts on http://localhost:8000
```
Verify the server health:
```bash
curl http://localhost:8000/api/health
```

### Step 2: Run the Flutter Frontend

#### On Web (Chrome):
```bash
cd My-Money
flutter run -d chrome
```

#### On Android Device / Emulator:
```bash
cd My-Money
flutter run -d android
```

#### On Windows Desktop (if Visual Studio workload is installed):
```bash
cd My-Money
flutter run -d windows
```

---

## 5. Verification & Automated Testing

### Run All Unit, Widget & Analytical Tests
```bash
cd My-Money
flutter test
```
**Expected Result**: All 29 unit and widget tests pass (`00:06 +29: All tests passed!`).

### Run Static Analysis
```bash
cd My-Money
flutter analyze
```

---

## 6. Production Build Execution

### A. Android Release APK
Produces an installable Android APK with local release signing:
```bash
cd My-Money
flutter build apk --release
```
- **Output Path**: `My-Money/build/app/outputs/flutter-apk/app-release.apk`
- **Distribution Release Path**: `releases/MONEY-v2.0.0-release.apk`

### B. Android App Bundle (Google Play Store)
Produces an optimized Google Play distribution package:
```bash
cd My-Money
flutter build appbundle --release
```
- **Output Path**: `My-Money/build/app/outputs/bundle/release/app-release.aab`
- **Distribution Release Path**: `releases/MONEY-v2.0.0-release.aab`

### C. Production Web Build
Produces an optimized static bundle for high-performance browser execution:
```bash
cd My-Money
flutter build web --release
```
- **Output Directory**: `My-Money/build/web/`

---

## 7. Artifact Integrity & SHA-256 Checksums

All distribution binaries have been verified on the filesystem:

| Artifact | File Path | File Size | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| **Android APK** | `releases/MONEY-v2.0.0-release.apk` | 32,257,619 bytes (30.76 MB) | `9BB5589AF04C053B9BCBD6625D09A383C662F853AADE23CC9AAE0BA4699E2AED` |
| **Android App Bundle** | `releases/MONEY-v2.0.0-release.aab` | 31,939,712 bytes (30.46 MB) | `AB628D64AEEF3D20CC49B7CD9840D46D7C439B666FF0A78BC024AB97FA1A136B` |
| **Web Production** | `My-Money/build/web/` | ~38 MB directory | Verified CanvasKit/Wasm compilation |

---

## 8. Serving the Production Web Build Locally

To test or demonstrate the production web build locally without Flutter development servers:
```bash
cd My-Money/build/web
python -m http.server 8080
```
Open [http://localhost:8080](http://localhost:8080) in your web browser.

---

## 9. Web Hosting Deployment Guide

### Option 1: Firebase Hosting
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# Set public directory to My-Money/build/web
# Configure as a single-page app: Yes
firebase deploy --only hosting
```

### Option 2: Vercel
```bash
npm install -g vercel
cd My-Money/build/web
vercel deploy --prod
```

### Option 3: Netlify
```bash
npm install -g netlify-cli
cd My-Money/build/web
netlify deploy --prod --dir=.
```

---

## 10. Troubleshooting & Common Questions

1. **Gradle Build Fails on Android Licenses**:
   Run: `powershell -Command "('y`n' * 10) | flutter doctor --android-licenses"`.
2. **AI Coach Shows Connection Notice**:
   Verify that `server/server.py` is running on port 8000 and that your workstation firewall allows local connections.
3. **Web Refresh Returns 404 on Hosted Servers**:
   Ensure single-page rewrite rules redirect all paths (`/*`) to `/index.html`.
