# Chapter 9: Web and UI Development

PureScript has a rich ecosystem for building web applications. This chapter covers the major approaches: Halogen for component-based UIs, React via `purescript-react-basic-hooks`, and direct DOM manipulation.

## Halogen: The PureScript-Native UI Framework

Halogen is a type-safe, component-based UI framework built specifically for PureScript. It is the most popular choice for PureScript web applications.

### Core Concepts

A Halogen component has:

- **State** — the component's internal data.
- **Action** — events that can change the state.
- **Input** — data passed from parent components.
- **Output** — messages sent to parent components.
- **HTML** — the view, rendered from state.

### A Simple Counter

```purescript
module App.Counter where

import Prelude
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

data Action = Increment | Decrement

component :: forall q i o m. H.Component q i o m
component =
  H.mkComponent
    { initialState: \_ -> 0
    , render
    , eval: H.mkEval H.defaultEval { handleAction = handleAction }
    }

render :: forall m. Int -> H.ComponentHTML Action () m
render count =
  HH.div_
    [ HH.button
        [ HE.onClick \_ -> Decrement ]
        [ HH.text "-" ]
    , HH.span_ [ HH.text (show count) ]
    , HH.button
        [ HE.onClick \_ -> Increment ]
        [ HH.text "+" ]
    ]

handleAction :: forall o m. Action -> H.HalogenM Int Action () o m Unit
handleAction = case _ of
  Increment -> H.modify_ (_ + 1)
  Decrement -> H.modify_ (_ - 1)
```

### Running a Halogen App

```purescript
module Main where

import Prelude
import Effect (Effect)
import Halogen.Aff as HA
import Halogen.VDom.Driver (runUI)
import App.Counter as Counter

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  runUI Counter.component unit body
```

### Component Communication

Parent-child communication uses input and output:

```purescript
-- Child sends output messages
data Output = ValueChanged Int

-- Parent receives them in its handleAction
handleAction :: Action -> HalogenM State Action ChildSlots Output m Unit
handleAction (HandleChild (ValueChanged n)) = do
  H.modify_ _ { childValue = n }
```

### Subscriptions and Effects

Halogen components can subscribe to external events and perform effects:

```purescript
handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction Initialize = do
  -- Perform an HTTP request
  response <- H.liftAff $ AX.get ResponseFormat.json "/api/data"
  case response of
    Left err -> H.modify_ _ { error = Just (AX.printError err) }
    Right res -> H.modify_ _ { data = Just res.body }
```

## React via purescript-react-basic-hooks

If you prefer React's component model, `purescript-react-basic-hooks` provides PureScript bindings:

```purescript
module App.Counter where

import Prelude
import React.Basic.DOM as R
import React.Basic.Events (handler_)
import React.Basic.Hooks (Component, component, useState)
import React.Basic.Hooks as React

mkCounter :: Component {}
mkCounter = do
  component "Counter" \_ -> React.do
    count /\ setCount <- useState 0
    pure $ R.div_
      [ R.button
          { onClick: handler_ $ setCount (_ - 1)
          , children: [ R.text "-" ]
          }
      , R.span_ [ R.text (show count) ]
      , R.button
          { onClick: handler_ $ setCount (_ + 1)
          , children: [ R.text "+" ]
          }
      ]
```

This looks remarkably similar to React hooks in JavaScript, with the added safety of PureScript's type system.

## Direct DOM Manipulation

For lower-level control, use `purescript-web-dom`:

```purescript
import Web.DOM.Document (createElement, createTextNode)
import Web.DOM.Element (setAttribute, toNode)
import Web.DOM.Node (appendChild)
import Web.HTML (window)
import Web.HTML.HTMLDocument (body, toDocument)
import Web.HTML.Window (document)

main :: Effect Unit
main = do
  doc <- document =<< window
  let d = toDocument doc
  elem <- createElement "div" d
  setAttribute "class" "greeting" elem
  text <- createTextNode "Hello from PureScript!" d
  appendChild (toNode text) (toNode elem) -- simplified
```

This is useful when you need fine-grained control over the DOM, such as when integrating with WebGL or WebXR.

