# Linear Algebra for Computer Graphics: A Conceptual Tree

## Vision and Purpose

This document is a comprehensive guide to linear algebra applied to computer graphics, structured as a conceptual tree. Each section builds upon the previous, allowing for a deep and progressive understanding of the mathematics behind 3D transformations. The goal is for you to analyze, compose, and create your own operations, using the computer as a tool, but never as a substitute for your reasoning.

> **See also**: [`CATEGORY_LINEAR_ALGEBRA.md`](./CATEGORY_LINEAR_ALGEBRA.md) for a treatment of these same concepts through the lens of category theory — understanding vector spaces as objects, linear maps as morphisms, and transformations as functors.

---

## Visión y Propósito

Este documento es una guía exhaustiva sobre álgebra lineal aplicada a gráficos computacionales, estructurada como un árbol conceptual. Cada sección se construye sobre la anterior, permitiendo una comprensión profunda y progresiva de las matemáticas detrás de las transformaciones 3D. El objetivo es que puedas analizar, componer y crear tus propias operaciones, usando la computadora como herramienta, pero nunca como sustituto de tu razonamiento.

---

## Fundamental Root: Scalars

### What is a scalar?
A scalar is a numerical quantity representing magnitude in a single dimension. Examples: temperature, distance, mass, time.

- Scalars are used in physics, engineering, and mathematics to represent quantities such as speed, energy, and force.
- In computer graphics, scalars are often used to scale objects, control brightness, or represent time intervals.

#### Relationship with geometry
- A scalar can be the length of a segment (1D), the area of a surface (2D, as the product of two scalars), or the volume of a body (3D, as the product of three scalars).
- Scalars are the foundation for constructing vectors and matrices.
- In higher dimensions, scalars are used to define measures such as hypervolume.

#### Examples
- Length: `a = 5` meters
- Temperature: `t = 22` °C
- Scaling a vector: If `v = [2, 3]`, then `2*v = [4, 6]`
- Mass: `m = 10` kg
- Time: `t = 60` seconds
- Energy: `E = m * c^2` (scalar multiplication in physics)

#### Exercises
1. What does the scalar `7` represent in the context of a straight line?
2. Multiply the scalar `3` by the vector `[1, 2, 3]`.
3. If you have two scalars `a = 4` and `b = 5`, what area do they represent together?
4. Give an example of a scalar in economics.

---

## Roots of the Tree: Vectors

### What is a vector?
A vector is an ordered collection of scalars representing position, direction, or magnitude in space. In 3D graphics, we use vectors with 3 or 4 components:

- **Position:** `[x, y, z, 1]` (represents a point)
- **Direction:** `[x, y, z, 0]` (represents a direction or force)

#### Properties of Vectors
- Magnitude (length)
- Normalization (unit vector)
- Dot product and cross product
- Addition and subtraction
- Scalar multiplication
- Angle between vectors
- Orthogonality (perpendicularity)
- Projection of one vector onto another

#### Examples
- 2D vector: `v = [3, 4]` (position in the plane)
- 3D vector: `w = [1, 2, 3]` (direction in space)
- Scaling: `2 * [1, 2, 3] = [2, 4, 6]`
- Vector addition: `[1, 2] + [3, 4] = [4, 6]`
- Dot product: `[1, 2, 3] · [4, 5, 6] = 1*4 + 2*5 + 3*6 = 32`
- Cross product: `[1, 0, 0] × [0, 1, 0] = [0, 0, 1]`
- Projection: Project `[2, 3]` onto `[1, 0]` gives `[2, 0]`

#### Exercises
1. Calculate the magnitude of the vector `[3, 4]`.
2. Normalize the vector `[2, 0]`.
3. What does the vector `[0, 1, 0]` represent in geometry?
4. Compute the dot product of `[2, 3]` and `[4, 5]`.
5. Find the angle between `[1, 0]` and `[0, 1]`.
6. Project `[3, 4]` onto `[1, 0]`.

---

## Trunk of the Tree: Matrices

### What is a matrix?
A matrix is a table of numbers (usually scalars) representing a transformation. In 3D graphics, we use 4x4 matrices to combine rotation, scaling, and translation in a single operation.

