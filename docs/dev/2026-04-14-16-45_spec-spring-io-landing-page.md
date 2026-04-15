# Spec: Spring I/O Landing Page

**URL:** `jvmskills.com/spring-io-2026/`
**File:** `site/spring-io-template.html`
**Generated into:** `dist/spring-io-2026/index.html`

## 1. Purpose

A single landing page tied to the Spring I/O 2026 talk "Claude Code for Spring Developers". It serves three audiences landing on the same URL, in priority order:

1. **Spring I/O 2026 attendees (developers)** — primary audience. Saw the talk, believe the argument, want the toolbelt **and** a way to pitch this upward to their Head of Engineering / CTO / Team Lead.
2. **Heads of Engineering / CTOs / Team Leads** who receive the forwarded link from a developer, or arrive directly via referral / LinkedIn / search. They need to be able to read the page cold and reach the "free audit" decision without the developer-framing getting in the way.
3. **Recruiters / fellow devs** arriving via LinkedIn.

The developer-first framing is intentional. The talk audience is developers, not buyers. Developers who see the talk can't buy consulting themselves — they have to convince their lead. The page makes both halves of that flow easy: the toolbelt serves the dev directly, a dedicated "Forwarding this to your Head of Engineering?" section arms them with a ready-to-send pitch, and the rest of the page (problem / offer / proof / process / audit CTA) is written so it stands on its own when the lead reads it cold.

The page is **not** linked from the main site navigation. It's reached via the QR code on stage, direct links in the talk, developers forwarding it, and external referrals.

## 2. Core thesis

> If you're not doing agentic engineering, you'll fall behind.

Every team that doesn't adopt agentic engineering will be out-shipped by one that does — at a fraction of the cost, in a fraction of the time, with more quality.

Developers don't have the time or space to build a custom AI coding workflow on top of their day job. That's the gap the offer fills. The positioning is **not** "we write more code with AI." It's **"we build the workflow that makes AI reliable on your codebase — CLAUDE.md, domain skills, hooks, MCP, spec-first workflow, evals — tailored to your stack and your team."**

Anchoring quote / red line from the talk: **"The speed is free. The discipline is yours."**

## 3. Audiences and intent

| Audience | Lands here because... | Wants to leave with... |
|---|---|---|
| Spring I/O attendee (dev) | Saw the QR code on stage, scanned the link | All the links from the talk, plus a ready-to-forward pitch for their lead |
| Head of Eng / CTO (forwarded) | A developer on their team sent them the link | The argument + proof + audit CTA, without the dev-framing getting in the way |
| Head of Eng / CTO (direct) | Referred by someone, LinkedIn, search | Same as above |
| Senior engineer | Curious about the workflow | Proof this is real, some links to try |
| Recruiter / fellow dev | Came via LinkedIn | A sense of who Thomas is and what he does |

## 4. Primary action

**Book a free audit** (email: `thomas@jvmskills.com`, subject prefilled).

The audit is framed as low-friction: send a note, we hop on a call, I hear where AI is breaking in your codebase today, we talk through what's fixable and what's structural. No commitment after. The scope is spelled out in the "Process" section and repeated verbatim in the final CTA. **It's a conversation, not a written deliverable** — no report, no scoped deep dive, no repo access required before the call.

## 5. Secondary actions

- **Jump to the Spring I/O toolbelt** (`#talk-toolbelt`) — for attendees
- **Forward to your lead** (`#forward`) — for developers who want to pitch this upward
- **LinkedIn** — for people who want to vet or message
- **GitHub** — for people who want proof of work
- **What I do ↓** (`#offer`) — for people not ready to email but want detail

## 6. Narrative flow

The page is structured so each section answers the next natural objection:

1. **Sticky banner** — "Spring I/O 2026 attendee? Every tool from the talk is below — plus a short pitch you can forward to your lead." Two anchor links: `Toolbelt ↓` and `For your lead ↓`.
2. **Hero** — headline thesis + three CTAs (audit, toolbelt, what I do). Voice works for either a developer or a lead reading cold.
3. **The problem** — "You already know this. The time to fix it is what you don't have." Pronouns are deliberately ambiguous: `you` reads as the dev if a dev is reading, as the team / CTO if a lead is reading. Closes with a dated-tech-vs-zipfiles analogy to create urgency.
4. **The offer** — four cards describing what an agentic engineering department actually delivers: CLAUDE.md, skills, hooks, workflow. Echoes the talk section headlines.
5. **The proof** — stats from PhotoQuest (5×, 3,700+, 1,700+, 11k+), reliability went up over the same window (Sentry errors down). Ends on the Thoughtworks Deer Valley 2026 quote. No bio/credibility bullet list — too self-promotional for a page the reader may have been forwarded.
6. **The process** — five named phases: Audit (free) → Deep dive → Build → Enable → Compound. The Audit step uses the same wording as the final CTA: "Your suspicion that the team is falling behind is the signal. Send a note — we hop on a call, I hear where AI is breaking in your codebase today, and we talk through what's fixable and what's structural. No commitment after."
7. **The Spring I/O toolbelt** (`#talk-toolbelt`) — every tool, skill, hook, MCP server, workflow, and link from the talk, grouped the way the talk is structured. Anchored for direct linking from the QR code.
8. **Forward to your lead** (`#forward`) — the developer's converting mechanism. A pre-styled email draft (subject + body + bullet-point proof + link back to this page + closing ask) inside a `.pitch-block`. Two primary actions: "Forward via email" (mailto with the full body URL-encoded) and "Share on LinkedIn". A ghost action back up to the toolbelt so the dev can keep browsing.
9. **Final CTA** — "Start with a free audit." Email + LinkedIn + GitHub. Same wording as the Audit process step.

## 7. Content rules

