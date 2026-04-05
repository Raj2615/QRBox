# QRBox – Digital Inventory for Physical Boxes

A production-ready **QR-based digital inventory system** for managing physical storage boxes. Attach QR labels to real boxes, scan them with any phone, enter a PIN, and view the contents — no app install needed for scanning.

## System Architecture

```
┌─────────────────────────┐      ┌─────────────────────────┐
│    Flutter Admin App     │─────▶│     Firebase Backend     │
│    (Box owners only)     │      │  • Authentication       │
│                          │      │  • Cloud Firestore      │
│  • Login / Register      │      │  • Cloud Storage        │
│  • Dashboard + Stats     │      │  • Cloud Functions      │
│  • Box CRUD              │      │  • Firebase Hosting     │
│  • Item CRUD + Images    │      └────────────┬────────────┘
│  • QR Generator + PDF    │                   │
│  • QR Scanner            │                   │
│  • Cross-box Search      │      ┌────────────┴────────────┐
└─────────────────────────┘      │   Next.js Web Viewer     │
                                  │   (Public, no login)     │
                                  │                          │
                                  │  • PIN entry             │
                                  │  • Inventory display     │
                                  │  • Mobile-optimized      │
                                  └──────────────────────────┘
```

## Project Structure

```
QRBox/
├── flutter_app/        # Flutter admin mobile app
│   └── lib/
│       ├── core/       # Constants, theme, utils
│       ├── models/     # BoxModel, ItemModel, UserModel
│       ├── services/   # Auth, Firestore, Storage
│       ├── repositories/  # Box, Item repositories
│       ├── providers/  # Riverpod state providers
│       ├── screens/    # All UI screens
│       ├── widgets/    # Reusable widgets
│       └── router/     # GoRouter config
├── web_viewer/         # Next.js public web viewer
│   └── src/app/
│       ├── page.tsx    # Landing page
│       └── box/[boxId]/page.tsx  # PIN + Inventory page
├── firebase/           # Firebase configuration
│   ├── firestore.rules
│   ├── storage.rules
│   ├── firebase.json
│   └── functions/      # Cloud Functions (PIN verification)
└── README.md
```

## Quick Start

### Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

> **Note:** Add your `google-services.json` (Android) to `flutter_app/android/app/` and `GoogleService-Info.plist` (iOS) to `flutter_app/ios/Runner/` before running.

### Web Viewer

```bash
cd web_viewer
npm install
npm run dev
```

Visit `http://localhost:3000/box/QRBOX-0001` to test.

### Firebase

```bash
cd firebase
npm install --prefix functions
firebase deploy
```

## Features

### Admin App
| Feature | Description |
|---------|-------------|
| Auth | Email/password + Google Sign-In |
| Dashboard | Stats cards, quick actions, recent boxes |
| Box Management | Create, edit, delete boxes with PIN |
| Inventory | Add items with name, quantity, description, photo |
| QR Generator | Batch generate QR codes (up to 500) |
| PDF Labels | A4 print-ready label sheets (2×5 grid) |
| QR Scanner | Camera-based scanner with URL parsing |
| Search | Cross-box item search with results |

### Web Viewer
| Feature | Description |
|---------|-------------|
| PIN Entry | 4-digit PIN with auto-submit |
| Inventory | Box info + items list with images |
| Responsive | Mobile-first, works on all devices |
| Dark Mode | Automatic system preference detection |

## Database Schema

```
users/{userId}        → name, email, createdAt
boxes/{boxId}         → ownerId, name, location, pinHash, isConfigured, itemCount
items/{itemId}        → boxId, ownerId, name, quantity, description, imageUrl
```

## Security

- **Firestore Rules**: Owner-only read/write for boxes and items
- **PIN Hashing**: SHA-256 — PINs never stored in plain text
- **Cloud Function**: Server-side PIN verification — `pinHash` never sent to clients
- **Storage Rules**: Auth-only uploads, 5MB image limit, images only

## QR Code Format

Each QR encodes: `https://qrbox.app/box/QRBOX-XXXX`

Box IDs follow the pattern: `QRBOX-0001`, `QRBOX-0002`, etc.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile App | Flutter + Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore, Storage, Functions) |
| Web Viewer | Next.js + TypeScript |
| QR Generation | qr_flutter |
| PDF Generation | pdf + printing |
| QR Scanning | mobile_scanner |

## Deployment

1. **Firebase**: `firebase deploy` from the `firebase/` directory
2. **Web Viewer**: Build with `npm run build` → deploy `out/` to Firebase Hosting
3. **Flutter App**: `flutter build apk` / `flutter build ios`

## Environment Variables

### Web Viewer
Create `.env.local` in `web_viewer/`:
```
NEXT_PUBLIC_API_URL=https://us-central1-YOUR_PROJECT.cloudfunctions.net/verifyPinAndGetBox
```
