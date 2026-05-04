# Texturas — articulación

Notas sobre el sistema de texturas en WebGL2 y cómo conecta con vértices, transparencia y la dirección a futuro de Manas. Escrito durante una sesión donde se confirmó el funcionamiento del Paso 2 (UVs como color debug) y se articularon los conceptos antes de avanzar al Paso 5.

---

## 1. La cadena completa del mapeo de texturas

Mapear una textura es una **cadena de indirecciones**. Vale verla entera antes de mirar cada eslabón:

```
imagen / bytes en CPU
  → texture object (memoria GPU)
  → texture unit slot (TEXTURE0, TEXTURE1, ...)
  → sampler uniform (en el shader, lee del slot)
  → texture(sampler, uv) en el fragment shader
  → un color
```

Cada flecha es una decisión deliberada. WebGL no te deja decir "usá esta textura" directamente — te obliga a pasar por slots. Entender por qué ilumina todo lo demás.

---

## 2. La textura como objeto opaco en el GPU

`createTexture` + `texImage2D` reservan memoria GPU y suben los bytes. Te devuelven un `Texture` — un handle. **El handle no es la imagen; es una referencia** a un bloque de memoria GPU donde viven los píxeles.

Ese objeto también guarda **cómo se debe leer**: filtro (`NEAREST` / `LINEAR`), wrap (`REPEAT` / `CLAMP_TO_EDGE`). Esos parámetros viven con la textura, no con el shader. Esto significa que el comportamiento de sampling es estado del recurso, no del programa que lo usa.

---

## 3. La textura es bytes — punto

`texImage2D` no sabe nada de "imágenes". Toma:

```
internalFormat   cómo el GPU guarda los píxeles (RGBA8, RGB16F, R32F...)
width, height
format           cómo vienen los bytes (RGBA, RGB, RED)
type             qué es cada canal (UNSIGNED_BYTE, FLOAT, UNSIGNED_SHORT)
data             los bytes
```

Una "textura de PNG" es exactamente lo mismo que `new Uint8Array([...])` — el PNG simplemente pasa por el decoder del navegador primero. **Cargar una imagen y generar una textura procedural son el mismo gesto** con distinto productor de bytes. Esto abre tres formas de hacer texturas, en orden de sofisticación.

### (a) Bytes generados en CPU, subidos una vez

Checker, gradiente, ruido pre-calculado, slice de un volumen, mapa de altura desde datos. La textura vive en memoria GPU, se sube una vez, se usa N veces. Es lo que vamos a hacer en el Paso 5.

### (b) Patrón calculado en el fragment shader, sin textura

Escribís la matemática del checker (o lo que sea) directamente en GLSL. Cero memoria GPU, pero se recalcula por cada fragmento. Útil cuando el patrón es barato de computar y resolución-independiente.

### (c) Render-to-texture

Lo más interesante. Podés **dibujar en una textura** en lugar de en la pantalla. Bindeás un framebuffer cuyo color attachment es la textura, dibujás una escena entera, el resultado queda en la textura, después la sampleás como entrada de otro draw. Esto desbloquea:

- Post-procesado (bloom, blur, distorsión)
- Espejos / portales (renderizar la escena desde otra cámara, samplearla en una superficie)
- Simulación en texturas (partículas, fluidos — la "posición" de cada partícula es un texel, lo actualizás con un draw)
- **Pizarras y dibujo en superficies** (lo que abre la dirección de Manas a futuro)

La línea entre "textura" y "buffer de datos" se difumina. Una textura `R32F` es un array bidimensional de floats en GPU. La gente usa texturas para guardar datos arbitrarios cuando los uniform buffers no alcanzan.

---

## 4. El shader no toma la textura — toma un *slot*

Acá está la parte rara que más confunde al principio. Tu fragment shader tiene:

```glsl
uniform sampler2D u_texture;
```

Vos esperarías poder hacer `uniform u_texture = miTextura`. **No se puede.** Un `sampler2D` no acepta un texture object — acepta un **número entero**, el índice de un *texture unit*.

Texture unit = un slot. WebGL2 tiene típicamente 16 o más slots: `TEXTURE0`, `TEXTURE1`, ..., `TEXTURE15`. Son ranuras donde podés "enchufar" texturas.

Para asociar la textura con el shader hay tres pasos en orden:

