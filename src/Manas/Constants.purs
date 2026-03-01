module Manas.Constants where

import Prelude

baseNumberOfDimensions :: Int
baseNumberOfDimensions = 3

numberOfJointsPerHand :: Int
numberOfJointsPerHand = 25

numberOfHandJointDimensions :: Int
numberOfHandJointDimensions = numberOfJointsPerHand * baseNumberOfDimensions

handSkeletonByJointIndices :: Array Int
handSkeletonByJointIndices =
  [ 0, 1, 1, 2, 2, 3, 3, 4
  , 0, 5, 5, 6, 6, 7, 7, 8, 8, 9
  , 0, 10, 10, 11, 11, 12, 12, 13, 13, 14
  , 0, 15, 15, 16, 16, 17, 17, 18, 18, 19
  , 0, 20, 20, 21, 21, 22, 22, 23, 23, 24
  ]

type HandJointName = String

wrist :: Int
wrist = 0

thumbMetacarpal :: Int
thumbMetacarpal = 1

thumbPhalanxProximal :: Int
thumbPhalanxProximal = 2

thumbPhalanxDistal :: Int
thumbPhalanxDistal = 3

thumbTip :: Int
thumbTip = 4

indexFingerMetacarpal :: Int
indexFingerMetacarpal = 5

indexFingerPhalanxProximal :: Int
indexFingerPhalanxProximal = 6

indexFingerPhalanxIntermediate :: Int
indexFingerPhalanxIntermediate = 7

indexFingerPhalanxDistal :: Int
indexFingerPhalanxDistal = 8

indexFingerTip :: Int
indexFingerTip = 9

middleFingerMetacarpal :: Int
middleFingerMetacarpal = 10

middleFingerPhalanxProximal :: Int
middleFingerPhalanxProximal = 11

middleFingerPhalanxIntermediate :: Int
middleFingerPhalanxIntermediate = 12

middleFingerPhalanxDistal :: Int
middleFingerPhalanxDistal = 13

middleFingerTip :: Int
middleFingerTip = 14

ringFingerMetacarpal :: Int
ringFingerMetacarpal = 15

ringFingerPhalanxProximal :: Int
ringFingerPhalanxProximal = 16

ringFingerPhalanxIntermediate :: Int
ringFingerPhalanxIntermediate = 17

ringFingerPhalanxDistal :: Int
ringFingerPhalanxDistal = 18

ringFingerTip :: Int
ringFingerTip = 19

pinkyFingerMetacarpal :: Int
pinkyFingerMetacarpal = 20

pinkyFingerPhalanxProximal :: Int
pinkyFingerPhalanxProximal = 21

pinkyFingerPhalanxIntermediate :: Int
pinkyFingerPhalanxIntermediate = 22

pinkyFingerPhalanxDistal :: Int
pinkyFingerPhalanxDistal = 23

pinkyFingerTip :: Int
pinkyFingerTip = 24

cubeVertices :: Array Number
cubeVertices =
  [ -0.1, -0.1,  0.1
  ,  0.1, -0.1,  0.1
  ,  0.1,  0.1,  0.1
  , -0.1, -0.1,  0.1
  ,  0.1,  0.1,  0.1
  , -0.1,  0.1,  0.1

  ,  0.1, -0.1, -0.1
  , -0.1, -0.1, -0.1
  , -0.1,  0.1, -0.1
  ,  0.1, -0.1, -0.1
  , -0.1,  0.1, -0.1
  ,  0.1,  0.1, -0.1

  ,  0.1, -0.1,  0.1
  ,  0.1, -0.1, -0.1
  ,  0.1,  0.1, -0.1
  ,  0.1, -0.1,  0.1
  ,  0.1,  0.1, -0.1
  ,  0.1,  0.1,  0.1

  , -0.1, -0.1, -0.1
  , -0.1, -0.1,  0.1
  , -0.1,  0.1,  0.1
  , -0.1, -0.1, -0.1
  , -0.1,  0.1,  0.1
  , -0.1,  0.1, -0.1

  , -0.1,  0.1,  0.1
  ,  0.1,  0.1,  0.1
  ,  0.1,  0.1, -0.1
  , -0.1,  0.1,  0.1
  ,  0.1,  0.1, -0.1
  , -0.1,  0.1, -0.1

  , -0.1, -0.1, -0.1
  ,  0.1, -0.1, -0.1
  ,  0.1, -0.1,  0.1
  , -0.1, -0.1, -0.1
  ,  0.1, -0.1,  0.1
  , -0.1, -0.1,  0.1
  ]

lookupJointIndex :: String -> Int
lookupJointIndex = case _ of
  "wrist" -> 0
  "thumb-metacarpal" -> 1
  "thumb-phalanx-proximal" -> 2
  "thumb-phalanx-distal" -> 3
  "thumb-tip" -> 4
  "index-finger-metacarpal" -> 5
  "index-finger-phalanx-proximal" -> 6
  "index-finger-phalanx-intermediate" -> 7
  "index-finger-phalanx-distal" -> 8
  "index-finger-tip" -> 9
  "middle-finger-metacarpal" -> 10
  "middle-finger-phalanx-proximal" -> 11
  "middle-finger-phalanx-intermediate" -> 12
  "middle-finger-phalanx-distal" -> 13
  "middle-finger-tip" -> 14
  "ring-finger-metacarpal" -> 15
  "ring-finger-phalanx-proximal" -> 16
  "ring-finger-phalanx-intermediate" -> 17
  "ring-finger-phalanx-distal" -> 18
  "ring-finger-tip" -> 19
  "pinky-finger-metacarpal" -> 20
  "pinky-finger-phalanx-proximal" -> 21
  "pinky-finger-phalanx-intermediate" -> 22
  "pinky-finger-phalanx-distal" -> 23
  "pinky-finger-tip" -> 24
  _ -> -1
