# FFI NAMING CONVENTIONS FOR WEBGL2 AND APPLICATION

## Overview
Consistent naming conventions make your FFI and application code easier to read, maintain, and extend. This document defines the meaning and usage of common terms for function names in the context of WebGL2 and general application development.

---

## Naming Convention Table

| Term         | Allocates? | Needs input? | Composes? | Side effect? | Example Use                |
|--------------|------------|--------------|-----------|--------------|----------------------------|
| create       | Yes        | Context      | No        | Yes          | createShader               |
| initialize   | No         | Object       | No        | Yes          | initializeShader           |
| build        | No         | Objects      | Yes       | Yes/No       | buildProgram               |
| get          | No         | Key/ID       | No        | No           | getUniformLocation         |
| declare      | No         | -            | No        | No           | declareConstants           |
| define       | No         | -            | No        | No           | defineShaderSource         |
| start        | No         | -            | No        | Yes          | startRenderLoop            |
| run          | No         | -            | No        | Yes          | runTest                    |

---

## Detailed Definitions

### 1. **create**
- **Meaning:** Allocate or instantiate a new resource/object, usually from a thunk (no arguments or just a context).
- **Example:** `createShader`, `createProgram`, `createBuffer`
- **JS FFI:** Typically wraps a constructor or a `gl.createX` method.

### 2. **initialize**
- **Meaning:** Set up an object/resource after creation, often by configuring or populating it with data.
- **Example:** `initializeShader` (compiles source), `initializeBuffer` (uploads data), `initializeProgram` (links shaders)
- **JS FFI:** Typically calls methods like `gl.shaderSource`, `gl.compileShader`, `gl.linkProgram`, etc.

### 3. **build**
- **Meaning:** Compose or combine multiple existing objects/resources into a new, higher-level object.
- **Example:** `buildScene` (from models, lights, etc.), `buildPipeline` (from shaders, buffers)
- **JS FFI:** Typically a function that takes several objects and returns a new one.

### 4. **get**
- **Meaning:** Retrieve an object or value from another object, usually by providing a key, name, or ID.
- **Example:** `getUniformLocation`, `getAttribLocation`, `getElementById`
- **JS FFI:** Typically calls methods like `gl.getUniformLocation(program, name)`.

### 5. **declare**
- **Meaning:** State the existence of something, often for variables or constants, but not for resources.
- **Example:** `declareConstants`, `declareUniforms`
- **JS FFI:** Rarely needed; more for internal code organization.

### 6. **define**
- **Meaning:** Provide a definition, often for a function, macro, or constant.
- **Example:** `defineShaderSource`
- **JS FFI:** Rarely needed; more for code structure.

### 7. **start**
- **Meaning:** Begin a process or computation, often with side effects or a running state.
- **Example:** `startRenderLoop`, `startExperience`
- **JS FFI:** Typically wraps a function that starts an animation, event loop, or async process.

### 8. **run**
- **Meaning:** Execute a computation or process, often to completion.
- **Example:** `runMainLoop`, `runTest`
- **JS FFI:** Typically wraps a function that performs a computation.

---

## Application to WebGL2 FFI

- **createShader**: Allocates a new shader object.
- **initializeShader**: Compiles the shader with source.
- **createProgram**: Allocates a new program object.
- **buildProgram**: Attaches shaders and links the program.
- **getAttribLocation**: Gets attribute location from a program.
- **getUniformLocation**: Gets uniform location from a program.
- **startRenderLoop**: Begins the main rendering loop.

---

## Summary
- Use these conventions consistently across your FFI and application code.
- Document any exceptions or new terms in this file for future contributors.