```js
gl.activeTexture(gl.TEXTURE0);              // (a) selecciono el slot 0 como "el slot activo"
gl.bindTexture(gl.TEXTURE_2D, miTextura);   // (b) enchufo miTextura en el slot activo
gl.uniform1i(u_texture_location, 0);        // (c) le digo al shader: "leé del slot 0"
```

(a) y (b) juntas dicen "la textura X está en el slot 0". (c) le dice al shader "tu sampler debe leer del slot 0".

**Por qué la indirección**: te permite cambiar la textura sin recompilar shaders. Cambiás lo que está en el slot 0 entre dibujos, el shader sigue leyendo "del slot 0". También te permite tener **varias texturas a la vez** (difuso en slot 0, normal map en slot 1) y el mismo programa las lee todas.

Las tres líneas siempre van juntas. Si te falta una, el render se rompe sutilmente — textura no aparece, aparece la anterior, aparece negra.

---

## 5. Los UVs se interpolan, no se eligen

¿Cómo sabe el fragment shader qué píxel de la textura mostrar para un fragmento en pantalla, si vos solo le diste 3 UVs (uno por vértice de un triángulo)?

**El rasterizador los interpola**. Esta es la magia silenciosa de WebGL:

- Pasás un `out vec2 v_uv` del vertex shader.
- El vertex shader corre **una vez por vértice** (3 veces por triángulo).
- Entre el vertex shader y el fragment shader, el GPU **rasteriza** el triángulo — calcula qué fragmentos cubre y, para cada uno, **interpola las salidas del vertex shader** usando coordenadas baricéntricas (las mismas de `rayTriangleIntersect`).
- El fragment shader recibe un `in vec2 v_uv` que es la **interpolación lineal** de los tres UVs del triángulo en ese punto.

Por eso el Paso 2 mostró un degradé suave del rojo al verde (los componentes x e y del UV mostrados como color). El gradiente **es** la interpolación.

Esta interpolación no es exclusiva de UVs. **Cualquier `out` del vertex shader se interpola** — color, normal, posición mundial, tiempo, lo que sea (ver sección 8).

---

## 6. `texture(sampler, uv)` hace el lookup

Adentro del fragment shader:

```glsl
outColor = texture(u_texture, v_uv);
```

Esto significa: tomá la textura conectada a `u_texture` (vía el slot), buscá el píxel correspondiente al UV interpolado, devolvelo como color.

El UV `(0, 0)` apunta a la esquina inferior izquierda de la textura. `(1, 1)` a la superior derecha. `(0.5, 0.5)` al centro. Es un sistema de coordenadas **normalizado** — independiente del tamaño real de la imagen.

### Filtro: qué hacer entre dos texels

Tu UV `(0.37, 0.62)` casi nunca cae exactamente sobre un texel. ¿Qué color devolvés?

- `NEAREST`: el texel más cercano. Píxel duro, estilo retro/pixelart.
- `LINEAR`: promedio ponderado de los 4 texels vecinos. Píxel suave, blureado al ampliar.

Para un checker 2×2 querés `NEAREST` — sino los cuadrantes se desdibujan en los bordes.

### Wrap: qué hacer fuera de [0, 1]

Si UV es `(1.3, 0.8)`, ¿qué hace?

- `REPEAT`: repite la textura en azulejo. UV `(1.3, 0.8)` se trata como `(0.3, 0.8)`.
- `CLAMP_TO_EDGE`: pega el borde. UV `(1.3, 0.8)` se trata como `(1.0, 0.8)`.

Para un checker que querés ver una vez por cara, los UVs se diseñan en `[0, 1]` exactamente y cualquier wrap funciona. `REPEAT` da flexibilidad si después decidís escalar.

---

## 7. Cómo encaja todo el flujo

```
[1] Init (una vez):
    - createTexture → handle
    - bind + texImage2D + texParameteri → la textura tiene datos y reglas
    - getUniformLocation("u_texture") → ubicación del sampler

[2] Por frame, antes de dibujar:
    - activeTexture(TEXTURE0)         "enfocá el slot 0"
    - bindTexture(TEXTURE_2D, tex)    "metelo ahí"
    - uniform1i(samplerLoc, 0)        "decile al shader: leé del slot 0"

[3] Por cada fragmento (automático):
    - rasterizador interpola v_uv
    - fragment shader: texture(u_texture, v_uv)
    - el GPU sigue la cadena: u_texture → slot 0 → la textura → busca el texel → color
```

---

## 8. Más allá de los UVs — el canal silencioso de los vértices