#### Properties of Matrices
- Dimension (4x4 in 3D)
- Identity
- Inverse
- Transpose
- Determinant
- Associativity of multiplication
- Non-commutativity (order matters)
- Row and column interpretation
- Matrix multiplication rules

#### Example
```
M = | m00 m01 m02 m03 |
    | m10 m11 m12 m13 |
    | m20 m21 m22 m23 |
    | m30 m31 m32 m33 |
```
- Example: 2x2 matrix for 2D transformations
- Example: 3x3 matrix for 3D rotation
- Example: 4x4 matrix for 3D transformations including translation

#### Exercises
1. Write the 2x2 identity matrix.
2. What happens if you multiply the identity matrix by a vector?
3. Calculate the transpose of the matrix:
```
| 1 2 |
| 3 4 |
```
4. Find the determinant of the matrix above.
5. Give an example of a matrix in statistics.

---

## First Nodes: Basic Operations

### Matrix-Vector Multiplication

Multiplying a matrix by a vector transforms a point or direction in space:

```
v = | x |
    | y |
    | z |
    | 1 |

v' = M x v
```

Each component of `v'` is the sum of the product of the matrix row by the vector.

#### Example
If `M` is a scaling matrix and `v` is a position vector, the result is the scaled point.
- Example: Scaling matrix `| 2 0 |; | 0 3 |` and vector `[1, 2]` gives `[2, 6]`
- Example: Rotation matrix applied to `[1, 0]` rotates the point

#### Exercises
1. Multiply the scaling matrix:
```
| 2 0 |
| 0 3 |
```
by the vector `[1, 2]`.
2. What happens if you multiply a rotation matrix by a direction vector?
3. Apply a translation matrix to `[2, 3, 1]`.

### Matrix-Matrix Multiplication

To combine transformations, we multiply matrices. The order is fundamental:

- **Scale → Rotation → Translation**

#### Example
```
M_total = T x R x S
```
Where T = translation, R = rotation, S = scale.
- Example: Combining a scaling matrix and a rotation matrix
- Example: Multiplying two transformation matrices for animation

#### Exercises
1. Multiply two scaling matrices:
```
| 2 0 |
| 0 2 |
```
and
```
| 3 0 |
| 0 3 |
```
2. What does the result represent?
3. Multiply a rotation matrix and a translation matrix.

---

## Intermediate Nodes: Types of Transformation Matrices

### Scaling
Multiplies each component by a factor:
```
| sx 0  0  0 |
| 0  sy 0  0 |
| 0  0  sz 0 |
| 0  0  0  1 |
```
- Example: Scaling a cube by 2 doubles its size
- Example: Scaling only in the X axis stretches the object horizontally
- Example: Scaling a vector `[3, 5, 7]` by 0.5 gives `[1.5, 2.5, 3.5]`

#### Exercises
1. How would the matrix change if you only want to scale in the X axis?
2. Apply the scaling matrix to a cube with side 1.
3. Scale a vector `[3, 5, 7]` by 0.5.

### Rotation
Uses trigonometry to rotate around an axis:

#### Rotation X
```
| 1  0      0     0 |
| 0  cosθ  -sinθ  0 |
| 0  sinθ   cosθ  0 |
| 0  0      0     1 |
```

#### Rotation Y
```
| cosθ  0  sinθ  0 |
| 0     1   0    0 |
| -sinθ 0  cosθ  0 |
| 0     0   0    1 |
```

#### Rotation Z
```
| cosθ -sinθ 0 0 |
| sinθ  cosθ 0 0 |
| 0     0    1 0 |
| 0     0    0 1 |
```
- Example: Rotating a point `[1, 0, 0]` 90° around Y gives `[0, 0, -1]`
- Example: Rotating a vector in 2D by 45°
- Example: Rotating `[2, 2, 0]` 180° around the Z axis gives `[-2, -2, 0]`

#### Exercises
1. What happens if θ = 0?
2. Apply a 90° rotation in the Y axis to the vector `[1, 0, 0]`.
3. Rotate `[2, 2, 0]` 180° around the Z axis.

### Translation
Moves the point in space:
```
| 1 0 0 tx |
| 0 1 0 ty |
| 0 0 1 tz |
| 0 0 0  1 |
```
- Example: Translating `[1, 2, 3]` by `[2, -1, 0]` gives `[3, 1, 3]`
- Example: Moving an object along the X axis
- Example: Translating `[0, 0, 0]` by `[5, 5, 5]` gives `[5, 5, 5]`

