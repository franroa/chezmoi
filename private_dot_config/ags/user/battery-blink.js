import { Astal, Gtk, Gdk } from 'astal';

export default function batteryBlink() {
    const batteryPath = '/sys/class/power_supply/BAT0';
    
    let isLowBattery = false;
    
    // Monitor battery
    const batteryFile = `${batteryPath}/uevent`;
    
    // Check battery status
    const checkBattery = () => {
        try {
            const content = exec(`cat ${batteryFile}`);
            const status = content.match(/POWER_SUPPLY_STATUS=(\w+)/)?.[1];
            const capacity = parseInt(content.match(/POWER_SUPPLY_CAPACITY=(\d+)/)?.[1] || '100');
            
            // Low battery (below 20%) and not charging
            if (status !== 'Charging' && status !== 'Full' && capacity < 20) {
                return true;
            }
            return false;
        } catch {
            return false;
        }
    };
    
    // Apply/remove blink class to battery widget
    const updateBlink = () => {
        const shouldBlink = checkBattery();
        
        // Find battery widgets and apply class
        const batteryWidget = Gdk.Display.get_default()?.get_monitors().map(m => {
            return exec(`xdotool search --name "HyprPanel" 2>/dev/null`);
        }).filter(Boolean);
        
        // Apply CSS class by setting environment variable or file
        if (shouldBlink) {
            exec(`touch /tmp/.battery_low_${USER}`);
        } else {
            exec(`rm -f /tmp/.battery_low_${USER}`);
        }
    };
    
    // Start monitoring
    setInterval(updateBlink, 5000);
    updateBlink();
}
