#!/usr/bin/env python3
# Simple key capture daemon using evdev

import select
import os
import sys
import time
import subprocess

NOTIF_OPENCODE = "/tmp/opencode_notifications_" + os.environ.get('USER', 'froa')
NOTIF_SLACK = "/tmp/slack_notifications_" + os.environ.get('USER', 'froa')
LETTER_MAP_OPENCODE = "/tmp/.opencode_letter_map"
LETTER_MAP_SLACK = "/tmp/.slack_letter_map"

def get_notification_for_letter(letter):
    if os.path.isfile(LETTER_MAP_OPENCODE):
        with open(LETTER_MAP_OPENCODE) as f:
            for line in f:
                if line.startswith(f"{letter}:"):
                    parts = line.strip().split(':')
                    if len(parts) >= 2:
                        notif_id = parts[1].split('|')[0]
                        if os.path.isfile(f"{NOTIF_OPENCODE}/{notif_id}.notif"):
                            with open(f"{NOTIF_OPENCODE}/{notif_id}.notif") as nf:
                                content = nf.read().strip()
                            return ('opencode', notif_id, content)
    
    if os.path.isfile(LETTER_MAP_SLACK):
        with open(LETTER_MAP_SLACK) as f:
            for line in f:
                if line.startswith(f"{letter}:"):
                    parts = line.strip().split(':')
                    if len(parts) >= 2:
                        notif_id = parts[1].split('|')[0]
                        if os.path.isfile(f"{NOTIF_SLACK}/{notif_id}.notif"):
                            with open(f"{NOTIF_SLACK}/{notif_id}.notif") as nf:
                                content = nf.read().strip()
                            return ('slack', notif_id, content)
    return None

def trigger_notification(app, notif_id, extra):
    # subprocess.run([
        Close notification
    'gdbus', 'call', '--session',
        '--dest', 'org.freedesktop.Notifications',
        '--object-path', '/org/freedesktop/Notifications',
        '--method', 'org.freedesktop.Notifications.CloseNotification',
        notif_id
    ], capture_output=True)
    
    if app == 'opencode':
        try:
            os.remove(f"{NOTIF_OPENCODE}/{notif_id}.notif")
        except:
            pass
        if os.path.isfile(LETTER_MAP_OPENCODE):
            with open(LETTER_MAP_OPENCODE) as f:
                lines = f.readlines()
            with open(LETTER_MAP_OPENCODE, 'w') as f:
                for line in lines:
                    if not line.startswith(f"{notif_id}:"):
                        f.write(line)
        
        parts = extra.split('|')
        if len(parts) >= 3:
            subprocess.run([
                '/home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh',
                parts[1], parts[2]
            ])
    
    elif app == 'slack':
        try:
            os.remove(f"{NOTIF_SLACK}/{notif_id}.notif")
        except:
            pass
        if os.path.isfile(LETTER_MAP_SLACK):
            with open(LETTER_MAP_SLACK) as f:
                lines = f.readlines()
            with open(LETTER_MAP_SLACK, 'w') as f:
                for line in lines:
                    if not line.startswith(f"{notif_id}:"):
                        f.write(line)
        
        subprocess.run(['/home/froa/.config/hypr/scripts/invoke-notification.sh'])

def check_panel():
    try:
        result = subprocess.run(['hyprctl', 'layers'], capture_output=True, text=True)
        return 'namespace: notificationsmenu' in result.stdout
    except:
        return False

# Key mapping
KEY_MAP = {
    'KEY_A': 'a', 'KEY_B': 'b', 'KEY_C': 'c', 'KEY_D': 'd', 'KEY_E': 'e',
    'KEY_F': 'f', 'KEY_G': 'g', 'KEY_H': 'h', 'KEY_I': 'i', 'KEY_J': 'j',
    'KEY_K': 'k', 'KEY_L': 'l', 'KEY_M': 'm', 'KEY_N': 'n', 'KEY_O': 'o',
    'KEY_P': 'p', 'KEY_Q': 'q', 'KEY_R': 'r', 'KEY_S': 's', 'KEY_T': 't',
    'KEY_U': 'u', 'KEY_V': 'v', 'KEY_W': 'w', 'KEY_X': 'x', 'KEY_Y': 'y',
    'KEY_Z': 'z',
}

panel_was_open = False

print("Starting key capture daemon...")

try:
    import evdev
    from evdev import InputDevice, categorize, ecodes
    
    # Find keyboard device
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    keyboard = None
    for dev in devices:
        if 'kbd' in dev.name.lower() or 'keyboard' in dev.name.lower():
            keyboard = dev
            break
    
    if not keyboard:
        # Try any input device
        for dev in devices:
            if ecodes.EV_KEY in dev.capabilities():
                keyboard = dev
                break
    
    if keyboard:
        print(f"Using keyboard: {keyboard.name}")
        keyboard.grab()
        
        while True:
            if check_panel():
                if not panel_was_open:
                    print("Panel opened")
                    panel_was_open = True
                    subprocess.run(['notify-send', '-t', '1500', 'Press a key', 'Notification mode'])
                
                # Read events with timeout
                r, w, x = select.select([keyboard], [], [], 0.1)
                if r:
                    for event in keyboard.read():
                        if event.type == ecodes.EV_KEY:
                            if event.value == 1:  # key down
                                key_name = ecodes.KEY[event.code]
                                if key_name in KEY_MAP:
                                    letter = KEY_MAP[key_name]
                                    info = get_notification_for_letter(letter)
                                    if info:
                                        print(f"Triggering notification for: {letter}")
                                        trigger_notification(*info)
            else:
                if panel_was_open:
                    print("Panel closed")
                    panel_was_open = False
                time.sleep(0.5)
    
    else:
        print("No keyboard device found")
        
except ImportError:
    print("evdev not available, trying alternative...")
    
    # Fallback: use simple polling with check
    while True:
        if check_panel():
            if not panel_was_open:
                print("Panel opened")
                panel_was_open = True
                subprocess.run(['notify-send', '-t', '1500', 'Press key', 'Waiting...'])
                
                # Try to read from terminal
                import sys
                if select.select([sys.stdin], [], [], 0.1)[0]:
                    key = sys.stdin.read(1)
                    print(f"Key: {key}")
        else:
            if panel_was_open:
                print("Panel closed")
                panel_was_open = False
            time.sleep(0.5)

except Exception as e:
    print(f"Error: {e}")
