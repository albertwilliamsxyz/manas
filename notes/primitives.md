# Primitives & Vec3 — articulación

Notas y preguntas sobre `src/Primitives.purs`, `src/Primitives.js`, y la representación de `Vec3` (en su momento dentro de `ForeignUtils`, hoy a separar). Mezcla las preguntas que escribí en `NOTES.md` y la articulación que salió de la conversación.

---

## 1. ArrayBuffer y polimorfismo sobre TypedArrays

**Pregunta**: ¿falta una declaración de `ArrayBuffer`? Solo tenemos getters/setters/operaciones para `Float32Array`, no para `Uint16Array` ni `Uint8Array`. ¿Se podrían generalizar con foreign imports polimórficos?

**Articulación**:

`Primitives.purs` ya tiene `ArrayBufferView`, que es la abstracción que WebGL acepta en `bufferData`. Lo que falta es `ArrayBuffer` *crudo* — el bloque de bytes sin interpretación. En JS, un `Float32Array` no es la memoria, es una *vista* sobre un `ArrayBuffer` que reinterpreta esos bytes como floats. Sobre el mismo buffer pueden coexistir varias vistas.

No lo tenemos porque no lo hemos necesitado: nunca asignamos memoria cruda y la reinterpretamos. Aparecerá el día que carguemos un GLB binario, leamos un blob, o pasemos memoria entre Web Workers. Hoy la ausencia es honesta.

**Sobre la generalización**, tres caminos ordenados por costo:

- **No generalizar todavía.** Solo se usa `Float32Array` en operaciones reales. Generalizar antes del segundo caso es premature crystallization. El segundo `TypedArray` que probablemente aparezca es `Uint16Array` para índices de triángulos al pasar de cubo a mallas más complejas.
- **Type class con functional dependency.**
  ```purescript
  class TypedArray a e | a -> e where
    getAt :: a -> Int -> Effect e
  ```
  El compilador deduce el tipo del elemento desde el del array. Preserva type honesty.
- **Vista única vía `ArrayBufferView`.** Una sola firma `getAt :: ArrayBufferView -> Int -> Effect Number`. Más simple pero la firma miente sobre lo que admite (no aceptaría `Float64Array` con la misma fidelidad).

Decisión actual: camino 1, esperar al segundo caso real.

---

## 2. ¿Es `Float32Array` efectivo para `Vec3`? ¿Qué otras representaciones funcionarían?

**A favor de `Float32Array`**:

- **Cero conversión en los bordes.** WebXR entrega poses, joints y matrices como `Float32Array`. WebGL2 espera `Float32Array` en `bufferData`. Si `Vec3` *es* un `Float32Array`, ingestión y upload son zero-copy. El engine vive en el flujo `XR → procesar → GL`, y los dos extremos son float32.
- **Precisión apropiada al dominio.** La GPU trabaja nativamente en float32. Cualquier precisión extra que se mantenga en CPU se pierde al subir al buffer. Trabajar en float32 desde el origen es honesto.
- **Compactez.** 12 bytes por Vec3 vs 24 bytes en float64. Para colecciones grandes, mejor cache locality.

**En contra**:

- **Costo de allocation por operación.** Cada `addImpl`/`subImpl`/`crossImpl` hace `new Float32Array(3)`. En hand tracking (50 joints/frame, varias ops por joint, 90fps en Quest) son miles de allocations/segundo — presión de GC real.
- **Penalización de optimización en V8.** Para vectores de tamaño fijo, un objeto `{x, y, z}` con `Number` puede ser más rápido en práctica — V8 lo monomorfiza con hidden classes.
- **Round-trip Number ↔ float32 silencioso.** Cada `setAt` trunca float64 a float32 sin avisar.

**Alternativas reales**:

1. **Record `{x :: Number, y :: Number, z :: Number}`** (estilo Three.js). Más rápido en CPU para operaciones puras, full precisión float64, pero copias al subir a GPU.
2. **Float32Array pre-alocado / pool.** Un `Float32Array` grande de tamaño `3*N` donde cada `Vec3` es un `subarray`. Elimina presión de GC pero hace que ownership y vida útil de los objetos sean explícitos.
3. **API mutable estilo gl-matrix.** `add(out, a, b)` en lugar de `Vec3 -> Vec3 -> Vec3`. Notablemente más rápido pero rompe la pureza funcional — el código deja de leerse como matemática.
4. **Structure-of-Arrays para colecciones.** Tres arrays separados (todos los x, todos los y, todos los z) en vez de un array de Vec3s. SIMD-friendly, cache-friendly. Solo tiene sentido para colecciones procesadas juntas.

**Veredicto actual**:

`Float32Array` es la elección correcta para Manas hoy, principalmente por la afinidad con WebXR/WebGL en los bordes. La asignación per-operación es real pero a la escala actual (un cubo, dos manos, cientos de ops por frame) está dentro del presupuesto.

Señales de que llegó el momento de revisitarlo: hitches en frame, sistemas de partículas, mallas con miles de vértices actualizándose cada frame. El primer paso ahí no sería cambiar el tipo subyacente — sería migrar selectivamente el hot path a una API mutable estilo gl-matrix sobre el mismo `Float32Array`.

