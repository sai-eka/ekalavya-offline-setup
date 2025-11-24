# Administrator Guide: License Generation

This guide is for the **Administrator** only. Do not distribute this file or the `generate-license.js` script to the end-users.

## Prerequisites for Admin

- Node.js (v18+) installed on your machine.

## How to Generate a License

1.  Open a terminal in the root directory of this repository.
2.  Run the generator script:

    ```bash
    # Usage: node generate-license.js <YYYY-MM-DD> [HH:mm:ss]

    # Example 1: Valid until Dec 31, 2025 (Defaults to 23:59:59 IST)
    node generate-license.js 2025-12-31

    # Example 2: Valid until specific time
    node generate-license.js 2025-12-31 14:30:00
    ```

3.  **Output**: This will create a `license.key` file in the current directory.
4.  **Distribution**: Copy this `license.key` to the deployment folder you are sending to the client.

## Important Security Notes

- **Private Key**: The first time you run the script, it generates a `private.pem`. **KEEP THIS SAFE.** Anyone with this file can generate valid licenses.
- **Public Key**: The `public.pem` file must be included in the distribution folder sent to the client.
