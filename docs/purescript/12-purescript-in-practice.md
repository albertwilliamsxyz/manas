# Chapter 12: PureScript in Practice

This final chapter brings everything together with architecture patterns, error handling strategies, and practical advice for building real PureScript applications.

## Application Architecture

### The Reader Pattern

Thread configuration through your application without passing it explicitly:

```purescript
import Control.Monad.Reader (ReaderT, ask, asks, runReaderT)

type AppConfig =
  { apiUrl :: String
  , logLevel :: LogLevel
  , maxRetries :: Int
  }

type App a = ReaderT AppConfig Aff a

fetchUser :: UserId -> App User
fetchUser userId = do
  config <- ask
  let url = config.apiUrl <> "/users/" <> show userId
  response <- lift $ AX.get ResponseFormat.json url
  -- ...

runApp :: AppConfig -> App Unit -> Aff Unit
runApp config app = runReaderT app config
```

Every function in the `App` monad can access the config without it being a parameter. This keeps function signatures clean while making dependencies explicit in the type.

### The Capability Pattern

Define what your application can do as type class constraints:

```purescript
class Monad m <= MonadLogger m where
  logInfo :: String -> m Unit
  logError :: String -> m Unit

class Monad m <= MonadUserRepo m where
  getUser :: UserId -> m (Maybe User)
  saveUser :: User -> m Unit

-- Business logic depends on capabilities, not implementations
registerUser :: forall m. MonadLogger m => MonadUserRepo m => UserInput -> m (Either AppError User)
registerUser input = do
  logInfo ("Registering user: " <> input.email)
  existing <- getUser input.email
  case existing of
    Just _ -> do
      logError "User already exists"
      pure (Left UserAlreadyExists)
    Nothing -> do
      let user = createUser input
      saveUser user
      logInfo "User registered successfully"
      pure (Right user)
```

In production, implement the type classes with real I/O. In tests, implement them with pure state:

```purescript
-- Production
instance MonadLogger App where
  logInfo msg = liftEffect $ Console.log msg
  logError msg = liftEffect $ Console.error msg

-- Test
newtype TestM a = TestM (StateT TestState Identity a)

instance MonadLogger TestM where
  logInfo msg = TestM $ modify_ \s -> s { logs = Array.snoc s.logs msg }
  logError msg = TestM $ modify_ \s -> s { errors = Array.snoc s.errors msg }
```

### State Machine Architecture

Model your application as explicit state transitions:

```purescript
data AppState
  = Initializing
  | Loading { progress :: Number }
  | Ready { scene :: Scene, mode :: AppMode }
  | Error { message :: String, recoverable :: Boolean }

data AppAction
  = LoadProgress Number
  | LoadComplete Scene
  | LoadFailed String
  | UserAction UserInput
  | Retry

transition :: AppState -> AppAction -> AppState
transition Initializing (LoadProgress p) = Loading { progress: p }
transition (Loading _) (LoadComplete scene) = Ready { scene, mode: Viewing }
transition (Loading _) (LoadFailed msg) = Error { message: msg, recoverable: true }
transition (Error { recoverable: true }) Retry = Initializing
transition state _ = state  -- ignore invalid transitions
```

This pattern makes every possible state and transition explicit. Invalid transitions are handled by the catch-all case — they are visible in the code and can be logged.

## Error Handling Strategies

### Domain Errors as Types

```purescript
data AppError
  = NetworkError { url :: String, status :: Int }
  | ValidationError (Array String)
  | NotFound { resource :: String, id :: String }
  | Unauthorized
  | Internal String

renderError :: AppError -> String
renderError = case _ of
  NetworkError { url, status } -> "Network error " <> show status <> " for " <> url
  ValidationError errors -> "Validation failed: " <> joinWith ", " errors
  NotFound { resource, id } -> resource <> " not found: " <> id
  Unauthorized -> "Authentication required"
  Internal msg -> "Internal error: " <> msg
```

### The Either Pipeline

```purescript
type Result a = Either AppError a

processOrder :: OrderInput -> App (Result Order)
processOrder input = runExceptT do
  -- Each step can fail; the pipeline short-circuits on error
  validated <- ExceptT $ pure $ validateOrder input
  user <- ExceptT $ getUser input.userId # map (note (NotFound { resource: "User", id: show input.userId }))
  inventory <- ExceptT $ checkInventory input.items
  order <- ExceptT $ pure $ createOrder validated user inventory
  ExceptT $ saveOrder order
  pure order
```

### Recovering from Errors

```purescript
withRetry :: forall a. Int -> Aff a -> Aff a
withRetry 0 action = action
withRetry n action = catchError action \err -> do
  delay (Milliseconds (1000.0 * toNumber (maxRetries - n)))
  withRetry (n - 1) action
  where
    maxRetries = n

withDefault :: forall a. a -> Aff a -> Aff a
withDefault fallback action = catchError action (\_ -> pure fallback)
```

## Module Organization for Large Projects

```
src/
├── Main.purs                    # Entry point
├── App/
│   ├── Monad.purs               # App type definition and runners
│   ├── Config.purs              # Configuration types and loaders
│   └── Routes.purs              # Routing definitions
├── Domain/
│   ├── User/
│   │   ├── Types.purs           # User, UserId, UserInput
│   │   ├── Validation.purs      # validateUser, validateEmail
│   │   └── Repository.purs      # MonadUserRepo class
│   ├── Order/
│   │   ├── Types.purs
│   │   ├── Logic.purs           # Pure business rules
│   │   └── Repository.purs
│   └── Error.purs               # AppError type
├── Infrastructure/
│   ├── Http.purs                # HTTP client wrapper
│   ├── Logger.purs              # Logging implementation
│   └── Database.purs            # Database access
├── UI/
│   ├── Components/
│   │   ├── Header.purs
│   │   ├── UserList.purs
│   │   └── OrderForm.purs
│   ├── Pages/
│   │   ├── Home.purs
│   │   └── Dashboard.purs
│   └── Layout.purs
└── FFI/
    ├── WebGL.purs               # WebGL bindings
    ├── WebGL.js                 # WebGL FFI implementations
    ├── LocalStorage.purs
    └── LocalStorage.js
```