#### Exercises
1. Translate the point `[1, 2, 3]` using `tx = 2`, `ty = -1`, `tz = 0`.
2. What does translation represent in geometry?
3. Translate `[0, 0, 0]` by `[5, 5, 5]`.

---

## Advanced Nodes: Composition of Transformations

To transform an object, compose matrices in the correct order:

1. Scale
2. Rotation (X, Y, Z)
3. Translation

Multiply the matrices in that order:
```
M_total = T x Rz x Ry x Rx x S
```

#### Practical Example
Suppose you want to scale, rotate, and move a cube:
- Calculate each individual matrix
- Multiply in the correct order
- Apply the result to the position vector
- Example: Animation pipeline for a moving and rotating object
- Example: Composing transformations for a camera

#### Exercises
1. Create a sequence of matrices to transform a triangle in the plane.
2. What happens if you change the order of multiplication?
3. Compose a scaling, rotation, and translation for a 3D model.

---

## Creative Nodes: Alternative Applications

- Reflect objects (reflection matrix)
- Distort (deformation matrix)
- Project (projection matrix)
- Animate (matrix interpolation)
- Simulate physics (application of forces and movements)
- Shear (shearing matrix)
- Perspective transformations
- Orthogonal projections
- Transformations for data visualization

#### Reflection Example
```
| -1 0 0 0 |
| 0  1 0 0 |
| 0  0 1 0 |
| 0  0 0 1 |
```
- Example: Reflecting a point `[2, 3, 4]` in the X axis gives `[-2, 3, 4]`
- Example: Projecting a point onto a plane
- Example: Shearing a vector `[1, 2, 3]` changes its shape

#### Exercises
1. Apply a reflection matrix to the point `[2, 3, 4]`.
2. How would you create a projection matrix for a camera?
3. Apply a shearing matrix to `[1, 2, 3]`.

---

## Thinking in Terms of Matrices: Philosophy and Strategies

- Every transformation is a matrix
- Matrices can be composed to create complex effects
- Think of matrices as mathematical functions
- The order of multiplication determines the final result
- Visualize the flow of transformations as branches of the tree
- Use diagrams to represent transformation pipelines
- Explore the algebraic properties of matrices
- Consider the geometric interpretation of matrix operations
- Use matrix decomposition for advanced analysis (e.g., eigenvalues, singular value decomposition)

#### Learning Strategy
- Practice multiplying matrices and vectors by hand
- Visualize how each transformation affects an object
- Use pure and compositional functions in your code
- Document each operation and its purpose
- Experiment with different transformation orders
- Study the geometric interpretation of matrix operations
- Draw diagrams of transformation pipelines

#### Exercises
1. Write a function that composes matrices in your favorite language.
2. Document each step of a complex transformation.
3. Draw a diagram of a transformation pipeline.

---

## Diverse Applications of Linear Algebra

### Physics
- Movement of particles and systems.
- Analysis of forces and energy.
- Waves and vibrations.
- Quantum mechanics (state vectors and operators)
- Electromagnetism (field vectors)
- Mechanics (kinematics and dynamics)

### Economics
- Supply and demand models.
- Resource optimization.
- Financial systems analysis.
- Portfolio optimization (matrix of assets)
- Linear programming for optimization

### Biology
- Population modeling.
- Biological neural networks.
- Genetic analysis.
- Protein folding (coordinate transformations)
- Systems biology (interaction networks)

### Statistics and Data Science
- Linear regression.
- Multivariate data analysis.
- PCA (Principal Component Analysis).
- Covariance matrices
- Clustering algorithms
- Dimensionality reduction

### Machine Learning
- Data representation.
- Space transformations.
- Classification and clustering algorithms.
- Neural network weights (matrix multiplication)
- Dimensionality reduction
- Feature extraction

### Engineering
- Systems of equations for circuits.
- Structural modeling.
- Signal processing.
- Robotics (kinematics and dynamics)
- Control systems

### Computer Graphics
- 2D and 3D transformations.
- Animation and simulation.
- Rendering and projection.
- Camera transformations
- Texture mapping
- Lighting calculations

