# Chapter 11: Performance and Optimization

PureScript compiles to JavaScript, so its performance characteristics are those of JavaScript — with some functional programming considerations. This chapter covers how to write fast PureScript code and avoid common pitfalls.

## Tail Call Optimization

PureScript optimizes self-recursive tail calls into loops:

```purescript
-- ✓ Tail recursive: the recursive call is the last operation
sum :: Array Int -> Int
sum = go 0
  where
    go acc [] = acc
    go acc (x : xs) = go (acc + x) xs
    -- Compiles to a while loop

-- ✗ NOT tail recursive: multiplication happens after the recursive call
factorial :: Int -> Int
factorial 0 = 1
factorial n = n * factorial (n - 1)
-- Each call adds a stack frame

-- ✓ Tail recursive version
factorial' :: Int -> Int
factorial' n = go n 1
  where
    go 0 acc = acc
    go k acc = go (k - 1) (k * acc)
```

The pattern: introduce an accumulator parameter that carries the result. The recursive call must be the very last thing the function does.

### Mutual Recursion

PureScript only optimizes self-recursion. For mutual recursion, use trampolining:

```purescript
import Control.Monad.Trampoline (Trampoline, done, delay, runTrampoline)

even' :: Int -> Trampoline Boolean
even' 0 = done true
even' n = delay \_ -> odd' (n - 1)

odd' :: Int -> Trampoline Boolean
odd' 0 = done false
odd' n = delay \_ -> even' (n - 1)

isEven :: Int -> Boolean
isEven n = runTrampoline (even' (abs n))
```

`Trampoline` converts mutual recursion into a loop by bouncing between thunks.

## Strictness and Evaluation

PureScript is strict (eager) — expressions are evaluated immediately. This means:

```purescript
-- Both branches are NOT evaluated eagerly in case expressions
-- Only the matching branch executes
case condition of
  true -> expensiveComputation
  false -> cheapDefault

-- But function arguments ARE evaluated before the function runs
f (expensiveComputation) -- expensiveComputation runs even if f ignores it
```

### Lazy Evaluation When Needed

Use thunks or `Data.Lazy` for deferred computation:

```purescript
import Data.Lazy (Lazy, defer, force)

-- Deferred: computation happens only when forced
expensiveResult :: Lazy BigResult
expensiveResult = defer \_ -> computeExpensiveThing

-- Force when needed
useResult :: BigResult
useResult = force expensiveResult
```

## Data Structure Performance

### Arrays

PureScript arrays are JavaScript arrays:

```purescript
-- O(1) - index access
Array.index xs 5

-- O(n) - cons (prepend)
Array.cons x xs  -- creates a new array

-- O(n) - snoc (append)
Array.snoc xs x  -- creates a new array

-- O(n) - map, filter, foldl
map f xs
filter p xs
```

For frequent prepend/append, consider using a different structure.

### Lists

Linked lists are better for prepend-heavy workloads:

```purescript
import Data.List (List(..), (:))

-- O(1) - cons (prepend)
x : xs

-- O(n) - index access
List.index xs 5

-- O(n) - snoc (append)
List.snoc xs x
```

### Maps

`Data.Map` is a balanced binary tree:

```purescript
import Data.Map as Map

-- O(log n) - insert, lookup, delete
Map.insert key value m
Map.lookup key m
Map.delete key m
```

For string keys with frequent access, consider using `Foreign.Object` (JavaScript object underneath):

```purescript
import Foreign.Object as Object

-- O(1) average - insert, lookup, delete
Object.insert key value obj
Object.lookup key obj
Object.delete key obj
```

## Avoiding Allocation

In hot loops (e.g., animation frames at 90fps), allocation pressure causes garbage collection pauses.

### Preallocate Buffers

```purescript
-- Bad: allocates a new array every frame
updatePositions :: Array Position -> Array Position
updatePositions = map (\p -> p { x = p.x + 1.0 })

-- Better: use a mutable typed array via FFI for hot paths
foreign import updatePositionsInPlace :: Float32Array -> Effect Unit
```

### Reuse Objects

