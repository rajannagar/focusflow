# FocusFlow

**Be Present** – The all-in-one iOS app for focused work.

FocusFlow is a premium focus timer, task manager, and progress tracker. Beautiful, private, and built for deep work.

**Version:** 1.2.1  
**Status:** 🟡 In Development (15/17 P1 tasks complete, 1 skipped, 1 deferred; P3-2 completed)

[![App Store](https://img.shields.io/badge/App%20Store-Download-blue?logo=apple)](https://apps.apple.com/app/focusflow-be-present/id6739000000)

---

## 📁 Project Structure

```
FocusFlow/
│
├── 📁 docs/                      # Documentation
│   └── IMPLEMENTATION_PLAN.md    # Launch implementation plan & progress
│
├── 📁 FocusFlow/                 # iOS App Source Code
│   ├── App/                      # App lifecycle & entry points
│   ├── Core/                     # Core functionality
│   │   ├── AppSettings/          # User preferences
│   │   ├── Logging/              # Debug logging & sync logs
│   │   ├── Notifications/        # Notification system
│   │   ├── UI/                   # Reusable UI components
│   │   └── Utilities/            # Helpers (ProGatingHelper, haptics, network, etc.)
│   ├── Features/                 # Feature modules
│   │   ├── Auth/                 # Authentication flows & guest migration
│   │   ├── Focus/                # Focus timer, ambient sounds & backgrounds
│   │   ├── Journey/              # Daily summary timeline (Pro only)
│   │   ├── NotificationsCenter/  # In-app notification center
│   │   ├── Onboarding/           # First-run experience
│   │   ├── Presets/              # Custom focus presets
│   │   ├── Profile/              # User profile & settings
│   │   ├── Progress/             # XP, levels & stats (Pro only)
│   │   └── Tasks/                # Task management
│   ├── Infrastructure/           # Backend & sync
│   │   └── Cloud/                # Supabase, auth, sync engines
│   ├── Resources/                # Assets, sounds, entitlements
│   ├── Shared/                   # Code shared with widgets
│   └── StoreKit/                 # In-app purchases & paywall
│
├── 📁 FocusFlowWidgets/          # Widget Extension
│   └── ...                       # Home screen & Live Activity widgets
│
├── 📁 FocusFlow.xcodeproj/       # Xcode Project
│
├── 📁 softcomputers-site/        # Marketing Website (Next.js)
│   ├── app/                      # Pages
│   ├── components/               # React components
│   ├── hooks/                    # Custom hooks
│   └── lib/                      # Utilities & constants
│
├── 📁 supabase/                  # Backend Functions
│   └── functions/
│       └── delete-user/          # Account deletion edge function
│
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 16+** (uses File System Synchronized Groups)
- **iOS 18.6+** deployment target
- **Node.js 18+** (for website development)

### iOS App

1. Open `FocusFlow.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on simulator or device

### Website

```bash
cd softcomputers-site
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

---

## 🎯 Key Features

### Focus Timer
- **14 Ambient Backgrounds** – Aurora, Rain, Ocean, Forest, Stars, and more
- **11 Focus Sounds** – Light Rain, Fireplace, Soft Ambience, and more
- **Custom Presets** – Save your perfect focus setup
- **Live Activity** – Timer in Dynamic Island (Pro only)

### Task Management
- **Smart Tasks** – Recurring tasks with reminders & duration estimates
- **Task Limits** – Free: 3 tasks | Pro: Unlimited

### Progress & Gamification
- **XP & Levels** – 50 levels to unlock, earn XP for sessions & tasks (Pro only)
- **Journey View** – Daily summaries & weekly reviews (Pro only)
- **Progress History** – Free: Last 3 days | Pro: Full history

### Customization
- **10 Themes** – Forest, Neon, Peach, Cyber, Ocean, Sunrise, Amber, Mint, Royal, Slate
- **Free Themes** – Forest, Neon (2)
- **Pro Themes** – All 10 themes

### Sync & Cloud
- **Cloud Sync** – Sync across devices with Supabase (Pro + SignedIn only)
- **Guest Mode** – Use without an account (local only)
- **Data Migration** – Seamless guest → account migration

### Platform Features
- **Widgets** – Home screen widgets (Free: view-only | Pro: full interactivity)
- **Live Activity** – Dynamic Island integration (Pro only)
- **External Music** – Spotify, Apple Music, YouTube Music integration (Pro only)

### Privacy & Security
- **Privacy First** – No tracking, no ads
- **Secure Authentication** – Email/Password & Google Sign-In
- **End-to-End Sync** – Your data, encrypted

---

## 💎 Free vs Pro

| Feature | Free | Pro |
|---------|------|-----|
| **Themes** | 2 (Forest, Neon) | 10 (All themes) |
| **Focus Sounds** | 3 | 11 (All sounds) |
| **Ambient Backgrounds** | 3 (Minimal, Stars, Forest) | 14 (All backgrounds) |
| **Presets** | 3 total | Unlimited |
| **Tasks** | 3 total | Unlimited |
| **Progress History** | Last 3 days | Full history |
| **XP & Levels** | ❌ Hidden | ✅ 50 levels |
| **Journey View** | ❌ Locked | ✅ Full access |
| **Cloud Sync** | ❌ | ✅ (requires sign-in) |
| **Widgets** | View-only | Full interactivity |
| **Live Activity** | ❌ | ✅ |
| **External Music** | ❌ | ✅ |

---

## 🔧 Tech Stack

### iOS App
- **SwiftUI** – Modern declarative UI
- **Supabase** – Authentication & database
- **StoreKit 2** – In-app purchases & subscriptions
- **WidgetKit** – Home screen widgets
- **ActivityKit** – Live Activities
- **Google Sign-In** – Social authentication

### Website
- **Next.js 14** – App Router, React Server Components
- **TypeScript** – Type safety
- **Tailwind CSS** – Styling
- **AWS Amplify** – Hosting

---

## 📊 Development Status

### ✅ Completed (15/17 P1 tasks + P3-2)
- ✅ PaywallView with contextual support
- ✅ ProGatingHelper (centralized gating logic)
- ✅ Guest → Account Migration
- ✅ Theme Gating (2 free, 8 Pro)
- ✅ Sound Gating (3 free, 8 Pro)
- ✅ Ambiance Gating (3 free, 11 Pro)
- ✅ Preset Gating (3 max free, unlimited Pro)
- ✅ Task Gating (3 max free, unlimited Pro)
- ✅ Progress History Gating (3 days free)
- ✅ XP/Levels Gating (Pro only)
- ✅ Journey View Gating (Pro only)
- ✅ Widget Gating (Pro only for interactivity)
- ✅ Live Activity Gating (Pro only)
- ✅ External Music Gating (Pro only)
- ✅ Sync Status UI in ProfileView
- ✅ Accessibility Pass (VoiceOver support, labels & hints)

### ⏭️ Skipped (1 task)
- ⏭️ Task Reminders Gating (free users can use reminders on their 3 tasks)

### ⏳ Remaining P1 Tasks (1)
- ⏸️ Cloud Sync Gating (DEFERRED - to be completed later)

See [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) for full details.

---

## 📄 License

Copyright © 2025 Soft Computers. All rights reserved.

---

## 📧 Contact

- **Email**: Info@softcomputers.ca
- **Website**: [softcomputers.ca](https://www.softcomputers.ca)

