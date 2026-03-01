/**
 * serve-https.mjs
 * Local HTTPS dev server for testing WebXR on Meta Quest.
 *
 * Generates a self-signed certificate on the fly using Node's crypto module.
 * No external tools required beyond Node.js.
 *
 * Usage:
 *   node serve-https.mjs
 *
 * Then on Meta Quest browser: https://192.168.0.104:3443
 * Accept the "connection not private" warning once, then the app loads.
 *
 * To rebuild PureScript and refresh:
 *   npm run build  (in a separate terminal)
 */

import https from 'https'
import fs from 'fs'
import path from 'path'
import { execSync } from 'child_process'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const PORT = 3443
const ROOT = __dirname

// ---------------------------------------------------------------------------
// Self-signed certificate generation
// ---------------------------------------------------------------------------
// We generate the cert fresh each run using openssl (available on macOS by default).
// The cert is kept in memory only — never written to disk.
//
// If you want the Meta Quest browser to fully trust the cert without a warning,
// follow the MKCERT instructions at the bottom of this file instead.

const generateSelfSignedCert = () => {
    try {
        const keyFile = path.join(ROOT, '.dev-key.pem')
        const certFile = path.join(ROOT, '.dev-cert.pem')

        // Only regenerate if files don't exist yet
        if (!fs.existsSync(keyFile) || !fs.existsSync(certFile)) {
            console.log('Generating self-signed certificate...')
            execSync(
                `openssl req -x509 -newkey rsa:2048 -keyout "${keyFile}" -out "${certFile}" ` +
                `-days 365 -nodes -subj "/CN=localhost" ` +
                `-addext "subjectAltName=IP:192.168.0.104,IP:127.0.0.1,DNS:localhost"`,
                { stdio: 'pipe' }
            )
            console.log('Certificate generated.')
        }

        return {
            key: fs.readFileSync(keyFile),
            cert: fs.readFileSync(certFile),
        }
    } catch (err) {
        console.error('openssl not found. Install it via: brew install openssl')
        process.exit(1)
    }
}

// ---------------------------------------------------------------------------
// MIME types
// ---------------------------------------------------------------------------

const MIME = {
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.wasm': 'application/wasm',
    '.json': 'application/json',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
}

// ---------------------------------------------------------------------------
// Request handler
// ---------------------------------------------------------------------------

const serve = (req, res) => {
    let urlPath = req.url.split('?')[0]  // strip query string
    if (urlPath === '/' || urlPath === '') urlPath = '/index.html'

    const filePath = path.join(ROOT, urlPath)

    // Security: don't serve files outside the project root
    if (!filePath.startsWith(ROOT)) {
        res.writeHead(403)
        res.end('Forbidden')
        return
    }

    const ext = path.extname(filePath)
    const mime = MIME[ext] ?? 'application/octet-stream'

    fs.readFile(filePath, (err, data) => {
        if (err) {
            if (err.code === 'ENOENT') {
                res.writeHead(404, { 'Content-Type': 'text/plain' })
                res.end(`Not found: ${urlPath}`)
            } else {
                res.writeHead(500)
                res.end('Server error')
            }
            return
        }

        res.writeHead(200, {
            'Content-Type': mime,
            // Required for SharedArrayBuffer (used by some WebXR features):
            'Cross-Origin-Opener-Policy': 'same-origin',
            'Cross-Origin-Embedder-Policy': 'require-corp',
        })
        res.end(data)
    })
}

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

const { key, cert } = generateSelfSignedCert()
const server = https.createServer({ key, cert }, serve)

server.listen(PORT, '0.0.0.0', () => {
    console.log()
    console.log('  HTTPS dev server running')
    console.log()
    console.log('  Local:   https://localhost:' + PORT)
    console.log('  Network: https://192.168.0.104:' + PORT)
    console.log()
    console.log('  On Meta Quest browser → open: https://192.168.0.104:' + PORT)
    console.log('  Accept the "connection not private" warning → Advanced → Proceed')
    console.log()
    console.log('  Rebuild: npm run build  (in another terminal)')
    console.log('  Then reload the Quest browser.')
    console.log()
})

/*
=============================================================================
OPTIONAL: Fully trusted certificate with mkcert (no browser warning)
=============================================================================

If you want zero warnings on the Quest:

1. On your Mac, install mkcert:
     brew install mkcert
     mkcert -install

2. Generate a cert for your local IP:
     mkcert 192.168.0.104 localhost 127.0.0.1

   This creates: 192.168.0.104+2.pem  and  192.168.0.104+2-key.pem

3. Update this file to load those files instead of the generated ones:
     key:  fs.readFileSync('192.168.0.104+2-key.pem')
     cert: fs.readFileSync('192.168.0.104+2.pem')

4. To trust the cert on Meta Quest:
   a. Find mkcert's root CA: mkcert -CAROOT
   b. Copy the rootCA.pem file to your Quest via: adb push rootCA.pem /sdcard/
   c. On Quest → Settings → Security → Install from storage → rootCA.pem
   d. Confirm install (may need to set a PIN if not set)
   → No more warnings. Works like a real HTTPS site.
=============================================================================
*/
