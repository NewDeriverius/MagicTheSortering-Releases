# Fase 8 — Auditoría de consolidación

Fecha: 2026-11-11. Ramas: Web, SharedUI y Companion `integration/consolidation`; Releases `integration/joint-distribution`. Sin cambios en main, merges, tags, releases públicas ni despliegues.

## Revisiones y arquitectura comprobadas

Plan congelado de la validación final: `6172af3e976898f3a209e96443cd1113775b128e`. Los commits siguientes de Releases solo documentan resultados; el dry-run utiliza ese objeto inmutable.

- SharedUI final: `6bc1f472fa1701853c248aa9578c302357162683`, idéntico en ambos gitlinks publicados.
- Web inicial: `b74930da48493cdc5e1068b90e6a85ac2f451304`. Web con las regresiones integrales: `c8f469c18478a5bfe4330787216d14154e9e1b39`; gitlink final publicado: `826fc48bf9f1ca7c285598be944cfbe03b0b161b`.
- Companion inicial: `c64c83aa931d87e21ed51c951461dfc567e82287`; corrección funcional: `098321bdac8d2e7d1309878a93f905efee0999cf`; final publicado: `3e99fff2349c673f61b2cb44fcf00e5ffec05cc9`. Esta fase corrige además el ciclo de vida de la ventana Android y la disponibilidad de acciones durante la inicialización de Mazos. No cambia dominio, datos físicos ni protocolo.
- Los checkouts independientes se clonaron desde GitHub, sin Local.props. Builds y tests usan `CI=true` y `UseLocalSharedUI=false`; no existe sustitución de SharedUIRoot.

La normalización está en Shared.Contracts/CatalogKeyNormalizer y CatalogSearchTerm. InventoryNameIndex e InventoryNameSearch pertenecen a la biblioteca Search.Sqlite separada de la RCL. Web/LocalizedInventoryNameSearch y Companion/SqliteCatalog delegan en ese motor. CollectionDatabase conserva el filtrado, agrupación, recorrido de ubicaciones y paginación de su persistencia offline. Se consultan las identidades del inventario; no se carga el catálogo completo en memoria. Los componentes de Mazos, representación de copias, paginadores, tema, estado y emparejamiento siguen compartidos; los adaptadores MAUI/SQLite/EF permanecen en sus hosts.

## Comprobado automáticamente en esta fase

- Builds limpios Web y SharedUI: Debug y Release correctos.
- SharedUI.Tests final: 42/42; Search.Sqlite.Tests: 3/3; JavaScript: 12/12.
- Componentes Web: 72/72; integración focalizada de búsqueda, backup e importación de mazos: 31/31.
- Companion.Mobile.Tests: 90/90, incluidas validación por contenido, manifiesto, SHA-256, ZIP, integridad SQLite, rollback, cancelación y conservación de mazos/outbox/identidad.
- Contratos HTTPS/SignalR/SQLite entre consumidores: 57/57. Dos regresiones integrales nuevas: 2/2, repetidas desde el commit publicado y checkout limpio. Combinan backup real de CollectionBackupService o SQLite consistente, edición offline, importación manual, reinicio del servicio, snapshot explícito y dos sincronizaciones sin duplicar mazos, cartas ni receipts.
- Android Debug y Release: compilación e inspección final de APK correctas. ApplicationId, permisos INTERNET/ACCESS_NETWORK_STATE/CAMERA, recursos, CSS, iconos y ausencia de depuración en Release comprobados. Se conservan los avisos conocidos XA0033 del JDK local.
- El primer checkout Android estaba anidado bajo una ruta larga y AAPT no pudo abrir un recurso compilado. La misma revisión, SDK y JDK compilan en el checkout limpio corto `C:\mts-phase8-199c3336`. No se cambió el producto para ocultarlo.
- Contratos del agregador/publicador: 16/16, sin publicación ni red. Sintaxis del coordinador comprobada con actionlint. SHA256SUMS generado en Windows se acepta con sha256sum real de Linux en un contenedor sin red.
- SDK local 10.0.203; JavaScript local Node 24.22.1. El coordinador fija Node 22 y ejecuta también las pruebas JS.

Medidas sintéticas de esta ejecución, sin red:
- Búsqueda Web: inventario p50 4,40 ms / p95 6,21 ms; catálogo 1,74 / 4,60 ms; primera consulta con índice 9,78 ms.
- Companion: inventario 10,26 / 12,56 ms; catálogo 1,54 / 3,51 ms; primera consulta 16,20 ms.
- Esas búsquedas usan 35 impresiones propias y 38 de catálogo: no acreditan latencia con un catálogo de producción completo. El benchmark histórico opt-in no se activó.
- Imágenes: 10.007 impresiones de catálogo, 25 identidades visibles; lote p50 0,53 ms / p95 0,60 ms frente a 10,76 / 11,94 ms individual. Un comando SQL y plan con índices de impresión/caras.
- SignalR en el host de pruebas: 35,02 s de reposo, cero peticiones HTTP periódicas; recuperación tras reinicio 989 ms. Aplicación de 10/100/1.000 operaciones: 530/351/1.153 ms. Son medidas del host de pruebas, no latencia del teléfono.

