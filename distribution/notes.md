# Magic The Sortering 1.0.1

Versión estable de Web y Companion Android. Protocolo de sincronización v1.

## Recuperación después de trasladar Web

La colección mantiene una identidad distinta de la instalación Web y de la época de sincronización. Restaurar un backup portable en otro servidor permite emparejar Companion con una invitación legítima y revisar la recuperación. Los backups 1.0.0 se reconocen mediante identificadores persistentes.

Antes de adoptar Web, Companion solicita confirmación y guarda una copia recuperable. Intenta integrar los cambios offline compatibles, evita repetir los ya aplicados y conserva en esa copia los incompatibles. Web prevalece en los conflictos y el resultado indica qué ocurrió con cada conjunto de cambios. Los reintentos sobreviven a interrupciones sin duplicar operaciones.

## Actualizaciones

Web muestra versiones instalada/disponible, novedades y posposición. La sección Actualizaciones explica cómo actualizar Windows, Linux y Docker conservando datos, configuración y certificados.

Companion detecta versiones estables oficiales y permite descargar e iniciar su instalación nativa. Verifica SHA-256, paquete, versión y continuidad de firma. Android requiere autorización de instalaciones desde Companion y confirmación del instalador. La descarga puede cancelarse o reintentarse sin sustituir la aplicación.

## Pasar desde 1.0.0

1. Exporta un backup antes de actualizar Web. En Windows ejecuta el Setup con las mismas rutas; en Linux/portable detén el servicio y conserva el directorio de datos. Docker conserva su volumen al reconstruir y recrear el contenedor.
2. Companion 1.0.0 no incluye actualizador. Instala manualmente esta APK encima de la versión oficial anterior, con el mismo paquete y certificado. Las siguientes versiones podrán descubrirse desde Companion 1.0.1.
3. Si has trasladado la colección, genera una nueva invitación desde Web 1.0.1 y revisa la recuperación en Companion. No borres datos ni desinstales para resolver un bloqueo de identidad.

El flujo normal mantiene compatibilidad v1. La recuperación entre instalaciones requiere Web y Companion 1.0.1. Una APK firmada con una clave de pruebas distinta no puede actualizarse a la oficial conservando la instalación mediante un simple reemplazo; no desinstales para sortear el rechazo de firma.

Descarga todos los paquetes y sus hashes desde esta misma release. Las revisiones exactas y el certificado público de firma figuran en distribution-manifest.json.
