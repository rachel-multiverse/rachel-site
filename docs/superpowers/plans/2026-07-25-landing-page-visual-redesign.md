# Rachel Landing Page Visual Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Rachel landing page so it looks like the game it sells and converts visitors into App Store downloads.

**Architecture:** Astro static site. `index.astro` (currently 447 lines) is decomposed into focused single-responsibility components under `src/components/`, with shared design tokens in `src/styles/tokens.css` and the App Store link isolated in `src/config.ts` so approval day is a one-line change. All motion is CSS-only; no JavaScript is added.

**Tech Stack:** Astro 5.16.8, hand-written CSS (no framework, no preprocessor), `cwebp` for images, `pyftsubset` for the font.

**Spec:** `docs/superpowers/specs/2026-07-25-landing-page-visual-redesign-design.md`

## Global Constraints

- Page purpose is **conversion to downloads**. When trading off, favour whatever puts a working CTA in front of the visitor sooner.
- Felt palette exactly: `--felt-deep: #114526`, `--felt: #1d6038`, `--felt-light: #2e7d4f`, `--card-stock: #fdfcf8`, `--ink: #14171a`, `--pip-red: #d1213b`, `--text: #f4f2ec`, `--text-muted: rgba(255,255,255,0.72)`.
- **No `#1d9bf0`** (the old blue accent) may remain anywhere in the built CSS.
- Playfair Display is **self-hosted**. Never load Google Fonts — the privacy page promises no third-party tracking.
- Section order below the hero is fixed: Multiverse/Emissaries → How It Works → Play Your Way → Closing CTA → Footer.
- `prefers-reduced-motion: reduce` must disable the deal animation entirely. Hard requirement.
- Animate `transform` and `opacity` only. Never animate layout properties.
- Total image payload **under 400 KB**; total page weight under 700 KB.
- Every `<img>` carries explicit `width` and `height`. Everything below the hero is `loading="lazy"`.
- Tagline `The last player standing loses.` must survive verbatim — it is the game's identity.
- Out of scope: scroll animation, parallax, hover choreography, any JS framework, a CMS, a light mode.
- Run all commands from `/Users/stevehill/Projects/Rachel/rachel-site`.

## File Structure

| File | Responsibility |
|---|---|
| `src/config.ts` | **Create.** `APP_STORE_URL` — the single approval-day switch. |
| `src/styles/tokens.css` | **Create.** Felt palette, type tokens, `@font-face`. |
| `public/fonts/playfair-display-700.woff2` | **Create.** Subset font, self-hosted. |
| `public/fonts/PlayfairDisplay-OFL.txt` | **Create.** Licence, required by SIL OFL. |
| `src/components/AppStoreButton.astro` | **Create.** Two-state CTA. Sole owner of CTA markup. |
| `src/components/PlayingCard.astro` | **Create.** One card face. Used by hero and How It Works. |
| `src/components/Hero.astro` | **Create.** Split hero + deal animation. |
| `src/components/Emissaries.astro` | **Create.** Multiverse + emissary cast. |
| `src/components/HowItWorks.astro` | **Create.** Three rules, as card shapes. |
| `src/components/PlayYourWay.astro` | **Create.** Four mode cards. |
| `src/components/ClosingCTA.astro` | **Create.** Final conversion prompt. |
| `src/layouts/Layout.astro` | **Modify.** Import tokens; drop the navy palette. |
| `src/pages/index.astro` | **Modify.** Becomes a thin composition file. |
| `src/pages/{privacy,terms,support}.astro` | **Modify.** Inherit tokens; drop blue. |
| `public/images/*.webp` | **Create.** Optimised images. |

---

### Task 1: Self-host Playfair Display

The app already ships this exact font at
`../rachel-ios/RachelApp/RachelApp/Fonts/PlayfairDisplay-VariableFont.ttf` (296 KB).
Subsetting it locally guarantees the site and app render identically.

**Files:**
- Create: `public/fonts/playfair-display-700.woff2`
- Create: `public/fonts/PlayfairDisplay-OFL.txt`

**Interfaces:**
- Produces: a font file at `/fonts/playfair-display-700.woff2` served at site root, referenced by `tokens.css` in Task 2.

- [ ] **Step 1: Verify the conversion tool can emit woff2**

```bash
python3 -c "import brotli; print('brotli OK')"
```

Expected: `brotli OK`. If it prints a `ModuleNotFoundError` instead, install it:

```bash
python3 -m pip install --user brotli
```

If you cannot or will not install `brotli`, substitute `--flavor=woff` for
`--flavor=woff2` in Step 2 and name the output `playfair-display-700.woff`,
updating the `src:` URL and `format('woff2')` → `format('woff')` in Task 2.
WOFF is universally supported; it is roughly 25% larger, which on a ~35 KB
subset is immaterial.

- [ ] **Step 2: Subset and convert the font**

Pinning the variable font to a single weight is a separate tool from subsetting —
`pyftsubset` has no `--instance` flag. Instance first, then subset:

```bash
mkdir -p public/fonts

python3 -m fontTools.varLib.instancer \
  ../rachel-ios/RachelApp/RachelApp/Fonts/PlayfairDisplay-VariableFont.ttf \
  wght=700 -o /tmp/playfair-700.ttf

pyftsubset /tmp/playfair-700.ttf \
  --output-file=public/fonts/playfair-display-700.woff2 \
  --flavor=woff2 \
  --unicodes="U+0020-007E,U+00A0-00FF,U+2018-201D,U+2022,U+2026,U+00B7" \
  --layout-features="kern,liga"
```

