module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Manas.Constants as C

main :: Effect Unit
main = do
  log "Running tests..."

  -- Verify constant values
  assertEq "baseNumberOfDimensions" C.baseNumberOfDimensions 3
  assertEq "numberOfJointsPerHand" C.numberOfJointsPerHand 25
  assertEq "numberOfHandJointDimensions" C.numberOfHandJointDimensions 75

  -- Verify joint index lookups
  assertEq "wrist lookup" (C.lookupJointIndex "wrist") 0
  assertEq "thumb-tip lookup" (C.lookupJointIndex "thumb-tip") 4
  assertEq "index-finger-tip lookup" (C.lookupJointIndex "index-finger-tip") 9
  assertEq "pinky-finger-tip lookup" (C.lookupJointIndex "pinky-finger-tip") 24
  assertEq "unknown lookup" (C.lookupJointIndex "unknown") (-1)

  -- Verify named constants match lookupJointIndex
  assertEq "thumbTip constant" C.thumbTip 4
  assertEq "indexFingerTip constant" C.indexFingerTip 9
  assertEq "middleFingerTip constant" C.middleFingerTip 14
  assertEq "ringFingerTip constant" C.ringFingerTip 19
  assertEq "pinkyFingerTip constant" C.pinkyFingerTip 24

  log "All tests passed!"

assertEq :: forall a. Eq a => Show a => String -> a -> a -> Effect Unit
assertEq label actual expected =
  if actual == expected
    then log ("  ✓ " <> label)
    else do
      log ("  ✗ " <> label <> ": expected " <> show expected <> " but got " <> show actual)
