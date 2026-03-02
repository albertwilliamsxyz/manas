# Chapter 6: Effects and Monads

PureScript is purely functional — functions cannot have side effects unless their types say so. This chapter explains how PureScript manages effects through `Effect`, `Aff`, `do` notation, and monad transformers.

## The Problem with Side Effects

In JavaScript, any function can do anything:

```javascript
function add(a, b) {
  console.log("adding");     // side effect: I/O
  fetch("/api/log");          // side effect: network
  localStorage.setItem("x"); // side effect: storage
  return a + b;
}
```

You cannot know what `add` does without reading its implementation. In PureScript, the type tells you:

```purescript
add :: Int -> Int -> Int
add a b = a + b
-- This function CANNOT do I/O, network, or anything else.
-- The type guarantees it.
```

## Effect: Synchronous Side Effects

`Effect` represents synchronous side effects:

```purescript
import Effect (Effect)
import Effect.Console (log)
import Effect.Random (random)
import Effect.Ref (Ref, new, read, write)

-- Print to console
greet :: String -> Effect Unit
greet name = log ("Hello, " <> name)

-- Generate a random number
roll :: Effect Number
roll = random

-- Mutable reference
counter :: Effect (Ref Int)
counter = new 0
```

An `Effect a` value is a *description* of a side effect that, when executed, produces a value of type `a`. Constructing an `Effect` does not execute it — effects are values that can be composed before execution.

## Do Notation

`do` notation sequences effectful computations:

```purescript
main :: Effect Unit
main = do
  log "What is your name?"
  name <- readLine
  log ("Hello, " <> name <> "!")
  log "Goodbye!"
```

Each line in a `do` block is an `Effect`. The `<-` operator extracts the result of an effect to use in subsequent lines. Without `<-`, the result is discarded (like `log` which returns `Unit`).

`do` notation is syntactic sugar for `bind` (`>>=`):

```purescript
-- These are equivalent:
main = do
  x <- getLine
  log x

main = getLine >>= \x -> log x
```

## Bind and the Monad Pattern

The `>>=` operator chains computations where each step can depend on the previous result:

```purescript
class Bind m where
  bind :: forall a b. m a -> (a -> m b) -> m b
```

For `Effect`:
- `m a` is an effect that produces an `a`
- `(a -> m b)` is a function that takes that `a` and produces a new effect
- The result is an effect that does both, threading the value through

This is exactly what `do` notation desugars to.

## Aff: Asynchronous Effects

`Aff` represents asynchronous effects — computations that may take time:

```purescript
import Affjax as AX
import Affjax.ResponseFormat as ResponseFormat

fetchUser :: String -> Aff (Either AX.Error String)
fetchUser userId = do
  response <- AX.get ResponseFormat.string ("/api/users/" <> userId)
  pure (map _.body response)
```

`Aff` supports:
- Asynchronous I/O (HTTP requests, file operations)
- Error handling (errors propagate automatically)
- Cancellation (computations can be cancelled)
- Forking (run computations in parallel)

### Running Aff in Effect

`Aff` computations are launched from `Effect`:

```purescript
import Effect.Aff (launchAff_)

main :: Effect Unit
main = launchAff_ do
  result <- fetchUser "123"
  case result of
    Left err -> liftEffect $ log ("Error: " <> AX.printError err)
    Right body -> liftEffect $ log ("User: " <> body)
```

`launchAff_` converts an `Aff Unit` into an `Effect Unit`, firing the async computation.

## Lifting Effects

When you need to use an `Effect` inside an `Aff`, use `liftEffect`:

```purescript
import Effect.Class (liftEffect)

myAffComputation :: Aff Unit
myAffComputation = do
  liftEffect $ log "Starting async work..."
  result <- someAsyncOperation
  liftEffect $ log "Done!"
```

`liftEffect` embeds a synchronous effect into an asynchronous context. The general pattern: `liftEffect :: Effect a -> Aff a`.