`varLib.instancer` pins the font to Bold, the only weight the design uses for
display type. The unicode range covers Latin, Latin-1, smart quotes, the bullet,
the ellipsis and the middot (`·`) used in the meta line.

- [ ] **Step 3: Verify the output is small and valid**

```bash
echo "$(stat -f%z public/fonts/playfair-display-700.woff2) bytes"
python3 -c "
from fontTools.ttLib import TTFont
f = TTFont('public/fonts/playfair-display-700.woff2')
print('flavor:', f.flavor)
print('glyphs:', len(f.getGlyphOrder()))
print('weightClass:', f['OS/2'].usWeightClass)
"
```

Expected: under 40000 bytes, `flavor: woff2`, a glyph count above 200, and
`weightClass: 700`. Actual on first run: 17120 bytes, 239 glyphs. If the file
is larger than 60 KB, the instancer step did not apply — check its output rather
than proceeding.

- [ ] **Step 4: Copy the licence**

SIL OFL requires the licence to travel with the font.

```bash
cp ../rachel-ios/RachelApp/RachelApp/Fonts/PlayfairDisplay-OFL.txt public/fonts/
```

- [ ] **Step 5: Commit**

```bash
git add public/fonts/
git commit -m "Self-host a subset of Playfair Display

Subset from the same variable font the iOS app ships, pinned to weight 700
and to the Latin ranges the site actually uses, so the site and the app
render display type identically.

Self-hosted rather than loaded from Google Fonts: the privacy page promises
no third-party tracking, and a local subset avoids the extra connection."
```

---

### Task 2: Felt design tokens

**Files:**
- Create: `src/styles/tokens.css`
- Modify: `src/layouts/Layout.astro` (replace the `:root` block and `html` rule in its global style)

**Interfaces:**
- Consumes: `/fonts/playfair-display-700.woff2` from Task 1.
- Produces: CSS custom properties `--felt-deep`, `--felt`, `--felt-light`, `--card-stock`, `--ink`, `--pip-red`, `--text`, `--text-muted`, `--font-display`, `--font-sans`, available to every page and component.

- [ ] **Step 1: Write the check that must fail**

Astro inlines a layout's `<style is:global>` into every page's HTML rather than
emitting it to `dist/_astro/*.css`, so the check must search the built HTML:

```bash
npm run build >/dev/null && grep -rl "1d9bf0" dist/
```

Expected now: four paths (`dist/index.html`, `dist/privacy/index.html`,
`dist/support/index.html`, `dist/terms/index.html`) — the old blue accent is
still there. This is the check Task 2 must drive to nothing.

- [ ] **Step 2: Create the tokens file**

Create `src/styles/tokens.css`:

```css
/* The site's palette is the game's card table. Any colour that isn't felt,
   card stock, ink or pip red is a mistake - the page and the app must read
   as one product. */

@font-face {
  font-family: 'Playfair Display';
  src: url('/fonts/playfair-display-700.woff2') format('woff2');
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}

:root {
  --felt-deep: #114526;
  --felt: #1d6038;
  --felt-light: #2e7d4f;
  --card-stock: #fdfcf8;
  --ink: #14171a;
  --pip-red: #d1213b;
  --text: #f4f2ec;
  --text-muted: rgba(255, 255, 255, 0.72);

  --font-display: 'Playfair Display', Georgia, 'Times New Roman', serif;
  --font-sans: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;

  --felt-surface: radial-gradient(ellipse at 50% 30%,
    var(--felt-light) 0%, var(--felt) 45%, var(--felt-deep) 100%);
}
```

- [ ] **Step 3: Wire the tokens into the layout**

In `src/layouts/Layout.astro`, add this import as the first line of the
frontmatter (above `interface Props`):

```astro
---
import '../styles/tokens.css';

interface Props {
```

Then in the same file's `<style is:global>` block, replace the whole `:root { … }`
rule (the one declaring `--color-bg` through `--font-sans`) and the `html` rule
with:

```css
  html {
    font-family: var(--font-sans);
    background: var(--felt-deep);
    color: var(--text);
    line-height: 1.6;
  }

  a {
    color: var(--text);
    text-decoration: underline;
    text-underline-offset: 2px;
  }

  a:hover {
    text-decoration: none;
  }
```

Delete the old `:root` block entirely — `tokens.css` owns the palette now.

- [ ] **Step 4: Add a preload so display type doesn't flash**

In `src/layouts/Layout.astro`, inside `<head>` immediately after the
`<meta name="description" …>` line:

```astro
    <link
      rel="preload"
      href="/fonts/playfair-display-700.woff2"
      as="font"
      type="font/woff2"
      crossorigin
    />
```

- [ ] **Step 5: Run the check and confirm it now passes**

```bash
npm run build >/dev/null && grep -rl "1d9bf0" dist/ || echo "PASS: no blue accent remains"
```

Expected: `PASS: no blue accent remains`. If paths print instead, find the
offender with `grep -rn "1d9bf0" src/` and replace it with a token.

- [ ] **Step 6: Commit**

```bash
git add src/styles/tokens.css src/layouts/Layout.astro
git commit -m "Replace the navy palette with the game's card table

The site used generic dark-navy tokens and a blue accent that appear
nowhere in the app, which is much of why it read as a template rather than
as Rachel. Palette is now felt, card stock, ink and pip red, with Playfair
Display carrying display type as it does in-game.

Tokens live in their own file so every page and component shares one
source of truth."
```

---

### Task 3: App Store button with its approval-day switch

**Files:**
- Create: `src/config.ts`
- Create: `src/components/AppStoreButton.astro`

