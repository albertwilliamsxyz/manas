# Chapter 3: Functions and Composition

Functions are the fundamental unit of abstraction in PureScript. This chapter covers how to define, combine, and reason about functions.

## Function Definitions

There are several ways to define functions:

```purescript
-- Named function with type signature
add :: Int -> Int -> Int
add x y = x + y

-- Anonymous function (lambda)
add' :: Int -> Int -> Int
add' = \x y -> x + y

-- Using where clause
hypotenuse :: Number -> Number -> Number
hypotenuse a b = sqrt (square a + square b)
  where
    square x = x * x

-- Using let binding
hypotenuse' :: Number -> Number -> Number
hypotenuse' a b =
  let
    square x = x * x
  in
    sqrt (square a + square b)
```

`where` and `let` are interchangeable in most cases. Convention: use `where` when the helper is ancillary, `let` when the binding is central to the expression.

## Currying

All PureScript functions are curried. A function that appears to take multiple arguments actually takes one argument and returns a function:

```purescript
add :: Int -> Int -> Int
add x y = x + y

-- This is equivalent to:
add :: Int -> (Int -> Int)
add = \x -> \y -> x + y
```

The arrow `->` associates to the right, so `Int -> Int -> Int` means `Int -> (Int -> Int)`.

## Partial Application

Because functions are curried, you can supply fewer arguments than expected to get a new function:

```purescript
add :: Int -> Int -> Int
add x y = x + y

increment :: Int -> Int
increment = add 1

double :: Int -> Int
double = add 0 >>> (_ * 2)  -- or: double x = x * 2
```

Partial application is the primary way to create specialized functions from general ones. Design your function argument order so that the most likely-to-vary argument comes last:

```purescript
-- Good: the array varies, the predicate is often fixed
filter :: forall a. (a -> Boolean) -> Array a -> Array a

-- Usage
positives = filter (_ > 0)
```

## Function Composition

Two operators compose functions:

```purescript
-- Forward composition: apply f first, then g
(>>>) :: forall a b c. (a -> b) -> (b -> c) -> (a -> c)

-- Backward composition: apply g first, then f
(<<<) :: forall a b c. (b -> c) -> (a -> b) -> (a -> c)
```

Examples:

```purescript
import Data.String (length, toUpper)

-- Forward: read left to right
shoutLength :: String -> Int
shoutLength = toUpper >>> length

-- Backward: read right to left (like mathematical notation)
shoutLength' :: String -> Int
shoutLength' = length <<< toUpper
```

Choose whichever reads more naturally for your use case. In pipelines, forward composition (`>>>`) is often clearer.

## The Apply Operator

The `$` operator applies a function to an argument with low precedence, eliminating parentheses:

```purescript
-- Without $
log (show (add 1 2))

-- With $
log $ show $ add 1 2
```

`$` is right-associative, so `f $ g $ x` means `f (g x)`.

## The Pipe Operator

The `#` operator (apply flipped) sends a value through a pipeline:

```purescript
-- Without #
length (filter (_ > 0) (map (_ * 2) numbers))

-- With # (read top to bottom)
numbers
  # map (_ * 2)
  # filter (_ > 0)
  # length
```

This is the PureScript equivalent of method chaining. The value flows left to right through each transformation.

## Point-Free Style

Point-free style defines functions without naming their arguments:

```purescript
-- Pointed (explicit arguments)
doubleAll :: Array Int -> Array Int
doubleAll xs = map (_ * 2) xs

-- Point-free (no explicit arguments)
doubleAll :: Array Int -> Array Int
doubleAll = map (_ * 2)
```

Point-free is cleaner when the pipeline is simple. When it becomes hard to read, name your arguments.

## Wildcards in Lambdas

PureScript supports concise anonymous functions using `_`:

```purescript
-- Full lambda
map (\x -> x + 1) [1, 2, 3]

-- Wildcard lambda
map (_ + 1) [1, 2, 3]

-- Multiple uses create multiple arguments
(\a b -> a + b)  ==  (_ + _)  -- ⚠ this creates a binary function
```

Be careful: each `_` in an expression introduces a new argument. `_ + _` is `\a b -> a + b`, not `\a -> a + a`.

## Guards

Guards add conditional logic to function definitions:

```purescript
abs :: Int -> Int
abs n
  | n < 0 = negate n
  | otherwise = n

classify :: Int -> String
classify n
  | n < 0 = "negative"
  | n == 0 = "zero"
  | otherwise = "positive"
```

Guards are checked top-to-bottom. `otherwise` is just `true`.

## Recursion

PureScript does not have loops. Use recursion instead:

```purescript
factorial :: Int -> Int
factorial 0 = 1
factorial n = n * factorial (n - 1)

-- With accumulator for tail-call optimization
factorial' :: Int -> Int
factorial' n = go n 1
  where
    go 0 acc = acc
    go k acc = go (k - 1) (k * acc)
```

The second version uses tail recursion — the recursive call is the last thing the function does. PureScript optimizes tail calls into loops, so `factorial'` runs in constant stack space.

## Common Higher-Order Functions

These functions appear everywhere in PureScript code:

```purescript
-- Transform each element
map :: forall a b. (a -> b) -> Array a -> Array b
map (_ * 2) [1, 2, 3]  -- [2, 4, 6]

-- Keep elements matching a predicate
filter :: forall a. (a -> Boolean) -> Array a -> Array a
filter (_ > 2) [1, 2, 3, 4]  -- [3, 4]

-- Reduce to a single value
foldl :: forall a b. (b -> a -> b) -> b -> Array a -> b
foldl (+) 0 [1, 2, 3]  -- 6

-- Apply a function to a value
apply :: forall a b. (a -> b) -> a -> b
apply f x = f x
```

## Summary

- All functions are curried; partial application is free.
- Use `>>>` for forward composition, `<<<` for backward.
- Use `#` to pipe values through transformations.
- Point-free style is a tool, not a goal — readability comes first.
- Tail-recursive functions are optimized into loops.
