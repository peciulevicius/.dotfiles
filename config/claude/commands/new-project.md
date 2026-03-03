Set up a new project from scratch — discovery session, stack recommendation, then scaffold `.claude/`.

This is a back-and-forth conversation, not a form. Work through the phases below in order. Don't rush to scaffold until the stack is confirmed.

---

## Phase 1 — Discovery

Start with ONE open question. Let the user describe freely before asking follow-ups.

Ask first:
> "Tell me about what you're building. What's the idea?"

Then based on their answer, ask relevant follow-ups (pick what's missing, don't ask all of them):
- Who are the users? (consumer, B2B, internal tool, developer tool?)
- How do users find it? (SEO, app stores, invite-only, word of mouth?)
- Is there a paid component? (one-time, subscription, freemium, free?)
- Does it need accounts/auth? (yes / no / social only?)
- Roughly how many users are you expecting at launch? (dozens / hundreds / thousands / unknown)
- Web only, mobile only, or both?
- Is this a side project or a real product you'll take seriously?
- Any existing tech choices already locked in? (database, cloud provider, domain, etc.)
- Any constraints? (budget, timeline, must use X, can't use Y?)

Don't ask all of these — only the ones that aren't obvious from what they already said. 2-3 follow-ups max per round. Keep it conversational.

---

## Phase 1b — Design Direction

After understanding what they're building, ask about design. Keep it casual — one or two questions, not a form.

Pick what's relevant and unknown:
- Light mode, dark mode, or both?
- What's the vibe? (minimal/clean, bold/striking, playful, professional/corporate, warm, techy)
- Any reference sites or apps you like the look of?
- Color preferences, or should I suggest something?
- Font preferences, or should I suggest based on the vibe?

Don't ask all of these. If they said "B2B SaaS", you know the vibe is probably professional. If they said "consumer app", ask about it. 1-2 questions max.

If they have no preferences, note that — you'll make design decisions in Phase 2 and they can change them in Phase 3.

---

## Phase 2 — Stack Recommendation

Once you understand the project well enough, recommend a specific stack. Be opinionated — don't list 5 options, pick one and explain why.

Format:
```
## Recommended Stack

**Web:** [framework] on [platform]
**Database:** [choice + why]
**Auth:** [choice + why]
**Payments:** [if needed]
**Mobile:** [if needed]
**Email:** [if needed]
**Analytics:** [if needed]

## Design Direction

**Components:** [shadcn/ui for Next.js / Skeleton UI for SvelteKit / NativeWind for Expo]
**Mode:** [Light / Dark / Both]
**Vibe:** [1-2 words: minimal, bold, playful, professional, warm, etc.]
**Primary colour:** [suggestion with hex — e.g. Slate blue #6366f1]
**Neutral:** [e.g. Zinc grays]
**Font:** [e.g. Inter (system-ui fallback), Geist, Cal Sans for headings]
**Animations:** [minimal / spring-based / expressive — and what that means for this project]

## Why this stack

[2-4 sentences explaining the key trade-offs and why this fits their specific situation]

## Alternatives worth considering

- **[Alt A]** instead of [X] if [condition]
- **[Alt B]** instead of [Y] if [condition]
```

Base the recommendation on their context. Default to the user's known stack when it fits:
- Web apps → Next.js (Vercel) or SvelteKit (Cloudflare Pages)
- Database → Supabase (unless there's a reason not to)
- Mobile → Expo + React Native
- Payments web → Stripe, mobile → RevenueCat
- Email → Resend (transactional) + Loops.so (marketing)
- Analytics → PostHog + Sentry

Deviate from defaults when the project warrants it (e.g., Astro for a purely content site, D1 for an edge-first app, no auth for a pure landing page).

---

## Phase 3 — Refine

Invite pushback:
> "Does this feel right, or do you want to change anything? If you're thinking about a different approach for any part, tell me — I'll explain the trade-offs."

Handle objections seriously. If the user prefers a different choice, either:
- Agree and update the recommendation (if their reason is valid)
- Explain why the original recommendation is better for their situation (if you still think so)
- Acknowledge it's a trade-off and go with their preference

Keep going until the user says "looks good" or equivalent.

---

## Phase 4 — Confirm

Show a final summary before scaffolding:

```
## Final Stack

[Clean list of everything decided]

## What I'll create

- `.claude/CLAUDE.md` — project context, stack, file paths, dev commands
- `.claude/settings.json` — permissions for this project's tools

Ready to scaffold? (yes / make one more change)
```

---

## Phase 5 — Scaffold

Create both files. Use the actual framework conventions for file paths and dev commands — don't use generic placeholders.

### `.claude/CLAUDE.md`

```markdown
# [Project Name]

[1-sentence description of what it does and who it's for]

## Stack
- **Web:** [framework] — [platform]
- **Database:** [choice]
- **Auth:** [choice]
- [other relevant parts]

## Key paths
[framework-appropriate structure, e.g.:]
src/app/          # Next.js App Router pages
src/components/   # UI components
src/lib/          # utilities, db client, actions

## Dev commands
pnpm dev        # start dev server
pnpm build      # production build
pnpm test       # run tests
pnpm lint       # lint

## Design System

**Components:** [shadcn/ui / Skeleton UI / NativeWind]
**Mode:** [Light / Dark / Both]
**Vibe:** [minimal / bold / playful / professional]

**Colours:**
- Primary: [name + hex — e.g. Indigo #6366f1]
- Neutral: [e.g. Zinc — bg-zinc-950, text-zinc-50 in dark]
- Accent: [if any]
- Semantic: green = success, red = error, yellow = warning

**Font:** [e.g. Inter — already Tailwind default]
**Border radius:** [tight (rounded-md) / soft (rounded-xl) / pill-heavy]

**Animations:** [minimal — functional only / spring-based — buttons and modals / expressive — stagger reveals, layout animations]

**Reference:** [any sites/apps mentioned for design direction, or "none"]

## Conventions
- pnpm always
- TypeScript strict mode, no `any`
- Zod for all validation
- Conventional commits (feat/fix/chore/docs/refactor)
- [any project-specific rules from the conversation]

## Context
[Key decisions from the conversation: monetization model, target user, constraints, why specific choices were made]
```

### `.claude/settings.json`

Include `allow` rules appropriate for this project's tools:
- Always include: `Bash(pnpm *)`, `Bash(git *)`, `Bash(gh *)`
- Add `Bash(supabase *)` if using Supabase
- Add `Bash(vercel *)` if deploying to Vercel
- Add `Bash(wrangler *)` if using Cloudflare
- Add `Bash(docker *)` if using Docker
- Add `Bash(expo *)` if using Expo

Always deny: `Bash(rm -rf *)`, `Bash(curl * | bash)`, `Bash(wget * | sh)`.

```json
{
  "permissions": {
    "allow": ["Bash(pnpm *)", "Bash(git *)", "Bash(gh *)", ...],
    "deny": ["Bash(rm -rf *)", "Bash(curl * | bash)", "Bash(wget * | sh)"]
  }
}
```

---

## After scaffolding

Report what was created:
```
Created:
  .claude/CLAUDE.md     — project context
  .claude/settings.json — project permissions
```

Remind to run `/commit` to save it. Don't install dependencies, scaffold the project itself, or do anything else unless explicitly asked.