**Interfaces:**
- Produces: `APP_STORE_URL: string | null` exported from `src/config.ts`; `<AppStoreButton />` accepting optional `size?: 'large' | 'normal'` (default `'normal'`).

- [ ] **Step 1: Create the config constant**

Create `src/config.ts`:

```ts
/**
 * The App Store URL, or null while the app is still in review.
 *
 * This is the whole approval-day switch. When Apple approves Rachel, set this
 * to the real product URL and every call to action on the site goes live at
 * once. Do not scatter the URL through the markup.
 */
export const APP_STORE_URL: string | null = null;
```

- [ ] **Step 2: Create the button component**

Create `src/components/AppStoreButton.astro`:

```astro
---
import { APP_STORE_URL } from '../config';

interface Props {
  size?: 'large' | 'normal';
}

const { size = 'normal' } = Astro.props;
const live = APP_STORE_URL !== null;
const label = live ? 'Download on the App Store' : 'Coming soon to the App Store';
---

{live ? (
  <a href={APP_STORE_URL} class:list={['cta', size]}>
    <svg class="apple" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
    </svg>
    {label}
  </a>
) : (
  <span class:list={['cta', 'pending', size]} aria-disabled="true">
    <svg class="apple" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
    </svg>
    {label}
  </span>
)}

<style>
  .cta {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.875rem 1.5rem;
    background: var(--card-stock);
    color: var(--ink);
    border-radius: 0.6rem;
    font-weight: 700;
    text-decoration: none;
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.32);
    transition: transform 0.2s ease, box-shadow 0.2s ease;
  }

  .cta.large {
    padding: 1rem 1.75rem;
    font-size: 1.0625rem;
  }

  a.cta:hover {
    text-decoration: none;
    transform: translateY(-2px);
    box-shadow: 0 10px 26px rgba(0, 0, 0, 0.4);
  }

  /* Pre-approval the button is honest about its state: present, so the page
     composes correctly, but plainly not yet clickable. */
  .cta.pending {
    background: rgba(253, 252, 248, 0.22);
    color: var(--text);
    box-shadow: none;
    cursor: default;
  }

  .apple {
    width: 1.15rem;
    height: 1.15rem;
    flex-shrink: 0;
  }

  @media (prefers-reduced-motion: reduce) {
    .cta { transition: none; }
    a.cta:hover { transform: none; }
  }
</style>
```

- [ ] **Step 3: Verify both states compile**

```bash
npm run build && echo "BUILD OK"
```

Expected: `BUILD OK`. Then temporarily set `APP_STORE_URL` to
`'https://apps.apple.com/app/id000000000'`, run `npm run build` again, confirm
it still succeeds, and **set it back to `null`** before committing.

- [ ] **Step 4: Commit**

```bash
git add src/config.ts src/components/AppStoreButton.astro
git commit -m "Add the App Store button as a single two-state component

The app is submitted but not approved, so every call to action needs to
read 'coming soon' today and become a real link the moment Apple says yes.
Routing both states through one component driven by one constant makes
approval day a one-line change instead of a hunt through markup."
```

---

### Task 4: Playing card component

**Files:**
- Create: `src/components/PlayingCard.astro`

**Interfaces:**
- Produces: `<PlayingCard rank="A" suit="hearts" />` accepting `rank: string`, `suit: 'hearts' | 'diamonds' | 'clubs' | 'spades'`, and optional `class?: string` for positioning by the parent.

- [ ] **Step 1: Create the component**

Create `src/components/PlayingCard.astro`:

```astro
---
interface Props {
  rank: string;
  suit: 'hearts' | 'diamonds' | 'clubs' | 'spades';
  class?: string;
}

const { rank, suit, class: className = '' } = Astro.props;

const GLYPHS = {
  hearts: '♥',
  diamonds: '♦',
  clubs: '♣',
  spades: '♠',
} as const;

const red = suit === 'hearts' || suit === 'diamonds';
---

<div class:list={['card', red ? 'red' : 'black', className]} aria-hidden="true">
  <span class="rank">{rank}</span>
  <span class="suit">{GLYPHS[suit]}</span>
</div>

<style>
  /* Cards are markup, not images: they stay crisp at any size and animate on
     the compositor rather than forcing layout. */
  .card {
    width: var(--card-w, 68px);
    height: calc(var(--card-w, 68px) * 1.4);
    background: var(--card-stock);
    border-radius: calc(var(--card-w, 68px) * 0.09);
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.34);
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    padding: calc(var(--card-w, 68px) * 0.08);
    font-family: var(--font-display);
    line-height: 1;
    box-sizing: border-box;
  }

  .red { color: var(--pip-red); }
  .black { color: var(--ink); }

  .rank {
    font-size: calc(var(--card-w, 68px) * 0.28);
    font-weight: 700;
  }

  .suit {
    font-size: calc(var(--card-w, 68px) * 0.26);
    margin-top: calc(var(--card-w, 68px) * 0.02);
  }
</style>
```

The card sizes itself from a `--card-w` custom property the parent sets, so one
component serves both the small hero fan and the larger How It Works cards.

- [ ] **Step 2: Verify it builds**

```bash
npm run build && echo "BUILD OK"
```

Expected: `BUILD OK`.

- [ ] **Step 3: Commit**

```bash
git add src/components/PlayingCard.astro
git commit -m "Add a reusable playing card component

Cards are HTML rather than images so they stay sharp at any size, animate
on the compositor, and cost no bytes. Size comes from a --card-w property
the parent sets, so the hero fan and the rules cards share one component."
```

---