Principio: **el tipo subyacente correcto es el que minimiza fricción en los bordes**. Float32Array gana en esa dimensión.

---

## 3. `newtype Vec3 = Vec3 Float32Array` — el nombre en dos mundos

**Pregunta**: ¿por qué `Vec3` aparece en el mundo de los tipos y en el mundo de los valores a la vez?

**Articulación**:

`newtype Vec3 = Vec3 Float32Array` define dos cosas con el mismo nombre, en dos *namespaces* disjuntos:

- A la **izquierda del `=`**: `Vec3` es un **type constructor**. Vive en el mundo de los tipos. Aparece en signaturas: `add :: Vec3 -> Vec3 -> Vec3`.
- A la **derecha del `=`**: `Vec3` es un **data constructor** (también *value constructor*). Vive en el mundo de los valores. Es una función `Float32Array -> Vec3`.

PureScript (y Haskell) tienen dos namespaces separados — un identificador puede aparecer en ambos sin conflicto. Por convención los nombres se reusan cuando el mapeo es obvio, especialmente con `newtype` que tiene exactamente un constructor. Podrías escribir `newtype Vec3 = MkVec3 Float32Array` y nada se rompería excepto el largo del código.

---

## 4. Constructores como deconstructores: `scale k (Vec3 v) = Vec3 (scaleImpl k v)`

**Pregunta**: ¿`Vec3` actúa como constructor *y* deconstructor? ¿Por qué `Number` primero?

**Articulación**:

`Vec3` aparece dos veces y juega dos roles:

- En `(Vec3 v)` del lado izquierdo, es un **patrón** (deconstrucción). "El segundo argumento debe encajar con la forma `Vec3 algo`. Cuando encaje, llama al `algo` con el nombre `v`".
- En `Vec3 (scaleImpl k v)` del lado derecho, es **construcción** — toma el `Float32Array` que devuelve `scaleImpl` y lo envuelve.

No son dos funciones separadas. Los **constructores de datos en lenguajes con pattern matching son inherentemente bidireccionales**: la sintaxis para construir y destruir es la misma, y el compilador sabe cuál es cuál por el contexto (lado izquierdo de `=` → patrón; lado derecho → expresión).

**Solo funciona con constructores de datos, no con funciones cualquiera.** No puedes escribir `scale k (add a b) = ...` esperando que `a` y `b` se enlacen. `add` no es invertible decidiblemente — `add a b = vec(5,5,5)` no te dice cuáles fueron `a` y `b`. Los constructores sí: si tienes `Vec3 v`, sabes con certeza que `v` fue el `Float32Array` con el que se construyó. Garantía estructural — los constructores son inyectivos por definición.

**Por qué `Number` primero**: aplicación parcial.
- `scale 0.5 :: Vec3 -> Vec3` = "una función que escala cualquier vector a la mitad". Verbo nominalizado, reusable.
- Si invirtieras los argumentos, `scale v :: Number -> Vec3` = "función que multiplica este vector por cualquier escalar". Útil a veces pero menos idiomático.

Heurística: primero el modificador, después el objeto modificado. Es lo que más probablemente fijás en una pipeline. Misma convención que `map`, `filter`, `fold`.

---

## 5. `negate = sub zero` — point-free y el vector cero

**Pregunta**: ¿el vector cero tiene dirección/ángulo? ¿Cómo funciona el point-free?

**Articulación**:

Currying y aplicación parcial. `sub :: Vec3 -> Vec3 -> Vec3`, `sub zero :: Vec3 -> Vec3` = "función que toma cualquier `v` y devuelve `zero - v`".

⚠️ **Orden importa**: `sub zero v = zero - v = -v`. Si fuera `\v -> sub v zero`, eso sería `v - zero = v` (identidad, no negación). Bug sutil esperando suceder.

**El vector cero**: matemáticamente, `(0, 0, 0)` no tiene dirección definida. Magnitud 0 y ángulo indeterminado (si la longitud es cero, no apunta a ningún lado). Por eso `normalize zero` devuelve `Nothing`.

Geométricamente: un vector se interpreta como flecha desde el origen. `sub a b = a - b` = "el desplazamiento que llevaría `b` hasta `a`". `sub zero v = 0 - v = -v` = "el desplazamiento que llevaría `v` al origen". Si `v` apunta a `(3, 4, 5)`, `-v` apunta a `(-3, -4, -5)`.

---

## 6. `dot` — fold sobre componentes pareados

**Pregunta**: ¿`dot` es una operación de reducción de dimensionalidad?

**Articulación**:

El término preciso es **reducción** o **forma bilineal**. "Reducción de dimensionalidad" sugiere proyectar a un subespacio (3D → 2D); `dot` colapsa dos vectores 3D a un escalar — un punto sin dimensión. Es un *fold*: `sum (zipWith (*) a b)`.

**Geométricamente**: `dot a b = |a| * |b| * cos(θ)`, donde θ es el ángulo entre los vectores.
- 0 cuando son perpendiculares.
- Positivo cuando apuntan en direcciones similares.
- Negativo cuando apuntan en direcciones opuestas.
- `dot v v = |v|²` (mismo vector consigo mismo, cos 0° = 1).