## Pure Values in Effectful Contexts

Use `pure` to wrap a plain value in an effectful context:

```purescript
getName :: Effect String
getName = pure "Alice"

getNumber :: Aff Int
getNumber = pure 42
```

`pure` does not perform any side effect — it just wraps the value.

## Error Handling

### With Either

The functional approach to error handling:

```purescript
divide :: Int -> Int -> Either String Int
divide _ 0 = Left "Division by zero"
divide a b = Right (a / b)

-- Chain operations that might fail
compute :: Int -> Int -> Int -> Either String Int
compute a b c = do
  x <- divide a b
  y <- divide x c
  pure (x + y)
```

`Either` short-circuits on the first `Left` — subsequent computations are skipped.

### With ExceptT

For effectful computations that can fail:

```purescript
import Control.Monad.Except (ExceptT, runExceptT, throwError)

type App a = ExceptT String Effect a

validateAge :: Int -> App Int
validateAge age
  | age < 0 = throwError "Age cannot be negative"
  | age > 150 = throwError "Age seems unrealistic"
  | otherwise = pure age
```

### With Aff Errors

`Aff` has built-in error handling:

```purescript
import Effect.Aff (Aff, attempt, throwError, catchError)

safeFetch :: String -> Aff String
safeFetch url = catchError (fetchUrl url) handleError
  where
    handleError err = pure ("Failed to fetch: " <> show err)
```

## Monad Transformers

Monad transformers stack effects:

```purescript
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import Control.Monad.State (StateT, get, put, modify, runStateT)
import Control.Monad.Except (ExceptT, throwError, runExceptT)
```

### ReaderT: Read-Only Environment

`ReaderT` threads a read-only value through computations:

```purescript
type Config = { dbUrl :: String, logLevel :: String }

type App a = ReaderT Config Effect a

getDbUrl :: App String
getDbUrl = do
  config <- ask
  pure config.dbUrl

runApp :: Config -> App Unit -> Effect Unit
runApp config app = runReaderT app config
```

### StateT: Mutable State

`StateT` threads mutable state:

```purescript
type Counter a = StateT Int Effect a

increment :: Counter Unit
increment = modify (_ + 1)

getCount :: Counter Int
getCount = get

program :: Counter Int
program = do
  increment
  increment
  increment
  getCount  -- returns 3
```

### Stacking Transformers

Transformers compose — you can stack them:

```purescript
type App a = ReaderT Config (StateT AppState (ExceptT AppError Aff)) a
```

This gives you: read-only config + mutable state + error handling + async effects. The order matters — the outermost transformer is run first when unwrapping.

## Common Patterns

### Traverse: Effects Over Collections

```purescript
import Data.Traversable (traverse, traverse_)

-- Fetch all users in parallel (conceptually)
fetchUsers :: Array String -> Aff (Array User)
fetchUsers ids = traverse fetchUser ids

-- Log all items (discarding results)
logAll :: Array String -> Effect Unit
logAll messages = traverse_ log messages
```

### When and Unless

```purescript
import Control.Monad (when, unless)

main :: Effect Unit
main = do
  debug <- isDebugMode
  when debug $ log "Debug mode is on"
  unless debug $ log "Running in production"
```

### For Loops

```purescript
import Data.Foldable (for_)

main :: Effect Unit
main = do
  for_ [1, 2, 3, 4, 5] \n ->
    log (show n)
```

## Summary

- `Effect` tracks synchronous side effects; `Aff` tracks asynchronous ones.
- `do` notation sequences effects readably; it desugars to `bind` (`>>=`).
- `pure` wraps values; `liftEffect` embeds `Effect` into `Aff`.
- `Either` handles pure errors; `ExceptT` handles effectful errors.
- Monad transformers (`ReaderT`, `StateT`, `ExceptT`) stack effects.
- The type signature tells you exactly what effects a function can perform.
