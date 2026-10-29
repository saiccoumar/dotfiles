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

    # 1. Force the workspace to the correct monitor
    subprocess.run(['hyprctl', 'dispatch', 'moveworkspacetomonitor', f'{ws_num} {target}'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # 2. Perform action
    if action == "move":
        subprocess.run(['hyprctl', 'dispatch', 'movetoworkspace', str(ws_num)])
    else:
        subprocess.run(['hyprctl', 'dispatch', 'workspace', str(ws_num)])

if __name__ == '__main__':
    main()