Hoy estamos pasando por vértice **dos cosas**: posición (vec3) y UV (vec2). Pero podés pasar cualquier cosa. **El UV no es especial — es una convención.** Cualquier `out` del vertex shader se interpola y llega al fragment shader.

Atributos comunes por vértice, de menos a más interesante:

### Color por vértice

Cada vértice tiene `vec3 color`. El rasterizador interpola → fragmentos del centro de un triángulo tienen el promedio de los tres vértices. Útil para terrenos (gradientes grass/rock/snow), highlights, gradientes orgánicos.

### Normales — desbloquea iluminación

Cada vértice tiene `vec3 normal` — la dirección perpendicular a la superficie en ese punto. Esto desbloquea **shading**:

```glsl
float intensity = max(dot(normalize(v_normal), lightDir), 0.0);
outColor = baseColor * intensity;
```

`dot(normal, lightDir)` te dice cuán alineada está la superficie con la luz. Cara mirando a la luz → 1.0 (brillante). Cara perpendicular → 0.0 (sombra). El rasterizador interpola las normales de los vértices, así que entre dos vértices con normales distintas obtenés un degradé suave de iluminación. Esto es **shading Phong/Gouraud** — la base de todo render con luz desde los 70s.

**Para Manas concretamente**: sin iluminación los cubos se ven planos (un cubo blanco con luz uniforme parece un cuadrado blanco). Con normales y un solo `dot(normal, lightDir)`, los cubos cobran volumen instantáneamente. Es probablemente el próximo gran salto visual después de texturas.

### Tangentes

Para *normal mapping*: una textura que codifica perturbaciones de la normal. La superficie geométrica es plana, pero la luz se calcula como si tuviera detalle micro. Una textura barata simula geometría cara.

### Pesos de huesos

Para animación esquelética: cada vértice tiene `vec4 weights, vec4 boneIndices`. El vertex shader mezcla las transformaciones de los huesos según los pesos. Una mano de 25 articulaciones moviendo una malla pesada es esto.

### Datos arbitrarios

Cualquier escalar, vector, color que sea **función del vértice** y deba interpolarse suavemente. Temperatura. Humedad. Tiempo desde que se tocó. Distancia al borde más cercano.

### La gran idea

Tus vértices no son solo posiciones, son **discretizaciones de funciones continuas sobre la superficie**. Tres números (x, y, z) son la función "posición". Dos números (u, v) son la función "coordenada de textura". Tres más (nx, ny, nz) son la función "normal". El rasterizador es un interpolador genérico que toma esas funciones discretas y las hace continuas en pantalla.

---

## 9. Transparencia — el último paso del pipeline

Transparencia es **una operación de combinación entre el fragmento que querés escribir y el que ya está en el framebuffer**.

### El operador "over"

La fórmula clásica:

```
final.rgb = src.alpha * src.rgb + (1 - src.alpha) * dest.rgb
```

Donde `src` es lo que estás escribiendo (output del fragment shader) y `dest` es lo que ya estaba. Si `src.alpha = 0` no afecta nada. Si `src.alpha = 1` reemplaza todo. Entre medio, mezcla.

Esto se llama "**over compositing**" y es la base de todo render 2D y 3D translúcido. Photoshop hace esto. CSS hace esto. WebGL hace esto.

### Activarlo

```js
gl.enable(gl.BLEND);
gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
```

Tu fragment shader devuelve `vec4(rgb, alpha)` con `alpha < 1` y se mezcla automáticamente.

### Pero el orden importa, profundamente

**El depth buffer no funciona con transparencia.** Si dibujás un cubo opaco rojo, escribe color y profundidad. Si después dibujás un vidrio azul translúcido enfrente, mezcla bien. Pero si los dibujás en orden inverso — vidrio primero, cubo después — el cubo se descarta porque "está más lejos que el vidrio" (depth test), aunque el vidrio sea transparente.

La regla operativa, vieja y dolorosa: **dibujá los opacos primero (cualquier orden, depth test los resuelve), después los translúcidos en orden de atrás para adelante** según la cámara.

Eso fuerza una arquitectura: separás tu escena en `opaqueObjects` y `transparentObjects`. Los segundos los ordenás por distancia a cámara cada frame. Los dibujás al final.

Para dos objetos translúcidos que se interpenetran, no hay orden correcto — los píxeles del fondo deben mezclarse con varias capas en simultáneo. Hay técnicas avanzadas (order-independent transparency, depth peeling) pero son caras.

