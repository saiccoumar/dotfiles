#!/usr/bin/env python3
import json
import subprocess
import sys

def get_monitors():
    try:
        output = subprocess.check_output(['hyprctl', 'monitors', '-j'])
        return json.loads(output)
    except Exception:
        return []

def main():
    if len(sys.argv) < 3:
        print("Usage: workspace_manager.py <workspace_index|next|prev> <action: switch|move>")
        sys.exit(1)

    ws_idx = sys.argv[1]
    action = sys.argv[2]

    monitors = get_monitors()
    if not monitors:
        sys.exit(1)

    if ws_idx in ('next', 'prev'):
        # Step by the number of monitors so we stay on the focused monitor's
        # workspaces (odd on primary, even on secondary)
        step = 2 if len(monitors) > 1 else 1
        focused = next((m for m in monitors if m.get('focused')), monitors[0])
        current = focused['activeWorkspace']['id']
        ws_num = current + step if ws_idx == 'next' else current - step
        if ws_num < 1:
            sys.exit(0)
    else:
        try:
            ws_num = int(ws_idx)
        except ValueError:
            sys.exit(1)

    # First monitor is primary
    primary = monitors[0]['name']
    
    # Second monitor if exists
    secondary = primary
    if len(monitors) > 1:
        # Avoid primary
        for m in monitors:
            if m['name'] != primary:
                secondary = m['name']
                break

    # Determine target monitor
    if len(monitors) > 1 and ws_num % 2 == 0:
        target = secondary
    else:
        target = primary

    # Hyprland's Lua config mode: `hyprctl dispatch` takes a Lua dispatcher.
    def dispatch(lua, quiet=False):
        out = subprocess.DEVNULL if quiet else None
        subprocess.run(['hyprctl', 'dispatch', lua], stdout=out, stderr=out)

    # 1. Force the workspace to the correct monitor
    dispatch(f'hl.dsp.workspace.move({{ workspace = {ws_num}, monitor = {json.dumps(target)} }})', quiet=True)

    # 2. Perform action
    if action == "move":
        dispatch(f'hl.dsp.window.move({{ workspace = {ws_num} }})')
    else:
        dispatch(f'hl.dsp.focus({{ workspace = {ws_num} }})')

if __name__ == '__main__':
    main()
