# Correct the public release information

Preserve local commit 60e7bde, which enables released Apple features and corrects press availability. The live store listing inspected in Chrome on 15 October shows version 1.4 and seven themes; the web search cache still shows an older release.

1. Correct theme counts in src/components/Saturday.astro and src/pages/press.astro. Retain existing imagery and its truthful alt text; do not replace captures as part of a copy correction.
2. Remove the forthcoming label from scripts/og-card.html and render public/images/og-card.png from that source at 1200 by 630. Update README.md to describe the released site without changing historical announcement drafts.
3. Build with npm run build and inspect generated homepage, support, press and metadata for stale release notices. Check the social card and live destination links. Inspect desktop/mobile copy in Chrome.
4. Commit this completion separately, preserving 60e7bde. Push the verified task commits, wait for GitHub Pages, and inspect the actual live pages and social image. Stop task-owned preview servers and close task tabs.

## Local verification

The production build generated all seven pages successfully. The stale-release check failed on the live baseline and passed on every built page; homepage metadata, press availability, seven-theme copy and the shared store ID were checked in the generated HTML. The 1200x630 social card was visually inspected and re-rendered with the old label removed. Desktop copy was inspected in Chrome. Mobile viewport emulation did not apply to the intended tab reliably, so no new mobile verification is claimed. The detector reported the pre-existing 3px press blockquote border; its CSS was not changed. Astro emitted its existing z80-language fallback warning. No dependencies were added or upgraded.
