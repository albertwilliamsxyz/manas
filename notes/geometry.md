# Geometry — articulación

Notas sobre `src/Math/Geometry.purs` y `src/Math/Geometry.js`. Hoy el módulo tiene una sola función, `rayTriangleIntersect`, pero es densa — el núcleo de "tocar cosas en 3D con un rayo".

---

## 1. Qué resuelve y por qué importa

`rayTriangleIntersect` toma un rayo (origen + dirección) y un triángulo (tres vértices) y devuelve `Maybe Number`:
- `Nothing` → el rayo no toca el triángulo.
- `Just t` → el rayo toca a distancia `t` a lo largo de su dirección. El punto de impacto es `origin + t * direction`.

Es la pieza fundacional para **selección/interacción en 3D**. Si querés saber si un dedo está apuntando a un cubo, lanzás un rayo desde la punta del dedo en la dirección del dedo, intersectás contra cada triángulo del cubo, y el hit con `t` mínimo positivo es el punto donde el rayo entra.

Es la primera función de Manas que cruza de **geometría continua** (rayos, planos) a **información discreta de contacto** (sí/no, dónde). El resto del engine maneja transformaciones; esta función responde preguntas.

---

## 2. Por qué devuelve `t` y no un punto

Decisión sutil. La función calcula internamente `t`; podría devolver `Maybe Vec3` reconstruyendo el punto. Devuelve `Number` porque:

- **Ordenar hits por cercanía**: si tenés varios triángulos en el camino, comparás los `t` directamente. Con un `Vec3` tendrías que recomputar distancias.
- **Tests sin reconstrucción**: "¿el rayo toca algo dentro de mi alcance?" es `t < maxRange`. Solo el escalar.
- **Reconstruir el punto es trivial**: `add origin (scale t direction)` — una línea cuando lo necesitás.

Principio: devolver lo más primitivo que captura la información. Lo derivado es responsabilidad del llamante.

---

## 3. La idea matemática: coordenadas baricéntricas

Cualquier punto **dentro** de un triángulo se puede escribir como:

```
P = v0 + u * (v1 - v0) + v * (v2 - v0)
  = v0 + u * e1 + v * e2
```

donde `e1` y `e2` son las dos aristas que salen de `v0`. Los números `(u, v)` son **coordenadas baricéntricas** — direcciones a lo largo de las aristas.

El punto está dentro del triángulo si y solo si:
- `u ≥ 0` (no atrás de la arista 1)
- `v ≥ 0` (no atrás de la arista 2)
- `u + v ≤ 1` (no más allá de la hipotenusa)

Esa tripleta de desigualdades **es** la membresía en el triángulo. Cualquier punto del plano del triángulo se puede escribir con `(u, v)`; solo los que cumplen las tres condiciones están dentro.

---

## 4. La intersección como sistema de ecuaciones

Punto del rayo: `P = origin + t * direction`.

Igualando con el punto baricéntrico:

```
origin + t * direction = v0 + u * e1 + v * e2
```

Reorganizando:

```
-t * direction + u * e1 + v * e2 = origin - v0
```

Sistema lineal **3×3 en las incógnitas (t, u, v)**. Tres ecuaciones (una por componente x, y, z), tres incógnitas. Si tiene solución única, es la intersección.

**Möller-Trumbore (1997)** resuelve este sistema con la regla de Cramer pero ordena las operaciones de forma que se puede **abortar temprano** cuando una incógnita ya viola la condición de membresía. Esa es la genialidad: no calcula t, u, v y después chequea — entrelaza cálculo y rechazo.

---

## 5. El algoritmo paso a paso

```js
const e1 = v1 - v0;  // arista 1 desde v0
const e2 = v2 - v0;  // arista 2 desde v0
```

Las dos aristas que parametrizan el triángulo desde `v0`.

```js
const p = cross(direction, e2);
const det = dot(e1, p);
if (|det| < EPSILON) return null;
```

`p = direction × e2` es perpendicular al plano formado por `direction` y `e2`. `e1 · p` es el **determinante** del sistema lineal. Geométricamente: el volumen del paralelepípedo formado por `direction`, `e1`, `e2`.

