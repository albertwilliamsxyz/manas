# Manas — Input Management, Gestures & State Machines

> Add your comments with <!-- -->. Everything here is conceptual first.

---

## I. The Anatomy of an Input Pipeline

Raw hardware data is not the same as application input. Between "the hardware
sends a signal" and "the Universe changes" there are three distinct steps:

```
Hardware Signal
  ↓ [Input Reading — effects layer]
Raw Data (joint positions, button states, ray directions)
  ↓ [Interpretation — pure functions]
Input State (gesture flags, normalized positions, named events)
  ↓ [Event Creation — pure functions]
Events (typed facts: PinchStarted, ModelGrabbed, CommandIssued)
  ↓ [Update — pure function]
New Universe
```

Each arrow is a function. Only the first one (Hardware → Raw Data) has effects.
All others are pure. This is the input pipeline. A weakness in any layer
propagates forward — a misinterpreted gesture becomes a wrong event becomes
wrong state.

### What each layer is responsible for:

**Input Reading (effects)**: call `frame.getJointPose()`, read `inputSources`,
read mouse/keyboard events. Convert hardware-specific APIs into flat,
straightforward data. Never decision-make here. Never log gestures here.
Output: plain data objects, not events.

**Interpretation (pure)**: take raw joint positions and compute what they mean.
Is the hand pinching? What velocity is a joint moving at? Which entity is closest
to the index finger tip? This is pure computation. Same inputs → same outputs.

**Event Creation (pure)**: take interpretation results and compare with previous
interpretation state (previous frame). If something CHANGED (pinch started,
an entity came within reach), emit a named Event. Events describe transitions,
not ongoing states.

**Update (pure)**: apply events to produce the new Universe. Has no knowledge
of hardware.

<!-- YOUR THOUGHTS: -->


---

## II. Why Threshold Checks Fail — The Case for State Machines

The simplest gesture detection: `if (distance < 0.02) { isPinching = true }`.

This has two problems:

**Problem 1: Chatter**
At 60fps, the distance oscillates. One frame it's 0.019, the next 0.021,
the next 0.019. This produces: pinching, not pinching, pinching, not pinching.
If a pinch triggers an action, that action fires multiple times per second.
You didn't mean to toggle that object 60 times. You meant to grab it once.

**Problem 2: No history**
A threshold doesn't know whether you were just pinching. It can't distinguish
"starting a pinch" from "maintaining a pinch" from "releasing a pinch."
Each of these should produce a different Event.

The solution to both problems is a STATE MACHINE.

A state machine is a formal model with:
- A finite set of STATES (IDLE, APPROACHING, PINCHING, RELEASING)
- A set of TRANSITIONS between states, each guarded by a CONDITION
- At most one active state at any moment
- Optional ACTIONS triggered on entering or leaving a state

The key property: transitions consume the past. The machine knows where it was,
which means it knows how to respond to the same distance reading differently
depending on what was happening before.

<!-- YOUR THOUGHTS: -->


---

## III. The Pinch Gesture State Machine

### States

**IDLE**: hand is relaxed, not approaching a pinch. The normal resting state.

**APPROACHING**: thumb and index are moving toward each other but haven't pinched.
This state exists for future uses: show a UI affordance, "get ready to pinch
this object," highlight the nearest entity. Optional state — skip if not needed.

**PINCHING**: the user is actively pinching. This is the "held" state.
An entity may be grabbed, a drawing may be happening, a menu may be open.

**RELEASING**: the user has opened their hand from a pinch but hasn't fully
separated yet. This state prevents accidental re-triggers. Optional state.

### Thresholds — Hysteresis is Essential

The key technique: use DIFFERENT thresholds for entering and exiting a state.
This is called hysteresis, borrowed from physics. It prevents chatter.

```
ENTER_APPROACH threshold:  0.05m  (5cm — hands are getting close)
ENTER_PINCH threshold:     0.02m  (2cm — you are pinching)
EXIT_PINCH threshold:      0.03m  (3cm — you have released, slightly more than enter)
EXIT_APPROACH threshold:   0.07m  (7cm — hands are clearly apart)
```

The EXIT thresholds are higher than the ENTER thresholds. This creates a
"sticky" zone: once you're pinching, you need to open your hand a little more
than you closed it to un-pinch. This is how physical switches work. This is
intentional and correct.

