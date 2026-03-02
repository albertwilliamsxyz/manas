---

Arquitectura de software
Cual es la mejor manera de abordarla para el desarrollo de mi aplicacion, estoy usando teoria de categorias y tipos para declarar un sistema de tipos correspondiendo a los arquetipos de mi dominio, y sus relaciones. Donde el programa tiene un solo objeto, llamado Universo, que es lo unico que se actualiza. Mi principio es que mi programa no lo voy "creando", lo voy descubriendo mas bien. Descubro un proceso o una representacion computable que al ejecutarlo resulta en la experiencia que busco. En mi caso, solo es una forma, de las infinitas formas que hay.
Yendo en el orden en el que he ido desarrollaba la aplicación primero comence con una implementación funcional de una aplicación de realidad virtual en la que puede dibujar en el espacio, puedes moverte a través de la pizarra virtual y puedes ver diferentes preyecciones de tus dibujos en tres dimensiones puedes cargarmos modelos de tres dimensiones y tiene tracking de manos y reconocimiento de gestos para poder usar las manos como interfaz para poder escribir en la pizarra virtual
Entonces, Empezé a escribir una versión 2 del proyecto, una vez ya todo estaba funcionando. Esta versión 2, lo estoy describiendo, esta vez con TypeScript y usando librerías de programación funcional. Para poder trabajar con teoría de categorías dentro de mi programa y tipado. Previamente está usando JavaScript Plano. De momento tengo setup con TypeScript que corre el punto de entrada del modulo para un index.html y está efectivamente funcionando. Solo tiene un console.log pero poco más.
En base a todo lo que te he comentado y en función de los features que tiene mi aplicación Pensaba crear primero una definición de todos los tipos que voy a soportar dentro de mi programa Pensando en las mejores primitivas para poder utilizar tipos de datos algebraicos y componer dichos tipos de datos algebraicos para lograr aplicaciones de alto nivel
los tipos de los que he pensado ahora y sus relaciones son:
Número 1 el universo el cual contiene todo el estado de la aplicación
Número 2 dentro del universo tengo una lista de entidades que es una lista de cadenas de texto cada cadena de texto representa un identificador que se utiliza para orquestar las diferentes partes del proceso de ejecución de los diferentes componentes que integran mi aplicación como por ejemplo la capa lógica, la capa gráfica, feedback, etc.  
número 3 el estado de la capa nuclear, el cual contiene todas las políticas de alto nivel y los objetos para las cuales aplican, así como también sus relaciones. Este estado de la capa nuclear contiene un mapa de todas las entidades, donde la llave es el id de entidad de la lista de entidades del universo, junto con los detalles de alto nivel como el identificador del modelo que contiene la declaración de los vértices y la geometría. Tambien los detalles específicos de cada entidad, como por ejemplo, su posición, la rotación, la traslación y el escalado. Es importante resaltar de que en esta declaración de tipo estamos dándole vida a la entidad, a la que estamos haciendo referencia en la lista de entidades del universo. También contendría el estado actual del sistema de gestos, el cual seria modelado como una máquina de estados finitos. Para esto también tendría que almacenar un timestamp referenciando al momento en el que se inicio la transición del estado para poder hacer validaciones y poder hacer cambios de estado, pasado una ventana de tiempo. 
número 4 el estado de la capa gráfica que contiene Un mapa donde la llave es el identificador de la entidad en el universo. Y todos los detalles de implementación necesarios para graficar mis entidades utilizando WebGL2, que es la tecnología con la que implemento el renderizado. 
número 5, potencialmente la información del sistema de gestos en caso de que extraiga la información del sistema de gestos de la capa nuclear y la coloque en su propia capa, dependiendo de tu recomendacion
número 6 el Universo contiene un campo llamado modelos que representa un mapa de nombres de modelos (o identificadores) a la información de los vértices o puntos y la geometría, la capa logica se referiria a los modelos en el campo que representa a una entidad en la escena (para que este en la escena tiene que apuntar a una referencia aca)
Luego, cada tic de la aplicación sería manejado como una función que toma el estado actual de la aplicación y genera un estado actualizado de la aplicación sin mutar el estado original.
Esta función sería una composición de funciones que procesa cada una de las capas de la aplicación comenzando por la capa nuclear, luego con la capa gráfica renderizando los objetos en la escena, luego la capa que se encarga de procesar el input en este caso las manos a través de web xr, y finalmente la capa que se encarga de mostrar en la pantalla el objeto renderizado, el cual dependiendo del cliente implementa una estrategia u otra por ejemplo en el caso de el navegador mostrarlo utilizando webgl2 para realizar el contenido de el buffer gráfico en el canvas en el cual está desplegado la aplicación o el caso número 2 con webxr tomando la posición relativa de cada uno de los ojos y computando las imágenes individuales para cada uno de los ojos usando el sistema que te provee la API de webxr

