# Magic The Sortering 0.9.10-beta

Distribución conjunta de Web y Companion Android. Incluye las mejoras y correcciones integradas en sus ramas principales.

## OCR y sesiones

- Captura automática nativa Android con modos En mano y Soporte fijo, estabilización y corrección de perspectiva. Se conserva el botón de captura manual.
- Calibración del marco y del soporte vacío, revisión de la fotografía mediante miniatura y aviso sonoro configurable.
- Conservación de capturas pendientes al perder la conexión y reintentos con la misma identidad, evitando duplicados de transporte.
- Las nuevas lecturas de la sesión muestran la carta recortada. El fotograma completo y las regiones de nombre/footer se conservan para el procesamiento; las fotografías históricas no se reescriben.
- Corrección del falso token causado por fragmentos como «t 30» en texto de reglas. Las marcas inciertas no excluyen cartas normales y las ambigüedades siguen requiriendo revisión.

## Colección y experiencia Android

- Búsqueda multidioma compartida entre Web y Companion sin modificar el idioma físico de las copias.
- Mazos adaptados a móvil con edición offline y navegación conservadas.
- Almacenaje con vistas Lista/Grid, orden por ubicación, cantidades agrupadas y paginación superior e inferior.
- Importación de inventario SQLite y backups portables .mtsbackup con validación y sustitución transaccional.
- Tema persistente, identidad visual Android, estado de conexión SignalR y escáner QR modal.

## Instalación y compatibilidad

Se distribuyen instalador y ZIP portable Windows x64, paquetes Linux x64 y ARM64, y APK Android firmada. El manifiesto indica versiones, commits, revisión compartida y huella de firma; SHA256SUMS.txt permite comprobar la integridad de los archivos.

Protocolo de sincronización directa v1 y backup portable v1. La APK usa un versionCode nuevo (9011). Actualiza conservando carpetas de datos y preferencias, sin desinstalar ni borrar almacenamiento; revisa el README de esta distribución para cada plataforma.

Es una versión beta. El OCR requiere una carta completa y legible; en soporte fijo es importante ajustar el marco y guardar la referencia vacía. La validación física ampliada de cámaras, giros, iluminación y formatos de carta continúa. Una identificación ambigua conserva las candidatas para confirmación humana.
