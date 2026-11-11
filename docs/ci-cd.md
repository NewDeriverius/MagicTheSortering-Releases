# CI/CD — distribución conjunta

## Responsabilidades

El coordinador único es release.yml de Companion (repositorio privado). El workflow homónimo de Web construye y valida sus paquetes, pero ya no publica. Los tags individuales no publican una distribución conjunta. Releases contiene documentación, plan y notas públicos, nunca las fuentes privadas ni secretos.

La coordinación permanece en Companion para mantener el keystore donde ya existe. El checkout adicional de Web se limita a esta distribución: los tests ordinarios de Web no requieren acceso a Companion.

## Plan reproducible

En la rama integration/joint-distribution de Releases se guarda distribution/plan.json:

- schemaVersion: 1.
- distributionVersion: versión SemVer del conjunto; coincide con Web para no alterar su comprobador de actualizaciones basado en tags.
- web / companion: versión **independiente** y SHA completo del producto.
- companion.androidVersionCode: entero explícito creciente (1–2100000000). No reutilizar un código para una nueva actualización, aunque no cambie la versión visible.
- sharedUI.commit: SHA completo que debe coincidir con ambos gitlinks y checkouts.
- protocol.minimum / maximum: actualmente 1/1, como SyncValidation.Version. No equivale a la versión de la aplicación ni del backup.

Publica primero SharedUI y actualiza ambos gitlinks; publica luego los commits consumidores. Solo entonces fija esos tres SHAs en el plan y confirma el commit de Releases que lo contiene. El workflow recibe **el SHA de ese commit del plan**, nunca una rama flotante. Las notas están en distribution/notes.md de la misma revisión y se redactan para el público; no se generan desde historiales privados.

La rama de Companion seleccionada al ejecutar debe resolver al SHA Companion registrado en el plan; el workflow lo comprueba antes de compilar. No hay dependencias de SharedUI.Local.props.

## Permisos y configuración

En Companion:

- GITHUB_TOKEN: únicamente contents:read.
- DISTRIBUTION_SOURCE_READ_TOKEN: token de alcance fino con Contents: Read sobre Web y SharedUI. Solo checkout y restauración; sin escritura. Si no existe, se prueba SHARED_UI_READ_TOKEN, que deberá permitir leer esos dos repositorios.
- ANDROID_KEYSTORE_BASE64, ANDROID_KEY_ALIAS, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_PASSWORD: los secretos persistentes existentes, sin rotarlos ni copiarlos a Web/Releases.
- PUBLIC_RELEASES_TOKEN: Contents: Read and write **solo** sobre NewDeriverius/MagicTheSortering-Releases. Se expone únicamente al job publish; el dry-run no lo recibe.

El destino público es fijo en el publicador. PUBLIC_RELEASES_REPOSITORY deja de decidir el destino de forma independiente; la variable antigua puede permanecer, pero ya no se usa en el flujo nuevo.