### Variantes que vale la pena tener en mente

**Alpha cutoff** (todo o nada): hojas, vallas. La textura tiene alpha 0 o 1 binario. En el fragment shader: `if (alpha < 0.5) discard;`. `discard` mata el fragmento — no escribe color ni profundidad. **No necesita blend, no necesita ordenar.** Más barato y simple, suficiente para masks duros.

**Premultiplied alpha**: en lugar de `(r, g, b, a)`, guardás `(r*a, g*a, b*a, a)`. La fórmula del over se simplifica a `final = src + (1-src.a) * dest`. Compositing en cadena se vuelve asociativo. Es la convención que usan Pixar y prácticamente todas las pipelines modernas. Importa cuando importes imágenes con alpha — saber si vienen premultiplicadas o straight.

**Additive blending**: `gl.blendFunc(gl.ONE, gl.ONE)`. `final = src + dest`. Suma colores. Ideal para luces, fuego, partículas brillantes. No representa "vidrio enfrente" — representa "luz emitiendo encima". Puede saturar a blanco, lo que es perfecto para un destello.

---

## 10. Roadmap de texturas en Manas

- **Paso 1** ✓ Cubo como triángulos rellenos (no wireframe).
- **Paso 2** ✓ UVs como color debug. Confirma que los UVs se interpolan bien y llegan al fragment shader.
- **Paso 3** ✓ FFI raw para texturas (createTexture, bindTexture, texImage2D, texParameteri, generateMipmap, activeTexture).
- **Paso 4** ✓ `makeTexture` idiomático en WebGL2.purs.
- **Paso 5** Aplicar textura procedural 2×2 (checker rojo/blanco) al cubo. Tres cambios:
  - Fragment shader: `texture(u_texture, v_uv)` cuando `u_useUV`.
  - Init: query `textureLocation`, `uniform1i textureLocation 0`, construir `checkerPixels` (Uint8Array de 16 bytes), llamar `WebGL2.makeTexture` con 2×2 / Nearest / Repeat.
  - Render loop: `activeTexture(TEXTURE0)` + `bindTexture(TEXTURE_2D, checkerTex)` antes de dibujar.
- **Paso 6** Textura desde imagen importada (PNG/JPG cargado vía fetch).
- **Paso 7** Patrón procedural calculado en el shader (sin textura).
- **Paso 8** `TextureId` + registry para múltiples texturas.

---

## 11. La dirección a futuro (resumen)

Articulada en esta sesión y guardada como memoria de proyecto (`project_lambda_instrument.md`):

**Manas como instrumento gestual de cálculo lambda**. Una pizarra virtual donde escribís a mano. A medida que se reconocen símbolos por encima de un umbral, el ink se reemplaza por glifos limpios (texture overlay). Los símbolos forman un AST espacialmente manipulable — pinch sobre cualquier sub-expresión, gestos de β-reducción.

**Ideas clave**:
- Lenguaje mínimo y completo (cálculo lambda: Var, Abs, App). Alfabeto chiquito.
- Recognition **guiada por gramática**, no OCR libre. La gramática poda el espacio de candidatos en cada posición — más cerca de autocomplete que de OCR.
- **Treesitter como modelo mental**: incremental, error-tolerante, estructural. Selección espacial = cursor en el árbol.
- β-reducción como gesto físico (clap, doble pinch sobre una aplicación), con animación de sustitución.

**Primer experimento sugerido** (sin pizarra ni OCR todavía):
1. `Math.Lambda.Syntax` y `Math.Lambda.Reduce` en PureScript puro — AST, β-reducción, sustitución, alpha-equivalencia. Testeable independiente.
2. Renderizar el AST como geometría 3D.
3. Manipulación con dos manos + gesto de β-reducción.
4. Si esa mitad (semántica espacial) se siente bien, **ahí** invertir en pizarra/OCR.

**Por qué importa para las decisiones intermedias**: las texturas necesitan soportar updates parciales rápidos (la pizarra los va a necesitar). Los scene objects van a necesitar estructura recursiva (nodos del AST). El vocabulario gestual debe dejar lugar a "seleccionar sub-árbol" y "colapsar/reducir".

---

## 12. Pendientes ortogonales

- Migrar `Geometry.vertices` de `Array Number` a `Array Vec3` (Phase 2 leftover — resuelve el `fromMaybe` paranoico actual).
- Phase 2.5 — Partir `uploadGeometry` en paso de estructura + paso de datos.
