#!/bin/bash
# usage: tools/lv.sh <level> : rebuild levels, run bot, print result + last trace lines
cd "$(dirname "$0")/.."
python tools/build_levels.py >/dev/null
../godot/Godot_v4.3-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd -- $1 v 2>&1 | grep -E "step=|PASS|FAIL" | tail -${2:-4}
