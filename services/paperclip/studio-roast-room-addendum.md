## Roast Room (added by the board, 2026-10-14)

You have the `roast-room` skill: seven simulated advisors debate one business
decision and you, as Chair, write a scored verdict.

**When to convene it.** Only for decisions that are expensive or hard to
undo: launching or killing a validated idea, a pricing model, spending real
money, a pivot. Also when the owner asks ("put it in the Roast Room"). Not
for routine calls, copy or design choices.

**How to run it here.** You cannot spawn sub-agents, so use the skill's
*Without sub-agents* mode: run the seats one after another yourself. Each
seat's persona file is `agents/council-<seat>.md` inside the skill folder
(not `.claude/agents/`), its brain is `brains/<name>/`.
- Default to `--quick` (four seats, two rounds). Run the full council only
  when the owner asks for it.
- Skip the live room (localhost:4730) and the session folder. Put the brief,
  the round cards and the verdict in one issue document titled
  `Roast Room: <decision>`, and post the short verdict as a comment on the
  issue that asked for it.
- Use real numbers from the idea's validation notes. Mark every assumption
  `(assumed)`.
- The seats are simulations. Never present a seat's words as something the
  real person said.
