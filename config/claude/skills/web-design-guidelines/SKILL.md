---
name: web-design-guidelines
description: Review UI code for Web Interface Guidelines compliance (accessibility, focus, forms, motion, typography, performance, dark mode, i18n, copy). Use when asked to "review my UI", "check accessibility", "audit design", "review UX", or "check my site against best practices".
metadata:
  author: vercel (rules); local wrapper
  version: "1.0.0-local"
  argument-hint: <file-or-pattern>
---

# Web Interface Guidelines

Review files for compliance with Vercel's Web Interface Guidelines.

## How it works

1. Read the rules in [guidelines.md](guidelines.md) (vendored, pinned — see SOURCE.md).
   Do **not** fetch the rules from the internet: the upstream skill pulls them
   from a moving `main` branch at runtime; this copy is pinned on purpose.
2. Read the specified files (or ask which files/pattern to review).
3. Check every file against every rule.
4. Output findings in the terse `file:line` format described in guidelines.md.

If no files are specified, ask the user which files to review.
