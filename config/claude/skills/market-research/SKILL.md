---
name: market-research
description: Research competitors, market size, user needs, and product positioning. Use when starting a new product, validating an idea, or analyzing competition.
disable-model-invocation: true
---

Research the market for: $ARGUMENTS

## 1. Problem Space
- What exact pain does this solve?
- Who has this pain most acutely? (ICP — Ideal Customer Profile)
- How are they solving it today?
- What's the cost of the problem (time, money, frustration)?

## 2. Competitor Analysis
For each competitor found:
- **Positioning**: what problem do they claim to solve?
- **Pricing**: tiers, price points, free tier?
- **Strengths**: what do they do well?
- **Weaknesses**: what do users complain about? (check G2, Capterra, Reddit, App Store reviews)
- **Target segment**: enterprise, SMB, indie?

Use these sources:
- Google: `site:reddit.com "best [category] tool"`, `"[competitor] alternative"`
- G2, Capterra, Product Hunt for reviews
- LinkedIn for team size / funding signals
- SimilarWeb estimates for traffic
- Twitter/X for user complaints

## 3. Market Sizing
- **TAM**: total market if everyone who has the problem used a solution
- **SAM**: the portion you can realistically reach
- **SOM**: your realistic 3-year target
- Look for: analyst reports, VC memos, similar company S-1s, industry newsletters

## 4. Positioning Gaps
- What niche is underserved?
- Who do competitors ignore? (freelancers, specific vertical, specific region)
- What's the 10x insight that makes you different?

## 5. Output Format
Summarize findings as:
```
Problem: [1 sentence]
ICP: [who + why now]
Market: TAM ~$Xb / SAM ~$Xm
Top competitors: [3-5 with one-line summary]
Gap/opportunity: [what they all miss]
Proposed positioning: "[Product] is the [category] for [ICP] who [differentiator]"
```
