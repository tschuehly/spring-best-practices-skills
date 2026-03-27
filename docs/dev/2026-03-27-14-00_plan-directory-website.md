# Plan: JVM Skills Directory Website

> Spec: [spec.md](./spec.md)

## Architectural Decisions

- **No database** — YAML files are the data layer, shell script generates static HTML
- **Routes**: Single-page site at `jvmskills.com` (GitHub Pages). All skills on one `index.html`.
- **Schema**: `skills/<category>/<name>.yaml` per the spec's field reference.
- **Build**: `build-site.sh` reads YAML + `template.html` → `dist/index.html`. Requires `yq` for YAML parsing.
- **Hosting**: GitHub Pages with custom domain `jvmskills.com`
- **Categories**: `database`, `web`, `infrastructure`, `testing`, `architecture`, `workflow`
- **Trust model**: Each skill has a `trust` field (`official`, `curated`, `community`)

### Design Aesthetic: Terminal / CLI

The site targets JVM developers — people who live in terminals, read stack traces, and appreciate precision over flash. The aesthetic leans into that identity:

- **Terminal-inspired UI** — monospace typography, command-prompt motifs, blinking cursors, syntax-highlighted accents
- **Dark-first** — dark background as default (like an IDE/terminal), with a light mode toggle
- **Color palette** — green-on-dark (`#00ff41` / phosphor green) as primary accent, muted grays for structure, syntax-highlighting colors (amber for strings, cyan for keywords) as secondary accents
- **Typography** — monospace display font (JetBrains Mono or similar) for headings and badges, clean sans-serif for body readability
- **Cards** — styled like terminal windows with title bars, category rendered as a file path (`~/skills/database/`), trust badges as inline terminal tags (`[EXPERT]`, `[COMMUNITY]`)
- **Animations** — subtle: typewriter effect on hero text, cursor blink on search input, smooth card reveals on filter
- **No generic AI aesthetic** — no purple gradients, no rounded-everything, no Inter font

---

## Phase 0: Seed Content

Create the YAML data layer — skill listings.

### Tasks
- [ ] `skills/database/jooq.yaml` — jOOQ Best Practices listing (repo: `jvm-skills/jooq-skill`, author: Lukas Eder, trust: curated)
- [ ] 4-5 additional seed skill YAML files across different categories (use spec examples: jpa, flyway, spring-core, jte, testcontainers, spring-boot-testing, hexagonal, grill-me, prd-to-plan)
- [ ] Verify all YAML files parse correctly with `yq`
- [ ] `/commit`

---

## Phase 1: Site Generation + Terminal Design

Build script and HTML template that produce a browsable single-page site with the terminal aesthetic.

### Tasks
- [ ] `/frontend-design` — design the full page layout with terminal aesthetic (hero, category sections, skill cards, footer)
- [ ] `template.html` — responsive HTML with embedded CSS/JS. Skill cards show: name, description, author, trust badge, tools, languages, tags. Cards grouped by category with section headers styled as directory paths.
- [ ] Cards link directly to `https://github.com/{repo}` — no detail pages
- [ ] Trust badges render as `[EXPERT]` or `[COMMUNITY]` with distinct terminal-style coloring
- [ ] **Dark/light mode** — dark as default, toggle switch in header, preference saved to `localStorage`, respects `prefers-color-scheme`
- [ ] **SEO meta tags** — `<title>`, `<meta description>`, Open Graph (`og:title`, `og:description`, `og:image`, `og:url`), Twitter card meta
- [ ] **Favicon** — terminal-prompt-inspired favicon (SVG + fallback PNG), Apple touch icon
- [ ] **Accessibility** — semantic HTML (`<main>`, `<nav>`, `<section>`, `<article>`), ARIA labels on interactive elements, keyboard-navigable filters, visible focus indicators, sufficient color contrast (WCAG AA), skip-to-content link
- [ ] `build-site.sh` — reads `skills/**/*.yaml`, injects card HTML into template, outputs `dist/index.html`
- [ ] `dist/` added to `.gitignore`
- [ ] Run `build-site.sh` and verify `dist/index.html` renders correctly in browser
- [ ] `agent-browser` verify — check rendering, dark/light toggle, responsive layout
- [ ] `/frontend-design` refine — UX review, design coherence, potential issues
- [ ] `agent-browser` verify final
- [ ] `/commit`

