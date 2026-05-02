# Mat4 — articulación

Notas sobre `src/Math/Mat4.purs` y `src/Math/Mat4.js`. Articula cada función del módulo y discute cuándo introducir cuaterniones.

---

## 1. ¿Cuaterniones, sí o no?

**Hoy no. Mat4 puro es honesto para el estado actual de Manas. Acá el tradeoff completo.**

### Qué carga cada uno

- **Mat4** carga una transformación afín completa: rotación + traslación + escala (uniforme o no) + shear. 16 floats. Es el lenguaje nativo de la GPU — el vertex shader recibe un `mat4`.
- **Quaternion** carga *solo* orientación. 4 floats. No habla de traslación ni escala — son responsabilidades distintas.

### Costos de hacer rotación con Mat4 puro

- **Drift al componer.** Multiplicar matrices muchas veces acumula error de punto flotante. La matriz va dejando de ser ortonormal — los ejes se "estiran" y "se desalinean" lentamente. Solución: re-ortonormalizar (Gram-Schmidt sobre columnas), pero es caro y se aplica como parche.
- **No hay interpolación limpia.** Hacer lerp sobre las 16 entradas de dos rotaciones no produce una rotación intermedia válida — produce algo que ni siquiera es una rotación. Para interpolar entre orientaciones hace falta **slerp**, definido sobre cuaterniones, no sobre matrices.
- **4× el storage para rotación.** 16 floats vs 4. Irrelevante para una matriz, importante si guardás orientación de muchos objetos.

### Costos de meter cuaterniones ahora

- **Trig de medio ángulo en el path crítico.** La rotación viene de un cross product entre vectores de la mano — eso da `axis`, `sin(θ)` y `cos(θ)` directamente. Construir un cuaternión `(axis * sin(θ/2), cos(θ/2))` requiere identidades de medio ángulo o `acos`. Después igual hay que convertir el cuaternión a Mat4 para subirlo a GPU. Ida y vuelta.
- **Más superficie conceptual.** Otro tipo, otro módulo, otro juego de operaciones.

### Por qué Mat4 puro alcanza hoy

Pipeline actual de two-hand grab:
- Cada frame la transformación se computa **fresca** desde las posiciones actuales de las manos. **No hay acumulación entre frames** → drift no aparece.
- **No se interpola** orientaciones — el input es directo, sin slerp.
- La rotación sale del cross product, que ya da axis + sin + cos. Mat4 los toma tal cual (ver `axisAngleRotation` abajo).

Drift cero porque el estado entre frames es solo "qué objeto está siendo agarrado", no "cuál es su orientación acumulada". Cada frame es un nuevo cómputo.

### Cuándo van a ser necesarios

Tres señales claras:

1. **Almacenar orientación entre frames** y acumularla. Por ejemplo: el objeto recuerda su rotación actual y querés girarlo más con cada gesto. Ahí el drift importa.
2. **Interpolar** — animaciones, smoothing del input de mano, transiciones suaves entre poses. Slerp es obligatorio.
3. **Leer la orientación de los joints** de WebXR (no solo posición). `XRRigidTransform.orientation` viene como cuaternión (`DOMPointReadOnly` con `x/y/z/w`). El día que uses orientación de joints, te aparece un cuaternión en el borde.

### Modelo híbrido estándar (Three.js, Unity, Unreal, Godot)

Estado interno de cada objeto: `{ position: Vec3, rotation: Quat, scale: Vec3 }`. Cada parte se compone por separado. Al subir a GPU, se construye Mat4 desde las tres. Vale la ceremonia cuando hay muchos objetos con transformación persistente.

**Para Manas**: el día que llegue una de las tres señales, introducir `Math.Quat`. Hasta entonces Mat4 carga todo y no se pierde nada.

---

## 2. `identity`

Elemento neutro de `multiply`. La transformación que no hace nada: `multiply identity m = m = multiply m identity`. Útil como punto de partida cuando vas acumulando — empezás en identidad y vas componiendo.

```
1 0 0 0
0 1 0 0
0 0 1 0
0 0 0 1
```

El `1` en la esquina inferior derecha (la coordenada homogénea) es lo que hace que translation funcione cuando aplicás la matriz a un punto.

---

## 3. `scale :: Number -> Mat4`

Construye una matriz de escala **uniforme**. Diagonal `[k, k, k, 1]`. Multiplica cada componente espacial por `k`, deja la coordenada homogénea en `1`.

```
k 0 0 0
0 k 0 0
0 0 k 0
0 0 0 1
```

⚠️ Detalle clave: el `1` final, no `k`. Si fuera `k`, al aplicarla a un punto con `w=1` la división por `w` al final cancelaría la escala. La matriz mantiene la coordenada homogénea intacta.

---

## 4. `multiply :: Mat4 -> Mat4 -> Mat4` — composición

**Orden importa**: `multiply A B` aplicada a un punto `v` produce `A * (B * v)` — **B sucede primero, después A**. Las transformaciones se leen de derecha a izquierda.

Ejemplo: `multiply (translation t) (scale 2.0)` aplicado a `v`:
1. Escala `v` por 2.
2. Traslada por `t`.

Si invertís el orden, `multiply (scale 2.0) (translation t)`:
1. Traslada por `t`.
2. Escala por 2 (incluyendo la traslación → quedás en `2t`).

Resultados muy distintos. Esta convención (right-to-left) es la matemática estándar.

