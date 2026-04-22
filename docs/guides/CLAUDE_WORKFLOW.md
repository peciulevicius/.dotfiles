# Claude Workflow Guide

How to go from idea → shipped product using the full Claude toolset.

---

## The Tools and When to Use Each

| Tool | What it is | Use when |
|------|-----------|----------|
| **claude.ai** | Chat (no file access) | Quick questions, brainstorming, writing |
| **Claude Design** | UI prototyping in claude.ai | Designing screens before coding |
| **Claude Code** (this) | Agentic coder — reads/writes files, runs commands | All actual development |
| **Skills** (`/develop`, `/review`, etc.) | Packaged workflows you invoke with `/` | Repeating workflows |
| **Agents** | Specialized Claude instances (frontend, backend, etc.) | Auto-invoked when relevant — you don't call them directly |
| **Hooks** | Shell commands that fire automatically | Policy enforcement (type check after edit, notify on done) |
| **MCP servers** | Connections to external tools (Figma, Notion, Gmail) | Reading context from external tools |
| **`/schedule`** | Routines on Anthropic infra | Automated recurring tasks (standup, PR review, backlog triage) |

---

## Starting a New Project

### 1. Validate the idea (claude.ai)

Open claude.ai and describe your idea. Ask:
- "What are the top 3 competitors? How are they positioned?"
- "Who is the target user? What's the critical pain point?"
- "What's the minimal v1 that proves value?"

Use `/market-research` in Claude Code for structured competitor research.

### 2. Design the screens (Claude Design — claude.ai)

Go to claude.ai → Claude Design.

Describe what you want:
> "I'm building a SaaS for [X]. I need: a landing page, a dashboard with [Y], and a settings page. My design system uses Tailwind + shadcn/ui. Use a clean, minimal SaaS aesthetic."

Claude Design will:
- Generate interactive prototypes you can click through
- Let you revise ("make the dashboard more data-dense", "change the CTA")
- Add comments/annotations for the developer
- Export an implementation bundle (components, tokens, copy)

You can also attach a screenshot of an existing app you like as reference.

**For existing projects:** paste a screenshot of your current UI and say "here's what I have, I want to redesign this section."

### 3. Scaffold the project (Claude Code)

In the terminal, `cd` to where you want the project and run:

```
/new-project
```

This starts a discovery session — Claude asks about your stack, generates a `.claude/` config, CLAUDE.md, and optionally scaffolds the full project.

For your standard stack: Next.js + Supabase + Stripe + Cloudflare or SvelteKit + Supabase.

### 4. Build features (Claude Code)

**Option A — GitHub Issues (recommended for your own projects)**

Create issues in your repo with full context: screenshots, acceptance criteria, design attachments. Then:

```
/develop 42
```

Claude reads the issue, plans, builds, tests, commits, and opens a PR. No back-and-forth needed.

**Option B — Jira (for day job)**

Paste the Jira ticket text or URL:

```
/jira PROJ-123
```

**Option C — Direct description**

```
/develop Add a usage limit of 100 API calls per month for free tier users. Show a banner when at 80%. Block at 100% with an upgrade prompt.
```

### 5. Review before merging

```
/review 42       # review PR #42
/review          # review current branch diff
```

### 6. Pre-deploy check

```
/check
```

Runs types + lint + tests + secret scan. Fix any failures.

### 7. Deploy

Skills for each platform:
- `/cloudflare` — Cloudflare Pages + Workers
- Vercel: `vercel --prod` (already in allowed commands)

---

## Day-to-Day Workflow

### Starting a work session
```
/standup          # see what you did yesterday, what's up today
gh issue list     # see open issues
```

### Working on a feature
```
/develop <issue number or description>
# Claude handles: read → plan → build → test → commit → PR
```

### Something is broken
```
/debug <description of what's wrong>
```

### Before committing
```
/check            # types + lint + tests + secrets
/commit           # conventional commit message
```

### Reviewing your own PR
```
/review           # current branch
```

---

## GitHub Issues as Your Task Board

For your own projects, GitHub Issues is the right tool. It's free, `gh` CLI reads them directly, and the `/develop` skill integrates with it natively.

### Setup per repo
```bash
# Create labels
gh label create "feature" --color "0075ca"
gh label create "bug" --color "d73a4a"
gh label create "design" --color "e4e669"
gh label create "v1" --color "0e8a16"
```

### Creating good issues (so /develop works without questions)
```markdown
## What
[One paragraph — what should exist after this is done]

## Why
[Context — why does this matter, what problem does it solve]

## Acceptance criteria
- [ ] User can do X
- [ ] When Y happens, Z appears
- [ ] Works on mobile

## Design
[Attach screenshot from Claude Design, or describe the UI]

## Notes
[Anything implementation-related — existing code to reuse, gotchas]
```

The more complete the issue, the less Claude needs to ask before building.

### Viewing issues
```bash
gh issue list                    # all open
gh issue list --label "v1"       # v1 scope only
gh issue view 42                 # full details
```

---

## Design System — Existing vs New Projects

### New project
1. Run `/new-project` in Claude Code — it sets up `.claude/` with your stack
2. Open Claude Design, describe your app, ask it to "use Tailwind + shadcn/ui tokens"
3. Claude Design generates a design system (colors, spacing, typography)
4. Export the implementation bundle → give it to Claude Code:
   ```
   I have a design system from Claude Design. Apply it to this project — update tailwind.config.ts with the tokens.
   ```

### Existing project
1. Take a screenshot of your current UI
2. Open Claude Design, paste the screenshot
3. Say: "Here's my existing app. I want to [redesign the dashboard / add a new onboarding flow / create a mobile version]. Keep the same design language."
4. Claude Design works within your existing style
5. For Figma files: share the Figma URL in Claude Code — the Figma MCP reads it directly

---

## Automating Recurring Tasks

### Weekly standup
```
/schedule
```
Then describe: "Every Monday at 9am, run `/standup` and post a summary to my email."

### Auto PR review on push
Set up GitHub Actions (Claude Code can write this for you):
```
/develop Add a GitHub Actions workflow that runs /review on every PR opened against main
```

### Nightly security audit
```
/schedule
```
Describe: "Every Sunday evening, run `/check` on all my active repos and email me a summary."

---

## Skill Reference

| Skill | When to use |
|-------|-------------|
| `/develop <issue/description>` | Build a feature end-to-end |
| `/review [PR number]` | Code review current branch or a PR |
| `/commit` | Create a conventional commit |
| `/check` | Pre-commit/pre-deploy verification |
| `/debug <problem>` | Systematic bug investigation |
| `/standup` | Daily activity summary |
| `/jira <ticket>` | Implement a Jira ticket |
| `/new-project` | Start a new project with `.claude/` config |
| `/market-research` | Research competitors and market |
| `/product-spec` | Write a PRD or feature spec |
| `/security-audit` | OWASP security checklist |
| `/landing-page` | Build or improve a landing page |

---

## Tips

**Make issues self-contained.** The less Claude needs to ask, the more autonomously it can build. A good issue with clear ACs, design screenshots, and notes → Claude builds it without a single question.

**CLAUDE.md per project.** The global one covers your stack. Add a project-level `.claude/CLAUDE.md` with: what this app does, the data model, key architectural decisions, things to avoid.

**Let agents work automatically.** You don't call `frontend-developer` or `backend-developer` — Claude Code delegates to them automatically when relevant. They have your stack wired in.

**`/check` before every deploy.** Types + lint + tests + secret scan. Takes 30 seconds, prevents 2-hour incidents.