### Transition Table

```
From          Condition                        To
─────────────────────────────────────────────────────────────────
IDLE          distance < ENTER_APPROACH        APPROACHING
IDLE          distance < ENTER_PINCH           PINCHING     (fast pinch, skip APPROACHING)

APPROACHING   distance < ENTER_PINCH           PINCHING
APPROACHING   distance > EXIT_APPROACH         IDLE         (pulled back without pinching)

PINCHING      distance > EXIT_PINCH            RELEASING    (opened hand)
PINCHING      [other hand also pinches]        → two-hand gesture begins

RELEASING     distance < ENTER_PINCH           PINCHING     (recapture — pinched again quickly)
RELEASING     distance > EXIT_APPROACH         IDLE         (fully released)
```

### Events Produced by the Machine

The machine emits events only on STATE TRANSITIONS, not on every frame:

- IDLE → APPROACHING:  `PinchApproachStarted { hand, position }`
- APPROACHING → IDLE:  `PinchApproachAborted { hand }`
- APPROACHING → PINCHING: `PinchStarted { hand, position }`
- IDLE → PINCHING:     `PinchStarted { hand, position }`
- PINCHING → RELEASING: `PinchReleased { hand, position }`
- RELEASING → IDLE:    `PinchEnded { hand }`
- RELEASING → PINCHING: `PinchRecaptured { hand, position }`

Each event fires once. The update function handles each once.
The GrabMoved behavior (moving an entity while pinching) is represented NOT
by an event per frame but by: a HANDS_UPDATED event per frame PLUS an AppMode
of `{ type: 'moving', entityId, grabOffset }`. The update function, seeing
that the mode is 'moving', applies the new hand position to the entity.
No per-frame movement event needed.

<!-- YOUR THOUGHTS: -->


---

## IV. The Hand as a Full State Machine

The pinch is one gesture on one pair of fingers. A full hand model requires
tracking multiple simultaneous gesture components:

```
Hand State = {
  pinchState:  IDLE | APPROACHING | PINCHING | RELEASING
  grabState:   OPEN | CLOSING | GRABBED | OPENING
  pointState:  RELAXED | POINTING | EXTENDED
  palmState:   FACE_DOWN | FACE_UP | FACE_TOWARD_USER | LATERAL
}
```

Each component has its own state machine with its own thresholds. They are
independent — you can be pointing while not pinching, or grabbing while
palm-down. The combination of active states determines the NAMED GESTURE.

### Named Gesture Recognition

After computing per-component states, pattern-match them to named gestures:

```
Pinch:      pinchState == PINCHING
Grab:       grabState == GRABBED and not pointing
Point:      pointState == POINTING
OpenPalm:   all fingers extended, palmState == FACE_TOWARD_USER
Swipe:      velocity > threshold, direction detected from wrist trajectory
```

Named gestures are what get exposed to the application. The component states
are implementation details of the gesture recognizer.

### Gesture to Semantic Action Mapping

The final step: map named gestures to semantic actions in Manas.
This mapping is domain-specific and can change without touching the gesture
recognizer. Today a pinch means "grab entity." Tomorrow it might mean
"begin annotation." The mapping is configuration, not logic.

```
Context: mode is 'viewing', entity within reach of right index tip
  Pinch (right) → grab nearest entity → mode becomes 'moving'

Context: mode is 'moving', entity is grabbed
  PinchRelease (right) → release entity → mode becomes 'viewing'

Context: mode is 'drawing', left hand open palm facing user
  OpenPalm (left) → show tool palette

Context: mode is 'viewing', no entity nearby
  Pinch (right) → begin drawing stroke → mode becomes 'drawing'
```

The context is the current `AppMode` in the Universe. The gesture recognizer
produces a named gesture. The update function matches gesture + context →
new state and new AppMode.

<!-- YOUR THOUGHTS: -->


---

## V. Two-Handed Gestures

Two-handed gestures require observing BOTH hands simultaneously. They cannot
be handled by individual hand state machines alone.

A two-hand gesture detector observes the combined state of both hands:

```
Zoom/Scale:  both hands pinching, moving apart or together
Rotate:      both hands pinching, rotating around a shared center
Portal:      both hands open palm, thumbs touching (future: open scene view)
```