- **No self-referencing links.** The page is on jvmskills.com; don't link back to jvmskills.com from the page body.
- **No header nav entry for this page.** The site header exposes Skills + Blog only; this page is reached via QR code or direct link.
- **Numbers from the talk are the source of truth.** Stats on the page must match what's shown on stage. When the talk updates, the page updates. Current canonical numbers: 5× commit velocity, 3,700+ commits, 1,700+ sessions, 11k+ prompts. Reliability delta: Sentry errors down over the four-month window.
- **Tool lists mirror the talk slides.** Skills (`/interview`, `/tdd-task`, `/test`, `/commit` in §04, `/restart` in §06, `/rebase-commit` in §08), hooks (`git-guardrails.sh`, `pre-commit-gate.sh`, `post-edit-lint.sh`, `stop-uncommitted-check.sh` in §05), MCP servers (IntelliJ, Linear, Sentry, JavaDoc Central, Spring AI, MCP Steroid in §06), tips (`/sandbox`, handy.computer, Worktrunk in §08) — all traceable to a slide.
- **Workflow levels match the talk (§07) exactly.** Five levels in order: 1) Human in the Loop, 2) Built-in Plan Mode, 3) Spec-Driven Development, 4) The Drift Problem, 5) The Ralph Loop. Don't rename "Ralph" to "autonomous loops" — Ralph IS the autonomous level. Don't skip Level 4 — the drift problem is the bridge that justifies Ralph.
- **Reading list is further reading, not talk citations.** The talk cites exactly one external source (Thoughtworks Deer Valley 2026 quote). Other items in the reading list (e.g. "The SDLC Is Dead", Martin Fowler's Context Anchoring, Matt Pocock's AGENTS.md guide, Compounding Engineering) are adjacent reading. Captions must not claim they were covered on stage.
- **Audit copy is identical in three places** (Process step 1, the Final CTA, and the body of the forward-to-your-lead email draft's free-audit paragraph). If the wording is updated, all three must stay in sync — including the URL-encoded `mailto:` body on the "Forward via email" button.
- **Proof stats must match the forward-to-your-lead bullet list verbatim.** The email body lists 5× commit velocity / 3,700+ commits / 1,700+ sessions / 11k+ prompts and "Sentry errors down." Those numbers are the ones a lead will see first — keep them aligned with the stats cards and with the talk.
- **Tone.** Direct, opinionated, single-author ("I"). No "we". No marketing-speak. No em-dash flourishes in sales copy (em dashes are fine in prose).
- **No emojis.** Matches the rest of the site.
- **No stack/location/language qualifiers on the page.** The "Spring Boot, Kotlin, Java. Remote or Stuttgart. DE/EN." line was removed — it diluted the offer and pinned the positioning to role-seeking language. Stack details surface in conversation, not on the page.

## 8. Design constraints

- Matches the phosphor-green terminal aesthetic of the rest of jvmskills.com (same font stack, same CSS variables, same theme toggle).
- Dark mode is default; light mode is supported.
- Fully responsive down to 360px.
- No JavaScript framework — vanilla theme toggle only.
- Sticky Spring I/O banner at the very top of `<main>`.
- Hero stats, offer cards, process steps, and link cards all use the same card style (`--bg-card` + `--border` → `--green` on hover).

## 9. What lives on the page vs. elsewhere

**On the page:**
- The thesis, the offer, the process, the proof, the Spring I/O toolbelt.

**Not on the page (by design):**
- Long-form case studies (go on the blog).
- Pricing (negotiated per engagement; the free audit sets scope).
- A form / calendar embed (deferred until the email volume justifies it).
- Per-audience segmentation cards for Developers / CTOs / Consulting firms (removed — they diluted the core thesis).
- A header nav link to this page (removed — it leaked "consulting" into the primary site nav and confused the attendee flow).

## 10. Success criteria

- **Attendees** can reach the toolbelt from the QR code in ≤ 2 scrolls or 1 click.
- **Attendees** can reach the forward-to-your-lead section in ≤ 1 click from the top banner.
- **Forwarding is one click** — the "Forward via email" button opens the mail client with subject, body, and ask already filled in. The developer only has to type the lead's address.
- **CTOs reading cold** reach the "Audit (free)" line within 10 seconds of arriving.
- **Email subject line arrives prefilled** (`Free agentic engineering audit`) so replies are identifiable.
- **All tool/skill/hook/MCP references** are traceable back to a specific slide in `claude-code-for-spring-developers/presentation/sections/`.

## 11. User Stories

- **US-1** (Spring I/O attendee): As a conference attendee, I scan the QR code from the closing slide, see the attendee banner, and click one button to reach the full list of links from the talk.
- **US-2** (Spring I/O attendee pitching upward): As a developer who saw the talk and wants to bring this to my team, I jump to the "Forwarding this to your Head of Engineering?" section, click "Forward via email", and send a pre-filled pitch to my lead without having to write anything myself.
- **US-3** (Head of Eng / CTO reading a forwarded link): As a lead who received this link from a dev on my team, I can read the page cold — problem, offer, proof, process, audit — without stumbling over language that assumes I saw the talk.
- **US-4** (Head of Eng / CTO): As a lead, I read the Audit step and understand the commitment is bounded — send a note, have one conversation, no obligation to continue and no prep (repo access, scope doc, deliverable) required up front.
- **US-5** (Senior engineer): As an engineer, I reach the toolbelt section and see every tool/skill/hook grouped the way the talk was structured, with links to real source.
- **US-6** (Returning visitor): As someone who bookmarked the URL for later, I can click a direct anchor link (`#talk-toolbelt`, `#forward`, `#offer`) and land on the right section without scrolling.
- **US-7** (Recruiter / fellow dev via LinkedIn): As someone arriving from LinkedIn, I see LinkedIn and GitHub links in the hero and final CTA so I can vet or message without leaving the page.
- **US-8** (Dark-mode user): As a dark-mode user, the page respects my system preference on first load and persists my choice if I toggle.
- **US-9** (Build integration): As the site maintainer, when I run `site/build.sh`, the Spring I/O page is generated to `dist/spring-io-2026/index.html` alongside the rest of the site.