Principles:
- **Domain/** contains pure business logic with no framework dependencies.
- **Infrastructure/** contains effectful implementations.
- **UI/** contains view components.
- **FFI/** isolates all JavaScript interop.
- **App/** wires everything together.

## Working with Records at Scale

### Smart Constructors

```purescript
newtype Email = Email String

mkEmail :: String -> Either String Email
mkEmail s
  | contains (Pattern "@") s = Right (Email s)
  | otherwise = Left "Invalid email format"

-- You can only create an Email through mkEmail
-- The constructor is not exported
module Data.Email (Email, mkEmail, unEmail) where
```

### Record Update Patterns

```purescript
-- Simple update
updateName :: String -> User -> User
updateName name user = user { name = name }

-- Conditional update
setVerified :: User -> User
setVerified user
  | isValidEmail user.email = user { verified = true }
  | otherwise = user

-- Bulk update with a modifier function
modifyUser :: (User -> User) -> UserId -> App Unit
modifyUser f userId = do
  mUser <- getUser userId
  case mUser of
    Nothing -> pure unit
    Just user -> saveUser (f user)
```

### Lenses for Deep Updates

```purescript
import Data.Lens (Lens', lens, over, view, set)

_name :: Lens' User String
_name = lens _.name (_ { name = _ })

_address :: Lens' User Address
_address = lens _.address (_ { address = _ })

_city :: Lens' Address String
_city = lens _.city (_ { city = _ })

-- Compose lenses for deep access
_userCity :: Lens' User String
_userCity = _address <<< _city

-- Use them
getCity :: User -> String
getCity = view _userCity

setCity :: String -> User -> User
setCity = set _userCity

updateCity :: (String -> String) -> User -> User
updateCity = over _userCity
```

## Practical Tips

### 1. Start with Types

Before writing any implementation, define your types:

```purescript
-- Step 1: What data do I have?
type Input = { ... }

-- Step 2: What data do I produce?
type Output = { ... }

-- Step 3: What can go wrong?
data Error = ...

-- Step 4: Write the function signature
process :: Input -> Either Error Output

-- Step 5: Implement (often the easiest step)
process input = ...
```

### 2. Make Impossible States Impossible

```purescript
-- Instead of:
type Form = { submitted :: Boolean, result :: Maybe Result, error :: Maybe Error }
-- Where submitted=false + result=Just is illegal

-- Use:
data Form
  = Editing FormData
  | Submitting FormData
  | Succeeded Result
  | Failed Error FormData
```

### 3. Use Newtypes for Domain Concepts

```purescript
newtype UserId = UserId String
newtype Email = Email String
newtype Dollars = Dollars Number
newtype Meters = Meters Number

-- The compiler prevents mixing them up
charge :: UserId -> Dollars -> App Unit
-- charge someUserId (Meters 5.0)  -- Compile error!
```

### 4. Keep Effects at the Edge

```purescript
-- Pure core: all business logic
validateOrder :: OrderInput -> Either (Array String) ValidatedOrder
calculateTotal :: ValidatedOrder -> Dollars
applyDiscount :: DiscountCode -> Dollars -> Dollars

-- Effectful shell: I/O at the boundary
processOrder :: OrderInput -> App (Either AppError Receipt)
processOrder input = do
  -- Validate (pure)
  case validateOrder input of
    Left errors -> pure (Left (ValidationError errors))
    Right order -> do
      -- Calculate (pure)
      let total = applyDiscount order.discount (calculateTotal order)
      -- Charge (effect)
      chargeResult <- chargeCard order.payment total
      -- Save (effect)
      receipt <- saveOrder order total
      pure (Right receipt)
```

### 5. Document with Types, Not Comments

```purescript
-- Instead of: -- This function might fail if the user doesn't exist
getUser :: UserId -> App (Maybe User)

-- Instead of: -- The string must be a valid email
newtype Email = Email String
mkEmail :: String -> Either String Email

-- Instead of: -- Don't call this outside of a transaction
newtype Transaction a = Transaction (Aff a)
runTransaction :: Transaction a -> App a
```

## From JavaScript to PureScript: Migration Strategy

If you have an existing JavaScript/TypeScript project:

1. **Start with types.** Define PureScript types for your core domain.
2. **Write pure logic first.** Business rules, validation, state transitions.
3. **Use FFI for existing code.** Wrap your JavaScript modules with PureScript types.
4. **Migrate module by module.** Replace JavaScript modules with PureScript as you touch them.
5. **Keep the boundary clean.** PureScript owns the types; JavaScript owns the runtime integration.

This is an incremental strategy — you do not need to rewrite everything at once.

## Summary

- Use the Reader pattern for configuration and the Capability pattern for testable abstractions.
- Model application states as explicit sum types with defined transitions.
- Handle errors with domain-specific types and the `Either` pipeline.
- Organize large projects with clear separation: Domain, Infrastructure, UI, FFI.
- Start with types, make impossible states impossible, keep effects at the edge.
- Migrate from JavaScript incrementally — PureScript and JavaScript coexist naturally.