---

## Research Areas and Future Applications

- Quantum computing: linear algebra for qubit manipulation.
- Advanced artificial intelligence: deep neural networks.
- Modeling complex systems: biology, climate, global economy.
- Interactive visualization of multidimensional data.
- Robotics and autonomous control.
- Cryptography and security.
- Simulation of virtual universes.
- Augmented reality and VR.
- Computational geometry.
- Computer vision and image processing.
- Data-driven scientific discovery.

---

## Solutions to Exercises

### Scalars
1. The scalar `7` represents the length of a segment of 7 units in a straight line.
2. `3 * [1, 2, 3] = [3, 6, 9]`.
3. Area: `a * b = 4 * 5 = 20` square units.
4. Example in economics: `price = 10` dollars (scalar value).

### Vectors
1. Magnitude of `[3, 4]`: `sqrt(3^2 + 4^2) = 5`.
2. Normalization of `[2, 0]`: Magnitude = `2`, unit vector = `[1, 0]`.
3. `[0, 1, 0]` represents a vertical direction in the Y axis.
4. Dot product: `[2, 3] · [4, 5] = 2*4 + 3*5 = 8 + 15 = 23`.
5. Angle between `[1, 0]` and `[0, 1]`: 90° (orthogonal).
6. Projection of `[3, 4]` onto `[1, 0]`: `[3, 0]`.

### Matrices
1. 2x2 identity matrix: `| 1 0 | | 0 1 |`.
2. Multiplying identity by a vector does not change the vector.
3. Transpose of `| 1 2 | | 3 4 |` is `| 1 3 | | 2 4 |`.
4. Determinant: `1*4 - 2*3 = 4 - 6 = -2`.
5. Example in statistics: covariance matrix.

### Matrix-Vector Multiplication
1. `| 2 0 | | 0 3 |` x `[1, 2]` = `[2, 6]`.
2. Multiplying a rotation matrix by a direction vector changes its orientation.
3. Translation matrix applied to `[2, 3, 1]` gives `[2+tx, 3+ty, 1+tz]`.

### Matrix-Matrix Multiplication
1. `| 2 0 | | 0 2 |` x `| 3 0 | | 0 3 |` = `| 6 0 | | 0 6 |`.
2. The result represents a total scale of 6 in each axis.
3. Rotation matrix times translation matrix: composite transformation.

### Scaling
1. If you only scale in X: `| sx 0 0 0 | | 0 1 0 0 | | 0 0 1 0 | | 0 0 0 1 |`.
2. Scaling a cube with side 1 by 2: sides = 2.
3. Scaling `[3, 5, 7]` by 0.5: `[1.5, 2.5, 3.5]`.

### Rotation
1. If θ = 0, the matrix is the identity (no rotation).
2. Rotating `[1, 0, 0]` 90° in Y: `[0, 0, -1]`.
3. Rotating `[2, 2, 0]` 180° in Z: `[-2, -2, 0]`.

### Translation
1. `[1, 2, 3]` + `[2, -1, 0]` = `[3, 1, 3]`.
2. Translation moves the point in space.
3. `[0, 0, 0]` + `[5, 5, 5]` = `[5, 5, 5]`.

### Composition
1. Sequence: Scale, then rotation, then translation.
2. Changing the order changes the final result.
3. Scaling, rotating, and translating a 3D model: composite transformation.

### Creative Applications
1. Reflection of `[2, 3, 4]` in X: `[-2, 3, 4]`.
2. Projection matrix: depends on the type, e.g., perspective projection.
3. Shearing `[1, 2, 3]`: result depends on the shearing matrix.

### Philosophy and Strategies
1. Example in Python:
```python
def compose_matrices(*matrices):
    result = matrices[0]
    for m in matrices[1:]:
        result = np.dot(result, m)
    return result
```
2. Document each step: "First scale, then rotate, then translate..."
3. Draw a diagram of the transformation pipeline.

---

## Next Steps: Category Theory

Once you are comfortable with the concepts in this document, explore [`CATEGORY_LINEAR_ALGEBRA.md`](./CATEGORY_LINEAR_ALGEBRA.md) to understand why these structures exist and how they fit into the broader categorical architecture of this project.
