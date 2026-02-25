# ADR-007 — Vite + basic-ssl as Build Tool and Dev Server

**Status:** Accepted  
**Date:** 2025  

---

## Context

The project needs:
1. TypeScript compilation with zero configuration overhead.
2. A local HTTPS development server — WebXR requires a secure context even on LAN.
3. Fast iteration cycle (no multi-second builds).

---

## Decision

Use **Vite** as the build tool and development server, with **`@vitejs/plugin-basic-ssl`** for automatic self-signed TLS.

---

## Configuration (`vite.config.js`)

```javascript
import basicSsl from '@vitejs/plugin-basic-ssl'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [basicSsl()],
  server: { https: true },
})
```

That is the entire configuration. Vite handles:
- TypeScript → JavaScript transpilation (via esbuild, sub-millisecond).
- ES module serving with Hot Module Replacement.
- `index.html` as the entry point.
- `<script type="module">` with correct MIME types.

---

## Why Vite over other options?

| Tool | Reason not chosen |
|------|------------------|
| Webpack | Complex configuration, slow cold start |
| Parcel | Less TypeScript control, less predictable |
| tsc + http-server | No HTTPS, no HMR, two processes |
| esbuild directly | No dev server, no plugin ecosystem |

Vite uses **esbuild** internally for transpilation (Go binary, ~100× faster than tsc for transpilation) and **Rollup** for production bundling. Both are best-in-class for their role.

---

## HTTPS and WebXR

WebXR is gated behind a **Secure Context** (HTTPS or `localhost`). Testing on a physical headset (Meta Quest) connected to the dev machine over LAN requires HTTPS at the dev server. `@vitejs/plugin-basic-ssl` generates a self-signed certificate automatically — no manual `openssl` invocation needed.

**Steps to test on a headset:**
1. Run `npx vite` (or `npm run dev`).
2. Note the LAN IP printed (e.g. `https://192.168.1.x:5173`).
3. On the Quest browser, navigate to that URL.
4. Accept the self-signed cert warning.
5. Tap "Start Experience".

---

## TypeScript integration

Vite transpiles TypeScript using esbuild — it strips types and emits modern JavaScript. It does **not** perform type-checking at build time. Run `tsc --noEmit` separately (or in watch mode) for type errors:

```bash
npx tsc --noEmit --watch
```

This separation is intentional: esbuild is fast but not a full type-checker; tsc is slow but complete. Use esbuild for iteration speed, tsc for correctness validation.

---

## Entry point

```html
<!-- index.html -->
<script src="./src/main.ts" type="module" defer></script>
```

Vite resolves this at dev time and replaces it with the transpiled module. No separate bundling step is required during development.

---

## Consequences

- **Positive:** Zero-config TypeScript + HTTPS in a single `vite.config.js`.
- **Positive:** Sub-second hot reload.
- **Positive:** Works with the native browser ES module system — no bundler magic during development.
- **Negative:** Self-signed certs produce browser warnings — acceptable for development, not for production.
- **Negative:** Vite does not type-check — must run `tsc --noEmit` separately as a quality gate.
