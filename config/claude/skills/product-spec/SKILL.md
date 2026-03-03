---
name: product-spec
description: Write a product spec or PRD for a feature or product. Use when planning a new feature, writing requirements, or communicating what to build.
disable-model-invocation: true
---

Write a product spec for: $ARGUMENTS

## Format

### TL;DR
One paragraph: what it is, why it matters, who it's for.

### Problem
- User story: "As a [user], I want to [action] so that [outcome]"
- Current pain: what happens today without this?
- Success metric: how do we know it worked? (e.g., "40% of new signups complete onboarding in first session")

### Scope
**In scope:**
- [specific feature/behavior 1]
- [specific feature/behavior 2]

**Out of scope (v1):**
- [explicitly excluded thing]

### User Stories & Acceptance Criteria
For each story:
```
Given [context]
When [action]
Then [expected outcome]
```

### Design / UX Notes
- Key screens/states needed
- Edge cases to handle
- Error states

### Technical Considerations
- Data model changes
- API changes
- Dependencies / risks
- Estimated complexity: S/M/L/XL

### Launch Plan
- Rollout: feature flag / % rollout / full launch
- Who to notify
- Docs needed
