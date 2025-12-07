# FVM Usage

Flutter SDK is pinned via FVM to `3.32.1` (see `.fvmrc`).

## Install FVM
```bash
dart pub global activate fvm
# ensure ~/.pub-cache/bin is on PATH
```

## Install & use the pinned SDK
```bash
fvm install 3.32.1
fvm use 3.32.1
```

## Run commands with the pinned SDK
Always prefix with `fvm`:
```bash
fvm flutter pub get
fvm flutter run -d emulator-5554
fvm flutter build apk --debug --target-platform android-arm64
```

## Notes
- The `.fvmrc` file keeps the SDK version consistent for the project.
- If you switch shells/CI, run `fvm use` in the repo root to re-pin.
- If you see PATH issues, verify `fvm` is available and that `fvm flutter --version` reports `3.32.1`.