```purescript
-- Bad: creates intermediate objects
transform :: Vec3 -> Mat4 -> Vec3
transform v m =
  let
    rotated = rotate m v      -- new Vec3
    scaled = scale 2.0 rotated  -- new Vec3
    translated = translate offset scaled  -- new Vec3
  in translated

-- Better: combine into one operation via FFI
foreign import transformVec3 :: Vec3 -> Mat4 -> Vec3
```

### Use Typed Arrays for Numeric Data

```purescript
-- For WebGL/WebXR, use Float32Array instead of Array Number
foreign import createFloat32Array :: Int -> Effect Float32Array
foreign import setFloat32 :: Float32Array -> Int -> Number -> Effect Unit
foreign import getFloat32 :: Float32Array -> Int -> Effect Number
```

## Profiling

### Browser DevTools

1. Build with source maps: `spago build`.
2. Open Chrome DevTools → Performance tab.
3. Record a session and inspect the flame chart.
4. PureScript function names are preserved in the output, making profiling readable.

### Benchmarking

Use `purescript-benchotron` or simple timing:

```purescript
import Effect.Now (now)
import Data.DateTime.Instant (unInstant)

benchmark :: forall a. String -> Effect a -> Effect a
benchmark label action = do
  start <- now
  result <- action
  end <- now
  let duration = unInstant end - unInstant start
  log (label <> ": " <> show duration <> "ms")
  pure result
```

## Common Performance Pitfalls

### 1. Unnecessary Intermediate Structures

```purescript
-- Bad: creates 3 intermediate arrays
result = xs
  # map f      -- array 1
  # filter p   -- array 2
  # map g      -- array 3

-- Better: combine map and filter
result = xs # foldl (\acc x ->
  let y = f x
  in if p y then Array.snoc acc (g y) else acc
) []
```

### 2. String Concatenation in Loops

```purescript
-- Bad: O(n²) string building
buildString :: Array String -> String
buildString = foldl (\acc s -> acc <> s) ""

-- Better: join once
buildString :: Array String -> String
buildString = joinWith ""
```

### 3. Deep Record Nesting

```purescript
-- Bad: updating deep fields creates many intermediate records
updateDeep :: State -> State
updateDeep s = s
  { level1 = s.level1
    { level2 = s.level1.level2
      { value = newValue }
    }
  }

-- Better: flatten your state or use lenses
import Data.Lens ((.~))

updateDeep :: State -> State
updateDeep = _level1 <<< _level2 <<< _value .~ newValue
```

### 4. Unbounded Recursion Without Tail Calls

```purescript
-- Bad: will stack overflow for large inputs
length :: forall a. List a -> Int
length Nil = 0
length (Cons _ xs) = 1 + length xs

-- Good: tail recursive with accumulator
length :: forall a. List a -> Int
length = go 0
  where
    go acc Nil = acc
    go acc (Cons _ xs) = go (acc + 1) xs
```

## Performance Budget

For real-time applications (XR at 90fps):

| Phase | Time |
|---|---|
| Total frame | 11.1ms |
| Input reading | ~1ms |
| State update | ~1-2ms |
| Render submission | ~2-3ms |
| GPU work | ~5ms |
| GC headroom | ~1ms |

Tips for staying within budget:
- Keep the pure state update under 2ms.
- Preallocate all buffers during initialization.
- Use mutation (behind `Effect`) for WebGL buffer updates.
- Batch draw calls to minimize GPU state changes.
- Profile on target hardware (Quest 3), not desktop.

## When to Drop to JavaScript

Use FFI for:
- Hot inner loops running every frame.
- WebGL buffer manipulation.
- Typed array operations.
- Complex math that benefits from SIMD-style operations.

Keep in PureScript:
- State management and transitions.
- Business logic and validation.
- Component architecture and composition.
- Everything that runs once or infrequently.

The boundary: PureScript decides *what* to do; JavaScript does the *how* for performance-critical operations.

## Summary

- PureScript optimizes tail-recursive functions into loops.
- Use accumulators to make recursive functions tail-recursive.
- Choose data structures based on access patterns: Array for indexing, List for prepend, Map for keyed lookup.
- Avoid allocation in hot loops — preallocate buffers and use typed arrays.
- Profile with browser DevTools; PureScript function names are preserved.
- Use FFI for performance-critical inner loops; keep logic in PureScript.
