Systematically debug the issue described in $ARGUMENTS (or ask me to describe it if no arguments given).

## Step 1 — Understand the problem
Ask (or infer from context):
- What's the **expected** behaviour?
- What's the **actual** behaviour?
- When did it start? (always / after a specific change / intermittent)
- What's the **error message** exactly? (copy the full stack trace if available)

## Step 2 — Gather information
Run relevant commands to collect evidence:
```bash
# Check recent changes
git log --oneline -10
git diff HEAD~1

# Check running processes / ports
lsof -i :3000  # or relevant port

# Check environment
cat .env.local  # redact secrets
node -e "console.log(process.version)"
```

Read the relevant files — don't guess, look at the actual code.

## Step 3 — Form hypotheses
List 2-3 most likely causes, ranked by probability. For each:
- What would cause this symptom?
- How can we confirm or rule it out?

## Step 4 — Test hypotheses (cheapest first)
- Add `console.log` / `console.error` at key points
- Check the browser Network tab / server logs
- Isolate: reproduce with minimal code
- Check: types, null/undefined, async timing, missing awaits, wrong env vars

## Step 5 — Fix and verify
Once root cause is confirmed:
1. Apply the smallest fix that solves the problem
2. Explain **why** it fixes it (not just what changed)
3. Check if the same bug could exist elsewhere
4. Remove any debug logging added in step 4

## Step 6 — Report
```
## Root Cause
[1-2 sentences — what was actually wrong]

## Fix
[what changed and why it works]

## How to prevent
[anything worth noting for the future — add to rules? add a test?]
```
