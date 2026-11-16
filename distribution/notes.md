# Magic The Sortering 1.0.2

Correcciones de Web y Companion Android. Protocolo de sincronización v1 y backups compatibles con 1.0.0/1.0.1.

## Cartas, estadísticas y mazos

- Companion permite abrir en el navegador la impresión y las reglas de Scryfall desde la ficha. Esta consulta necesita Internet; un error conserva los datos locales.
- Las estadísticas de símbolos de maná utilizan el mismo criterio en Web y Android, incluyendo copias múltiples y cartas de varias caras.
- El enfundado masivo encuentra las mismas copias elegibles que el individual. Las preferencias ordenan las candidatas y se admite una confirmación parcial explícita. La confirmación comprueba cambios de las copias y evita duplicados.
- El catálogo actualizado conserva los datos de legalidad de Scryfall para validar mazos offline. Se distinguen legal, ilegal y no verificable; las infracciones confirmadas no ocultan las comprobaciones sin datos.

## Almacenaje Web

- «Seleccionar página» y «Seleccionar todas» cuentan copias físicas y distinguen la página y todos los resultados filtrados, incluidos subalmacenes. La selección permanece al paginar; cambiar el filtro la reinicia explícitamente.
- Los lotes de más de diez copias pueden asignarse juntos a una fila o celda con un clic. Es una propuesta editable que se confirma después, con alternativa individual y resumen de seleccionadas, asignadas y pendientes.
- El selector muestra las hojas finales en el panel de distribución de su contenedor. La navegación habitual del almacén se conserva.
- Paginación compartida arriba y abajo, con primera/anterior, número editable y siguiente/última. Se mantienen capacidad y políticas del almacén sin movimientos parciales silenciosos.

## Actualizar conservando los datos

1. Conserva un backup antes de actualizar Web. Utiliza las mismas rutas de datos, configuración y certificados; Docker conserva su volumen.
2. Instala la APK oficial sobre la anterior, con el mismo paquete y certificado. No desinstales ni borres almacenamiento para resolver una firma incompatible. Se mantienen los mecanismos de actualización introducidos en 1.0.1.
3. Actualiza el catálogo en Web 1.0.2 y sincronízalo o impórtalo en Companion para obtener los datos de legalidad. Un catálogo anterior sigue funcionando, pero no puede verificar hechos que nunca guardó. Actualizar estos hechos no modifica mazos ni sus operaciones offline.

Companion continúa consultando el almacén y editando composición de mazos offline; los movimientos físicos se administran en Web. Las versiones exactas, revisiones, certificado de firma y hashes de los paquetes constarán en el manifiesto de la distribución.
