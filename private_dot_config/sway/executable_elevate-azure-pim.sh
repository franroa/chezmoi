#!/usr/bin/env bash
#
# Azure PIM Role Elevation Script (Browser Automation)
# Activates PIM eligible group memberships via Azure Portal
#
# Groups activated:
#   - platform-sandbox-contributors
#   - platform-live-contributors
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DURATION_HOURS="${PIM_DURATION_HOURS:-8}"
JUSTIFICATION="${PIM_JUSTIFICATION:-Daily Work}"
DEBUG_PORT="${CHROME_DEBUG_PORT:-9222}"
PIM_URL="https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade/~/aadgroup"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Create the Playwright automation script
create_automation_script() {
    cat > "${SCRIPT_DIR}/pim-activate.mjs" << 'PLAYWRIGHT_SCRIPT'
import { chromium } from 'playwright';

const GROUPS = [
    'platform-sandbox-contributors',
    'platform-live-contributors'
];

const DURATION_HOURS = parseInt(process.env.PIM_DURATION_HOURS || '8');
const JUSTIFICATION = process.env.PIM_JUSTIFICATION || 'Daily Work';
const DEBUG = process.env.DEBUG === '1';
const DEBUG_PORT = process.env.CHROME_DEBUG_PORT || '9222';

const PIM_URL = 'https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade/~/aadgroup';

function log(msg) {
    console.log(`[${new Date().toISOString()}] ${msg}`);
}

async function waitForPageLoad(page) {
    // Wait for Azure Portal to fully load
    try {
        await page.waitForLoadState('networkidle', { timeout: 30000 });
    } catch {
        // Ignore timeout, portal may keep loading
    }
    await page.waitForTimeout(3000);
}

async function activateGroup(page, groupName) {
    log(`Activating group: ${groupName}`);
    
    try {
        // Step 1: Wait for the table to load (subscriptions take time)
        log('Waiting for table to load...');
        await page.waitForSelector('text=' + groupName, { timeout: 120000 });
        log(`Found group in table: ${groupName}`);

        // Step 2: Find the row with this group name
        const row = page.locator(`tr:has-text("${groupName}"), div[role="row"]:has-text("${groupName}")`).first();
        
        if (await row.count() === 0) {
            log(`Could not find row for: ${groupName}`);
            return false;
        }

        // Step 3: Find and click the "Activate" link in the Action column of that row
        const activateLink = row.locator('a:has-text("Activate"), button:has-text("Activate"), [role="link"]:has-text("Activate")').first();
        
        if (await activateLink.count() === 0) {
            // Maybe already activated?
            const rowText = await row.textContent();
            if (rowText.toLowerCase().includes('deactivate') || rowText.match(/\bactive\b/i)) {
                log(`Already active: ${groupName}`);
                return true;
            }
            log(`Activate link not found for: ${groupName}`);
            await page.screenshot({ path: `/tmp/pim-no-link-${groupName.replace(/[^a-z0-9]/gi, '_')}.png` });
            return false;
        }

        log('Clicking Activate link in Action column...');
        await activateLink.click();

        // Step 4: Wait for the new window/panel to appear (5 seconds)
        log('Waiting 5 seconds for activation window...');
        await page.waitForTimeout(5000);

        // Step 5: Write "Daily Work" in the text field inside the panel/blade
        log('Looking for justification input in activation panel...');
        
        // The panel/blade should be the rightmost or topmost element
        // Look for input specifically inside a panel, blade, or dialog - NOT the global search
        const panelSelectors = [
            '.ms-Panel textarea',
            '.ms-Panel input[type="text"]',
            '[role="dialog"] textarea',
            '[role="dialog"] input[type="text"]',
            '.fxs-blade-content-container-default textarea',
            '.fxs-blade-content-container-default input[type="text"]',
            '.fxs-contextpane textarea',
            '.fxs-contextpane input[type="text"]',
            // Azure-specific blade selectors
            'div[class*="blade"] textarea',
            'div[class*="blade"] input[type="text"]:not([aria-label*="Search"])',
            // Last resort: any textarea that's visible and not in header
            'main textarea',
        ];
        
        let inputField = null;
        for (const selector of panelSelectors) {
            const field = page.locator(selector).first();
            if (await field.count() > 0 && await field.isVisible()) {
                inputField = field;
                log(`Found input with selector: ${selector}`);
                break;
            }
        }
        
        if (inputField) {
            await inputField.click();
            await inputField.fill(JUSTIFICATION);
            log(`Entered justification: "${JUSTIFICATION}"`);
        } else {
            log('Warning: Could not find text input for justification in panel');
            await page.screenshot({ path: '/tmp/pim-no-input.png' });
            log('Screenshot saved to /tmp/pim-no-input.png');
        }

        // Take a screenshot to debug button finding
        await page.screenshot({ path: '/tmp/pim-before-button.png' });
        log('Screenshot saved to /tmp/pim-before-button.png');

        // Step 6: Press the submit button next to Cancel (wait for it to be enabled)
        log('Waiting for submit button to become enabled...');
        await page.waitForTimeout(5000);  // Wait 5 seconds as user mentioned
        
        // Find the submit button in the popup - it's next to the Cancel button
        // First try to find Cancel and get its sibling, then fall back to common patterns
        let activateButton = null;
        
        // Strategy 1: Find button container with Cancel and get the other button
        const cancelButton = page.locator('button:has-text("Cancel"):visible').first();
        if (await cancelButton.count() > 0) {
            // Get the parent container and find the other button (not Cancel)
            const buttonContainer = cancelButton.locator('xpath=..');
            const siblingButton = buttonContainer.locator('button:not(:has-text("Cancel"))').first();
            if (await siblingButton.count() > 0 && await siblingButton.isVisible()) {
                activateButton = siblingButton;
                log('Found submit button as sibling of Cancel');
            }
        }
        
        // Strategy 2: Find the primary Activate button (div[role="button"]) in the context pane
        // Azure uses div[role="button"] with class fxs-portal-button-primary for the submit button
        if (!activateButton) {
            const primaryActivate = page.locator('.fxs-contextpane div[role="button"].fxs-portal-button-primary:has-text("Activate")').first();
            if (await primaryActivate.count() > 0 && await primaryActivate.isVisible()) {
                activateButton = primaryActivate;
                log('Found primary Activate button (div[role=button])');
            }
        }
        
        // Strategy 3: Find any div[role="button"] with Activate text in context pane
        if (!activateButton) {
            const divActivate = page.locator('.fxs-contextpane div[role="button"]:has-text("Activate")').first();
            if (await divActivate.count() > 0 && await divActivate.isVisible()) {
                activateButton = divActivate;
                log('Found Activate div[role=button] in context pane');
            }
        }
        
        // Strategy 4: Find by class fxs-button with title="Activate"
        if (!activateButton) {
            const fxsActivate = page.locator('.fxs-contextpane .fxs-button[title="Activate"]').first();
            if (await fxsActivate.count() > 0 && await fxsActivate.isVisible()) {
                activateButton = fxsActivate;
                log('Found Activate button by title attribute');
            }
        }
        
        if (activateButton) {
            // Wait for button to be enabled (poll for up to 10 seconds)
            // Azure uses aria-disabled and fxs-button-disabled class for div[role="button"]
            for (let i = 0; i < 10; i++) {
                const ariaDisabled = await activateButton.getAttribute('aria-disabled').catch(() => 'true');
                const hasDisabledClass = await activateButton.evaluate(el => el.classList.contains('fxs-button-disabled')).catch(() => true);
                const isDisabled = ariaDisabled === 'true' || hasDisabledClass;
                if (!isDisabled) {
                    log('Submit button is now enabled');
                    break;
                }
                log(`Waiting for button to enable... (${i + 1}/10)`);
                await page.waitForTimeout(1000);
            }
            
            const btnText = await activateButton.textContent().catch(() => 'unknown');
            await activateButton.click();
            log(`Clicked submit button: "${btnText}"`);
        } else {
            log('Warning: Submit button not found (button next to Cancel)');
            await page.screenshot({ path: '/tmp/pim-no-button.png' });
            log('Screenshot saved to /tmp/pim-no-button.png');
            return false;
        }

        // Step 7: Wait for the window to close
        log('Waiting for activation to complete...');
        await page.waitForTimeout(5000);
        
        log(`Successfully activated: ${groupName}`);
        return true;
        
    } catch (error) {
        log(`Error activating ${groupName}: ${error.message}`);
        await page.screenshot({ path: `/tmp/pim-error-${groupName.replace(/[^a-z0-9]/gi, '_')}.png` }).catch(() => {});
        return false;
    }
}

async function ensureLoggedIn(context) {
    const page = await context.newPage();
    try {
        log('Checking Azure login status...');
        await page.goto(PIM_URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
        await page.waitForTimeout(3000);

        if (!page.url().includes('login.microsoftonline.com')) {
            log('Already logged in.');
            await page.close();
            return true;
        }

        log('');
        log('========================================');
        log('  Azure login required.');
        log('  Complete the login in the Chrome window.');
        log('  Waiting up to 5 minutes for login...');
        log('========================================');
        log('');

        const LOGIN_TIMEOUT_MS = 5 * 60 * 1000;
        const start = Date.now();
        while (Date.now() - start < LOGIN_TIMEOUT_MS) {
            await page.waitForTimeout(2000);
            if (!page.url().includes('login.microsoftonline.com')) {
                log('Login detected, continuing...');
                await page.waitForTimeout(3000);
                await page.close();
                return true;
            }
        }

        log('Login timed out after 5 minutes.');
        await page.close();
        return false;
    } catch (error) {
        log(`Login check error: ${error.message}`);
        await page.close().catch(() => {});
        return false;
    }
}

async function activateGroupInNewPage(context, groupName) {
    const page = await context.newPage();
    
    try {
        log(`[${groupName}] Opening PIM page...`);
        await page.goto(PIM_URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
        
        // Check if login is needed
        await page.waitForTimeout(3000);
        
        if (page.url().includes('login.microsoftonline.com')) {
            log(`[${groupName}] Azure login required. Please log in manually and re-run the script.`);
            await page.close();
            return false;
        }

        await waitForPageLoad(page);
        
        const result = await activateGroup(page, groupName);
        await page.close();
        return result;
        
    } catch (error) {
        log(`[${groupName}] Fatal error: ${error.message}`);
        if (DEBUG) console.error(error);
        await page.close().catch(() => {});
        return false;
    }
}

async function main() {
    log('Starting Azure PIM activation via browser automation (PARALLEL)');
    log(`Duration: ${DURATION_HOURS} hours`);
    log(`Justification: ${JUSTIFICATION}`);
    log(`Groups: ${GROUPS.join(', ')}`);
    log(`Connecting to Chrome on port ${DEBUG_PORT}...`);
    
    let browser;
    try {
        // Connect to existing Chrome with remote debugging
        browser = await chromium.connectOverCDP(`http://127.0.0.1:${DEBUG_PORT}`);
        log('Connected to Chrome');
    } catch (error) {
        log(`Failed to connect to Chrome: ${error.message}`);
        log('');
        log('Please restart Chrome with remote debugging enabled:');
        log(`  google-chrome --remote-debugging-port=${DEBUG_PORT}`);
        log('');
        log('Or add this to your Sway config to always start Chrome with debugging:');
        log(`  exec google-chrome --remote-debugging-port=${DEBUG_PORT}`);
        process.exit(1);
    }

    // Get the default context
    const contexts = browser.contexts();
    const context = contexts[0];

    // Make sure we're logged in before fanning out (waits for manual login)
    const loggedIn = await ensureLoggedIn(context);
    if (!loggedIn) {
        log('Cannot proceed without an active Azure login.');
        process.exit(1);
    }

    // Activate all groups in parallel
    log('');
    log('Starting parallel activation of all groups...');
    log('');
    
    const results = await Promise.all(
        GROUPS.map(group => activateGroupInNewPage(context, group))
    );
    
    const successCount = results.filter(r => r).length;
    const failCount = results.filter(r => !r).length;

    log('');
    log('=========================================');
    log(`Activation complete! Success: ${successCount}, Failed: ${failCount}`);
    log('=========================================');
    
    process.exit(failCount > 0 ? 1 : 0);
}

main();
PLAYWRIGHT_SCRIPT
}

# Check if Chrome is running with remote debugging
check_chrome_debug() {
    if curl -s "http://127.0.0.1:${DEBUG_PORT}/json/version" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Start Chrome with remote debugging
start_chrome_debug() {
    log_info "Starting Chrome with remote debugging on port ${DEBUG_PORT}..."
    
    # Use a separate profile for remote debugging
    CHROME_DEBUG_PROFILE="${HOME}/.config/chrome-pim-debug"
    
    google-chrome \
        --remote-debugging-port="${DEBUG_PORT}" \
        --user-data-dir="${CHROME_DEBUG_PROFILE}" \
        --no-first-run \
        --no-default-browser-check \
        "${PIM_URL}" &
    
    # Wait for Chrome to start
    for i in {1..30}; do
        if check_chrome_debug; then
            log_info "Chrome is ready"
            return 0
        fi
        sleep 1
    done
    
    log_error "Chrome failed to start with remote debugging"
    return 1
}

main() {
    log_info "Starting Azure PIM elevation (Browser Automation)..."
    log_info "Duration: ${DURATION_HOURS} hours"
    log_info "Justification: ${JUSTIFICATION}"
    echo ""

    create_automation_script

    # Check if Chrome is running with remote debugging
    if ! check_chrome_debug; then
        log_warn "Chrome is not running with remote debugging enabled"
        log_info "Starting Chrome with remote debugging..."
        
        if ! start_chrome_debug; then
            log_error "Failed to start Chrome. Please start it manually:"
            echo "  google-chrome --remote-debugging-port=${DEBUG_PORT}"
            exit 1
        fi
        
        # Give Chrome time to load the page
        sleep 5
    else
        log_info "Chrome remote debugging is active"
    fi

    log_info "Running browser automation..."
    echo ""

    # Export config for the Node script
    export PIM_DURATION_HOURS="${DURATION_HOURS}"
    export PIM_JUSTIFICATION="${JUSTIFICATION}"
    export CHROME_DEBUG_PORT="${DEBUG_PORT}"
    export DEBUG="${DEBUG:-0}"

    # Run the playwright script with timeout notification
    START_TIME=$(date +%s)
    
    # Start timeout watcher in background
    (
        sleep 10
        ELAPSED=$(($(date +%s) - START_TIME))
        if [ $ELAPSED -ge 10 ] && kill -0 $$ 2>/dev/null; then
            notify-send -u normal -t 0 -i dialog-warning "Azure PIM" "Activation is taking longer than expected..."
        fi
    ) &
    WATCHER_PID=$!
    
    # Run the script
    /home/froa/.local/share/nvm/v25.4.0/bin/node "${SCRIPT_DIR}/pim-activate.mjs"
    EXIT_CODE=$?
    
    # Kill the watcher if still running
    kill $WATCHER_PID 2>/dev/null
    
    # Notify result and close window
    if [ $EXIT_CODE -eq 0 ]; then
        notify-send -u normal -t 5000 -i dialog-information "Azure PIM" "Roles activated successfully"
        sleep 1
        exit 0
    else
        notify-send -u critical -t 0 -i dialog-error "Azure PIM" "Role activation failed"
        sleep 1
        exit 1
    fi
}

main "$@"
