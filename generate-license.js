const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

// --- Configuration ---
const PRIVATE_KEY_PATH = process.env.PRIVATE_KEY_PATH || path.join(__dirname, 'private.pem');
const PUBLIC_KEY_PATH = process.env.PUBLIC_KEY_PATH || path.join(__dirname, 'public.pem');
const LICENSE_FILE_PATH = process.env.LICENSE_FILE_PATH || path.join(__dirname, 'license.key');

// --- Helper: Generate Keys if missing ---
function generateKeys() {
    if (fs.existsSync(PRIVATE_KEY_PATH) && fs.existsSync(PUBLIC_KEY_PATH)) {
        console.log('Keys already exist. Using existing keys.');
        return;
    }
    console.log('Generating new RSA key pair...');
    const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: { type: 'spki', format: 'pem' },
        privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
    });
    fs.writeFileSync(PRIVATE_KEY_PATH, privateKey);
    fs.writeFileSync(PUBLIC_KEY_PATH, publicKey);
    console.log('Keys generated successfully.');
}

// --- Helper: Create License ---
function createLicense(dateStr, timeStr) {
    if (!fs.existsSync(PRIVATE_KEY_PATH)) {
        console.error('Error: Private key not found. Run this script once to generate keys.');
        process.exit(1);
    }

    // Combine date and time if provided, otherwise default to end of day
    let isoString;
    if (timeStr) {
        // "YYYY-MM-DD HH:mm:ss" -> "YYYY-MM-DDTHH:mm:ss+05:30"
        isoString = `${dateStr}T${timeStr}+05:30`;
    } else {
        // "YYYY-MM-DD" -> "YYYY-MM-DDT23:59:59+05:30"
        isoString = `${dateStr}T23:59:59+05:30`;
    }

    const expiryDate = new Date(isoString);
    
    if (isNaN(expiryDate.getTime())) {
        console.error('Error: Invalid date format. Use YYYY-MM-DD or "YYYY-MM-DD HH:mm:ss".');
        process.exit(1);
    }

    console.log(`Generating license for IST Time: ${dateStr} ${timeStr || '23:59:59'}`);
    console.log(`Stored as UTC (ISO): ${expiryDate.toISOString()}`);

    const payload = JSON.stringify({
        expiry: expiryDate.toISOString(),
        issuedAt: new Date().toISOString(),
        type: 'offline-license'
    });

    const privateKey = fs.readFileSync(PRIVATE_KEY_PATH, 'utf8');
    const signature = crypto.sign("sha256", Buffer.from(payload), privateKey);

    const licenseData = {
        payload: payload,
        signature: signature.toString('base64')
    };

    fs.writeFileSync(LICENSE_FILE_PATH, JSON.stringify(licenseData, null, 2));
    console.log(`License generated successfully!`);
    console.log(`Saved to: ${LICENSE_FILE_PATH}`);
}

// --- Main ---
const args = process.argv.slice(2);
if (args.length === 0) {
    generateKeys();
    console.log('\nUsage: node generate-license.js <YYYY-MM-DD> [HH:mm:ss]');
    console.log('Examples:');
    console.log('  node generate-license.js 2025-12-31            (Defaults to 23:59:59 IST)');
    console.log('  node generate-license.js 2025-12-31 14:30:00   (Specific IST Time)');
} else {
    generateKeys(); // Ensure keys exist
    createLicense(args[0], args[1]);
}
