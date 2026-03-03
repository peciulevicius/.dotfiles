#!/bin/bash
# Claude Code — notify when a session finishes
# Fires when Claude stops responding (Stop event)

if [[ "$(uname)" == "Darwin" ]]; then
    # macOS — native notification
    osascript -e 'display notification "Claude is done" with title "Claude Code" sound name "Glass"' 2>/dev/null || true
elif command -v notify-send &>/dev/null; then
    # Linux (libnotify)
    notify-send "Claude Code" "Done" --icon=terminal 2>/dev/null || true
fi