---

## Phase 2: Client-Side Filtering

Add JavaScript filtering with terminal-style interaction patterns.

### Tasks
- [ ] Search input styled as terminal prompt (`$ grep ___`), filters cards by name, description, author, tags (case-insensitive)
- [ ] Filter toggles for AI tool (`claude`, `cursor`, `copilot`, `windsurf`, `aider`) — styled as CLI flags or toggle chips
- [ ] Filter toggles for language (`kotlin`, `java`)
- [ ] Filter toggle for trust level (`expert`, `community`, `all`)
- [ ] Filters combine with AND logic — empty category shows all
- [ ] URL hash state for shareable filter links (e.g., `#tool=claude&lang=kotlin`)
- [ ] Show result count ("N skills found" or "no matches — clear filters")
- [ ] Smooth card show/hide transitions on filter change
- [ ] `agent-browser` verify — test all filter combinations, URL hash persistence
- [ ] `/commit`

---

## Phase 3: CI/CD, Docs & Deployment

GitHub Actions pipelines, contribution docs, and final polish.

### Tasks
- [ ] `.github/workflows/build.yml` — on PR: install `yq`, validate all `skills/**/*.yaml` against required fields (name, description, repo, category, tools, languages, trust, author), run `build-site.sh`, upload artifact
- [ ] `.github/workflows/deploy.yml` — on push to main: build site, deploy to GitHub Pages
- [ ] Configure GitHub Pages with custom domain `jvmskills.com` (CNAME file in `dist/`)
- [ ] `CONTRIBUTING.md` — step-by-step guide for adding a skill listing (fork, create YAML, fill fields, open PR)
- [ ] Update `README.md` — project description, link to jvmskills.com, contribution pointer, badge for build status
- [ ] Verify responsive design on mobile viewport (375px width)
- [ ] Push to a test branch and verify CI runs green
- [ ] `/commit`

---

## Coverage Check

All spec requirements covered:
- Skill listings as YAML ✓ (Phase 0)
- Browsable directory with cards ✓ (Phase 1)
- Trust badges ✓ (Phase 1)
- Client-side filtering ✓ (Phase 2)
- Dark/light mode ✓ (Phase 1)
- SEO meta tags ✓ (Phase 1)
- Favicon ✓ (Phase 1)
- Accessibility ✓ (Phase 1)
- CI/CD + GitHub Pages ✓ (Phase 3)
- Contribution workflow ✓ (Phase 3)
- Responsive/mobile ✓ (Phase 1 + Phase 3)

Uncovered: none

---

## TODO: Publishing Checklist

Manual steps required to go live at jvmskills.com:

### GitHub Repository Setup
- [ ] Create the `jvm-skills/jvm-skills` GitHub organization and repo (or push to existing)
- [ ] Push all code to `main` branch

### GitHub Pages Configuration
- [ ] Go to repo **Settings → Pages**
- [ ] Set **Source** to "GitHub Actions"
- [ ] Verify the deploy workflow runs successfully on push to main

### Custom Domain (jvmskills.com)
- [ ] Purchase/own the domain `jvmskills.com` (if not already)
- [ ] Add DNS records pointing to GitHub Pages:
  - `A` records for apex domain:
    ```
    185.199.108.153
    185.199.109.153
    185.199.110.153
    185.199.111.153
    ```
  - `CNAME` record: `www` → `jvm-skills.github.io`
- [ ] In repo **Settings → Pages → Custom domain**, enter `jvmskills.com`
- [ ] Check **Enforce HTTPS** once DNS propagates
- [ ] Verify `CNAME` file is being generated in `dist/` by the deploy workflow

### Verify
- [ ] Visit `https://jvmskills.com` and confirm the site loads
- [ ] Test dark/light mode toggle
- [ ] Test search and filter functionality
- [ ] Test on mobile (375px viewport)
- [ ] Verify all skill card links resolve to valid GitHub repos
- [ ] Open a test PR and verify the build workflow validates YAML + builds the site