### Task 5: Optimise the images

The site currently ships 17 MB of images because App Store submission assets
were copied to the web unmodified. On a phone that is a page people abandon
before it renders, which defeats the point of a conversion page.

**Files:**
- Create: `public/images/screenshot-1.webp`, `screenshot-2.webp`, `screenshot-3.webp`, `emissary-table.webp`
- Delete: the four corresponding `.png` files

**Interfaces:**
- Produces: four WebP files, referenced by Tasks 6 and 7.

- [ ] **Step 1: Record the starting payload**

```bash
du -ch public/images/*.png | tail -1
```

Expected: roughly `17M total`. This is the number the task must cut.

- [ ] **Step 2: Resize and convert**

```bash
cd public/images
for n in 1 2 3; do
  cp screenshot-$n.png /tmp/s$n.png
  sips --resampleWidth 400 /tmp/s$n.png >/dev/null
  cwebp -q 82 /tmp/s$n.png -o screenshot-$n.webp
done
cp emissary-table.png /tmp/et.png
sips --resampleWidth 1400 /tmp/et.png >/dev/null
cwebp -q 82 /tmp/et.png -o emissary-table.webp
cd ../..
```

Phones display at roughly 200 px wide, so 400 px covers 2× screens. The iPad
shot spans the content column, so 1400 px covers it.

- [ ] **Step 3: Verify the budget is met**

```bash
du -ch public/images/*.webp | tail -1
for f in public/images/*.webp; do
  printf "%-28s %s\n" "$(basename $f)" "$(sips -g pixelWidth -g pixelHeight $f | tail -2 | tr -d ' \n')"
done
```

Expected: total well under 400 KB, phone shots 400 px wide, iPad shot 1400 px
wide. If the total exceeds 400 KB, re-run Step 2 with `-q 75`.

- [ ] **Step 4: Remove the originals**

The full-resolution masters remain in `../marketing/screenshots-draft/`; these
web copies are derived artefacts and should not be duplicated at full size.

```bash
rm public/images/screenshot-1.png public/images/screenshot-2.png \
   public/images/screenshot-3.png public/images/emissary-table.png
```

- [ ] **Step 5: Commit**

```bash
git add -A public/images/
git commit -m "Cut the image payload from 17MB to under 400KB

App Store submission assets had been copied to the web unmodified - four
PNGs totalling 17MB, one of them 6.3MB. On a phone that is a page people
leave before it renders, which works directly against the only thing this
page exists to do.

Resized to the sizes actually displayed and converted to WebP. The
full-resolution masters stay in ../marketing/screenshots-draft/."
```

---

### Task 6: The hero

**Files:**
- Create: `src/components/Hero.astro`

**Interfaces:**
- Consumes: `<AppStoreButton size="large" />` (Task 3), `<PlayingCard>` (Task 4), `/images/screenshot-2.webp` (Task 5).
- Produces: `<Hero />`, no props.

- [ ] **Step 1: Create the hero**

Create `src/components/Hero.astro`:

```astro
---
import AppStoreButton from './AppStoreButton.astro';
import PlayingCard from './PlayingCard.astro';

// Fanned hand beside the phone. Each card deals in with its own delay and
// settles at its own angle, so the arc looks thrown rather than placed.
const HAND = [
  { rank: 'K', suit: 'spades',   rot: -14, x: -104, y: 16,  delay: 0 },
  { rank: '7', suit: 'diamonds', rot: -7,  x: -52,  y: 4,   delay: 80 },
  { rank: '2', suit: 'clubs',    rot: 0,   x: 0,    y: 0,   delay: 160 },
  { rank: 'A', suit: 'hearts',   rot: 7,   x: 52,   y: 4,   delay: 240 },
  { rank: 'J', suit: 'spades',   rot: 14,  x: 104,  y: 16,  delay: 320 },
] as const;
---

<section class="hero">
  <div class="container">
    <div class="copy">
      <h1>Rachel</h1>
      <p class="promise">
        Shed your hand. Survive the attacks.<br />
        The last player standing loses.
      </p>
      <AppStoreButton size="large" />
      <p class="meta">iPhone &amp; iPad · £2.99 · No ads, no tracking</p>
    </div>

    <div class="stage">
      <img
        src="/images/screenshot-2.webp"
        alt="A Rachel game in progress, with an opponent down to their last card"
        width="400"
        height="866"
        class="phone"
      />
      <div class="hand">
        {HAND.map((c) => (
          <PlayingCard
            rank={c.rank}
            suit={c.suit}
            class="dealt"
            style={`--rot:${c.rot}deg; --x:${c.x}px; --y:${c.y}px; --delay:${c.delay}ms`}
          />
        ))}
      </div>
    </div>
  </div>
</section>

<style>
  .hero {
    background: var(--felt-surface);
    position: relative;
    overflow: hidden;
    padding: 4.5rem 0 5rem;
  }

  /* The same felt watermark the game puts on its table. */
  .hero::before {
    content: 'Rachel';
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: var(--font-display);
    font-style: italic;
    font-size: clamp(9rem, 26vw, 22rem);
    color: rgba(255, 255, 255, 0.04);
    pointer-events: none;
    user-select: none;
    white-space: nowrap;
  }

  .container {
    position: relative;
    z-index: 1;
    max-width: 1080px;
    margin: 0 auto;
    padding: 0 1.5rem;
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 3rem;
    align-items: center;
  }

  h1 {
    font-family: var(--font-display);
    font-size: clamp(3.25rem, 8vw, 5.5rem);
    line-height: 0.95;
    margin-bottom: 1.25rem;
    text-shadow: 0 2px 18px rgba(0, 0, 0, 0.35);
  }

  .promise {
    font-size: clamp(1.0625rem, 2.2vw, 1.3rem);
    color: var(--text);
    margin-bottom: 1.75rem;
    max-width: 26rem;
  }

  .meta {
    margin-top: 1rem;
    font-size: 0.875rem;
    color: var(--text-muted);
  }

  .stage {
    position: relative;
    display: flex;
    justify-content: center;
  }

  .phone {
    width: min(260px, 70%);
    height: auto;
    border-radius: 1.6rem;
    box-shadow: 0 0 0 8px #1c1c1e, 0 0 0 10px #3a3a3c,
      0 26px 50px rgba(0, 0, 0, 0.5);
    position: relative;
    z-index: 2;
  }

  .hand {
    position: absolute;
    bottom: -1.5rem;
    left: 50%;
    transform: translateX(-50%);
    z-index: 3;
    --card-w: 62px;
  }

  .hand :global(.dealt) {
    position: absolute;
    bottom: 0;
    left: 0;
    animation: deal 500ms cubic-bezier(0.2, 0.7, 0.3, 1) both;
    animation-delay: var(--delay);
  }

  /* Cards fly in from the deck's position at centre, then settle into the arc.
     Transform and opacity only - both run on the compositor. */
  @keyframes deal {
    from {
      transform: translate(0, -120px) rotate(0deg) scale(0.86);
      opacity: 0;
    }
    to {
      transform: translate(var(--x), var(--y)) rotate(var(--rot)) scale(1);
      opacity: 1;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .hand :global(.dealt) {
      animation: none;
      transform: translate(var(--x), var(--y)) rotate(var(--rot));
      opacity: 1;
    }
  }

  @media (max-width: 820px) {
    .container {
      grid-template-columns: 1fr;
      gap: 3.5rem;
      text-align: center;
    }
    .promise { margin-inline: auto; }
    .stage { margin-top: 0.5rem; }
    .hand { --card-w: 52px; }
  }
</style>
```