The two-hand detector runs AFTER both individual hand machines have updated.
It takes the current gesture state of left AND right hands and checks for
combined patterns. It produces its own events:
`TwoHandScaleStarted`, `TwoHandScaleChanged { scaleFactor }`, `TwoHandScaleEnded`.

The independence principle: individual hand machines don't know about each other.
The two-hand layer observes both outputs. This is composition, not coupling.

<!-- YOUR THOUGHTS: -->


---

## VI. The Abstract Input Layer

All the gesture detection above assumes XR hand tracking data. But Manas
should also work with a mouse, a keyboard, or XR controllers. The abstract
input layer decouples gesture semantics from hardware specifics.

### Abstract Input Events

Define a hardware-neutral event vocabulary:

```
AbstractInputEvent =
  | CursorMoved    { position3D: Vec3, screenPosition: Vec2 }
  | SelectStarted  { position3D: Vec3 }           (pinch, left click, trigger)
  | SelectEnded    { position3D: Vec3 }
  | MenuRequested  { position3D: Vec3 }            (open palm, right click)
  | CommandIssued  { command: 'undo' | 'redo' | 'delete' | 'save' | ... }
  | ScrollChanged  { delta: Vec2, position3D: Vec3 }
  | TwoHandScale   { scaleFactor: number, center: Vec3 }
```

These events are what the update function receives. Not XR joints — named
semantic events.

### Hardware Adapters

One adapter per hardware type. Each adapter converts hardware events into
AbstractInputEvents:

```
XRHandAdapter
  Input:  XRFrame, XRInputSourceArray, XRReferenceSpace
  Output: AbstractInputEvent[]
  Logic:  runs the gesture state machines, maps pinch → SelectStarted, etc.

MouseAdapter
  Input:  MouseEvent, camera: Camera
  Output: AbstractInputEvent[]
  Logic:  ray-cast from mouse position into 3D space, left-click → SelectStarted

KeyboardAdapter
  Input:  KeyboardEvent
  Output: AbstractInputEvent[]
  Logic:  maps key combos to CommandIssued events

XRControllerAdapter
  Input:  XRInputSource (with gamepad, no hand)
  Output: AbstractInputEvent[]
  Logic:  trigger press → SelectStarted, B button → MenuRequested
```

The update function never calls `frame.getJointPose()`. It receives events
that have already been processed by an adapter. The adapter is the impure edge;
the update function is the pure core.

### Multi-Modal Input: Running Multiple Adapters Simultaneously

In a spectator scenario: someone is wearing XR glasses; another person is
watching on a desktop with a mouse. Both are "in" the same scene:
- The XR user sends hand events via `XRHandAdapter`
- The desktop observer sends mouse events via `MouseAdapter`
- Both produce `AbstractInputEvent[]`
- The update function receives events from both, tagged with source identity
- The Universe knows player A moved object X; player B moved object Y

This is how multi-user sessions work: multiple input adapters feeding into
one update function. The adapters are parallel; the update is sequential.

<!-- YOUR THOUGHTS: -->


---

## VII. Handling the Frame — The Full Input Step

The complete input step in `onXRFrame`, in the correct order:

```
1. READ:   for each inputSource, read raw joint poses → RawHandData
2. INTERPRET: for each hand, compute per-joint positions → JointConfiguration
3. DETECT:  run gesture state machines → GestureState per hand
4. COMPARE: diff current GestureState with previous GestureState → transitions
5. EMIT:   for each transition, create an Event → Event[]
6. UPDATE:  for each event, run update(universe, event) → new Universe
7. RENDER:  render new Universe for each view → GPU calls
```

Steps 1-2 are effects. Steps 3-7 are pure (except 7). The gesture state
machines (step 3) require the previous frame's gesture state. This state is
stored in the Universe (or as a parallel "input state" object alongside the
Universe — architectural decision: whether gesture machine state IS app state
or is separate input processing state).

The argument for keeping gesture machine state IN the Universe: it's auditable,
replayable, and stored with everything else.
The argument for keeping it SEPARATE: it is input-system-internal state, not
domain state. The app doesn't care what the pinch state machine's current mode
is; it cares that a PinchStarted event arrived. This is a real design question.

<!-- YOUR THOUGHTS: -->

---

*This document gives you everything needed to implement input. Start with
the pinch state machine — one state machine, two thresholds — and build from there.*
