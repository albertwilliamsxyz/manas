# Chapter 1: Introduction to PureScript

## What Is PureScript?

PureScript is a strongly-typed, purely functional programming language that compiles to readable JavaScript. Created by Phil Freeman in 2013, it brings the rigor of Haskell-style programming to the JavaScript ecosystem without the complexity of lazy evaluation.

Unlike TypeScript, which adds types on top of JavaScript's semantics, PureScript is a completely separate language with its own semantics. The type system is sound — if your program compiles, you have strong guarantees about its behavior at runtime.

## Philosophy

PureScript is built on three core principles:

1. **Purity by default.** Functions do not have side effects unless their type says so. A function `add :: Int -> Int -> Int` will never write to disk, make a network request, or throw an exception.

2. **Types as documentation.** The type signature of a function tells you almost everything you need to know about what it does. When types are precise, you rarely need to read the implementation.

3. **Composition over configuration.** Small, well-typed functions compose into larger systems. There is no framework — just functions and types.

## PureScript vs. Haskell

PureScript borrows heavily from Haskell, but differs in important ways:

| Feature | PureScript | Haskell |
|---|---|---|
| Evaluation | Strict (eager) | Lazy |
| Compilation target | JavaScript | Native / LLVM |
| Records | Extensible row types | Nominal records |
| Type classes | No orphan instances allowed | Orphan instances possible |
| Strings | JavaScript strings | Packed byte arrays |
| Ecosystem | npm + Spago | Cabal / Stack |

Strict evaluation means you always know when computation happens. There are no thunks, no space leaks from unevaluated expressions, and no need for bang patterns.

## PureScript vs. TypeScript

TypeScript makes JavaScript safer. PureScript makes a different set of tradeoffs:

| Feature | PureScript | TypeScript |
|---|---|---|
| Type soundness | Sound | Unsound (by design) |
| Null safety | No null/undefined in types | Optional chaining, strict mode |
| Effects | Tracked in types | Untracked |
| Pattern matching | Exhaustive, first-class | Switch statements |
| Immutability | Default | Opt-in with `readonly` |
| Learning curve | Steeper | Gentler |

Choose PureScript when correctness matters more than onboarding speed.

## Your First PureScript Program

```purescript
module Main where

import Prelude
import Effect (Effect)
import Effect.Console (log)

main :: Effect Unit
main = log "Hello, PureScript!"
```

Let's break this down:

- `module Main where` — every PureScript file is a module.
- `import Prelude` — imports the standard prelude (basic types and functions).
- `import Effect (Effect)` — imports the `Effect` type, which represents side effects.
- `import Effect.Console (log)` — imports the `log` function for console output.
- `main :: Effect Unit` — the type says: `main` is an effectful computation that produces no meaningful value.
- `main = log "Hello, PureScript!"` — the implementation: print a string to the console.

The type `Effect Unit` is key. It is the PureScript equivalent of `void` in a function that does I/O. You cannot accidentally call an `Effect` function as if it were pure — the type system prevents it.

## Installing PureScript

The recommended setup:

```bash
# Install PureScript compiler and Spago (build tool)
npm install -g purescript spago

# Verify installation
purs --version
spago --version
```

Create a new project:

```bash
spago init
spago build
spago run
```

`spago init` creates a project with a `spago.yaml` configuration, a `src/` directory, and a `test/` directory. `spago build` compiles all PureScript source files. `spago run` executes the `main` function.

## The REPL

PureScript has an interactive REPL for exploration:

```bash
spago repl
```

```
> import Prelude
> 1 + 2
3

> :type map
forall (f :: Type -> Type) (a :: Type) (b :: Type). Functor f => (a -> b) -> f a -> f b

> map (_ * 2) [1, 2, 3]
[2, 4, 6]
```

Use `:type` to inspect types, `:kind` to inspect kinds, and `:quit` to exit.

## What You Will Learn

This book progresses from fundamentals to practical application:

- **Chapters 2–5** build your understanding of PureScript's type system, functions, data types, and type classes.
- **Chapter 6** introduces effects and monads — how PureScript manages side effects without sacrificing purity.
- **Chapter 7** covers the Foreign Function Interface for interoperating with JavaScript.
- **Chapters 8–12** focus on practical concerns: project structure, web development, testing, performance, and real-world architecture.

By the end, you will be able to write, test, and deploy PureScript applications that are correct by construction.
