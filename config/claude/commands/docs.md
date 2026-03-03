Generate or update documentation for $ARGUMENTS (a file, function, module, or feature). If no arguments, ask what to document.

## What to document
Ask if unclear:
- A specific **file or function** → generate JSDoc / inline docs
- A **feature or flow** → write a guide in `docs/`
- A **README** → project overview
- **API endpoints** → request/response reference

## For code documentation (JSDoc)
Read the target file first. Add JSDoc only where:
- The function is exported or public
- The logic isn't self-evident
- Parameters have non-obvious types or constraints

```typescript
/**
 * Calculates the prorated amount for a mid-cycle plan change.
 * Does NOT create the charge — call createCharge() separately.
 *
 * @param currentPlan - The plan the user is switching FROM
 * @param newPlan - The plan the user is switching TO
 * @param daysRemaining - Days left in the current billing period
 * @returns Amount in cents to charge (positive) or credit (negative)
 */
export function calculateProration(
  currentPlan: Plan,
  newPlan: Plan,
  daysRemaining: number
): number
```

Rules:
- Skip JSDoc on functions with obvious names and typed params (`formatDate(date: Date): string`)
- Never document `what` (the code shows that) — document `why` and constraints
- Keep descriptions to 1-2 sentences max

## For feature docs (Markdown guide)
Structure:
```markdown
# Feature Name

Brief 1-sentence description.

## Overview
What it does and why it exists.

## Usage
Practical example — code first, explanation after.

## Configuration
Options with defaults and examples.

## How it works
Brief technical explanation (optional, for complex features).

## Troubleshooting
Common issues and fixes.
```

Save to `docs/` unless it belongs closer to the code.

## For README
```markdown
# Project Name

[1-sentence tagline]

## Quick Start
[Minimal steps to get running — 3-5 commands max]

## Development
[Commands for dev, test, build, lint]

## Stack
[Key technologies with links]

## Deployment
[How to deploy]
```

## After writing docs
- Check all code examples actually run
- Check that referenced file paths exist
- Keep it concise — docs that are too long don't get read