---

Si también estaba pensando con respecto al overhead de performance de tener todo el estado en un solo objeto. Entonces si considero cada capa y sus estados separados. Pero en variables individuales en ese contexto. En caso de hacer con esa propuesta reducería en qué proporción el overhead?
luego para implementar conexiones en línea pensaba simplemente sincronizar entre las maquinas el estado de la capa lógica el cual contiene todo lo que ocupó para poder reproducir el programa en el resto de computadoras luego de hacer un setup inicial que como su nombre dice inicializa la aplicación en base a el estado que viene desde la fuente, el cual es el estado de la capa lógica y los modelos, el cual es suficiente para reconstruir el estado del programa

  "dependencies": {
    "fp-ts": "^2.16.11",
    "lodash": "^4.17.23",
    "monocle-ts": "^2.3.13",
    "uuid": "^13.0.0"
  }

Estoy usando las librerias arriba, explicame cada una a detalle tambien, salvo uuid, vale la pena usar uuids como identificadores de entidades?
¿Cuál crees que sea el mejor algoritmo de sincronización del estado del universo entre diferentes computadoras para mi caso particular? En mi caso que quiero hacer una experiencia compartida entre usuarios.
Finalmente, refina el modelo y efectivamente separa la capa de gestos y la capa de modelos para tener esos elementos individualmente.
Como nota no es necesario copiar constantemente los modelos porque los modelos solo serían cargados una vez en la app y actualizados a través de eventos. 

---

La rotación, traslación y el escalado, asi como el resto de transformaciones se aplican desde la capa gráfica y la capa de la experiencia de realidad virtual para cada vertice de los modelos carados en el buffer a traves del shader de vertices. Entonces, no es necesario preocuparse de las copias de los modelos ni tan siquiera los buffers, sino de las actualizaciones de los uniforms que corresponden a las matrices de transformacion. Por ejemplo, al momento de moverme a través del mapa, no se actualiza el buffer de cada modelo individualmente, sino que se actualizan las uniforms que referencian las matrices de proyección, vista, y transformaciones para cada uno de los elementos dependiendo del caso y como ventaja de tener rotación, traslación y escalado en las entidade individuales puedo aplicar estas transformaciones individualmente con la ventaja de poder componer todo como en algebra lineal facilmente. Y puedo tomar un objeto individual y rotarlo, o escalarlo con gestos capturados por la capa de gestos, que luego se interpretan por el sistema de eventos que este morfa a cambios en la capa del nucleo, el cual luego de ser representado por la capa grafica (una vez el estado esta "actualizado") genera la experiencia deseada.
como segundo apartado y sobre el tema de las actualizaciones en línea una vez haya cargado el estado del programa en linea al inicializar la experiencia, el resto de la sincronización se realiza utilizando un sistema de eventos que quiero que incluyas a la arquitectura, que actualiza la experiencia de forma idempotente para todos los usuarios y permite un buen desempeño ya que no hay que actualizar toda la información constantemente para todo el mundo.
Como cuarta consulta, hay alguna manera definir tipos utilizando tipos como first class citizens? Por ejemplo crear una declaración general de vector de N-dimensiones donde N sea un parámetro y tenga N elementos en base a la declaración.
Quinta pregunta, me recomiendas crear un alias usando type para los types primitivos de TypeScript para crear una capa de abstraccion de mis propios tipos para mis composiciones y mi aplicación? Y no hacer uso de las primitivas que vienen por defecto tal como vienen. Como por ejemplo en type EntityId = string;
¿Por qué utilizas la palabra kind en vez de algo como type o category para los gestos? También quiero que añadas a la arquitectura el estado pinch para cuando el índice y el pulgar se tocan en las puntas 
También quiero que cambies el nombre de Quaternion a Vector 4 para hacer juego con Vec3 o me busques una taxonomía de nombres normalizado y regular sobre nombres para mis objetos de algebra como en este caso Vector 4.

