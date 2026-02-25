# Project Overview

This program aims to elevate human cognition by providing an immersive, holistic experience. Users can express and experiment with any model of the world they imagine, using a general framework that allows ideas to be run or evaluated in a live environment.

---

## Current Capabilities

- **WebXR & WebGL2 Integration**: The main application leverages WebXR and WebGL2 to render interactive 3D environments, supporting VR/AR sessions.
- **Hand Tracking**: Real-time hand tracking is implemented, allowing users to interact with the environment using gestures. The system tracks 25 joints per hand and recognizes gestures such as pinching.
- **3D Model Rendering**: The program renders a cube and hand skeletons, supporting dynamic drawing based on user gestures.
- **Shader Management**: Custom vertex and fragment shaders are used for rendering, with dynamic color changes triggered by gestures.
- **Scene Setup**: The environment includes buffers and vertex arrays for the main model, hands, skeletons, and user drawings.

---

## Roadmap & Future Directions

- **Multiple Models Support**: Plans to implement a scene graph for managing multiple models, including grouping, hierarchical transformations, and model metadata.
- **Gesture Recognition & Manipulation**: Advanced gesture recognition (pinch, grab, rotate, scale) and manipulation mapping are outlined, with ideas for custom gestures and accessibility.
- **Collision Detection**: Future integration of bounding volumes, collision algorithms, and physics engines for realistic interactions.
- **Scene Management**: Features like persistence, undo/redo, import/export, and collaborative editing are planned.

---

## Architecture

- **main.js**: Core logic for rendering, hand tracking, gesture recognition, and drawing.
- **vite.config.js**: Vite configuration for secure development server.
- **ROADMAP.md**: Detailed development plan and theoretical frameworks for future enhancements.

---

## Documentation

- **[docs/LINEAR_ALGEBRA.md](docs/LINEAR_ALGEBRA.md)**: Comprehensive guide to linear algebra for computer graphics, covering scalars, vectors, matrices, and transformations.
- **[docs/HOMOTOPY_TYPE_THEORY.md](docs/HOMOTOPY_TYPE_THEORY.md)**: Guide to dependent type theory and homotopy type theory (HoTT), covering the Curry–Howard correspondence, Π and Σ types, identity types, univalence, higher inductive types, and their connections to category theory and TypeScript.
- **[docs/architecture/DESIGN.md](docs/architecture/DESIGN.md)**: Categorical implementation plan describing the type system and morphisms of the Universe model.
- **[docs/architecture/NOTES.md](docs/architecture/NOTES.md)**: Architecture notes and design decisions.

---

## Usage

- Requires a browser with WebXR and WebGL2 support.
- Launch the application and start an immersive AR session.
- Use hand gestures to interact, draw, and manipulate objects in the scene.

---

## Vision

The project is designed for extensibility, composability, and user empowerment. It aims to become a flexible instrument for exploring ideas, cognition, and interaction in immersive environments.

