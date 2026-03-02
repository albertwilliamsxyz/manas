# Chapter 7: Foreign Function Interface

PureScript compiles to JavaScript, and the Foreign Function Interface (FFI) is how you bridge between the two worlds. This chapter covers how to call JavaScript from PureScript, how to write FFI modules safely, and when to use them.

## When to Use FFI

Use the FFI when you need to:

1. Call a JavaScript library that has no PureScript bindings.
2. Access browser APIs (DOM, WebGL, WebXR, Web Audio).
3. Perform operations that are impractical in pure PureScript (e.g., mutation-heavy algorithms for performance).
4. Interface with Node.js APIs.

Avoid the FFI when a pure PureScript solution exists — every FFI boundary is an unchecked trust boundary.

## FFI Module Structure

Every PureScript module can have a companion JavaScript file. If your PureScript module is `src/Utils.purs`, the FFI file is `src/Utils.js`:

**src/Utils.purs:**
```purescript
module Utils where

foreign import add :: Int -> Int -> Int
foreign import now :: Effect Number
```

**src/Utils.js:**
```javascript
export const add = (a) => (b) => a + b;
export const now = () => Date.now();
```

Key rules:
- The JavaScript file must use ES module syntax (`export`).
- Every `foreign import` must have a corresponding `export` in the JS file.
- Curried functions: PureScript functions take one argument at a time, so `add :: Int -> Int -> Int` maps to `(a) => (b) => a + b`, not `(a, b) => a + b`.
- Effects: `Effect a` maps to `() => a` — a thunk that produces a value.

## Currying Convention

PureScript functions are curried. Your FFI functions must match:

```javascript
// PureScript: add :: Int -> Int -> Int
export const add = (a) => (b) => a + b;

// PureScript: greet :: String -> String -> String
export const greet = (greeting) => (name) => greeting + ", " + name + "!";

// PureScript: multiply3 :: Number -> Number -> Number -> Number
export const multiply3 = (a) => (b) => (c) => a * b * c;
```

## Effects in FFI

Functions with side effects must be wrapped in thunks:

```javascript
// PureScript: log :: String -> Effect Unit
export const log = (msg) => () => console.log(msg);

// PureScript: getTime :: Effect Number
export const getTime = () => Date.now();

// PureScript: setItem :: String -> String -> Effect Unit
export const setItem = (key) => (value) => () => {
  localStorage.setItem(key, value);
};
```

The pattern: arguments come first (curried), then a final `() =>` thunk for the effect. The thunk is what PureScript's runtime will call when the effect is executed.

## Working with Arrays

PureScript arrays are JavaScript arrays, so no conversion is needed:

```javascript
// PureScript: foreign import sortNumbers :: Array Number -> Array Number
export const sortNumbers = (arr) => [...arr].sort((a, b) => a - b);

// PureScript: foreign import range :: Int -> Int -> Array Int
export const range = (start) => (end) => {
  const result = [];
  for (let i = start; i <= end; i++) result.push(i);
  return result;
};
```

Always return new arrays — never mutate the input array.

## Working with Records

PureScript records compile to plain JavaScript objects:

```javascript
// PureScript: type Point = { x :: Number, y :: Number }
// PureScript: foreign import makePoint :: Number -> Number -> Point
export const makePoint = (x) => (y) => ({ x, y });

// PureScript: foreign import distance :: Point -> Point -> Number
export const distance = (p1) => (p2) => {
  const dx = p1.x - p2.x;
  const dy = p1.y - p2.y;
  return Math.sqrt(dx * dx + dy * dy);
};
```

## Working with Maybe

`Maybe` values have a specific runtime representation. Use helper functions instead of constructing them directly:

**src/SafeFFI.purs:**
```purescript
module SafeFFI where

import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable, toMaybe)

foreign import _getElementById :: String -> Effect (Nullable Element)

getElementById :: String -> Effect (Maybe Element)
getElementById id = toMaybe <$> _getElementById id
```

