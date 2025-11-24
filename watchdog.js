const fs = require('fs');
const crypto = require('crypto');
const http = require('http');

// --- Configuration ---
const LICENSE_PATH = process.env.LICENSE_PATH || '/app/license.key';
const PUBLIC_KEY_PATH = process.env.PUBLIC_KEY_PATH || '/app/public.pem';
const STATE_FILE_PATH = process.env.STATE_FILE_PATH || '/app/data/state.json';
const CHECK_INTERVAL_MS = process.env.CHECK_INTERVAL_MS || 60 * 1000; // Check every 1 minute
const DOCKER_SOCKET = process.env.DOCKER_SOCKET || '/var/run/docker.sock';

// --- Helper: Log ---
function log(msg) {
    console.log(`[${new Date().toISOString()}] ${msg}`);
}

// --- Helper: Stop All Containers ---
function stopContainers() {
    log('CRITICAL: Stopping all containers...');
    
    const options = {
        socketPath: DOCKER_SOCKET,
        path: '/containers/json',
        method: 'GET'
    };

    const req = http.request(options, (res) => {
        let data = ''; 
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
            try {
                const containers = JSON.parse(data);
                containers.forEach(container => {
                    // Filter logic: Stop everything EXCEPT myself (optional, but good practice)
                    // For now, we stop everything to be safe/strict.
                    stopContainer(container.Id);
                });
            } catch (e) {
                log('Error parsing docker response: ' + e.message);
            }
        });
    });
    req.on('error', (e) => log('Docker API Error: ' + e.message));
    req.end();
}

function stopContainer(id) {
    const options = {
        socketPath: DOCKER_SOCKET,
        path: `/containers/${id}/stop`,
        method: 'POST'
    };
    const req = http.request(options, (res) => {
        log(`Stop command sent for container ${id.substring(0, 12)}: Status ${res.statusCode}`);
    });
    req.end();
}

// --- Helper: Validate License ---
function validateLicense() {
    try {
        if (!fs.existsSync(LICENSE_PATH)) {
            log('Error: License file not found.');
            return false;
        }
        if (!fs.existsSync(PUBLIC_KEY_PATH)) {
            log('Error: Public key not found.');
            return false;
        }

        const licenseData = JSON.parse(fs.readFileSync(LICENSE_PATH, 'utf8'));
        const publicKey = fs.readFileSync(PUBLIC_KEY_PATH, 'utf8');

        // 1. Verify Signature
        const verifier = crypto.createVerify('sha256');
        verifier.update(licenseData.payload);
        const isValid = verifier.verify(publicKey, licenseData.signature, 'base64');

        if (!isValid) {
            log('VIOLATION: Invalid License Signature.');
            return false;
        }

        // 2. Check Expiry
        const payload = JSON.parse(licenseData.payload);
        const expiryDate = new Date(payload.expiry);
        const now = new Date();

        if (now > expiryDate) {
            log(`VIOLATION: License Expired. Expiry: ${expiryDate.toISOString()}, Now: ${now.toISOString()}`);
            return false;
        }

        // 3. Anti-Tamper (Clock Rollback)
        let lastSeen = 0;
        if (fs.existsSync(STATE_FILE_PATH)) {
            const state = JSON.parse(fs.readFileSync(STATE_FILE_PATH, 'utf8'));
            lastSeen = new Date(state.lastSeen).getTime();
        }

        if (now.getTime() < lastSeen) {
            log(`VIOLATION: Clock Tampering Detected. Last Seen: ${new Date(lastSeen).toISOString()}, Now: ${now.toISOString()}`);
            return false;
        }

        // Update State
        fs.writeFileSync(STATE_FILE_PATH, JSON.stringify({ lastSeen: now.toISOString() }));
        
        log(`License Valid. Expires: ${expiryDate.toISOString()}`);
        return true;

    } catch (e) {
        log('Error validating license: ' + e.message);
        return false;
    }
}

// --- Main Loop ---
log('Starting Watchdog...');
setInterval(() => {
    if (!validateLicense()) {
        stopContainers();
    }
}, CHECK_INTERVAL_MS);

// Initial check
if (!validateLicense()) {
    stopContainers();
}
