# Solace

A privacy-first, open-source Android app designed to help you disconnect. With strict time-blocking and a clean, minimalist interface, it provides the quiet space you need for deep work and mental clarity.

[![API](https://img.shields.io/badge/API-🤖-black)](docs/API.md)
[![Contribute](https://img.shields.io/badge/Build_&_Contribute-🛠️-black)](docs/CONTRIBUTING.md)
[![Verify](https://img.shields.io/badge/Verify-🔐-black)](docs/VERIFICATION.md)

---

# Features

### 1. Focus Mode
Stay on track with session types like Study, Work, or Creative. Use countdown or stopwatch modes, and review your session timeline to track progress and stay consistent.

### 2. Screen Time Limits
Set daily usage limits for apps — especially for addictive short content like Reels or Shorts. Group similar apps, add shared limits, and enable Invincible Mode to lock restrictions after they're hit.

### 3. Detailed Usage Insights
Check weekly screen time, app usage, and data consumption. Solace helps you understand your habits so you can take control of your time.

### 4. App & Internet Blocking
Block distracting apps or cut off internet access with one tap. Filter adult content and create a focused, safe environment for work or study.

### 5. Notification Management
Batch notifications, schedule delivery, or mute apps during focus time. Keep interruptions low and your attention high.

### 6. Bedtime Mode
Wind down with paused apps and DND during sleep hours. Wake up to a clean slate — apps resume automatically when the day begins.

### 7. Parental Controls
Set healthy digital habits for children with tamper-proof restrictions, invincible mode, and optional biometric lock.

### 8. Privacy-First & Open Source
No ads. No tracking. Solace works completely offline, keeping your data on your device — and it's fully open-source, forever.

> [!IMPORTANT]
> ## Why _internet_ permission in the manifest?
>
> Android restricts apps from creating and protecting Local VPN tunnels without network permission. The Local VPN allows Solace to block internet access for selected apps. This is why you see the network permission in Solace's manifest. However, rest assured that Solace does not collect or transmit any user data. You can verify this by checking the network usage in the app or in your device settings.

---

# Tech Stack

| Layer | Technology |
| ----- | ---------- |
| UI / App logic | [Flutter](https://flutter.dev/) (Dart) |
| Android platform | Kotlin (native modules, VPN, services) |
| Local database | Drift / SQLite |
| License | GPL-2.0 |

---

# Building from Source

1. Set up the Flutter environment for your [platform](https://docs.flutter.dev/get-started/install).

2. Clone the repository:

   ```sh
   git clone https://github.com/Afraar99/Solace.git && cd Solace
   ```

3. Get dependencies:

   ```sh
   flutter pub get
   ```

4. Generate temporary files:

   ```sh
   dart run build_runner build -d
   ```

5. Build the APK:

   ```sh
   flutter build apk
   ```

For more detail, see [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) and [docs/VERIFICATION.md](docs/VERIFICATION.md).

---

# Contributing

1. **Open an issue** — Discuss proposed changes or features before starting work.
2. **Branch from `dev`** — Fork the repository and create your branch from `dev`.
3. **Make your changes** — Implement and commit to your branch.
4. **Open a pull request** — Target `dev` and reference any related issues.
5. **Review** — PRs are reviewed and, once approved, merged into `dev` for the next release.

Full guidelines: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

Deep linking / API reference: [docs/API.md](docs/API.md)

---

# Feedback

Suggestions, bugs, and security reports are welcome via [GitHub Issues](https://github.com/Afraar99/Solace/issues).

---

# Credits & License

Solace is built on top of the open-source work of [akaMrNagar/Mindful](https://github.com/akaMrNagar/Mindful), licensed under GPL-2.0.
