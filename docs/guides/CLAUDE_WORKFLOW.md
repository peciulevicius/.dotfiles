# Claude workflow

How the Claude tools and the skills in `config/claude/` fit together, from an
idea to a deployed change.

## Tools

| Tool | Purpose | Use for |
|---|---|---|
| claude.ai | Chat, no local file access | Questions, brainstorming, writing |
| Claude Design | UI prototyping in claude.ai | Designing screens before implementation |
| Claude Code | Agent that reads and edits files and runs commands | Development work |
| Skills (`/develop`, `/review`, …) | Packaged workflows invoked with `/` | Repeated workflows |
| Agents | Specialised subagents (frontend, backend, …) | Delegated automatically when relevant |
| Hooks | Shell commands triggered by Claude Code events | Enforcement, e.g. type-check after edits |
| MCP servers | Connections to external tools (Figma, Notion, Gmail) | Pulling context from those tools |
| `/schedule` | Scheduled routines on Anthropic infrastructure | Recurring tasks |

---

## New project

### 1. Validate the idea

In claude.ai, or with `/market-research` in Claude Code:

- Who are the main competitors, and how are they positioned?
- Who is the target user, and what is the core problem?
- What is the smallest first version that proves value?

### 2. Design the screens

In Claude Design, describe the product and the stack, for example:

> A SaaS for [X]. Pages: landing page, dashboard with [Y], settings. Tailwind +
> shadcn/ui, minimal style.

Claude Design produces clickable prototypes, accepts revisions and annotations,
and exports an implementation bundle (components, tokens, copy). Screenshots of
an existing product can be attached as reference or as the starting point for
a redesign.

### 3. Scaffold

```
/new-project
```

Runs a discovery session: asks about the stack, generates `.claude/` and
`CLAUDE.md`, and optionally scaffolds the project. Common stacks: Next.js +
Supabase + Stripe on Cloudflare, or SvelteKit + Supabase.

### 4. Build features

From a GitHub issue:

```
/develop 42
```

Claude reads the issue, plans, implements, tests, commits and opens a pull
request.

From a Jira ticket:

```
/jira PROJ-123
```

From a description:

```
/develop Limit free-tier users to 100 API calls per month. Show a banner at 80%; block at 100% with an upgrade prompt.
```

### 5. Review

```
/review 42       # a pull request
/review          # the current branch
```

### 6. Verify before deploying

```
/check
```

Runs type checks, lint, tests and a secret scan.

### 7. Deploy

- Cloudflare Pages and Workers: `/cloudflare`
- Vercel: `vercel --prod`

---

## Daily use

| Situation | Command |
|---|---|
| Start of day | `/standup`, `gh issue list` |
| Work on a feature | `/develop <issue number or description>` |
| Investigate a bug | `/debug <description>` |
| Before committing | `/check`, then `/commit` |
| Self-review | `/review` |

---

## GitHub Issues as the task board

Issues integrate directly with `gh` and `/develop`.

### Labels

```bash
gh label create "feature" --color "0075ca"
gh label create "bug" --color "d73a4a"
gh label create "design" --color "e4e669"
gh label create "v1" --color "0e8a16"
```

### Issue template

A complete issue lets `/develop` work without follow-up questions.

```markdown
## What
One paragraph describing what should exist when this is done.

## Why
The problem it solves.

## Acceptance criteria
- [ ] User can do X
- [ ] When Y happens, Z appears
- [ ] Works on mobile

## Design
Screenshot from Claude Design, or a description of the UI.

## Notes
Existing code to reuse, known pitfalls.
```

### Viewing issues

```bash
gh issue list
gh issue list --label "v1"
gh issue view 42
```

---

## Design systems

**New project**

1. Run `/new-project`.
2. In Claude Design, describe the app and ask for Tailwind + shadcn/ui tokens.
3. Export the implementation bundle and ask Claude Code to apply the tokens to
   `tailwind.config.ts`.

**Existing project**

1. Take a screenshot of the current UI and give it to Claude Design with the
   change you want, asking it to keep the existing design language.
2. For Figma files, share the Figma URL in Claude Code; the Figma MCP server
   reads it directly.

---

## Recurring tasks

| Task | Setup |
|---|---|
| Weekly standup summary | `/schedule`: "Every Monday at 9am, run `/standup` and email a summary." |
| Automatic PR review | Ask Claude Code to add a GitHub Actions workflow that reviews every pull request against `main`. |
| Weekly verification | `/schedule`: "Every Sunday evening, run `/check` on active repositories and email a summary." |

---

## Skill reference

| Skill | Purpose |
|---|---|
| `/develop <issue or description>` | Implement a feature end to end |
| `/review [PR number]` | Review the current branch or a pull request |
| `/commit` | Create a conventional commit |
| `/check` | Pre-commit and pre-deploy verification |
| `/debug <problem>` | Structured bug investigation |
| `/standup` | Activity summary |
| `/jira <ticket>` | Implement a Jira ticket |
| `/new-project` | Start a project with `.claude/` configuration |
| `/market-research` | Competitor and market research |
| `/product-spec` | Write a PRD or feature specification |
| `/security-audit` | OWASP-based security checklist |
| `/landing-page` | Build or improve a landing page |

## Practices

- **Write self-contained issues.** Clear acceptance criteria, design references
  and notes let Claude implement without questions.
- **Add a project `CLAUDE.md`.** The global file covers the stack; the project
  file should describe what the app does, the data model, key architectural
  decisions and things to avoid.
- **Let agents be delegated automatically.** Subagents such as
  `frontend-developer` and `backend-developer` are selected by Claude Code when
  relevant.
- **Run `/check` before every deploy.**