Las contraseñas Android se pasan mediante env:, no como valores en argumentos ni en archivos versionados. El keystore se decodifica en RUNNER_TEMP con nombre único y se retira en finally. [Propiedades oficiales de firma](https://learn.microsoft.com/en-us/dotnet/android/building-apps/build-properties#androidsigningkeypass).

## Dry-run

Desde una consola con GitHub CLI autenticada (no pegues credenciales en el chat):

~~~powershell
$planCommit='SHA_COMPLETO_DEL_COMMIT_PUBLICADO_EN_RELEASES'
gh workflow run release.yml --repo NewDeriverius/MagicTheSortering-Companion-App --ref integration/consolidation -f plan_commit=$planCommit -f mode=dry-run
~~~

El archivo release.yml ya existe en main, permitiendo probar la definición de la rama sin fusionarla. [Requisitos de workflow_dispatch](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).

La ejecución, en un único runner Windows limpio:

1. Descarga y valida el plan; comprueba commit Companion, gitlinks, estado limpio y protocolo.
2. Construye Web y conserva sus gates existentes: dominio, componentes, Playwright sobre publicación Release e integración. Ejecuta además SharedUI, búsqueda SQLite y JavaScript comunes.
3. Genera instalador Windows con Inno Setup 6, ZIP portable y tar.gz Linux x64/ARM64; inspecciona contenido y ausencia de datos/secretos.
4. Ejecuta Mobile.Tests, publica Release firmada con la identidad persistente y valida **esa APK final**: firma, versión, ApplicationId, permisos, HTML/JS, icono, CSS y ausencia de depuración.
5. Verifica procedencia y hashes de ambos productores; agrega exactamente cinco paquetes, RELEASE-NOTES.md, distribution-manifest.json y SHA256SUMS.txt.
6. Guarda un artefacto privado joint-distribution-RUN-ATTEMPT con retención de un día. La subida es obligatoria; si se agota cuota falla el proceso sin publicar nada. No se eliminan artefactos ajenos ni se usan releases públicas como almacenamiento temporal.

Compilar Linux desde Windows no certifica la ejecución nativa; el workflow Web network-platforms.yml mantiene sus validaciones Windows/Linux/ARM64, y la fase 8 debe revisar los resultados y ejecutar la validación integral. La prueba de actualización Android con la firma de producción sigue siendo una prueba física independiente.

Descarga el artefacto desde esa ejecución de Actions; no desde una release. Localmente:

~~~powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\RUTA\MagicTheSortering-Companion-App\scripts\Test-DistributionContracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File C:\RUTA\MagicTheSortering-Companion-App\scripts\Test-Distribution.ps1 -Path RUTA_EXTRAIDA -PlanPath RUTA_PLAN_JSON -PlanCommit SHA_COMPLETO_DEL_PLAN
~~~

Las pruebas de contrato usan archivos sintéticos aislados, no bases ni claves personales; distinguen la validación del agregador de una compilación real.

## Publicación futura (no ejecutada en fase 7)

Solo con autorización de publicación se repite el mismo comando con mode=publish y un plan de versión nueva. La ejecución vuelve a construir y validar **ambos** productos; no publica un subconjunto de resultados de workflows independientes.

El job publish depende del build completo y descarga el artefacto por su ID exacto, preservado al reintentar únicamente el job fallido. Verifica de nuevo hashes y procedencia. Crea primero una release **draft**, carga/verifica todos los bytes y solo después cambia a pública. El tag apunta al commit inmutable del plan en Releases. No publica repositorios fuente ni changelogs privados.

La concurrencia joint-public-distribution serializa todos los runs, sin cancelación de uno en curso. No usar los publicadores antiguos de main durante la transición: ambas PR deben integrarse por el usuario antes de habilitar publicaciones conjuntas.

## Idempotencia y fallos

- Sin --clobber ni sobrescrituras: una distribución publicada es inmutable.
- Reintentar la publicación con **los mismos bytes y el mismo plan** no cambia una release idéntica.
- Un draft interrumpido admite completar assets faltantes solo si todos los ya existentes coinciden; una diferencia de SHA, notas, tag o nombres bloquea la operación.
- Recompilar no garantiza bytes idénticos (compresión, timestamps y toolchain); si los hashes cambian, no reemplazar una publicación. Usar una nueva versión/plan. Las revisiones fuente sí son inmutables.
- Un fallo de firma, tests, upload, cuota o verificación impide que el flujo pase a publicar. Un fallo remoto durante publicación deja el draft sin exponerlo como release completa.
- Los drafts ajenos o assets inesperados se rechazan; no se borran automáticamente.

SHA-256 acredita integridad frente al manifiesto descargado, no sustituye una firma ni un canal de confianza. Android conserva su certificado; Windows todavía no dispone de Authenticode. El manifiesto incluye huella pública de firma APK, versiones, commits, SharedUI, protocolo, checks ejecutados y hashes de los cinco paquetes y notas.

## Evidencia de preparación

[Resultados y limitación de facturación](phase-7-validation.md). El dry-run remoto no inició el runner; el ejemplo de manifiesto es sintético y no acredita una distribución real. Las acciones externas de los workflows nuevos están fijadas por SHA completo.