---

Explícame como derivar por mi mismo la fórmula para calcular la matriz de proyección. From first principles. Quiero entender todo lo necesario para poder construir una matriz como esa si la necesito en el futuro para cualquier otro caso particular no necesariamente relacionado con desarrollo de experiencias 3d. No quiero utilizar librerías (como gl-matrix) porque quiero calcular todo por mi mismo de tal manera que mi codigo refleje mi entendimiento de los componentes en todos los niveles, solo omitiendo librerias de programacion funcional y librerias para manejo de hardware/graficos, aunque mi plan a futuro es usar la modularizacion y encapsulado que me da FP para poder crear mis propias implementaciones de absolutamente todo, e ir investigando lo necesario para optimizar todo individualmente, estoy moviendome de lo macro a lo micro y viseversa, segun ocupo, moviendome entre capas de abstraccion.
También quiero que me expliques toda la teoría de tipos necesaria para poder trabajar con los tipos de TypeScript y quiero que me hables de como TypeScript maneja types incluyendo objetos comunes, acciones comunes, etc. para poder componer a abstracciones y composiciones poderosas, utilizando todas las herramientas que me provee TypeScript. Me gusta la idea de declarar los vectores como me compartiste con la parametrizacion, pero prefiero volver a usar una declaracion sencilla de tuplas, esta bien para mi caso, luego podemos ver que otras opciones tenemos o si usamos Any en caso de tener algo mas avanzado (o una construccion custom)

---

FAQ:

1. ¿Cuál es la visión principal de tu aplicación? Describe la experiencia ideal del usuario final en una sesión típica de uso.
La visión principal de la aplicación es servir como un mecanismo para poder aumentar la cognición humana, permitiéndole al usuario poder componer todas las herramientas necesarias para trabajar en cualquier dominio que puede ser descrito a través del lenguaje y permitiendo el acceso a computación en tiempo real para crear frameworks y estudiar objetos en base a las declaraciones de esos universos, anotaciones (como un whiteboard), ver archivos en el plano de realidad virtual (como visores pdf embebidos en la experiencia, o de otros formatos), y hasta manipulacion de modelos interactivos en 3d, etc.

3. ¿Cómo defines los "arquetipos" de tu dominio (e.g., entidades, modelos, gestos)? ¿Cómo se mapean a categorías en teoría de categorías?

4. ¿Qué significa exactamente "descubrir" el programa en lugar de "crearlo"? Dame ejemplos de cómo esto ha influido en decisiones pasadas.
5. ¿Cuáles son los objetivos a corto plazo (MVP) vs. largo plazo (e.g., multiplayer avanzado, integración con IA)?
6. ¿Qué plataformas objetivo tienes en mente (e.g., navegadores desktop, Oculus Quest via WebXR, mobile AR)?
7. ¿Cómo priorizas features: dibujo 3D, navegación en pizarras, carga de modelos, tracking de manos, o reconocimiento de gestos?
8. ¿Qué inspiraciones externas (libros, papers, apps) han moldeado tu enfoque categórico y funcional?
9. ¿Cuáles son los constraints presupuestarios o temporales para la implementación?
10. ¿Cómo mides el éxito de la app (e.g., métricas de engagement, feedback de usuarios, rendimiento técnico)?