Esa última propiedad es la que reusa `length`.

**Sobre `dotImpl`**: sí, codifica iteración pero **desplegada manualmente** (unrolled). En lugar de un `for` loop, `a[0]*b[0] + a[1]*b[1] + a[2]*b[2]`. Para tamaño fijo y conocido (3), unrolling es:
- Más rápido (sin overhead de loop, mejor pipelining).
- Más legible — la fórmula matemática es visible.
- No requiere generalización (solo funciona para Vec3).

Típico en código de gráficos. Librerías como `gl-matrix` lo hacen en todas sus operaciones de Vec2/Vec3/Vec4.

---

## 7. `length v = sqrt (dot v v)` — Pitágoras

**Articulación**:

Pitágoras en 3D. `dot v v = v₀² + v₁² + v₂²` (suma de cuadrados de componentes). La raíz es la longitud — literalmente `√(x² + y² + z²)`.

¿Por qué reusar `dot` en vez de calcular la suma de cuadrados directo? Porque conecta `length` con el resto del álgebra. Ya no es operación independiente — es caso especial de algo más general (producto punto consigo mismo). Mini-cristalización: el patrón "longitud al cuadrado = producto punto consigo mismo" emerge naturalmente.

---

## 8. `distance a b = length (sub a b)`

**Articulación**:

`sub a b = a - b` apunta desde la punta de `b` hasta la punta de `a` (interpretando vectores como flechas desde el origen). Su longitud es la distancia euclidiana entre los puntos.

Detalle lindo: `distance a b == distance b a`, aunque `sub a b ≠ sub b a`. La diferencia es la *dirección* del desplazamiento, pero la *longitud* es la misma. Simetría que toda métrica debe satisfacer.

---

## 9. `cross` — producto vectorial

**Articulación**:

Único caso aquí donde la salida es un vector, no un escalar. `cross a b` devuelve un vector que es:
- **Perpendicular a ambos** `a` y `b`, orientado por la regla de la mano derecha.
- **De magnitud** `|a| * |b| * sin(θ)` — el área del paralelogramo generado por `a` y `b`.

Si `a` y `b` son paralelos (mismo sentido o opuestos), `cross` es cero (sin 0° = sin 180° = 0). Si son perpendiculares, magnitud máxima.

**Para qué sirve en el engine**:
- **Normales de superficie**: cross de dos aristas de un triángulo es perpendicular a la cara — la dirección "hacia afuera".
- **Bases ortogonales**: dado dos ejes, su cross da el tercero.
- **Orientación**: el signo del cross dice si un giro es horario o antihorario en cierto plano. Útil para winding order, caras visibles.

**Sobre `crossImpl`**: es la fórmula del **determinante 3x3 expandido**. Cada componente del resultado es un determinante 2x2 de los otros dos pares de componentes:

```
componente x: a.y * b.z - a.z * b.y
componente y: a.z * b.x - a.x * b.z
componente z: a.x * b.y - a.y * b.x
```

Memotécnico: el componente `i` *ignora* la componente `i` de ambos vectores y hace un determinante 2D con los otros dos. Los índices avanzan cíclicamente: x→y→z→x.

---

## 10. `normalize` — por qué `Maybe`

**Articulación**:

Devuelve un vector con la misma dirección pero longitud 1. `scale (1.0 / len) v` divide cada componente por la longitud, lo que escala la magnitud a 1.

`Maybe` está ahí porque **el vector cero no tiene dirección que normalizar** — sería `1/0`. La división por cero es la traducción aritmética de esa indeterminación geométrica. `Maybe` codifica esta verdad en el sistema de tipos: la firma obliga al llamante a manejar el caso del cero antes de usar el resultado.

"Parse, don't validate" en acción. La función no falla silenciosamente, no lanza excepción, no devuelve un valor garbage — devuelve `Maybe` y deja que el llamante decida qué hacer cuando no hay dirección.

---

## 11. `midpoint a b = scale 0.5 (add a b)`

**Articulación**:

Promedio aritmético de dos puntos: `(a + b) / 2`. El punto a mitad de camino entre `a` y `b` en línea recta. Útil para subdivisión de mallas, suavizado, centrar segmentos, interpolación lineal a t=0.5.

---

## 12. `toFloat32Array` / `fromFloat32Array` — la asimetría es honesta

**Pregunta**: ¿por qué no las mismas funciones para los otros TypedArrays?

**Articulación**:

`Vec3` está definido **sobre `Float32Array` específicamente**. Un `Vec3` es siempre 3 floats de 32 bits — no hay un `Vec3 Uint16Array` que tenga sentido (los Uint16 no representan coordenadas espaciales con la precisión que AR necesita).

La generalización polimórfica tendría sentido si quisieras tipos como `Index3` o `TriIndices` envolviendo `Uint16Array` para índices de mallas — pero serían tipos *distintos* a `Vec3`, no un `Vec3` polimórfico. La asimetría aquí es honesta sobre la representación.
