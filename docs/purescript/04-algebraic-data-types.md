# Chapter 4: Algebraic Data Types

Algebraic data types (ADTs) are PureScript's primary tool for modeling domains. They let you define exactly what shapes your data can take, and the compiler enforces that you handle every case.

## Sum Types

A sum type represents a choice — a value is one of several alternatives:

```purescript
data Color = Red | Green | Blue

data Shape
  = Circle Number
  | Rectangle Number Number
  | Triangle Number Number Number
```

`Color` has three constructors with no data. `Shape` has three constructors, each carrying different data. A `Shape` value is *either* a `Circle` *or* a `Rectangle` *or* a `Triangle` — never more than one.

## Product Types

A product type bundles multiple values together:

```purescript
data Pair a b = Pair a b

data Point = Point Number Number

data Person = Person String Int Boolean
```

Product types combine data with AND: a `Person` has a `String` AND an `Int` AND a `Boolean`.

## The Algebra of Types

The names "sum" and "product" come from algebra:

- **Sum types** correspond to addition: `Either a b` has `|a| + |b|` possible values.
- **Product types** correspond to multiplication: `Tuple a b` has `|a| × |b|` possible values.
- **Function types** correspond to exponentiation: `a -> b` has `|b|^|a|` possible values.
- **Unit** corresponds to 1 (one value).
- **Void** corresponds to 0 (no values).

This algebra is not just an analogy — it guides how you design types. If your type has more values than your domain has states, illegal states are representable.

## Pattern Matching

Pattern matching deconstructs data types:

```purescript
colorToString :: Color -> String
colorToString Red = "red"
colorToString Green = "green"
colorToString Blue = "blue"

area :: Shape -> Number
area (Circle r) = 3.14159 * r * r
area (Rectangle w h) = w * h
area (Triangle a b c) =
  let s = (a + b + c) / 2.0
  in sqrt (s * (s - a) * (s - b) * (s - c))
```

Pattern matching is exhaustive — the compiler requires you to handle every constructor. If you add a new constructor to `Shape`, every pattern match on `Shape` becomes a compile error until updated.

## Nested Patterns

Patterns can be nested to match deep structure:

```purescript
data Expr
  = Lit Int
  | Add Expr Expr
  | Mul Expr Expr

eval :: Expr -> Int
eval (Lit n) = n
eval (Add (Lit 0) e) = eval e          -- optimization: 0 + e = e
eval (Add e (Lit 0)) = eval e          -- optimization: e + 0 = e
eval (Add e1 e2) = eval e1 + eval e2
eval (Mul (Lit 0) _) = 0               -- optimization: 0 * e = 0
eval (Mul _ (Lit 0)) = 0               -- optimization: e * 0 = 0
eval (Mul (Lit 1) e) = eval e          -- optimization: 1 * e = e
eval (Mul e (Lit 1)) = eval e          -- optimization: e * 1 = e
eval (Mul e1 e2) = eval e1 * eval e2
```

Patterns are matched top to bottom. Put more specific patterns before general ones.

## Maybe

`Maybe` represents an optional value — the safe alternative to null:

```purescript
data Maybe a = Nothing | Just a

head :: forall a. Array a -> Maybe a
head [] = Nothing
head xs = Just (Array.unsafeIndex xs 0)
-- Safe here: the empty case is already handled above

-- Using Maybe
greet :: Maybe String -> String
greet Nothing = "Hello, stranger!"
greet (Just name) = "Hello, " <> name <> "!"
```

You can never forget to handle the absent case — the compiler requires it. No more `undefined is not a function`.

## Either

`Either` represents a value that is one of two types, commonly used for error handling:

```purescript
data Either a b = Left a | Right b

parseInt :: String -> Either String Int
parseInt s = case runParser s of
  Nothing -> Left ("Not a valid integer: " <> s)
  Just n -> Right n

-- Chain computations that might fail
divide :: Int -> Int -> Either String Int
divide _ 0 = Left "Division by zero"
divide a b = Right (a / b)
```

By convention, `Left` carries the error and `Right` carries the success value. "Right" is right — the correct result.

## Newtypes

A newtype wraps an existing type with zero runtime cost:

```purescript
newtype Email = Email String
newtype UserId = UserId Int
newtype Meters = Meters Number
```

Newtypes create distinct types that cannot be accidentally mixed:

```purescript
sendEmail :: Email -> Effect Unit
sendEmail (Email addr) = -- ...

-- This is a compile error:
sendEmail (UserId 42)    -- ✗ Cannot match UserId with Email
sendEmail "test@foo.com" -- ✗ Cannot match String with Email
sendEmail (Email "test@foo.com") -- ✓
```

Newtypes are free at runtime — they compile to the underlying type with no wrapping overhead.

## Records as Product Types

Records are PureScript's primary product type for labeled data:

```purescript
type Config =
  { host :: String
  , port :: Int
  , debug :: Boolean
  }

defaultConfig :: Config
defaultConfig =
  { host: "localhost"
  , port: 8080
  , debug: false
  }
```

Records are preferable to positional product types when you have more than two or three fields, because the field names serve as documentation.

## Recursive Types

Types can reference themselves:

```purescript
data List a = Nil | Cons a (List a)

data Tree a = Leaf a | Branch (Tree a) (Tree a)

data JSON
  = JNull
  | JBool Boolean
  | JNumber Number
  | JString String
  | JArray (Array JSON)
  | JObject (Map String JSON)
```

Recursive types model naturally recursive data: lists, trees, ASTs, JSON, file systems.

## Deriving Instances

PureScript can automatically derive type class instances for your data types:

```purescript
data Color = Red | Green | Blue

derive instance Eq Color
derive instance Ord Color

-- For newtypes, use newtype deriving
newtype Email = Email String
derive newtype instance Eq Email
derive newtype instance Show Email
```

`derive instance` generates the implementation automatically. `derive newtype instance` delegates to the wrapped type's instance.

## Making Illegal States Unrepresentable

The most powerful use of ADTs is making invalid states impossible to construct:

```purescript
-- Bad: what does Connection "" 0 false mean?
type Connection = { host :: String, port :: Int, connected :: Boolean }

-- Good: the type tells you what state you're in
data Connection
  = Disconnected
  | Connecting { host :: String, port :: Int }
  | Connected { host :: String, port :: Int, socket :: Socket }
  | Failed { host :: String, port :: Int, error :: String }
```

In the second design, you cannot access a `socket` unless you have a `Connected` value. The compiler enforces this — no runtime checks needed.

## Summary

- Sum types model choices (OR); product types model combinations (AND).
- Pattern matching is exhaustive — the compiler catches missing cases.
- `Maybe` replaces null; `Either` replaces exceptions.
- Newtypes create distinct types at zero runtime cost.
- Design types so that illegal states cannot be constructed.
