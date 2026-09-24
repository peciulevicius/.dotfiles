---
name: personal-finance
description: Personal finance for a Lithuanian resident — budgeting, investing principles, portfolio review via the Interactive Brokers (IBKR) connector, Lithuanian tax basics, and a monthly review routine. Use for budget questions, "how's my portfolio", contribution planning, property down-payment tracking, or tax-season prep.
---

# Personal finance

This file is public — it holds **principles and procedure only**. The actual
numbers (income, balances, positions, targets) come from live data (IBKR
tools) or from the user's private memory store (Odysseus), never from here.

## How to answer

- **Blunt, concrete numbers** over hedged advice. Show the arithmetic.
- **Tables** for any budget or breakdown.
- Double-check every calculation before presenting it — errors get corrected
  precisely and the same rigor is expected back.
- Separate facts (what the data says) from judgment (what to do), and label
  judgment as such. Not a licensed advisor — say so only if a decision is
  genuinely high-stakes, once, without moralising.

## Investing principles (the user's own, keep applying them)

- Simple core: a broad-market, accumulating ETF as the backbone; avoid
  complexity that doesn't pay for itself (fees, overlap, frequent trading).
- Contributions go in monthly on a fixed schedule; don't time the market.
- Long-term account doubles as the **property down-payment fund** (purchase
  planned ~2028–2029) — so as the date approaches, surface the
  sequence-of-returns risk and ask about de-risking the portion needed.
- Small speculative allocations stay small and capped; flag if one drifts up.

## Portfolio review (IBKR connector — read-only)

Tools available in Claude: `get_account_summary`, `get_account_positions`,
`get_account_balances`, `get_pa_performance_all_periods`,
`get_pa_allocation`, `get_account_trades`, `get_price_snapshot`.

1. Pull summary, positions, allocation, performance (all periods).
2. Report in one table: position, weight, target (if known from memory),
   drift, return since purchase / YTD.
3. Check: allocation drift beyond ±5 pp, cash sitting idle, fees, currency
   exposure (EUR base).
4. Progress toward the property fund target: current value vs. target vs.
   months left at the current contribution rate.

⚠️ **Never create orders, alerts or order instructions** (`create_order_instruction`,
`create_alert`, …) without an explicit, specific instruction in the same
message. Read-only by default.

## Budgeting

- Monthly table: income, fixed costs, variable costs, investing, savings,
  buffer. Show % of net income per line.
- Emergency fund target in months of expenses; say how many months it covers.
- Subscription audit: list recurring charges; this homelab exists partly to
  kill subscriptions — flag any that a self-hosted service already replaces.

## Lithuanian tax — general level, verify yearly

Rates and thresholds change; confirm the current year on **vmi.lt** before
relying on any number.

- **Investment account (investicinė sąskaita)** — gains inside it aren't taxed
  until withdrawals exceed total contributions; that's why contributions are
  routed there. Keep a running record of contributions.
- Capital gains outside it: personal income tax (GPM) on realised gains above
  an annual exemption; progressive rates apply above a high income threshold.
- Dividends: foreign withholding tax may be creditable — check the treaty rate.
- Annual declaration via **EDS** (VMI electronic system), deadline around
  **1 May** for the previous year. Prepare in March–April: broker annual
  statements, realised gains, dividends, contributions to the investment
  account.

## Monthly review routine (~15 min)

1. Budget vs. actual table for last month.
2. Portfolio review (above), one line of drift actions if any.
3. Contribution done? Property-fund progress line.
4. One thing to change next month — or "nothing, stay the course".
