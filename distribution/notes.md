# Magic The Sortering 1.0.4

Actualización de Web y Companion Android. Conserva el protocolo de sincronización v1, los datos y las preferencias existentes.

## Imagen de Inicio

- La imagen personalizada vuelve a conservarse al navegar y recargar la aplicación.
- Se mantiene como preferencia local del navegador o dispositivo, junto con la opción de restaurar la predeterminada.
- Se conservan el tema y los límites de formato, tamaño y dimensiones de la imagen.

## Dossiers e importación

- Las casillas mantienen un máximo de dos impresiones diferentes y cuatro copias de cada impresión. Las excepciones de cantidad ilimitada de la colección no amplían estos límites físicos.
- La importación de inventario y la restauración de backups comprueban estos límites antes de sustituir datos. Un archivo con casillas excedidas se rechaza con un mensaje explícito, conservando los datos actuales.
- No se mueven ni eliminan automáticamente copias existentes. Las cajas y otras ubicaciones conservan sus reglas anteriores.

## Instalación y actualización

- Disponibles: instalador y portable Windows x64, Linux x64/ARM64 y APK Android, con manifiesto y hashes SHA-256.
- Guarda un backup antes de actualizar Web y conserva las rutas de datos, configuración y certificados. En Docker, conserva el volumen de datos.
- Instala la APK oficial sobre la anterior para conservar la colección, mazos y operaciones pendientes. No desinstales ni borres almacenamiento para actualizar.
- Consulta el README para instalación, configuración inicial y problemas habituales.