## Routing

### With Halogen

Use `purescript-routing-duplex` for type-safe routing:

```purescript
import Routing.Duplex (RouteDuplex', root, segment, end)

data Route
  = Home
  | About
  | User String

routeCodec :: RouteDuplex' Route
routeCodec = root $ sum
  { "Home": end
  , "About": "about" / end
  , "User": "user" / segment
  }
```

The route codec both parses URLs into `Route` values and prints `Route` values back to URLs — they are guaranteed to be inverses.

### Hash-Based Routing

For single-page applications:

```purescript
import Routing.Hash (matchesWith)

main :: Effect Unit
main = void $ matchesWith (parse routeCodec) \old new -> do
  -- old: Maybe Route (previous route)
  -- new: Either error Route (current route)
  case new of
    Left _ -> log "404"
    Right route -> navigate route
```

## HTTP Requests

Use `purescript-affjax` for HTTP:

```purescript
import Affjax as AX
import Affjax.RequestBody as RequestBody
import Affjax.ResponseFormat as ResponseFormat

getUsers :: Aff (Either AX.Error (Array User))
getUsers = do
  response <- AX.get ResponseFormat.json "/api/users"
  pure $ map (decodeJson <<< _.body) response

createUser :: User -> Aff (Either AX.Error Unit)
createUser user = do
  void $ AX.post ResponseFormat.ignore "/api/users"
    (Just $ RequestBody.json $ encodeJson user)
  pure (Right unit)
```

## JSON Handling

Use `purescript-argonaut` for JSON encoding and decoding:

```purescript
import Data.Argonaut (class DecodeJson, class EncodeJson, decodeJson, encodeJson)
import Data.Argonaut.Decode.Generic (genericDecodeJson)
import Data.Argonaut.Encode.Generic (genericEncodeJson)

newtype User = User
  { name :: String
  , email :: String
  , age :: Int
  }

derive instance Generic User _

instance EncodeJson User where
  encodeJson = genericEncodeJson

instance DecodeJson User where
  decodeJson = genericDecodeJson
```

## CSS and Styling

### Inline Styles

```purescript
import Halogen.HTML.Properties as HP

render state =
  HH.div
    [ HP.style "color: red; font-size: 16px;" ]
    [ HH.text "Styled text" ]
```

### CSS Classes

```purescript
render state =
  HH.div
    [ HP.classes [ HH.ClassName "container", HH.ClassName "active" ] ]
    [ HH.text "Classy text" ]
```

### CSS Modules / Tailwind

PureScript integrates with any CSS solution. Reference your CSS classes as strings:

```purescript
render state =
  HH.div
    [ HP.class_ (HH.ClassName "flex items-center gap-4 p-4") ]
    [ HH.text "Tailwind styled" ]
```

## WebGL and Canvas Integration

For graphics-intensive applications, use FFI with WebGL:

```purescript
foreign import getWebGLContext :: HTMLCanvasElement -> Effect (Maybe WebGLRenderingContext)
foreign import clearCanvas :: WebGLRenderingContext -> Effect Unit
foreign import drawScene :: WebGLRenderingContext -> SceneState -> Effect Unit

renderLoop :: WebGLRenderingContext -> Ref SceneState -> Effect Unit
renderLoop gl stateRef = do
  state <- read stateRef
  clearCanvas gl
  drawScene gl state
  requestAnimationFrame (renderLoop gl stateRef)
```

This pattern — PureScript managing state, JavaScript handling WebGL calls — gives you type safety where it matters most (state transitions) while leveraging JavaScript for performance-critical rendering.

## Summary

- **Halogen** is the PureScript-native UI framework: type-safe components with state, actions, and parent-child communication.
- **purescript-react-basic-hooks** brings React's hooks model with PureScript types.
- **Direct DOM** manipulation for low-level control (WebGL, WebXR integration).
- **Routing** with `purescript-routing-duplex` provides bidirectional, type-safe routes.
- **Affjax** for HTTP requests; **Argonaut** for JSON.
- PureScript manages state and logic; FFI bridges to browser APIs.