**src/SafeFFI.js:**
```javascript
export const _getElementById = (id) => () => document.getElementById(id);
```

The pattern: the FFI function returns a `Nullable` (which is just `null` or a value in JavaScript), and the PureScript wrapper converts it to a proper `Maybe`.

## Working with Promises

JavaScript promises map to PureScript's `Aff`:

```purescript
import Control.Promise (Promise, toAffE)

foreign import _fetch :: String -> Effect (Promise String)

fetch :: String -> Aff String
fetch url = toAffE (_fetch url)
```

```javascript
export const _fetch = (url) => () =>
  globalThis.fetch(url).then((res) => res.text());
```

`toAffE` converts an `Effect (Promise a)` to `Aff a`, properly handling both resolution and rejection.

## Wrapping a JavaScript Library

Here is a complete example wrapping a small part of a JavaScript library:

**src/LocalStorage.purs:**
```purescript
module LocalStorage where

import Prelude
import Effect (Effect)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)

foreign import _getItem :: String -> Effect (Nullable String)
foreign import setItem :: String -> String -> Effect Unit
foreign import removeItem :: String -> Effect Unit
foreign import clear :: Effect Unit

getItem :: String -> Effect (Maybe String)
getItem key = toMaybe <$> _getItem key
```

**src/LocalStorage.js:**
```javascript
export const _getItem = (key) => () => localStorage.getItem(key);
export const setItem = (key) => (value) => () => localStorage.setItem(key, value);
export const removeItem = (key) => () => localStorage.removeItem(key);
export const clear = () => localStorage.clear();
```

## Safety Practices

### 1. Minimize the FFI Surface

Write a thin FFI layer and do all logic in PureScript:

```purescript
-- FFI: just the raw access
foreign import _readFile :: String -> Effect (Nullable String)

-- PureScript: all the logic
readFile :: FilePath -> Effect (Either FileError String)
readFile (FilePath path) = do
  result <- toMaybe <$> _readFile path
  pure case result of
    Nothing -> Left (FileNotFound path)
    Just contents -> Right contents
```

### 2. Prefix Internal FFI with Underscore

Convention: prefix FFI imports with `_` and expose a safe PureScript wrapper:

```purescript
foreign import _unsafeHead :: forall a. Array a -> a  -- unsafe!

head :: forall a. Array a -> Maybe a
head arr
  | length arr == 0 = Nothing
  | otherwise = Just (_unsafeHead arr)
```

### 3. Validate at the Boundary

Never trust data coming from JavaScript:

```purescript
foreign import _parseJSON :: String -> Effect Foreign

parseJSON :: String -> Effect (Either String MyType)
parseJSON str = do
  raw <- _parseJSON str
  pure (decode raw)
```

Use `purescript-foreign` or `purescript-argonaut` to safely decode JavaScript values into typed PureScript values.

## Debugging FFI

When FFI code misbehaves:

1. **Check currying.** `(a, b) => ...` is wrong; `(a) => (b) => ...` is correct.
2. **Check thunks.** Effects need `() => ...` as the final wrapper.
3. **Check exports.** Every `foreign import` needs a matching `export`.
4. **Inspect generated code.** Look at `output/ModuleName/index.js` to see what PureScript generated.
5. **Use console.log in the FFI.** It's JavaScript — you can debug normally.

## Summary

- FFI files are companion `.js` files matching your `.purs` module path.
- Functions must be curried: `(a) => (b) => result`.
- Effects must be thunked: `(args) => () => sideEffect`.
- Use `Nullable` + `toMaybe` for nullable values from JavaScript.
- Use `Control.Promise` to bridge JavaScript promises to `Aff`.
- Minimize the FFI surface: thin JavaScript layer, thick PureScript logic.
- Prefix unsafe FFI imports with `_` and wrap them safely.
