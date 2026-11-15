# Magic The Sortering 1.0.0

Distribución estable conjunta de Web y Companion Android, construida desde revisiones inmutables integradas en sus ramas principales.

## Staging y reconocimiento

- Selección de cualquier lectura de Staging, individual, por grupo o global, conservada al recargar mientras la entrada exista.
- Edición masiva con campos explícitos y valores mixtos; los campos sin modificar conservan su valor. Las políticas de ubicación, capacidad, reservas y concurrencia siguen siendo obligatorias.
- Retirada masiva con confirmación del número de entradas y copias, sin eliminar inventario ni catálogo. Se conserva la confirmación parcial.
- Resolución de tokens mediante su clasificación y los alias de set impresos, incluidos MH2/TMH2 y MSH/TMSH. Las contradicciones y el idioma físico no se adivinan.
- Una candidata válida única se presenta correctamente; las ambigüedades reales continúan requiriendo elección.

## Companion

- Cámara nativa con zoom multitáctil, enfoque coordinado y uso del marco guardado en soporte fijo; captura de cartas con borde blanco y recorte conservado en el envío.
- Acciones de cámara e icono específico para guardar el soporte vacío, miniatura de revisión y sonido configurable.
- Retirada explícita de capturas pendientes incompatibles, con confirmación, sin enviarlas a otro emparejamiento o época.
- Diagnósticos de errores HTTP y colas más claros, nombre de dispositivo coherente y paginación mejorada.
- Importación Archidekt compartida y búsqueda de catálogo mediante infraestructura común de solo lectura.
- Pestañas de Configuración protegidas frente a pulsaciones durante el prerenderizado.

Se mantienen la búsqueda multidioma, Mazos offline, Almacenaje Lista/Grid con ubicación y cantidades, importación .db/.mtsbackup y sincronización reactiva Web ↔ Companion.

## Instalación y actualización

Incluye instalador y ZIP portable Windows x64, paquetes Linux x64 y ARM64, APK Android firmada, notas, manifiesto y SHA256SUMS.txt. El manifiesto identifica commits, revisión SharedUI, versiones, protocolo y certificado de firma.

Protocolo directo v1 y backup portable v1, sin nuevas migraciones en esta candidata. Android usa el ApplicationId habitual y versionCode 10000, superior al 9011 de la beta 0.9.10. Actualiza instalando encima únicamente con la misma firma; una compilación diagnóstica firmada con Android Debug no puede actualizarse directamente con la APK oficial. No desinstales ni borres datos para forzarlo.

Antes de actualizar Web, conserva un backup .mtsbackup y una copia coherente de datos, configuración y PKI. Mantén esas rutas al sustituir binarios. No se incluyen datos personales, catálogo ni certificados de instancia en los paquetes.

El OCR necesita una carta completa y legible. En soporte fijo, ajusta el marco y guarda el soporte vacío. Cámaras, iluminación y cartas concretas pueden requerir captura manual y revisión humana; no se promete identificación infalible. La validación automática no sustituye la comprobación física de cada dispositivo.
