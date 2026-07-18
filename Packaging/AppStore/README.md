# Cork App Store Media

This directory contains the English (U.S.) storefront media for Cork 1.0. All boards and card content shown here are synthetic demo data.

## Screenshots

Upload the opaque 2560x1600 PNG files in this order:

1. `Screenshots/01-Instant-Corkboard.png` - Cork's core promise and Launch Plan board.
2. `Screenshots/02-Everything-Nearby.png` - Supported card types on the Writing Room board.
3. `Screenshots/03-Connect-Ideas.png` - Card connections and red string.
4. `Screenshots/04-Board-Templates.png` - A weekly planning template.
5. `Screenshots/05-Make-It-Yours.png` - Native preferences and customization.

`Cork-App-Store-Contact-Sheet.png` is a review aid and should not be uploaded as a storefront screenshot.

## App Preview

- `Previews/Cork-App-Preview.mp4` is a 20-second, 1920x1080, 30 fps H.264 preview with a 48 kHz stereo AAC track.
- `Previews/Cork-App-Preview-Poster.png` is a 1920x1080 reference image for choosing the preview poster frame in App Store Connect.

## Source Tools

- `../Screenshots/GenerateDemoData.swift` creates deterministic demo boards without using personal data.
- `../Screenshots/ComposeScreenshots.swift` crops captures and produces opaque App Store PNGs.
- `../Screenshots/ComposePreview.swift` builds the App Preview from the five final screenshots.

Review all text and visuals at full size before each upload. Storefront media should be regenerated whenever the visible product UI changes materially.
