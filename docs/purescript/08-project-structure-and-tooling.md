# Chapter 8: Project Structure and Tooling

This chapter covers how to set up, organize, build, and manage PureScript projects using modern tooling.

## Spago: The Build Tool

Spago is the standard build tool for PureScript. It handles compilation, dependency management, testing, and more.

### Installing Spago

```bash
npm install -g spago purescript
```

Or with Nix:

```bash
nix-shell -p spago purescript
```

### Creating a New Project

```bash
mkdir my-project && cd my-project
spago init
```

This creates:

```
my-project/
├── spago.yaml          # Project configuration
├── src/
│   └── Main.purs       # Entry point
└── test/
    └── Test/
        └── Main.purs   # Test entry point
```

### spago.yaml

The configuration file defines your project:

```yaml
package:
  name: my-project
  dependencies:
    - prelude
    - console
    - effect
    - aff
    - maybe
    - either
    - arrays
    - strings
  test:
    main: Test.Main
    dependencies:
      - spec
      - quickcheck

workspace:
  packageSet:
    registry: 55.4.0  # Package set version
```

Key sections:
- `dependencies` — libraries your code uses.
- `test.dependencies` — additional libraries used only in tests.
- `packageSet` — the curated set of package versions that are known to compile together.

### Common Spago Commands

```bash
spago build          # Compile the project
spago run            # Compile and run src/Main.purs
spago test           # Compile and run test/Test/Main.purs
spago repl           # Start an interactive REPL
spago install <pkg>  # Add a dependency
spago docs           # Generate documentation
spago bundle-app     # Bundle for browser deployment
```

## Project Layout

A well-organized PureScript project:

```
my-project/
├── spago.yaml
├── src/
│   ├── Main.purs
│   ├── App/
│   │   ├── Types.purs
│   │   ├── State.purs
│   │   └── Effects.purs
│   ├── Data/
│   │   ├── User.purs
│   │   └── Config.purs
│   └── Utils/
│       ├── String.purs
│       └── Array.purs
├── test/
│   ├── Test/
│   │   └── Main.purs
│   └── Test/
│       ├── App/
│       │   └── StateSpec.purs
│       └── Data/
│           └── UserSpec.purs
└── output/               # Generated JavaScript (gitignored)
```

### Module Naming Conventions

Modules follow the directory structure:

```purescript
-- src/App/Types.purs
module App.Types where

-- src/Data/User.purs
module Data.User where

-- test/Test/App/StateSpec.purs
module Test.App.StateSpec where
```

Module names are hierarchical, separated by dots. The convention:
- `Data.*` — pure data types and operations.
- `App.*` — application-specific modules.
- `Utils.*` — general-purpose utilities.
- `Test.*` — test modules.

## Dependency Management

### Adding Dependencies

```bash
spago install argonaut    # JSON handling
spago install aff         # Async effects
spago install halogen     # UI framework
```

This updates `spago.yaml` and downloads the package.

### Package Sets

PureScript uses curated package sets — collections of packages at specific versions that are guaranteed to compile together. This eliminates dependency hell:

```yaml
workspace:
  packageSet:
    registry: 55.4.0
```

All packages in a set are version-locked. When you upgrade the set, all packages upgrade together.

### Extra Packages

For packages not in the standard set:

```yaml
workspace:
  extraPackages:
    my-local-lib:
      path: ./lib/my-local-lib
    some-git-lib:
      git: https://github.com/user/repo.git
      ref: v1.0.0
```

## Building for Production

### Bundle for Browser

```bash
spago bundle-app --to dist/app.js
```

This produces a single JavaScript file suitable for `<script>` tags. For more control, use esbuild or webpack:

```bash
spago build
npx esbuild output/Main/index.js --bundle --outfile=dist/app.js --minify
```

### Bundle for Node.js

```bash
spago bundle-app --platform node --to dist/server.js
```

## Integration with JavaScript Tools

### Using with npm

PureScript projects can live alongside JavaScript projects:

```json
{
  "name": "my-project",
  "scripts": {
    "build:purs": "spago build",
    "build:js": "esbuild src/index.js --bundle --outfile=dist/index.js",
    "build": "npm run build:purs && npm run build:js",
    "test": "spago test",
    "dev": "spago build --watch"
  },
  "devDependencies": {
    "esbuild": "^0.19.0",
    "purescript": "^0.15.0",
    "spago": "^0.21.0"
  }
}
```

### Using with Vite

For web projects with hot module replacement:

```javascript
// vite.config.js
import { defineConfig } from "vite";

export default defineConfig({
  build: {
    rollupOptions: {
      input: "src/index.js",
    },
  },
});
```

```javascript
// src/index.js
import { main } from "../output/Main/index.js";
main();
```

Run `spago build --watch` in one terminal and `vite` in another for a fast development loop.

## Editor Setup

### VS Code

Install the "PureScript IDE" extension (`nwolverson.ide-purescript`) and "PureScript Language Support" (`nwolverson.language-purescript`).

The extension provides:
- Type information on hover
- Autocomplete with type signatures
- Go to definition
- Inline errors
- Automatic imports

Configuration (`settings.json`):

```json
{
  "purescript.addSpagoSources": true,
  "purescript.buildCommand": "spago build --purs-args --json-errors"
}
```

### Vim/Neovim

Use `purescript-vim` for syntax highlighting and `ale` or `coc.nvim` for language server integration.

## Continuous Integration

A basic GitHub Actions workflow:

```yaml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm install -g purescript spago
      - run: spago build
      - run: spago test
```

## Summary

- Spago is the standard build tool: `spago build`, `spago test`, `spago repl`.
- Package sets eliminate dependency conflicts.
- Organize modules by domain: `Data.*`, `App.*`, `Utils.*`.
- Bundle with `spago bundle-app` or pipe through esbuild for production.
- Integrate with JavaScript tools (npm, Vite, esbuild) for web projects.
- Set up editor support for type-driven development.
