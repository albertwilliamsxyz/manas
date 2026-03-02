# Chapter 5: Type Classes

Type classes are PureScript's mechanism for ad-hoc polymorphism — defining functions that behave differently for different types while sharing a common interface.

## What Is a Type Class?

A type class is a set of functions that any type can implement:

```purescript
class Show a where
  show :: a -> String

class Eq a where
  eq :: a -> a -> Boolean
```

`Show` says: "any type `a` that is an instance of `Show` has a function `show` that converts it to a `String`." This is similar to interfaces in object-oriented languages, but more powerful — you can add instances for types you did not define.

## Defining Instances

An instance provides the implementation of a type class for a specific type:

```purescript
data Color = Red | Green | Blue

instance Show Color where
  show Red = "Red"
  show Green = "Green"
  show Blue = "Blue"

instance Eq Color where
  eq Red Red = true
  eq Green Green = true
  eq Blue Blue = true
  eq _ _ = false
```

Now you can use `show` and `eq` on `Color` values:

```purescript
show Red        -- "Red"
eq Green Blue   -- false
Red == Red      -- true (== is defined in terms of eq)
```

## Type Class Constraints

Functions can require that their type arguments have certain type class instances:

```purescript
showAndLog :: forall a. Show a => a -> Effect Unit
showAndLog x = log (show x)

contains :: forall a. Eq a => a -> Array a -> Boolean
contains x = any (eq x)
```

The `Show a =>` constraint says: "this function works for any type `a`, as long as `a` has a `Show` instance." The constraint comes before the main type, separated by `=>`.

## Multiple Constraints

Functions can have multiple constraints:

```purescript
showIfEqual :: forall a. Eq a => Show a => a -> a -> String
showIfEqual x y
  | x == y = show x
  | otherwise = "not equal"
```

## The Standard Type Class Hierarchy

PureScript organizes its core type classes in a hierarchy. Understanding this hierarchy is essential:

### Eq and Ord

```purescript
class Eq a where
  eq :: a -> a -> Boolean

class Eq a <= Ord a where
  compare :: a -> a -> Ordering
```

`Ord` extends `Eq` — anything you can order, you can also compare for equality. `Ordering` is `LT | EQ | GT`.

### Semigroup and Monoid

```purescript
class Semigroup a where
  append :: a -> a -> a  -- also written as (<>)

class Semigroup a <= Monoid a where
  mempty :: a
```

`Semigroup` means you can combine two values. `Monoid` adds an identity element. Examples:

```purescript
-- String: append is concatenation, mempty is ""
"hello" <> " " <> "world"  -- "hello world"

-- Array: append is concatenation, mempty is []
[1, 2] <> [3, 4]  -- [1, 2, 3, 4]

-- Boolean (conjunction): append is &&, mempty is true
-- Boolean (disjunction): append is ||, mempty is false
```

### Functor

```purescript
class Functor f where
  map :: forall a b. (a -> b) -> f a -> f b
```

`Functor` means you can transform the contents of a container without changing the container's structure. The `<$>` operator is an alias for `map`:

```purescript
map (_ + 1) [1, 2, 3]          -- [2, 3, 4]
map (_ + 1) (Just 5)           -- Just 6
map (_ + 1) Nothing            -- Nothing
(_ + 1) <$> [1, 2, 3]          -- [2, 3, 4]
```

### Apply and Applicative

```purescript
class Functor f <= Apply f where
  apply :: forall a b. f (a -> b) -> f a -> f b

class Apply f <= Applicative f where
  pure :: forall a. a -> f a
```

`Apply` lets you apply a function inside a container to a value inside a container. `Applicative` lets you put a value into a container. The `<*>` operator is an alias for `apply`:

```purescript
pure (+) <*> Just 3 <*> Just 5   -- Just 8
pure (+) <*> Nothing <*> Just 5  -- Nothing
```

### Bind and Monad

```purescript
class Apply m <= Bind m where
  bind :: forall a b. m a -> (a -> m b) -> m b

class (Applicative m, Bind m) <= Monad m
```

`Bind` (with the `>>=` operator) lets you chain computations where each step depends on the previous result. This is the foundation for `do` notation (covered in Chapter 6).

### Foldable and Traversable

```purescript
class Foldable f where
  foldl :: forall a b. (b -> a -> b) -> b -> f a -> b
  foldr :: forall a b. (a -> b -> b) -> b -> f a -> b
  foldMap :: forall a m. Monoid m => (a -> m) -> f a -> m

class (Functor t, Foldable t) <= Traversable t where
  traverse :: forall a b m. Applicative m => (a -> m b) -> t a -> m (t b)
  sequence :: forall a m. Applicative m => t (m a) -> m (t a)
```

`Foldable` means you can reduce a structure to a single value. `Traversable` means you can traverse a structure with effects, collecting results.

## Defining Your Own Type Classes

```purescript
class HasArea a where
  area :: a -> Number

data Circle = Circle Number
data Rectangle = Rectangle Number Number

instance HasArea Circle where
  area (Circle r) = 3.14159 * r * r

instance HasArea Rectangle where
  area (Rectangle w h) = w * h

totalArea :: forall a. HasArea a => Array a -> Number
totalArea = foldl (\acc shape -> acc + area shape) 0.0
```

## Superclass Constraints

Type classes can require other type classes:

```purescript
class Eq a <= Ord a where
  compare :: a -> a -> Ordering
```

The `Eq a <=` syntax means "any type that is `Ord` must also be `Eq`." This ensures you can always use `==` when you have `Ord`.

## Orphan Instances

PureScript does not allow orphan instances — you can only define an instance in:

1. The module where the type class is defined, or
2. The module where the data type is defined.

This prevents conflicts where two modules define conflicting instances for the same type and class. If you need a custom instance for a type you don't own, use a newtype wrapper.

## Deriving Type Classes

For common type classes, PureScript can generate instances automatically:

```purescript
data Direction = North | South | East | West

derive instance Eq Direction
derive instance Ord Direction

-- Generic deriving for Show
derive instance Generic Direction _
instance Show Direction where
  show = genericShow
```

## Summary

- Type classes define shared interfaces that types can implement.
- Constraints (`Show a =>`) restrict type variables to types with the required instances.
- The hierarchy (Functor → Apply → Applicative → Monad) forms the backbone of PureScript programming.
- Semigroup/Monoid capture the pattern of combining values.
- No orphan instances — use newtypes when you need custom instances for external types.
