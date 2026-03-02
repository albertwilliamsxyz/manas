# Chapter 10: Testing Strategies

Testing in PureScript benefits from the type system — many bugs that require tests in other languages are caught at compile time. This chapter covers the testing tools and strategies that complement the type checker.

## What the Type System Already Tests

Before writing a single test, PureScript's type system guarantees:

- No null pointer exceptions (use `Maybe` instead).
- No missing cases in pattern matches (exhaustiveness checking).
- No type mismatches (sound type system).
- No accessing undefined fields on records (row types).
- No calling effectful functions in pure context (effect tracking).

Your tests can focus on *logic* — the type system handles *structure*.

## purescript-spec: Unit and Integration Testing

`purescript-spec` is the standard testing library:

```bash
spago install spec
```

### Basic Test Structure

```purescript
module Test.Main where

import Prelude
import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual, shouldNotEqual, shouldSatisfy)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)

main :: Effect Unit
main = launchAff_ $ runSpec [consoleReporter] do
  describe "Math" do
    it "adds numbers correctly" do
      (2 + 2) `shouldEqual` 4

    it "handles negative numbers" do
      (-1 + 1) `shouldEqual` 0

  describe "String" do
    it "concatenates" do
      ("hello" <> " " <> "world") `shouldEqual` "hello world"

    it "has length" do
      length "abc" `shouldEqual` 3
```

### Assertions

```purescript
import Test.Spec.Assertions

-- Equality
result `shouldEqual` expected
result `shouldNotEqual` unexpected

-- Predicates
result `shouldSatisfy` (_ > 0)

-- Containment (strings)
result `shouldContain` "substring"
```

### Testing Effects

```purescript
import Effect.Ref as Ref

describe "Ref" do
  it "reads and writes" do
    ref <- liftEffect $ Ref.new 0
    liftEffect $ Ref.write 42 ref
    value <- liftEffect $ Ref.read ref
    value `shouldEqual` 42
```

### Testing Async Code

```purescript
import Effect.Aff (delay, Milliseconds(..))

describe "Async" do
  it "handles delays" do
    delay (Milliseconds 100.0)
    -- If we got here, the delay completed
    pure unit

  it "fetches data" do
    result <- fetchUser "test-id"
    case result of
      Left err -> fail ("Unexpected error: " <> show err)
      Right user -> user.name `shouldEqual` "Test User"
```

### Organizing Tests

```purescript
-- test/Test/Main.purs
module Test.Main where

import Test.App.StateSpec as StateSpec
import Test.Data.UserSpec as UserSpec
import Test.Utils.StringSpec as StringSpec

main :: Effect Unit
main = launchAff_ $ runSpec [consoleReporter] do
  StateSpec.spec
  UserSpec.spec
  StringSpec.spec

-- test/Test/Data/UserSpec.purs
module Test.Data.UserSpec where

spec :: Spec Unit
spec = describe "Data.User" do
  describe "createUser" do
    it "creates a user with valid data" do
      -- ...
  describe "validateEmail" do
    it "rejects empty emails" do
      -- ...
```

## purescript-quickcheck: Property-Based Testing

Property-based testing generates random inputs and checks that properties hold:

```bash
spago install quickcheck
```

### Basic Properties

```purescript
import Test.QuickCheck (quickCheck, (===))

main :: Effect Unit
main = do
  -- Addition is commutative
  quickCheck \(a :: Int) (b :: Int) ->
    a + b === b + a

  -- Reversing a list twice gives the original
  quickCheck \(xs :: Array Int) ->
    reverse (reverse xs) === xs

  -- Sorting is idempotent
  quickCheck \(xs :: Array Int) ->
    sort (sort xs) === sort xs
```

### Custom Generators

```purescript
import Test.QuickCheck (class Arbitrary, arbitrary)
import Test.QuickCheck.Gen (Gen, chooseInt, elements)

newtype PositiveInt = PositiveInt Int

instance Arbitrary PositiveInt where
  arbitrary = PositiveInt <$> chooseInt 1 1000

newtype Email = Email String

instance Arbitrary Email where
  arbitrary = do
    user <- elements (NonEmpty "alice" ["bob", "charlie"])
    domain <- elements (NonEmpty "example.com" ["test.org"])
    pure (Email (user <> "@" <> domain))
```

### Property-Based Testing with Spec

```purescript
import Test.Spec.QuickCheck (quickCheck)

describe "Array operations" do
  it "map preserves length" do
    quickCheck \(xs :: Array Int) ->
      length (map (_ + 1) xs) === length xs

  it "filter never increases length" do
    quickCheck \(xs :: Array Int) ->
      length (filter (_ > 0) xs) <= length xs
```

### When to Use Property-Based Testing

Property-based testing excels when:

- **Algebraic laws** must hold (associativity, commutativity, identity).
- **Round-trip properties** exist (encode then decode gives original).
- **Invariants** must be maintained (sorted output, positive values).
- **Edge cases** are hard to think of manually (empty arrays, boundary values).

```purescript
-- Round-trip: JSON encode/decode
quickCheck \(user :: User) ->
  (decodeJson <<< encodeJson) user === Right user

-- Invariant: sorting produces sorted output
quickCheck \(xs :: Array Int) ->
  isSorted (sort xs) === true

-- Algebraic law: monoid identity
quickCheck \(s :: String) ->
  (mempty <> s === s) && (s <> mempty === s)
```

## Testing Pure Functions

Pure functions are the easiest to test — no setup, no teardown, no mocking:

```purescript
describe "parseCommand" do
  it "parses move commands" do
    parseCommand "move 10 20" `shouldEqual` Just (Move { x: 10, y: 20 })

  it "parses rotate commands" do
    parseCommand "rotate 90" `shouldEqual` Just (Rotate 90)

  it "returns Nothing for invalid input" do
    parseCommand "invalid" `shouldEqual` Nothing
    parseCommand "" `shouldEqual` Nothing
```

Because PureScript separates pure computation from effects, most of your code is pure and testable without mocking.

## Testing with State

Use `StateT` or `Ref` for testing stateful logic:

```purescript
describe "StateMachine" do
  it "transitions correctly" do
    let
      initialState = Idle
      afterStart = transition Start initialState
      afterComplete = transition Complete afterStart

    afterStart `shouldEqual` Running
    afterComplete `shouldEqual` Done
```

## Test Coverage Strategy

Given PureScript's type system, prioritize testing:

1. **Business logic** — pure functions that encode domain rules.
2. **State transitions** — ensure your state machines move correctly.
3. **Boundary conditions** — empty inputs, maximum values, zero.
4. **Algebraic laws** — properties that must hold for your types.
5. **Integration points** — FFI boundaries, API calls, serialization.

Do not test:
- Type-level guarantees (the compiler already checks these).
- Simple accessors or constructors.
- Third-party library internals.

## Running Tests

```bash
# Run all tests
spago test

# Run tests with a specific reporter
spago test -- --reporter=dot

# Watch mode
spago test --watch
```

## Summary

- PureScript's type system eliminates entire categories of bugs before testing.
- `purescript-spec` provides describe/it-style unit testing.
- `purescript-quickcheck` generates random inputs to verify properties.
- Test pure logic thoroughly; the type system handles structural correctness.
- Property-based testing is especially valuable for algebraic laws and round-trip properties.
- Organize tests to mirror source directory structure.