**Sobre el JS**: usa **column-major** layout — `M[col, row]` está en `M[col * 4 + row]`. Es la convención que WebGL espera. El loop interno computa `out[col=j, row=i] = Σ a[col=k, row=i] * b[col=j, row=k]`, que es exactamente el producto matricial.

---

## 5. `translation :: Vec3 -> Mat4`

Matriz de traslación pura — rotación identidad, escala 1, solo desplazamiento.

```
1 0 0 v.x
0 1 0 v.y
0 0 1 v.z
0 0 0 1
```

Aplicada a un punto homogéneo `(x, y, z, 1)`, suma `v` a la posición. Aplicada a un vector dirección `(x, y, z, 0)` no hace nada — la traslación se "activa" solo cuando `w = 1`. Por eso transformar puntos vs vectores es una operación distinta (aunque acá solo está `transformPoint`).

---

## 6. `translationOf :: Mat4 -> Vec3`

Extrae la columna de traslación. En column-major: `m[12], m[13], m[14]` — la cuarta columna, primeras tres filas.

Útil porque después de componer una transformación completa (rotación + escala + traslación), la posición sigue viviendo intacta en esa última columna. Lectura honesta sin importar lo que tenga el resto de la matriz.

Pseudo-inversa de `translation`: `translationOf (translation v) = v`. No es inversa estricta — `translationOf` aplicado a una matriz arbitraria devuelve un Vec3 cualquiera, mientras que `translation` solo construye matrices muy específicas.

---

## 7. `scaleOf :: Mat4 -> Number`

Extrae la escala uniforme calculando la longitud de la **primera columna**: `sqrt(m[0]² + m[1]² + m[2]²)`.

¿Por qué? La primera columna es "a dónde va el eje X". Para una matriz puramente rotacional, esa columna es unitaria (longitud 1). Cuando aplicás escala uniforme `k`, esa columna se vuelve un vector de longitud `k`. Entonces su norma devuelve `k`.

**Pista en la firma**: devuelve `Number`, no `Vec3`. Eso codifica una *constraint* del engine — **solo soporta escala uniforme**. Si la matriz tuviera escala no-uniforme `(kx, ky, kz)`, devolvería solo `kx`, descartando los otros dos. Si tuviera shear, devolvería algo completamente mal.

Esa firma es honesta con el pipeline actual: en two-hand grab, la escala viene de un solo escalar (la distancia entre las manos), entonces es uniforme por construcción. El día que quieras estirar un objeto en un solo eje, esta función deja de servir y la firma tendría que cambiar a `Vec3` o `{ x, y, z }`.

---

## 8. `axisAngleRotation :: Vec3 -> Number -> Number -> Mat4` — Rodrigues

Construye una matriz de rotación con la **fórmula de Rodrigues**. Toma:
- `axis :: Vec3` — eje de rotación, **unitario** (la fórmula asume `|axis| = 1`).
- `cosAngle :: Number`.
- `sinAngle :: Number`.

**¿Por qué cos y sin separados, en vez del ángulo?** Porque el pipeline ya los tiene computados directo:

```
axis = cross(v_old, v_new)
sin(θ) = |axis| / (|v_old| * |v_new|)
cos(θ) = dot(v_old, v_new) / (|v_old| * |v_new|)
```

Si `axisAngleRotation` aceptara el ángulo, habría que hacer `acos(cos)` para producirlo y luego internamente la implementación volvería a calcular `sin/cos`. Round-trip innecesario. Y peor: `acos` es numéricamente inestable cerca de 0 y π — pierde precisión justo en los casos límite.

Mini-aplicación de "parse, don't validate" en sentido inverso: tenés la representación más directa (cos/sin), pasala tal cual.

**Fórmula** (`t = 1 - c`):

```
[ t·x·x + c    t·x·y + s·z   t·x·z - s·y   0 ]
[ t·x·y - s·z  t·y·y + c     t·y·z + s·x   0 ]
[ t·x·z + s·y  t·y·z - s·x   t·z·z + c     0 ]
[ 0            0             0             1 ]
```

Descomposición clásica de una rotación 3D en eje + ángulo. Vale la pena verla deducida una vez (proyecto el vector sobre el eje, lo roto en el plano perpendicular, sumo) — no urgente, pero ilumina por qué los términos tienen esa forma.

---

## 9. `transformPoint :: Mat4 -> Vec3 -> Vec3`

Aplica la matriz a un **punto**. Trata el Vec3 como `(x, y, z, 1)` homogéneo, multiplica por el 4×4, descarta `w`. El `1` en la cuarta coordenada es lo que activa la traslación.

```js
m[0] * x + m[4] * y + m[8] * z + m[12]
```

Los primeros tres términos son rotación/escala aplicada a `(x, y, z)`. El último, `m[12]`, es la traslación (multiplicada por el `1` implícito).

**Distinción no presente todavía**: para transformar **direcciones** (vectores, normales), haría falta un `transformVector` que trate el Vec3 como `(x, y, z, 0)` — la traslación se cancela. Y para transformar **normales** correctamente bajo escala no-uniforme, habría que usar la traspuesta de la inversa de la submatriz 3×3. Por ahora no es necesario.

---

## 10. `toFloat32Array` / `fromFloat32Array`

Mismo patrón que en Vec3. La asimetría con otros TypedArrays es honesta — Mat4 vive sobre Float32Array por las mismas razones que Vec3 (zero-copy con WebGL/WebXR).
