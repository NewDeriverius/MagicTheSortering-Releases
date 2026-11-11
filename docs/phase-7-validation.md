# Fase 7 — documentación y distribución conjunta

Estado: **parcial por bloqueo externo del dry-run remoto**. Código y documentación preparados; sin merges, releases públicas, tags nuevos ni despliegues. No se inicia la fase 8.

## Ramas y PR

Se mantienen las ramas existentes integration/consolidation de Web, SharedUI y Companion. Releases usa la nueva integration/joint-distribution.

- Web: 5e707b776bd2f2d0d801bf0b7d491dbeeacf906d — [PR #11](https://github.com/NewDeriverius/MagicTheSortering/pull/11).
- SharedUI: 875dc1d87c23fb771a43971b25bb874be94636a0 — [PR #8](https://github.com/NewDeriverius/MagicTheSortering-SharedUI/pull/8).
- Companion: 52e234ce76e24ef8fa97a3ab03c66a77a51b66cb — [PR #8](https://github.com/NewDeriverius/MagicTheSortering-Companion-App/pull/8).
- Releases: [PR #1](https://github.com/NewDeriverius/MagicTheSortering-Releases/pull/1), con el plan actualizado y este informe.

Los dos consumidores fijan SharedUI 875dc1d por gitlink publicado; no dependen de overrides locales. Todos los main se conservan.

## Cambios entregados

README de los cuatro repositorios actualizados: instalación/actualización, Windows/Linux/Docker/Android, rutas, certificados, autorización de navegador, backups, catálogo, importación .db/.mtsbackup, sincronización directa/reactiva, capacidades offline y límites reales. Se sustituyen las instrucciones obsoletas de sincronización e importaciones pendientes.

Web extrae los gates existentes a Build-ValidatedRelease.ps1 y conserva sus paquetes como artefactos, sin publicación independiente. Docker copia Search.Sqlite antes del restore; era una dependencia añadida en fase 2 que faltaba en la etapa de caché.

Companion coordina desde su repositorio privado para mantener allí el keystore. Consume plan, fuentes y SharedUI por SHA completo, comprueba los gitlinks, usa acciones fijadas por commit y valida ambos productos antes de agregar exactamente cinco paquetes, notas, manifiesto y SHA-256. Las versiones son independientes; el tag sigue Web para conservar el actualizador existente.

La APK se inspecciona después de firmar: identidad, versión, permisos, MAIN/LAUNCHER, icono, recursos, CSS, ausencia de depuración/datos y apksigner. No se cambia ApplicationId ni clave de firma. Las contraseñas usan env:.

El dry-run no expone el token de publicación. El publicador separado serializa ejecuciones, usa drafts y rechaza sobrescrituras. Los reintentos sobre los mismos bytes son idempotentes; los drafts interrumpidos solo se completan si coinciden los assets existentes. Una recompilación con bytes distintos exige otra versión/plan.

## Validación ejecutada

- Web Release: correcta, **0 errores y 0 advertencias**. Sin overrides: CI=true, UseLocalSharedUI=false.
- SharedUiIntegrationTests: **3/3** correctos contra el consumidor Web.
- Android Release: correcta, **0 errores**; persisten los **3 XA0033** conocidos al interpretar la versión del JDK local.
- Test-AndroidSyncPackage.ps1: correcto sobre la APK Release local; cubre manifiesto/permisos, actividad, recursos, icono, estilos y ausencia de datos/secretos. Esta APK local no acredita firma de producción ni actualización física.
- Contratos del agregador/publicador: **16/16** correctos en PowerShell, con archivos sintéticos aislados y CLI simulada. Incluyen versiones distintas, hashes alterados, archivos ajenos, paquetes faltantes, validación/procedencia incompatible, commits flotantes, protocolo, código Android, salida ya ocupada, publicación idéntica sin escrituras y recuperación de draft.
- actionlint **1.7.12**: correctos los dos workflows de distribución y el CI consumidor modificado. Binario oficial verificado por SHA-256.
- Scripts PowerShell: análisis sintáctico correcto; enlaces relativos de documentación revisados.
- Docker build local: correcto con la dependencia Search.Sqlite. Imagen magicthe-sortering:consolidation-phase7-dryrun, digest local sha256:090e3a6c234197d3a224f477ec324f1ba4322aca9735be3903a40a6cc4447ef0. No se inicia un contenedor ni se publica la imagen.
- No se ejecuta localmente la suite integral ni se utiliza ADB/datos personales en esta fase.

## Dry-run remoto y bloqueo

Se ejecutó workflow_dispatch con mode=dry-run, plan cabf04aeda8b186c01dbe0fdceb86078b0f0d840 y Companion da2233b8d0366c23a3d3f9e6cb58fd2dcb3a1734:

[Run 43008538405](https://github.com/NewDeriverius/MagicTheSortering-Companion-App/actions/runs/43008538405).

GitHub rechazó iniciar el runner con esta anotación:

> The job was not started because recent account payments have failed or your spending limit needs to be increased.

**Ningún paso del build se ejecutó; publish se omitió. No se generó un artefacto real conjunto.** No se interpreta este bloqueo como un fallo de tests ni se da el pipeline por validado de extremo a extremo.

El plan de esta PR se ha actualizado a los commits finales posteriores de documentación/artefactos indicados arriba. Para repetirlo cuando el titular reactive los runners:

~~~powershell
# Desde el checkout Releases, rama integration/joint-distribution limpia y publicada.
$planCommit=git rev-parse HEAD
gh workflow run release.yml --repo NewDeriverius/MagicTheSortering-Companion-App --ref integration/consolidation -f plan_commit=$planCommit -f mode=dry-run
~~~

Si las ramas han avanzado, actualizar primero el plan para que Companion coincida con el commit seleccionado. No reintentar el run antiguo para validar los commits finales.

## Manifiesto de ejemplo

[examples/distribution-manifest.example.json](../examples/distribution-manifest.example.json) se genera con New-Distribution.ps1 desde las mismas fixtures de las 16 regresiones. **Es sintético:** versiones 1.2.3-beta / 0.8.1, commits a/b/c/e repetidos y huella d repetida; los hashes corresponden a textos de prueba, no a paquetes instalables.

Para regenerarlo desde Companion:

~~~powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Test-DistributionContracts.ps1 -ExampleManifestPath C:\RUTA\MagicTheSortering-Releases\examples\distribution-manifest.example.json
~~~

## Pendiente antes de aprobar una entrega

Restablecer disponibilidad de runners y completar el dry-run con cinco paquetes reales, firma persistente y artefacto agregado descargable; verificar lectura de Web/SharedUI con el token configurado y cuota de artefactos. Su retención es de un día y el fallo de subida bloquea publicación. No se han cambiado secretos ni facturación.

La fase 8 debe validar ejecución nativa Linux x64/ARM64, experiencia integral, compatibilidad y actualización Android con APK de producción conservando datos. El build cruzado y las pruebas físicas Debug anteriores no acreditan esa actualización.

El plan actual usa v0.9.9-beta, que ya existe públicamente: sirve para dry-run y **no debe publicarse encima**. Preparar una versión Web nueva y un versionCode Android creciente antes de una futura publicación autorizada. El código impide reemplazar la release antigua si difieren assets, notas o procedencia.
