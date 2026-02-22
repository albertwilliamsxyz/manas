# Functional Programming in TypeScript: Complete Guide

## What is Functional Programming?
Functional programming (FP) is a paradigm that treats computation as the evaluation of mathematical functions, avoiding mutable state and side effects.

## Fundamental Principles
- **Pure functions:** The result depends only on the arguments, with no side effects.
- **Immutability:** Data is not modified; new values are created.
- **Composition:** Build complex functions from simple ones.
- **Expressiveness:** Use higher-order functions, currying, and composition.
- **Referential transparency:** An expression can be replaced by its value without changing program behavior.

## Advantages in TypeScript
- **Type Safety:** The type system helps prevent errors.
- **Type inference:** Fewer annotations, more safety.
- **Safe composition:** fp-ts and monocle-ts allow safe composition of functions and data structures.
- **Advanced tooling:** TypeScript provides interfaces, generics, mapped types, and utility types for powerful abstractions.

## Key Tools
- **fp-ts:** Provides ADTs (Option, Either, Task), type classes, and combinators.
- **monocle-ts:** Optics/lenses for deep and immutable data manipulation.
- **lodash/fp:** Functional utilities for data manipulation.
- **TypeScript:** Advanced type system, interfaces, generics, and utility types.

## Essential Concepts
### 1. Pure Functions
```typescript
const add = (a: number, b: number): number => a + b;
// Example: add(2, 3) returns 5
```

### 2. Immutability
```typescript
const arr = [1, 2, 3];
const newArr = [...arr, 4]; // arr remains unchanged
```

### 3. Function Composition
```typescript
const double = (x: number) => x * 2;
const increment = (x: number) => x + 1;
const doubleThenIncrement = (x: number) => increment(double(x));
// Example: doubleThenIncrement(3) returns 7
```

### 4. Currying
```typescript
const multiply = (a: number) => (b: number) => a * b;
const double = multiply(2);
double(5); // 10
```

### 5. ADTs with fp-ts
```typescript
import { Option, some, none } from 'fp-ts/Option';
const safeDivide = (a: number, b: number): Option<number> => b === 0 ? none : some(a / b);
// Example: safeDivide(10, 2) returns some(5), safeDivide(10, 0) returns none
```

### 6. Type Classes and Combinators
```typescript
import { map } from 'fp-ts/Array';
const arr = [1, 2, 3];
const doubled = map((x: number) => x * 2)(arr); // [2, 4, 6]
```

### 7. Optics/Lenses with monocle-ts
```typescript
import { Lens } from 'monocle-ts';
type User = { name: string; address: { city: string } };
const addressLens = Lens.fromProp<User>()('address');
const cityLens = addressLens.compose(Lens.fromProp<User['address']>()('city'));
const user: User = { name: 'Ana', address: { city: 'Madrid' } };
const newUser = cityLens.modify(city => city.toUpperCase())(user);
// Example: newUser.address.city === 'MADRID'
```

### 8. Utilities with lodash/fp
```typescript
import map from 'lodash/fp/map';
const arr = [1, 2, 3];
const squared = map((x: number) => x * x)(arr); // [1, 4, 9]
```

### 9. Higher-Order Functions
```typescript
const applyTwice = (fn: (x: number) => number) => (x: number) => fn(fn(x));
const result = applyTwice(double)(2); // 8
```

### 10. Pattern Matching (with ADTs)
```typescript
import { fold } from 'fp-ts/Option';
const showResult = fold(
  () => 'No result',
  (value: number) => `Result: ${value}`
);
console.log(showResult(safeDivide(10, 2))); // 'Result: 5'
console.log(showResult(safeDivide(10, 0))); // 'No result'
```

## Best Practices
- Prefer pure functions and avoid side effects.
- Use ADTs to model absence of values or errors.
- Compose small, reusable functions.
- Leverage TypeScript's type system for safety and clarity.
- Document your types and functions.
- Use lenses for deep updates and immutable data structures.
- Use combinators and higher-order functions for expressive code.

## Recommended Resources
- [fp-ts documentation](https://gcanti.github.io/fp-ts/)
- [monocle-ts documentation](https://gcanti.github.io/monocle-ts/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [Mostly Adequate Guide to FP (JS)](https://mostly-adequate.gitbooks.io/mostly-adequate-guide/)
- [Functional Programming in JavaScript](https://www.freecodecamp.org/news/functional-programming-in-js/)
- [Haskell for TypeScript Developers](https://github.com/chevrotain/typescript-functional-programming)