- [ ] **Step 2: Mount it so you can see it**

In `src/pages/index.astro`, add to the frontmatter:

```astro
import Hero from '../components/Hero.astro';
```

and replace the entire existing `<section class="hero"> … </section>` block
(the one containing `<h1>Rachel</h1>`, the `.screenshots` div and the `.cta`
div) with:

```astro
    <Hero />
```

- [ ] **Step 3: Verify the deal animation and its reduced-motion fallback**

```bash
npm run build && npx astro preview --port 4324 &
sleep 4
curl -s -o /dev/null -w "preview %{http_code}\n" http://localhost:4324/
```

Open `http://localhost:4324/` and confirm: five cards deal in sequence and
settle in a fan; the phone sits behind them; the wordmark, promise, button and
meta line all sit left on desktop and centred below 820 px.

Then verify the accessibility requirement — in Chrome DevTools open the Command
Menu (⌘⇧P), run **"Emulate CSS prefers-reduced-motion: reduce"**, and reload.
Expected: cards appear instantly in their final fanned positions with no
movement at all. Stop the preview with `pkill -f "astro preview --port 4324"`.

- [ ] **Step 4: Commit**

```bash
git add src/components/Hero.astro src/pages/index.astro
git commit -m "Rebuild the hero as a split layout on felt

Name, promise, button and price now land in a single glance at every width,
which the old centred stack of three small phone mockups did not - its
call to action sat below the fold on mobile.

The hand deals in on load as the page's one piece of motion, animating
only transform and opacity, and renders instantly in place under
prefers-reduced-motion."
```

---

### Task 7: The emissaries section

**Files:**
- Create: `src/components/Emissaries.astro`
- Modify: `src/pages/index.astro`

**Interfaces:**
- Consumes: `/images/emissary-table.webp` (Task 5).
- Produces: `<Emissaries />`, no props.

Accent colours are the emissaries' real values from
`../rachel-ios/RachelApp/RachelApp/Game/Emissary.swift`, converted from Swift's
0–1 floats to 0–255: Sid `Color(0.42, 0.45, 0.78)` → `rgb(107,115,199)`,
Speccy `Color(0.85, 0.2, 0.2)` → `rgb(217,51,51)`, The Scribe
`Color(0.2, 0.55, 0.55)` → `rgb(51,140,140)`.

- [ ] **Step 1: Create the component**

Create `src/components/Emissaries.astro`:

```astro
---
const PLATFORMS = [
  'ZX Spectrum', 'Commodore 64', 'Amiga', 'NES', 'Game Boy',
  'Atari ST', 'Apple II', 'MS-DOS', '+25 more',
];

// Names, universe codes, lore and accent colours are taken verbatim from
// Emissary.swift so the site and the app describe the cast identically.
const CAST = [
  {
    name: 'Sid',
    universe: 'C64-1982',
    accent: 'rgb(107,115,199)',
    lore: 'From a universe of three-voice symphonies and 64 honest kilobytes. Smug about it.',
  },
  {
    name: 'Speccy',
    universe: 'ZX-1984',
    accent: 'rgb(217,51,51)',
    lore: 'From a universe of bedroom coders, rubber keys, and glorious clashing colour. Plays chaos.',
  },
  {
    name: 'The Scribe',
    universe: 'MAMLUK-1370',
    accent: 'rgb(51,140,140)',
    lore: 'From the origin universe — the first Rachel, before the world knew it. Teaches while winning.',
  },
];
---

<section class="multiverse">
  <div class="container">
    <h2>Their emissaries got here first</h2>
    <p class="intro">
      Rachel is being ported to every computing platform that ever existed.
      You don't have to wait for the ports to meet the multiverse — fourteen
      emissaries already sit at your table, and they don't all come from machines.
    </p>

    <img
      src="/images/emissary-table.webp"
      alt="Three emissaries seated around the Rachel table on iPad, each with their universe's badge and colour"
      width="1400"
      height="1050"
      loading="lazy"
      class="shot"
    />

    <div class="cast">
      {CAST.map((e) => (
        <article class="emissary" style={`--accent:${e.accent}`}>
          <h3>{e.name}</h3>
          <p class="universe">{e.universe}</p>
          <p class="lore">{e.lore}</p>
        </article>
      ))}
    </div>

    <p class="note">
      The rift runs through time as well as hardware: a medieval copyist, a
      Victorian gambler, a deco card sharp, a neon-lit ghost from 2077. Each
      plays differently, and each has something to say about how you're doing.
    </p>

    <div class="platforms">
      {PLATFORMS.map((p) => <span>{p}</span>)}
    </div>
    <p class="note">
      Same rules. Same 64-byte protocol. A ZX Spectrum can play against an
      iPhone. This is the plan.
    </p>
  </div>
</section>

<style>
  .multiverse {
    background: var(--felt-deep);
    padding: 5rem 0;
    text-align: center;
  }

  .container {
    max-width: 1000px;
    margin: 0 auto;
    padding: 0 1.5rem;
  }

  h2 {
    font-family: var(--font-display);
    font-size: clamp(1.9rem, 4.5vw, 2.75rem);
    margin-bottom: 1rem;
  }

  .intro {
    color: var(--text-muted);
    max-width: 42rem;
    margin: 0 auto 2.5rem;
  }

  .shot {
    width: 100%;
    height: auto;
    border-radius: 0.9rem;
    border: 1px solid rgba(255, 255, 255, 0.12);
    box-shadow: 0 18px 44px rgba(0, 0, 0, 0.4);
    margin-bottom: 3rem;
  }

  .cast {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
    gap: 1.5rem;
    text-align: left;
    margin-bottom: 2rem;
  }

  /* Each emissary carries their own universe's colour, the same one their
     seat uses in game. */
  .emissary {
    padding: 1.5rem;
    background: rgba(255, 255, 255, 0.045);
    border-radius: 0.75rem;
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-left: 3px solid var(--accent);
  }

  .emissary h3 {
    font-family: var(--font-display);
    font-size: 1.25rem;
    margin-bottom: 0.15rem;
  }

  .universe {
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: 0.72rem;
    letter-spacing: 0.04em;
    color: var(--accent);
    margin-bottom: 0.6rem;
  }

  .lore {
    color: var(--text-muted);
    font-size: 0.9375rem;
  }

  .note {
    color: var(--text-muted);
    font-size: 0.9375rem;
    font-style: italic;
    max-width: 44rem;
    margin: 0 auto 2rem;
  }

  .platforms {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 0.6rem;
    margin-bottom: 1.5rem;
  }

  .platforms span {
    padding: 0.35rem 0.8rem;
    background: rgba(255, 255, 255, 0.08);
    border-radius: 1rem;
    font-size: 0.8125rem;
    color: var(--text-muted);
  }
</style>
```

- [ ] **Step 2: Mount it directly after the hero**

In `src/pages/index.astro` frontmatter add:

```astro
import Emissaries from '../components/Emissaries.astro';
```

and place `<Emissaries />` immediately after `<Hero />`, **before** the existing
`<section class="features">`. Then delete the old
`<section class="multiverse"> … </section>` block near the bottom of the file
and its associated styles (`.multiverse`, `.multiverse-intro`, `.platforms`,
`.platforms span`, `.multiverse-note`, `.emissary-heading`, `.emissary-intro`,
`.emissary-shot`, `.emissaries`, `.emissary`, `.emissary .universe`,
`.emissary p`) from the page's `<style>` block — the component owns them now.

- [ ] **Step 3: Verify**

```bash
npm run build && grep -c "emissary-table.webp" dist/index.html
```

Expected: `1`. Then preview and confirm the emissaries now appear immediately
below the hero, each card carrying its own accent colour on the left edge, and
that the old duplicate multiverse section is gone.

- [ ] **Step 4: Commit**

```bash
git add src/components/Emissaries.astro src/pages/index.astro
git commit -m "Lead with the emissaries instead of burying them

The cast is the one thing no competing card game has, and it sat at the
very bottom of the page behind a rules explanation every card game also
has. It now runs directly under the hero.

Each emissary carries their real accent colour from Emissary.swift, so a
visitor meets the same Sid violet and Speccy red they will see in game."
```

---

### Task 8: Rules, modes, closing CTA, and page composition

**Files:**
- Create: `src/components/HowItWorks.astro`
- Create: `src/components/PlayYourWay.astro`
- Create: `src/components/ClosingCTA.astro`
- Modify: `src/pages/index.astro`

**Interfaces:**
- Consumes: `<PlayingCard>` (Task 4), `<AppStoreButton>` (Task 3).
- Produces: `<HowItWorks />`, `<PlayYourWay />`, `<ClosingCTA />`, no props.

- [ ] **Step 1: Create HowItWorks with card-shaped rules**

Create `src/components/HowItWorks.astro`:

```astro
---
import PlayingCard from './PlayingCard.astro';

const RULES = [
  {
    rank: '8', suit: 'clubs' as const,
    title: 'Match cards',
    body: "Play cards that match the top card by suit or rank. Can't play? Draw from the deck.",
  },
  {
    rank: 'J', suit: 'spades' as const,
    title: 'Special cards',
    body: '2s force draws, 7s skip players, Black Jacks attack, Red Jacks defend, Queens reverse, Aces change suit.',
  },
  {
    rank: 'A', suit: 'hearts' as const,
    title: 'Last one loses',
    body: 'Empty your hand to get out. The last player still holding cards loses the game.',
  },
];
---

<section class="how">
  <div class="container">
    <h2>How it works</h2>
    <div class="rules">
      {RULES.map((r) => (
        <article class="rule">
          <PlayingCard rank={r.rank} suit={r.suit} />
          <h3>{r.title}</h3>
          <p>{r.body}</p>
        </article>
      ))}
    </div>
  </div>
</section>

<style>
  .how {
    background: var(--felt);
    padding: 5rem 0;
  }

  .container {
    max-width: 1000px;
    margin: 0 auto;
    padding: 0 1.5rem;
  }

  h2 {
    font-family: var(--font-display);
    font-size: clamp(1.9rem, 4.5vw, 2.75rem);
    text-align: center;
    margin-bottom: 2.5rem;
  }

  .rules {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
    gap: 2.5rem;
  }

  .rule {
    text-align: center;
    display: flex;
    flex-direction: column;
    align-items: center;
    --card-w: 76px;
  }

  .rule h3 {
    font-family: var(--font-display);
    font-size: 1.25rem;
    margin: 1.25rem 0 0.5rem;
  }

  .rule p {
    color: var(--text-muted);
    font-size: 0.9375rem;
  }
</style>
```

- [ ] **Step 2: Create PlayYourWay**

Create `src/components/PlayYourWay.astro`:

```astro
---
const MODES = [
  { title: 'Solo', body: 'Face the emissaries of the multiverse, at Easy, Medium, or Hard.' },
  { title: 'Local multiplayer', body: 'Play with friends nearby using Game Center or local networking.' },
  { title: 'iPhone & iPad', body: 'One universal app. On iPad the table opens into a full horseshoe.' },
  { title: 'Online', body: 'Coming soon: play with anyone, anywhere.', soon: true },
];
---

<section class="modes-section">
  <div class="container">
    <h2>Play your way</h2>
    <div class="modes">
      {MODES.map((m) => (
        <article class:list={['mode', m.soon && 'soon']}>
          <h3>{m.title}</h3>
          <p>{m.body}</p>
        </article>
      ))}
    </div>
  </div>
</section>

<style>
  .modes-section {
    background: var(--felt-deep);
    padding: 5rem 0;
  }

  .container {
    max-width: 1000px;
    margin: 0 auto;
    padding: 0 1.5rem;
  }

  h2 {
    font-family: var(--font-display);
    font-size: clamp(1.9rem, 4.5vw, 2.75rem);
    text-align: center;
    margin-bottom: 2.5rem;
  }

  .modes {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
    gap: 1.5rem;
  }

  .mode {
    padding: 1.5rem;
    background: rgba(255, 255, 255, 0.045);
    border-radius: 0.75rem;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .mode h3 {
    font-family: var(--font-display);
    font-size: 1.2rem;
    margin-bottom: 0.5rem;
  }

  .mode p {
    color: var(--text-muted);
    font-size: 0.9375rem;
  }

  .mode.soon { opacity: 0.68; }
</style>
```

- [ ] **Step 3: Create ClosingCTA**

Create `src/components/ClosingCTA.astro`:

```astro
---
import AppStoreButton from './AppStoreButton.astro';
---

<section class="closing">
  <div class="container">
    <h2>Take a seat</h2>
    <p>Fourteen emissaries are waiting, and none of them intend to lose.</p>
    <AppStoreButton size="large" />
    <p class="meta">iPhone &amp; iPad · £2.99 · No ads, no tracking</p>
  </div>
</section>

<style>
  .closing {
    background: var(--felt-surface);
    padding: 5.5rem 0;
    text-align: center;
  }

  .container {
    max-width: 640px;
    margin: 0 auto;
    padding: 0 1.5rem;
  }

  h2 {
    font-family: var(--font-display);
    font-size: clamp(2rem, 5vw, 3rem);
    margin-bottom: 0.75rem;
  }

  .closing p {
    color: var(--text-muted);
    margin-bottom: 1.75rem;
  }

  .meta {
    margin-top: 1rem;
    font-size: 0.875rem;
  }
</style>
```

- [ ] **Step 4: Reduce index.astro to composition**

Replace the entire contents of `src/pages/index.astro` with:

```astro
---
import Layout from '../layouts/Layout.astro';
import Hero from '../components/Hero.astro';
import Emissaries from '../components/Emissaries.astro';
import HowItWorks from '../components/HowItWorks.astro';
import PlayYourWay from '../components/PlayYourWay.astro';
import ClosingCTA from '../components/ClosingCTA.astro';
---

<Layout title="Rachel - A Strategic Card Game">
  <main>
    <Hero />
    <Emissaries />
    <HowItWorks />
    <PlayYourWay />
    <ClosingCTA />

    <footer>
      <div class="container">
        <nav>
          <a href="/privacy">Privacy</a>
          <a href="/terms">Terms</a>
          <a href="/support">Support</a>
        </nav>
        <p class="copyright">&copy; 2026 Steve Hill</p>
      </div>
    </footer>
  </main>
</Layout>

<style>
  footer {
    padding: 3rem 0;
    background: var(--felt-deep);
    border-top: 1px solid rgba(255, 255, 255, 0.1);
    text-align: center;
  }

  .container {
    max-width: 1000px;
    margin: 0 auto;
    padding: 0 1.5rem;
  }

  nav {
    display: flex;
    justify-content: center;
    gap: 2rem;
    margin-bottom: 1rem;
  }

  .copyright {
    color: var(--text-muted);
    font-size: 0.875rem;
  }
</style>
```

