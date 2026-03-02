# Chapter 2: Type System Fundamentals

PureScript's type system is its greatest asset. It catches entire classes of bugs at compile time and serves as machine-checked documentation. This chapter covers the building blocks.

## Primitive Types

PureScript has a small set of primitive types:

```purescript
-- Numeric
42 :: Int          -- 32-bit integer
3.14 :: Number     -- IEEE 754 double

-- Text
'a' :: Char        -- single character
"hello" :: String  -- text string

-- Logic
true :: Boolean
false :: Boolean
```

Note: there is no implicit coercion between types. `1 + 1.0` is a type error — you must explicitly convert.

## Type Annotations

Every top-level definition should have a type annotation:

```purescript
greet :: String -> String
greet name = "Hello, " <> name <> "!"

add :: Int -> Int -> Int
add x y = x + y
```

Type annotations are not mandatory — the compiler infers types — but they serve as documentation and catch mistakes early. A mismatch between your annotation and implementation is a compile error, not a runtime surprise.

## Type Inference

PureScript uses Hindley-Milner type inference with extensions. The compiler deduces types from usage:

```purescript
-- No annotation needed; compiler infers: double :: Int -> Int
double x = x + x

-- Compiler infers: pair :: forall a b. a -> b -> Tuple a b
pair x y = Tuple x y
```

When inference is ambiguous, the compiler asks for a type annotation. This happens most often with type class constraints and numeric literals.

## Parametric Polymorphism

Functions can work over any type using type variables:

```purescript
identity :: forall a. a -> a
identity x = x

const :: forall a b. a -> b -> a
const x _ = x

flip :: forall a b c. (a -> b -> c) -> b -> a -> c
flip f b a = f a b
```

The `forall` keyword introduces type variables. `identity` works for any type `a` — integers, strings, records, functions — without any runtime cost. This is parametric polymorphism: the function behaves identically regardless of the type.

## The Forall Keyword

Unlike Haskell, PureScript requires explicit `forall`:

```purescript
-- This is required; implicit forall is not supported
map :: forall a b. (a -> b) -> Array a -> Array b
```

This makes type signatures unambiguous and easier to read, especially when multiple type variables are involved.

## Records

PureScript records are structurally typed using row types:

```purescript
type Person = { name :: String, age :: Int }

greetPerson :: Person -> String
greetPerson p = "Hello, " <> p.name

-- Records are accessed with dot notation
getName :: { name :: String | r } -> String
getName rec = rec.name
```

The type `{ name :: String | r }` means "any record that has at least a `name :: String` field, plus possibly other fields `r`." This is row polymorphism — functions can accept records with extra fields without knowing about them.

## Record Updates

Records are immutable. To "change" a field, you create a new record:

```purescript
birthday :: Person -> Person
birthday person = person { age = person.age + 1 }
```

The syntax `record { field = newValue }` creates a copy with the specified field updated. All other fields are unchanged.

## Type Aliases

`type` creates an alias — a new name for an existing type:

```purescript
type Name = String
type Age = Int
type Person = { name :: Name, age :: Age }
type Callback a = a -> Effect Unit
```

Type aliases are fully interchangeable with the types they name. They exist purely for readability.

## The Unit Type

`Unit` is the type with exactly one value, `unit`:

```purescript
doNothing :: Unit -> Unit
doNothing _ = unit
```

It is used where other languages use `void`. `Effect Unit` means "an effectful computation that produces no meaningful result."

## The Void Type

`Void` is the type with *no* values. It is useful for making impossible states unrepresentable:

```purescript
-- You can never construct a Void value, so this function can never be called
absurd :: forall a. Void -> a
```

## Kind System

Types themselves have types, called kinds:

```purescript
-- Int has kind Type
-- Array has kind Type -> Type (it needs a type argument)
-- Effect has kind Type -> Type
-- Tuple has kind Type -> Type -> Type
```

You can inspect kinds in the REPL:

```
> :kind Int
Type

> :kind Array
Type -> Type

> :kind Effect
Type -> Type
```

Understanding kinds becomes important when working with type classes and higher-kinded types (Chapter 5).

## Common Mistakes

**Forgetting `forall`:**
```purescript
-- Wrong: a is not in scope
identity :: a -> a

-- Correct
identity :: forall a. a -> a
```

**Confusing `type` and `newtype`:**
```purescript
-- type: just an alias, no runtime cost, no type safety
type UserId = String

-- newtype: wrapper type, no runtime cost, but distinct from String
newtype UserId = UserId String
```

**Numeric literal ambiguity:**
```purescript
-- Ambiguous: could be Int or Number
x = 42

-- Explicit: no ambiguity
x :: Int
x = 42
```

## Summary

- PureScript's type system is sound: well-typed programs don't go wrong.
- Use `forall` to introduce type variables.
- Records use structural typing with row polymorphism.
- Type aliases improve readability; newtypes improve safety.
- Kinds classify types the way types classify values.
