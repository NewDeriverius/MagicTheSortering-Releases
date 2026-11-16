# Distribución conjunta 1.0.3

Publicación autorizada por el usuario después de corregir xUnit2029 y comprobar el CI. El plan fija los commits integrados de Web y Companion y el mismo gitlink SharedUI publicado. Las versiones visibles son 1.0.3 y Android versionCode 10003; protocolo 1/1.

Contenido: navegación compartida de Almacenaje (#15), imagen local configurable de Inicio (#9), corrección de legalidades (#13) y reparación del analizador de pruebas de SharedUI. Las evidencias previas del hotfix local no se presentan como validación física nueva de esta release.

La publicación utiliza `release.yml` de Companion, desde su main integrado, con `plan_commit` inmutable de este repositorio y `mode=publish`. El coordinador compila y valida ambos productos antes de publicar los paquetes y el tag público. No se crean tags manuales ni se modifican certificados, keystores, secretos, ApplicationId o reglas del protocolo.

Integración: SharedUI primero; Web y Companion después de sus comprobaciones; por último este plan. El publish se ejecuta una vez sobre las revisiones del plan. Si falla un job, se diagnostica ese fallo y se reutilizan artefactos validados cuando el flujo lo permita; no se lanzan compilaciones duplicadas por defecto.
