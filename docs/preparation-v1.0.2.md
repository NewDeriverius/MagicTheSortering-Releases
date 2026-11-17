# Preparación de la distribución 1.0.2

Este plan prepara la futura compilación; no representa una release ya publicada. El usuario revisará CI y fusionará manualmente las PR. No se han lanzado workflows de distribución desde esta preparación.

Orden: SharedUI, Web y Companion, y por último el plan de Releases. Ambos consumidores fijan el mismo commit SharedUI publicado, sin overrides locales. Las revisiones del plan son inmutables y corresponden a las candidatas revisadas; si squash/rebase cambia los commits al integrar, actualizar el plan y comprobar los gitlinks antes de solicitar la compilación.

La versión visible es 1.0.2 en Web y Companion, con Android versionCode 10002. El protocolo sigue en 1/1. No se han cambiado secretos, keystore, ApplicationId ni las comprobaciones de firma y procedencia existentes.

Antes de publicar, tras la solicitud del usuario: ejecutar el proceso coordinado existente, validar el conjunto y comprobar instalador Windows, portable Windows, Linux x64/ARM64, APK firmada oficial, SHA-256, manifiesto y notas. Verificar actualización desde las versiones públicas anteriores y descubrimiento de la nueva release. Las APK locales de prueba no sustituyen esa validación de producción.
