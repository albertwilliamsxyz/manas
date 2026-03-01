import { createServer } from "node:https";
import { readFileSync, existsSync, mkdirSync, statSync } from "node:fs";
import { execSync } from "node:child_process";
import { join, extname } from "node:path";
import { networkInterfaces } from "node:os";

const PORT = 8443;
const HOST = process.argv.includes("--host") ? "0.0.0.0" : "localhost";

const CERT_DIR = ".certs";
const CERT_KEY = join(CERT_DIR, "key.pem");
const CERT_FILE = join(CERT_DIR, "cert.pem");

if (!existsSync(CERT_KEY) || !existsSync(CERT_FILE)) {
  console.log("Generating self-signed SSL certificate...");
  mkdirSync(CERT_DIR, { recursive: true });
  execSync(
    `openssl req -x509 -newkey rsa:2048 -keyout ${CERT_KEY} -out ${CERT_FILE} -days 365 -nodes -subj "/CN=localhost"`,
    { stdio: "pipe" }
  );
}

const MIME_TYPES = {
  ".html": "text/html",
  ".js": "application/javascript",
  ".css": "text/css",
  ".json": "application/json",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
};

const server = createServer(
  { key: readFileSync(CERT_KEY), cert: readFileSync(CERT_FILE) },
  (req, res) => {
    const url = req.url.split("?")[0];
    let filePath = "." + (url === "/" ? "/index.html" : url);
    const ext = extname(filePath);
    const contentType = MIME_TYPES[ext] || "application/octet-stream";

    try {
      if (existsSync(filePath) && statSync(filePath).isFile()) {
        res.writeHead(200, { "Content-Type": contentType });
        res.end(readFileSync(filePath));
      } else {
        res.writeHead(404);
        res.end("Not Found");
      }
    } catch {
      res.writeHead(500);
      res.end("Internal Server Error");
    }
  }
);

server.listen(PORT, HOST, () => {
  console.log("\n  HTTPS dev server running:\n");
  console.log(`  > Local:   https://localhost:${PORT}/`);
  if (HOST === "0.0.0.0") {
    const nets = networkInterfaces();
    for (const name of Object.keys(nets)) {
      for (const net of nets[name]) {
        if (net.family === "IPv4" && !net.internal) {
          console.log(`  > Network: https://${net.address}:${PORT}/`);
        }
      }
    }
  }
  console.log(
    "\n  Use --host to expose on your local network (for Meta Quest testing)\n"
  );
});