La CI Web previa sobre b74930d pasó Windows x64, Linux x64 y Linux ARM64: dominio 40, componentes 72, integración 701 y Playwright 64 por plataforma. [Ejecución](https://github.com/NewDeriverius/MagicTheSortering/actions/runs/43053473289). No se atribuyen a esta fase como una suite local nueva.

## Comprobado en Android físico

Dispositivo autorizado mediante ADB, Android API 36. Debug actualizado con `adb install -r`. Perfil nuevo por GUID, servidor HTTPS nuevo, catálogo y colección sintéticos; sin importar la colección personal.

- Edición offline de un mazo con el servidor detenido; pendiente visible.
- 20 arranques consecutivos con señal de primer render Razor. La edición y la cola sobreviven a los reinicios.
- Reconexión y sincronización: Web conserva un único mazo con el título editado; Companion acaba con cero pendientes. Una sincronización adicional no lo duplica.
- Mazos en 393×851, 851×393 y 1280×720, claro/oscuro: tamaños, imágenes/fallback, comandante, identidad y acciones táctiles; sin desbordamiento. Los viewports se emulan dentro del WebView físico, no son seis dispositivos.
- «Jefe supremo aberrante» encuentra Abhorrent Overlord; conserva Inglés (en), ubicación y ×2 copias.
- Importación .db desde el selector nativo con confirmación explícita; conserva el mazo editado. La selección del archivo fue asistida por el usuario. Se descartó una segunda selección .db antes de aplicar cambios.

- Portable .mtsbackup real importado y confirmado en Android: conserva el mazo. Ambos archivos se seleccionaron con asistencia humana; todas las comprobaciones y confirmaciones se verificaron en el perfil sintético.
- Lista/Grid en doce escenarios de tamaños/temas, 25 grupos en primera página, paginadores superior/inferior, segunda página, ficha y regreso, doble cara y fallback.
- Modal QR con cámara real: abrir/cerrar termina todos los tracks. La lectura óptica/autocierre se acreditó en fase 6 y no se repitió en fase 8.
- Dos renombrados desde la interfaz Web publicada llegaron automáticamente al listado Android abierto, sin refresco. El segundo se recibe después de tres salidas con Atrás y reaperturas en el mismo proceso; SignalR, aplicación automática y preferencias se conservan.

Se encontró y corrigió un fallo real: Window.Destroying eliminaba el coordinador de toda App. Android puede reutilizar App y destruir la ventana antigua después de activar la nueva. Ahora se pausa sin eliminar el coordinador y solo los eventos de la ventana activa afectan su sesión. La regresión Test-AndroidReactiveResume.ps1 exige un WebView nuevo y su primer render interactivo, sin aceptar reconexiones de otro proceso.

La prueba Web usa una publicación completa, catálogo sintético con esquema Web completo e InitializeOnStartup=false. El cliente de pruebas fija el SPKI del certificado de esa instancia; no instala CAs ni debilita el TLS de las aplicaciones. Los intentos con assets sin publicar, catálogo reducido o prerender aún no interactivo no se contabilizan como validación del producto.

También se corrigió la automatización DevTools: PowerShell envolvía el array JSON y podía seleccionar un WebView retenido. Siete regresiones exigen el target adjunto/visible y rechazan ambigüedades.

Las capturas versionadas contienen únicamente la aplicación con datos sintéticos. El test visual espera a que termine la transición CSS del tema y comprueba contraste del encabezado, evitando capturas de un estado transitorio.

Ambos perfiles de pruebas se retiraron tras revocarlos. Se restauraron el marcador original, preferencias, tema/vista y rotación. Los SHA-256 de las cuatro bases personales comparadas coinciden antes/después. No quedan forwards propios y los procesos Web de pruebas están detenidos. La APK Debug final queda instalada con la aplicación detenida. La APK final pasó otros 20 arranques y tres recreaciones de ventana; Release final también compila y se inspecciona. El commit Native final se compiló además desde el checkout limpio corto, con gitlink exacto y sin Local.props.

## Distribución conjunta y bloqueos

El primer dry-run [43060332592](https://github.com/NewDeriverius/MagicTheSortering-Companion-App/actions/runs/43060332592) validó y empaquetó Web/SharedUI, pasó los 90 tests Companion y produjo una APK Release con manifiesto/recursos correctos, pero falló al verificar su firma. No se agregaron ni subieron los ocho archivos, y no hubo publicación.

Se añadió captura de la salida pública de apksigner y su código de salida, manteniendo la verificación estricta y el rechazo del certificado Android Debug. La misma condición pasa localmente con una APK válida; eso no demuestra que la firma de producción del runner sea válida.

El diagnóstico del segundo intento [43065792572](https://github.com/NewDeriverius/MagicTheSortering-Companion-App/actions/runs/43065792572) confirma exit=0 y firma válida. Build Tools 37 imprime V3.0 Signer: donde el parser esperaba Signer #1. Se fija apksigner 36, previsto por el workflow, y se aceptan ambos formatos con un único firmante y huella inequívoca. Se mantienen rechazo de Debug y códigos fallidos. Doce regresiones más la salida real capturada pasan.

[43083059959](https://github.com/NewDeriverius/MagicTheSortering-Companion-App/actions/runs/43083059959) se canceló al descubrir el fallo funcional Android, para construir después la corrección. Ya había pasado Web/SharedUI y 59/59 contratos cruzados. Antes de cancelarse expuso además un IOException de limpieza SQLite en Mobile.Tests: no se oculta ese fallo.

La causa de esa carrera está reproducida localmente. Esperar solo a DisposeAsync no bastó. Los contratos podían terminar/interactuar con una lectura inicial de ubicaciones aún pendiente. SharedUI ahora expone aria-busy y deshabilita crear/importar mientras termina la lectura; los contratos esperan ese estado y disponen bUnit asíncronamente. Un test con lectura bloqueada verifica el estado; 42 tests SharedUI y los dos contratos Web pasan. En móvil pasan cinco repeticiones consecutivas de ambos contratos (10 casos) y los 90 tests completos, sin demoras artificiales de limpieza ni aserciones retiradas.

El intento [43091965130](https://github.com/NewDeriverius/MagicTheSortering-Companion-App/actions/runs/43091965130) pasó Web, pero falló en una espera síncrona de SharedUI con cero aserciones ejecutadas. Se convierten los eventos y las esperas de ese caso a async, conservando todos los asserts y el timeout. Suite 42/42 y cinco repeticiones focalizadas correctas. El coordinador añade un preflight temprano para detectar fallos compartidos antes del gasto de todo Web; conserva también todos los gates del builder.

Los cambios posteriores a 098321b no modifican código funcional Android ni el protocolo: solo tests, gitlinks, workflow y documentación.

La validación final [43095384654](https://github.com/NewDeriverius/MagicTheSortering-Companion-App/actions/runs/43095384654), con el plan 6172af3 y las tres revisiones finales publicadas, permanece en cola en GitHub y aún no tiene jobs asignados. No hay artefacto final descargable y no se declara completada la distribución de extremo a extremo. No se han iniciado ejecuciones duplicadas ni se ha atribuido la cola a facturación o a una incidencia sin evidencia.

La batería entre consumidores se incorpora al coordinador privado, que ya tiene ambos checkouts inmutables. CompanionRoot señala ese checkout verificado; SharedUI sigue fijado por gitlink. La CI independiente Web no obtiene acceso a Companion.

## Reproducir y consumir SharedUI

Clonar las ramas indicadas y sus submódulos; ambos consumidores deben mostrar exactamente 6bc1f472fa1701853c248aa9578c302357162683 en `git ls-tree HEAD external/SharedUI`. Ese objeto se publicó en la rama SharedUI y las compilaciones limpias lo descargaron del remoto.

Para avanzar SharedUI: publicar primero su commit; en cada consumidor, fetch del remoto del submódulo, checkout detached del SHA completo y commit del gitlink. Actualizar el plan con los tres SHA completos publicados. No usar overrides locales como condición para compilar o distribuir.

Pruebas cruzadas:

~~~powershell
dotnet test tests/MagicTheSortering.DeviceSync.Tests/MagicTheSortering.DeviceSync.Tests.csproj -c Release -p:CI=true -p:UseLocalSharedUI=false "-p:CompanionRoot=C:\RUTA\MagicTheSortering-Companion-App"
~~~

El probe Web protege sus acciones con directorio GUID y marcador de instancia sintética. `setup` con el catalog.db del generador WarehouseFixture, seguido por `audit-seed` y `audit-export`, produce colección, mazo, SQLite consistente y .mtsbackup real. No apuntarlo a instancias personales. Los scripts Android exigen el marcador del perfil aislado.

## PR y orden de integración humana

1. [SharedUI #8](https://github.com/NewDeriverius/MagicTheSortering-SharedUI/pull/8).
2. [Web #11](https://github.com/NewDeriverius/MagicTheSortering/pull/11) y [Companion #8](https://github.com/NewDeriverius/MagicTheSortering-Companion-App/pull/8), compatibles mediante protocolo 1 y la misma revisión SharedUI.
3. [Releases #1](https://github.com/NewDeriverius/MagicTheSortering-Releases/pull/1), con el plan fijando los commits consumidores aprobados y un dry-run completo correcto.

Si se integra SharedUI mediante squash/rebase, actualizar los gitlinks al SHA resultante publicado antes de integrar consumidores y regenerar el plan. Conservar 56cfef1 si sigue siendo el objeto aprobado y alcanzable con una integración que preserva su historia.

No publicar encima de v0.9.9-beta existente. Una futura distribución pública necesita una versión Web nueva y versionCode Android creciente, autorización de publicación y dry-run correcto. Esta auditoría no ejecuta esa publicación.

La actualización física con la APK de producción sigue pendiente: el teléfono utiliza Debug y no se desinstaló ni cambió su identidad de firma para forzar una instalación Release. Los tests automáticos no sustituyen esa prueba.
