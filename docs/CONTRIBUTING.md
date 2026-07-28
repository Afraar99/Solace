# Acknowledgements & Disclaimer

Thank you for considering a contribution to **Solace**.

### Before you contribute

- Contributions (code, ideas, or assets) become part of Solace under the project license (GPL-2.0).
- Solace will remain free and open-source — no paywalls for core features.
- Credit is always welcome: open a PR or issue and we’ll acknowledge meaningful work where we can.

### Upstream credit

Solace is a fork of [akaMrNagar/Mindful](https://github.com/akaMrNagar/Mindful). When contributing, please keep that lineage in mind for licensing and attribution.

---

# How to contribute

### 1. Open an issue

Discuss proposed changes or features before starting large work so efforts stay aligned with the project.

### 2. Branching

- Default branch is `main`.
- Fork the repository and create your feature branch from `main`.

### 3. Make changes

Implement, test locally, and commit to your branch.

### 4. Submit a pull request

Open a PR targeting `main`. Reference related issues in the description.

### 5. Review and merge

PRs are reviewed; once approved they merge into `main` and ship in the next release.

---

# Building from source

1. Set up Flutter for your [platform](https://docs.flutter.dev/get-started/install).

2. Clone the repository:

   ```sh
   git clone https://github.com/Afraar99/Solace.git && cd Solace
   ```

3. Get dependencies:

   ```sh
   flutter pub get
   ```

4. Generate code:

   ```sh
   dart run build_runner build -d
   ```

5. Debug build:

   ```sh
   flutter build apk --debug
   ```

6. Signed release (optional):

   Create `android/key.properties` (gitignored) pointing at your local keystore, then:

   ```sh
   flutter build apk --release --split-per-abi
   ```

See [VERIFICATION.md](VERIFICATION.md) to check release APK signatures.
