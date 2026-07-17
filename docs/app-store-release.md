# App Store Release

This guide covers Cork's macOS App Store build. The Swift package remains useful for fast development and tests, but releases must use `Cork.xcodeproj` and the shared `Cork App` scheme.

## Current Release Shape

- Product: `Cork.app`
- Minimum system: macOS 14
- Category: Productivity
- Version: `1.0`
- Build: `1`
- Bundle identifier: `net.miguelrodriguez.Cork`
- Development team: `FLJNW3455S`
- Architectures: Apple silicon and Intel
- App Sandbox: enabled
- Hardened Runtime: enabled
- Distribution: Mac App Store

The team-signed Debug build and signed universal Release archive both succeed with Hardened Runtime and the intended App Sandbox entitlements. App Store Connect validation remains to be completed.

## Account Setup

1. Open `Cork.xcodeproj` in Xcode.
2. Select the Cork project, then the Cork app target.
3. Open Signing & Capabilities.
4. Confirm team `FLJNW3455S` is selected.
5. Confirm `net.miguelrodriguez.Cork` is the final unique bundle identifier.
6. Create the macOS app record in App Store Connect with that exact bundle identifier.
7. Keep Automatically manage signing enabled unless the account requires manual profiles.

The bundle identifier becomes part of Cork's identity and sandbox container. Choose it before distributing test builds broadly.

## Required Storefront Work

- Host a public privacy policy URL.
- Provide a support URL and support contact.
- Prepare the app name, subtitle, description, keywords, and release notes.
- Answer App Privacy using the shipped behavior. The current build declares no tracking or data collection.
- Answer export compliance consistently with `ITSAppUsesNonExemptEncryption = false`.
- Capture one to ten Mac screenshots without alpha at an accepted 16:10 size, such as 2560x1600.
- Choose pricing, availability, age rating, and release method.

## Release Gates

- Pass the complete packaged-app checklist in `docs/manual-testing.md`.
- Confirm newly imported images and file cards survive a full quit and relaunch in the signed sandboxed app.
- Verify the global shortcut from Finder, Safari, full-screen apps, and multiple Spaces.
- Verify Launch at Login with the signed app, including the approval-required path.
- Confirm the privacy manifest still matches the final feature set.
- Complete an accessibility pass for keyboard navigation, VoiceOver labels, contrast, and reduced motion.

## Archive and Upload

1. Increment the build number for every upload. Increment the marketing version for a new App Store version.
2. Select the shared `Cork App` scheme.
3. Choose `Any Mac (Apple Silicon, Intel)` as the destination.
4. Choose Product > Archive.
5. In Organizer, choose Validate App and resolve every error before continuing.
6. Choose Distribute App > App Store Connect > Upload.
7. Wait for processing, attach the build to the App Store version, complete the listing, and submit for review.

## Preflight

Before each archive:

```sh
swift test --quiet
xcodebuild -project Cork.xcodeproj -scheme "Cork App" -configuration Release build
git diff --check
```

Also lint `Packaging/Info.plist`, `Packaging/Cork.entitlements`, and `Packaging/PrivacyInfo.xcprivacy`, then inspect the archive to confirm `AppIcon.icns`, `Assets.car`, and `PrivacyInfo.xcprivacy` are present.

## Review Notes

App Review should receive concise instructions explaining that Cork is a menu bar utility, how to open the board, the default global shortcut, where Preferences lives, and why user-selected file access is needed. Mention Launch at Login only as an optional user-controlled preference.
