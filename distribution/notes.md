# Magic The Sortering 1.0.3

Actualización conjunta de Web y Companion Android. Mantiene el protocolo de sincronización v1 y la compatibilidad con las colecciones y backups existentes.

## Legalidad de mazos

- Companion puede completar desde Scryfall los datos de legalidad de las impresiones de sus mazos y conservarlos en el catálogo para consultar sin conexión. No modifica la composición de los mazos ni sus operaciones offline.
- La actualización del catálogo incorpora estos datos y permite revalidar el mazo; se puede reintentar desde Mazos si la fuente no está disponible.
- Web corrige el aplazamiento de importaciones de catálogos antiguos que todavía no contenían legalidades.
- Los avisos agrupan las cartas pendientes de verificación en un bloque desplegable, separado de las infracciones confirmadas. No se considera ilegal una carta por falta de información.

## Navegación de Almacenaje

- Web y Companion comparten la resolución de ubicaciones y breadcrumbs.
- Al abrir las cartas de una casilla, hoja o fila se conserva la ruta y se puede volver a su ubicación padre, sin depender de un historial previo del navegador.
- Los accesos directos y ubicaciones que ya no existen mantienen una salida segura hacia Almacenaje.

## Imagen de Inicio

- Configuración permite elegir una imagen PNG, JPEG o WebP y restaurar la imagen predeterminada.
- La preferencia es local a cada navegador o dispositivo, igual que el tema; no se sincroniza con la colección.
- Se valida el contenido, la decodificación, el tamaño máximo de 2 MB y las dimensiones (8192 píxeles por lado y 16 megapíxeles). Si la imagen guardada es inválida o no está disponible, se utiliza la predeterminada.
- Companion utiliza el selector nativo de Android; la configuración y presentación se comparten con Web.

## Actualizar conservando los datos

1. Guarda un backup antes de actualizar Web y conserva las mismas rutas de datos, configuración y certificados. Docker debe mantener su volumen.
2. Instala la APK oficial 1.0.3 sobre la anterior. Conserva el identificador de paquete y la firma de distribución; el código Android pasa a 10003. No desinstales ni borres el almacenamiento para actualizar.
3. Actualiza las legalidades desde Mazos o al importar/descargar el catálogo. La consulta inicial a Scryfall necesita conexión; los datos guardados se utilizan sin red. Los estados desconocidos se mantienen cuando la fuente no proporciona información.

La distribución incluye instalador y portable Windows x64, Linux x64/ARM64, APK Android firmada, manifiesto de procedencia y SHA-256. Las versiones y commits exactos constan en el manifiesto de esta release.
