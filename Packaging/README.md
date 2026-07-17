# Cork Packaging

This directory contains the bundle metadata and release assets used by the `Cork` target in `Cork.xcodeproj`.

## App Icon

- `AppIcon/Cork-AppIcon-Master-1024.png` is the unmasked 1024x1024 illustrated source artwork.
- `Assets.xcassets/AppIcon.appiconset` contains all required macOS icon sizes from 16x16 through 512x512 at 2x.
- Keep the source artwork square. macOS applies the final rounded-corner mask.
- The current icon is a flattened default appearance. A layered Icon Composer source and optional dark, clear, or tinted appearances can be evaluated after the app target is in place.

## Bundle Files

- `Info.plist` declares Cork as a menu bar productivity app, sets version metadata, and records that Cork does not use non-exempt encryption.
- `Cork.entitlements` enables App Sandbox, read-only user-selected file access, and app-scoped security bookmarks.
- `PrivacyInfo.xcprivacy` declares no tracking, data collection, or required-reason API use in the current app.

## Xcode Target

Open `Cork.xcodeproj` and use the shared `Cork App` scheme. The app target compiles `Sources/Cork`, links the local `CorkCore` package product, and includes the asset catalog and privacy manifest.

Before the first signed archive:

1. Select the Cork target's Signing & Capabilities tab.
2. Choose the Apple Developer team that owns the App Store Connect record.
3. Confirm the `net.miguelrodriguez.Cork` bundle identifier matches App Store Connect.
4. Keep App Sandbox and Hardened Runtime enabled.
5. Confirm the App Store Connect record uses the exact same bundle identifier.

See `docs/app-store-release.md` for archive, validation, and packaged-app QA steps.
