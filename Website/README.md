# Cork Website

This directory is the static marketing and App Store support site for Cork.

## App Store Connect URLs

With the provisional `usecorkboard.app` domain:

- Marketing URL: `https://usecorkboard.app/`
- Support URL: `https://usecorkboard.app/support/`
- Privacy Policy URL: `https://usecorkboard.app/privacy/`

The Support URL includes a direct email address as required by App Store Connect. Configure `support@usecorkboard.app` as a working mailbox or forwarding alias before publishing these URLs.

See `DOMAIN-SUGGESTIONS.md` for the dated availability shortlist and the existing-product name warning.

Apple references:

- [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information) documents the required Support URL and optional Marketing URL.
- [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information) documents the required macOS Privacy Policy URL.

## Before Publishing

1. Register the final domain.
2. Replace every instance of `usecorkboard.app` if a different domain is selected.
3. Configure the support email address and test it from an unrelated email account.
4. Replace the coming-soon buttons with Cork's final App Store URL after the app record is public.
5. Confirm the privacy policy still matches the shipping app and hosting provider.
6. Test the homepage, Support page, and Privacy page over HTTPS on desktop and mobile.

## Hosting

The site has no build step, cookies, analytics, external fonts, or third-party scripts. Publish this directory as the site root.

- Cloudflare Pages: choose a static site with `Website` as the output directory. The included `_headers` file applies security and caching headers.
- GitHub Pages: publish the `Website` directory from a dedicated branch or workflow, then attach the custom domain in repository settings.
- Netlify: deploy the `Website` directory directly. The included `_headers` file is supported.

This repository includes `.github/workflows/pages.yml`, which publishes this
directory whenever website files are pushed to `main`. It can also be run
manually from the Actions tab. Until a custom domain is configured, the site is
served at `https://kopitarfan.github.io/Cork/`.

The `.app` top-level domain requires HTTPS. All three hosts can provision and renew TLS certificates automatically after DNS is connected.