11. ¿Qué tipos de dibujos soporta la app (e.g., líneas, formas primitivas, pinceles personalizados)? ¿Cómo se representan computablemente?
12. ¿Cómo funciona la navegación en la pizarra virtual? ¿Incluye zoom, pan, rotación global, o vistas múltiples?
13. ¿Qué formatos de modelos 3D se pueden cargar (e.g., OBJ, GLTF)? ¿Cómo se integran con el dibujo existente?
14. ¿Qué gestos específicos reconoces (e.g., pinch para escalar, swipe para mover, fist para borrar)? ¿Cómo los priorizas?
15. ¿Cómo manejas tracking de manos en WebXR? ¿Soportas una o dos manos? ¿Qué pasa si el tracking falla?
16. ¿Qué proyecciones 3D ofreces (e.g., perspectiva, ortográfica, estéreo para VR)? ¿Cómo cambian dinámicamente?
17. ¿Incluyes undo/redo para acciones de dibujo? ¿Cómo se modela en un estado inmutable?
18. ¿Qué herramientas de edición avanzadas planeas (e.g., selección múltiple, grouping de entidades)?
19. ¿Cómo integras feedback háptico o audio para gestos (e.g., vibración en pinch)?
20. ¿Qué personalizaciones permite la app (e.g., colores, estilos de pincel, temas de UI)?

21. ¿Cómo defines los tipos algebraicos para entidades (e.g., sum types para variantes)? Dame ejemplos refinados.
22. ¿Qué librerías FP adicionales recomiendas más allá de fp-ts, lodash, monocle-ts (e.g., effect-ts para efectos)?
23. ¿Cómo modelas el FSM para gestos en tipos? ¿Incluyes transiciones timed o condicionales?
24. ¿Qué morfismos clave hay entre capas (e.g., nuclear a gráfica)? ¿Cómo aseguras composabilidad?
25. ¿Cómo manejas asincronía en ticks (e.g., carga de modelos via promises)? ¿Usas monads como Task?
26. ¿Qué estructuras de datos persistentes usas para inmutabilidad eficiente (e.g., Immutable.js)?
27. ¿Cómo integras eventos en la arquitectura (e.g., como stream o reducer)?
28. ¿Qué tipos para transforms (Vec3, Vec4)? ¿Incluyes validaciones (e.g., quaternion normalizado)?
29. ¿Cómo derivas graphicsState de nuclear y models sin copias innecesarias?
30. ¿Qué patterns categóricos aplicas (e.g., functors para Universe, lenses para updates)?

31. ¿Qué métricas de rendimiento priorizas (e.g., FPS, latencia de gestos, uso de memoria)?
32. ¿Cómo optimizas uniforms en shaders para miles de entidades? ¿Usas instancing?
33. ¿Qué trade-offs aceptas entre pureza funcional y rendimiento (e.g., mutaciones internas en WebGL)?
34. ¿Cómo manejas sincronización en redes lentas (e.g., throttling de eventos)?
35. ¿Qué algoritmo CRDT específico para nuclearState (e.g., Y.Map para mapas)?
36. ¿Cómo resuelves conflictos en multiplayer (e.g., dos usuarios editando misma entidad)?
37. ¿Qué setup inicial para multiplayer (e.g., server centralizado vs. P2P con WebRTC)?
38. ¿Cómo escalas a más usuarios (e.g., sharding de eventos)?
39. ¿Qué profiling tools usas (e.g., Chrome DevTools para WebGL)?
40. ¿Cómo manejas updates diferenciales en eventos para bandwidth efficiency?

41. ¿Qué UX para onboarding (e.g., tutorial de gestos)?
42. ¿Cómo aseguras accesibilidad (e.g., soporte para no-VR, voice commands)?
43. ¿Qué feedback visual para gestos (e.g., highlighting manos virtuales)?
44. ¿Cómo pruebas usabilidad (e.g., user testing con prototipos)?
45. ¿Qué edge cases para gestos (e.g., manos temblorosas, iluminación pobre)?
46. ¿Qué implicaciones de privacidad en multiplayer (e.g., datos de tracking de manos)?
47. ¿Qué licencias y consideraciones legales (e.g., open-source, patentes en VR)?
48. ¿Cómo integras con ecosistemas existentes (e.g., exportar a Blender)?
49. ¿Qué riesgos de implementación (e.g., bugs en WebXR cross-browser)?
50. ¿Cómo iteras post-implementación (e.g., A/B testing de features, community feedback)?