- [ ] **Step 5: Verify the page shrank and still builds**

```bash
wc -l < src/pages/index.astro
npm run build && echo "BUILD OK"
```

Expected: under 60 lines (from 447), and `BUILD OK`.

- [ ] **Step 6: Commit**

```bash
git add src/components/HowItWorks.astro src/components/PlayYourWay.astro \
        src/components/ClosingCTA.astro src/pages/index.astro
git commit -m "Split the page into components and add a closing call to action

index.astro had grown to 447 lines holding every section's markup and CSS
at once. Each section is now its own component owning its own styles, and
the page is a 50-line composition file.

Adds a closing call to action so a visitor who reads to the end has
somewhere to go without scrolling back up."
```

---

### Task 9: Inner pages and final verification

**Files:**
- Modify: `src/pages/privacy.astro`, `src/pages/terms.astro`, `src/pages/support.astro`

**Interfaces:**
- Consumes: tokens from Task 2.

- [ ] **Step 1: Retint the three long-form pages**

In each of `privacy.astro`, `terms.astro` and `support.astro`, replace these
declarations inside their `<style>` blocks:

- `color: var(--color-text-muted);` → `color: var(--text-muted);`
- `color: var(--color-text);` → `color: var(--text);`
- `border-top: 1px solid rgba(255,255,255,0.1);` — leave as is

Then add this rule at the top of each file's `<style>` block:

```css
  .legal {
    background: var(--felt-deep);
    padding: 4rem 0;
  }
```

replacing the existing `.legal { padding: 4rem 0; }` rule. These pages keep a
flat dark felt background rather than the gradient — legibility beats atmosphere
on a policy page.

- [ ] **Step 2: Confirm no stale token names survive**

```bash
grep -rn "color-bg\|color-text\|color-accent\|color-green\|color-red" src/ || echo "PASS: no stale tokens"
```

Expected: `PASS: no stale tokens`. Fix any hits by mapping to the new names.

- [ ] **Step 3: Run the full spec verification**

```bash
npm run build
echo "--- no blue accent ---"
grep -rl "1d9bf0" dist/ || echo "PASS"
echo "--- image payload ---"
du -ch dist/images/* | tail -1
echo "--- total page weight ---"
du -sh dist | tail -1
echo "--- explicit dimensions on every image ---"
grep -o "<img[^>]*>" dist/index.html | grep -c "width=" 
grep -o "<img[^>]*>" dist/index.html | wc -l
```

Expected: `PASS` for the accent; image payload under 400 KB; the last two
numbers equal (every `<img>` has a `width`).

- [ ] **Step 4: Check the three viewports and reduced motion**

```bash
npx astro preview --port 4325 &
sleep 4
```

At `http://localhost:4325/`, confirm at 375 px, 768 px and 1280 px: nothing
overflows horizontally, the hero CTA is visible without scrolling at 375 px, and
text on felt is comfortably readable. Then emulate
`prefers-reduced-motion: reduce` and reload — the cards must not move.

```bash
pkill -f "astro preview --port 4325"
```

- [ ] **Step 5: Commit and deploy**

```bash
git add src/pages/privacy.astro src/pages/terms.astro src/pages/support.astro
git commit -m "Bring the policy pages onto the felt palette

The privacy, terms and support pages still carried the old navy tokens and
would have clashed with the redesigned landing page. They take a flat felt
background rather than the gradient - on a page someone is actually
reading, legibility beats atmosphere."
git push origin main
```

- [ ] **Step 6: Verify the deployed site, not just the local build**

```bash
until curl -s -L --max-time 15 https://rachel.stevehill.xyz/ | grep -q "emissaries got here first"; do sleep 5; done
echo "--- live checks ---"
curl -s -L https://rachel.stevehill.xyz/ | grep -c "1d9bf0" | grep -q '^0$' \
  && echo "PASS: no blue accent live" || echo "FAIL: blue accent still live"
for p in / /privacy /terms /support; do
  echo "$(curl -s -o /dev/null -w '%{http_code}' -L https://rachel.stevehill.xyz$p)  $p"
done
```

Expected: `PASS: no blue accent live`, and `200` for all four pages.

---

## Self-Review

**Spec coverage.** Purpose → Global Constraints. Tokens → Task 2. Self-hosted
Playfair → Task 1. Hero split + copy + deal + reduced motion → Task 6. Section
order → Task 8 Step 4. Emissary accent colours → Task 7. Card-shaped rules →
Task 8 Step 1. Two-state CTA → Task 3. Inner pages → Task 9. Images under
400 KB → Task 5. Verification list → Task 9 Steps 3, 4 and 6. No gaps.

**Type consistency.** `APP_STORE_URL` is declared in Task 3 and consumed only
through `AppStoreButton`. `PlayingCard` props (`rank`, `suit`, `class`) are
defined in Task 4 and used with those exact names in Tasks 6 and 8. `--card-w`
is declared in Task 4 and set by parents in Tasks 6 and 8. Image filenames
created in Task 5 match those referenced in Tasks 6 and 7.

**Known latitude.** The hero's first promise line is Claude's wording, flagged
in the spec as replaceable. Task 6 Step 1 contains it inline; changing it is a
one-line edit to `Hero.astro`.
