# Rachel Landing Page Visual Redesign

**Status:** Approved 2026-07-25
**Repo:** `rachel-multiverse/rachel-site` (Astro 5, static, GitHub Pages)

## Goal

Rebuild `rachel.stevehill.xyz` so it looks like the product it sells and drives
App Store downloads. The page currently uses a generic dark-navy template that
shares no visual language with the game, and ships 17 MB of images.

## Purpose (decided)

**The page exists to convert visitors into downloads.** Success is App Store
taps. Atmosphere and world-building serve that goal; anything that delays the
call to action gets cut. This decision governs every trade-off below — when in
doubt, favour the option that puts a working CTA in front of the visitor sooner.

## Decisions and rationale

| Decision | Choice | Why |
|---|---|---|
| Art direction | The card table itself | The site must look like the app. Reuses assets that already exist; no new illustration needed. |
| Motion | One signature moment | A hero that deals a hand is memorable and cheap. Broad scroll choreography costs more and reads cheap when slightly off. |
| Hero layout | Split (type left, device right) | Only layout where name, promise, price and button all land in the first glance at every screen size. |
| Section order | Differentiator first | The emissaries are the one thing no competing card game has. Rules are table stakes and can wait. |

Rejected: full scroll choreography (cost/risk), retro-computing art direction
(risks reading as "retro demo" not "polished card game"), Apple-style product
slick (least distinctive), keeping the teaching order (buries the differentiator).

## Design tokens

Replace the navy palette in `src/layouts/Layout.astro`:

```
--felt-deep:   #114526
--felt:        #1d6038
--felt-light:  #2e7d4f
--card-stock:  #fdfcf8   /* warm white, not pure #fff */
--ink:         #14171a
--pip-red:     #d1213b
--text:        #f4f2ec
--text-muted:  rgba(255,255,255,0.72)
```

The existing `--color-*` names may stay as aliases if that reduces churn, but no
element may keep the old blue accent `#1d9bf0`.

**Type.** Playfair Display for the wordmark and headings; system sans for body.
Playfair is **self-hosted** as a subset `woff2` under `public/fonts/`, `preload`ed,
with `font-display: swap`. Do not use Google Fonts — the privacy page promises no
third-party tracking, and a self-hosted subset is faster.

## Hero

Two columns on wide viewports, stacked on narrow.

**Left:** wordmark (Playfair), promise line, App Store button, then a quiet meta
line — `iPhone & iPad · £2.99 · No ads, no tracking`.

Exact copy:

- Wordmark: `Rachel`
- Promise: `Shed your hand. Survive the attacks.` / `The last player standing loses.`
  (two lines; the second is the existing tagline and must survive verbatim —
  it is the game's one-line identity)
- Meta: `iPhone & iPad · £2.99 · No ads, no tracking`

The promise line's first sentence is provisional and written by Claude, not
Steve. Replace it if better words exist; the second line is fixed.

**Right:** one phone showing `screenshot-2` (the last-card tension frame), with
playing cards spilling past its edges.

**Background:** radial felt gradient (`--felt-light` centre → `--felt-deep` edge)
plus the *Rachel* watermark in Playfair italic at very low opacity, as in-game.

**The signature moment.** On load, five cards deal into the fan beside the phone:
staggered ~80 ms apart, ~500 ms each, animating `transform` and `opacity` only
(never layout properties), settling at slight individual rotations.

Under `prefers-reduced-motion: reduce` the cards render in their final position
with no animation. This is a hard requirement, not a nicety.

Cards are CSS/HTML elements (rounded rect, corner rank + suit, `--pip-red` or
`--ink`), not images — they scale cleanly and animate on the compositor.

## Section order

1. Hero
2. **The Multiverse + emissaries** — platform chips, the three emissary cards, the landscape iPad shot
3. **How It Works** — the three rules blocks
4. **Play Your Way** — the four mode cards
5. **Closing CTA** — repeat the App Store button on felt
6. Footer

Two upgrades applied while restyling:

- Each emissary card takes **its real accent colour from `Emissary.swift`** rather
  than uniform grey: Sid `rgb(107,115,199)`, Speccy `rgb(217,51,51)`, The Scribe
  `rgb(51,140,140)`. Use as a left border or subtle glow, not a fill.
- The three How It Works blocks become **playing-card shapes** — card stock on
  felt — so the rules literally look like the game.

## Call to action

The app is submitted but not approved, so the button has two states driven by a
single constant (e.g. `const APP_STORE_URL = null` in the page frontmatter):

- **Pre-approval:** reads *Coming soon to the App Store*, styled as a real button
  but visually secondary, not interactive.
- **Post-approval:** set the constant to the live URL; label and `href` switch.

Switching states must be a one-line change. On approval day this is the first
thing that needs updating, and it should not require touching markup or CSS.

## Other pages

`privacy.astro`, `terms.astro` and `support.astro` inherit the new tokens through
`Layout.astro`. They keep their long-form reading layout on a **felt-tinted dark
background**, not full felt — legibility beats atmosphere on a policy page. They
must not retain any blue accent.

## Images

Current payload is 17 MB across four PNGs (`emissary-table` alone is 6.3 MB) —
App Store submission assets copied to the web unmodified. This actively works
against the page's purpose.

- Phone shots: resize to ~400 px wide, convert to WebP
- iPad landscape shot: resize to ~1400 px wide, convert to WebP
- Target total image payload: **under 400 KB**
- Keep the full-resolution originals in `../marketing/screenshots-draft/`; the
  web copies are derived artefacts

Set explicit `width`/`height` on every `<img>` to prevent layout shift, and
`loading="lazy"` on everything below the hero.

## Out of scope

Scroll-triggered animation, parallax, hover choreography on emissary cards, any
JS framework, a CMS, a light/dark toggle, and new photography or illustration.
Felt is the identity; there is no light mode.

## Verification

- Renders correctly at 375 px, 768 px and 1280 px
- Total image payload under 400 KB; page weight under 700 KB
- `prefers-reduced-motion: reduce` disables the deal entirely
- Text on felt meets WCAG AA contrast
- No `#1d9bf0` remains anywhere in the built CSS
- Deploys green to `rachel.stevehill.xyz` and is verified live, not just locally