Si ese volumen es cero (o casi), las tres direcciones son coplanares — el rayo es **paralelo al plano del triángulo** y no hay intersección única. La rama `|det| < EPSILON` rechaza este caso.

```js
const t_vec = origin - v0;
const u = dot(t_vec, p) * invDet;
if (u < 0 || u > 1) return null;
```

`t_vec = origin - v0` es el desplazamiento desde `v0` hasta el origen del rayo. `u` es el primer baricéntrico, por Cramer. Si viola `0 ≤ u ≤ 1`, bail antes de computar `v` o `t`.

```js
const q = cross(t_vec, e1);
const v = dot(direction, q) * invDet;
if (v < 0 || u + v > 1) return null;
```

`q = t_vec × e1` es el otro vector auxiliar. `v` es el segundo baricéntrico. Las dos condiciones (`v ≥ 0` y `u + v ≤ 1`) son las membresías que faltaban.

```js
const t = dot(e2, q) * invDet;
if (t > EPSILON) return t;
return null;
```

Finalmente `t`. El chequeo `t > EPSILON` exige que el hit esté **delante del origen**, no detrás. (`t < 0` significa rayo apuntando al revés. `t = 0` significa origen sobre el triángulo — ambiguo, se rechaza.)

---

## 6. El rol doble de `EPSILON`

Aparece dos veces con propósitos distintos:

1. **`|det| < EPSILON`** — guarda contra rayos casi-paralelos al plano. Sin esto dividirías por casi-cero y todo el cálculo explotaría numéricamente.

2. **`t > EPSILON`** — guarda contra hits "en el origen". En ray tracing, un rayo rebota en una superficie y vuelve a salir desde ella; sin EPSILON se intersectaría inmediatamente consigo mismo. Acá no estás haciendo ray tracing pero el patrón se mantiene — captura "el hit es real, no degenerado".

Ambos son `1e-6`. Razonable para escalas típicas de AR (centímetros a metros). A escala sub-milimétrica habría que reconsiderar.

---

## 7. Decisiones de la capa PureScript

**Ray como record anónimo** `{ origin :: Vec3, direction :: Vec3 }`. Coherente con la convención: named types para abstracciones con operaciones; records anónimos para forma de paso. `Ray` no tiene operaciones propias todavía. Cuando las tenga (`extend`, `transform`, `at`), se nominaliza.

**Triángulo como tres `Vec3` separados**, no como `{ v0, v1, v2 }` ni `Triangle`. Refleja la realidad subyacente: en una malla, los triángulos son tres índices en un buffer de vértices, no structs. La firma es honesta sobre lo que la función necesita: tres puntos.

**`Nullable` al borde FFI, `Maybe` al borde idiomático**, con `toMaybe` puenteando. Patrón estándar de la separación Raw/idiomatic.

**`Maybe Number` no `Maybe { t, u, v }`**. Las baricéntricas se computan y descartan. Si las necesitaras (interpolar atributos de vértice — colores, normales, UVs — al punto de impacto), la firma cambiaría. Hoy no las necesitás → no las devuelve.

---

## 8. Lo que no está y cuándo importará

- **Back-face culling**: la función intersecta desde cualquier lado. Para cullear caras traseras (optimización en mallas cerradas): rechazar `det < EPSILON` (negativo, no solo cercano a cero). Útil cuando las mallas crezcan.

- **`t_max`**: hoy acepta cualquier `t > 0`. "Solo hits a menos de 1 metro" requiere un parámetro adicional. Trivial de agregar.

- **Una sola comparación a la vez**: para una malla, el llamante itera y se queda con el `t` mínimo. Cuando las mallas crezcan, entran BVH/octree — capa por encima de esta función, no parte.

- **Coordenadas baricéntricas u, v devueltas**: si interpolás atributos de vértice al punto de impacto (textura, color suavizado), necesitás `u` y `v`. Cambio futuro razonable: `Maybe { t, u, v }` o un tipo nominal `Hit`.
