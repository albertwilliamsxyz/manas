# PureScript Mini Book

A practical guide to learning PureScript and using it effectively for real-world applications.

---

## Who This Book Is For

This book is for developers who want to write correct, composable, and maintainable software using PureScript. Whether you come from JavaScript, TypeScript, Haskell, or another language, this book will give you a solid foundation in PureScript's type system, functional patterns, and ecosystem.

## Why PureScript?

PureScript is a strongly-typed, purely functional programming language that compiles to JavaScript. It offers:

- **A sound type system** — no `any`, no runtime type errors, no null pointer exceptions.
- **Algebraic data types and pattern matching** — model your domain precisely.
- **Type classes** — ad-hoc polymorphism done right.
- **Controlled effects** — side effects are tracked in the type system via `Effect` and `Aff`.
- **JavaScript interop** — call JavaScript from PureScript and vice versa through a well-defined FFI.
- **Small, readable output** — the generated JavaScript is clean and debuggable.

## Table of Contents

1. [Introduction to PureScript](01-introduction.md)
   Getting started, philosophy, and how PureScript differs from other languages.

2. [Type System Fundamentals](02-type-system.md)
   Primitive types, type annotations, type inference, and parametric polymorphism.

3. [Functions and Composition](03-functions-and-composition.md)
   Currying, partial application, point-free style, and function composition operators.

4. [Algebraic Data Types](04-algebraic-data-types.md)
   Sum types, product types, newtypes, records, and pattern matching.

5. [Type Classes](05-type-classes.md)
   Defining and using type classes, common type class hierarchies, and instances.

6. [Effects and Monads](06-effects-and-monads.md)
   `Effect`, `Aff`, `do` notation, monad transformers, and managing side effects.

7. [Foreign Function Interface](07-foreign-function-interface.md)
   Calling JavaScript from PureScript, writing FFI modules, and safety considerations.

8. [Project Structure and Tooling](08-project-structure-and-tooling.md)
   Spago, package sets, project layout, and build configuration.

9. [Web and UI Development](09-web-and-ui-development.md)
   Halogen, React via `purescript-react-basic-hooks`, DOM manipulation, and routing.

10. [Testing Strategies](10-testing-strategies.md)
    Unit tests, property-based testing, and integration testing with `purescript-spec` and `purescript-quickcheck`.

11. [Performance and Optimization](11-performance-and-optimization.md)
    Tail call optimization, lazy evaluation, profiling, and avoiding common pitfalls.

12. [PureScript in Practice](12-purescript-in-practice.md)
    Architecture patterns, error handling strategies, and applying PureScript to real projects.

---

## Conventions Used in This Book

- Code examples are complete and runnable unless noted otherwise.
- Type signatures are always shown — they are documentation.
- Each chapter builds on the previous, but chapters 7–12 can be read independently.
