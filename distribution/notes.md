# Notas candidatas — consolidación

Plan de dry-run. No constituye una nueva release pública; v0.9.9-beta ya existe y no se sobrescribirá. Antes de publicar se debe preparar una versión Web nueva y su plan, con el versionCode Android creciente.

- Búsqueda multidioma común a Web y Companion, sin cambiar el idioma físico de las copias.
- Mazos Android responsive con edición offline y navegación conservadas.
- Almacenaje con lista/grid, orden físico, cantidades agrupadas y doble paginador.
- Importación transaccional de inventario .db y .mtsbackup con validación de contenido.
- Tema persistente, icono Android, estado de conexión y escáner QR modal.
- Paquetes conjuntos con procedencia y hashes, manteniendo versiones independientes.

Compatibilidad declarada: protocolo directo v1 y backup portable v1. Consulte el manifiesto para versiones, commits, revisión SharedUI y huella de firma Android exactos. La validación integral final y la actualización física entre APK de producción deben completarse antes de aprobar una entrega.
