# Rachel website

Astro site for Rachel, deployed to GitHub Pages at
https://rachel.stevehill.xyz. The current local update is prepared for Rachel
1.2: Saturday, Game Center invitations and Apple silicon Mac support.

## Local preview

```sh
npm ci
npm run dev -- --host 127.0.0.1
```

Open http://127.0.0.1:4321. To check the static production build:

```sh
npm run build
npm run preview -- --host 127.0.0.1
```

## Images

`./scripts/images.sh` converts existing native captures into small, versioned
WebP files. ImageMagick is required. It does not recreate or alter the app's UI.
The social card source is `scripts/og-card.html`, rendered in a browser at
1200×630 and saved as `public/images/og-card.png`. Serve the repository root
on a loopback-only HTTP server so its relative font and image paths resolve;
capture the full page to preserve the exact canvas size. The current card was
rendered and verified through Chrome.

The default source is the completed 2026-10-01 validation directory in
`../rachel-ios/fastlane/generated/release-validation/2026-10-01/`:

| Site image | Native source |
| --- | --- |
| Gameplay | `ipad-screenshots/02-table.png` |
| Tutorial | `ipad-screenshots/04-tutorial.png` |
| Nearby lobby | `network-screenshots/20-host-lobby.png` |
| Wide gameplay | `ipad-screenshots/07-landscape-table.png` |
| Saturday settings | `ipad-screenshots/08-settings.png` |

Pass another validation directory as the first argument to regenerate from
newer captures with the same filenames. Landscape orientation is baked before
metadata is stripped. The app icon comes from the iOS asset catalogue.

## Release

This update describes 1.2. Wait until manual app release and confirm store
availability before deploying it. App approval by itself does not release it.
The App Store URL is shared through `src/config.ts`; every download button
uses it.

Pushing `main` runs `.github/workflows/deploy.yml` and publishes the site.
No push or deployment is required for local review.

Announcement drafts and publication order: [docs/release-1.2.md](docs/release-1.2.md).
