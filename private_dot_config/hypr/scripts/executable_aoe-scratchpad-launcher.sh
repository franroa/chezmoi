#!/bin/bash
# Wrapper script to launch aoe session
echo "Launcher started" > /tmp/aoe_launcher.log
echo "last_nvim_root: $(cat /tmp/last_nvim_root 2>/dev/null)" >> /tmp/aoe_launcher.log
echo "Running foot..." >> /tmp/aoe_launcher.log
foot --app-id=aoe-cwd -D ~ bash -c 'source /home/froa/.config/hypr/scripts/aoe-session.sh' 2>&1 | tee -a /tmp/aoe_launcher.log &
FOOT_PID=$!
sleep 2
if ps -p $FOOT_PID > /dev/null 2>&1; then
    echo "Foot is running with PID $FOOT_PID" >> /tmp/aoe_launcher.log
else
    echo "Foot exited!" >> /tmp/aoe_launcher.log
fi
echo "Launcher finished" >> /tmp/aoe_launcher.log