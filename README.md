# Magic The Sortering — distribuciones

Descargas oficiales de **Magic The Sortering Web** y **Companion Android** para gestionar tu colección, almacenaje y mazos.

Elige una [release publicada](https://github.com/NewDeriverius/MagicTheSortering-Releases/releases) y consulta sus notas antes de instalar o actualizar. Descarga los paquetes y sus hashes desde la misma release.

Consulta las [notas de versión de 1.0.3](distribution/notes.md). La disponibilidad de cada paquete se indica en la página de descargas de su release.

## Paquetes de una distribución conjunta

- MagicTheSortering-Setup-WEBVERSION-win-x64.exe: instalador Windows x64, servicio y onboarding.
- MagicTheSortering-WEBVERSION-win-x64-portable.zip: binarios Windows autocontenidos, sin instalador.
- MagicTheSortering-WEBVERSION-linux-x64.tar.gz: paquete con scripts de instalación systemd.
- MagicTheSortering-WEBVERSION-linux-arm64.tar.gz: equivalente para Linux ARM64/aarch64 con glibc.
- MagicTheSortering-Companion-ANDROIDVERSION.apk: Android API 24 o superior, firmada con la identidad persistente.
- distribution-manifest.json: versiones independientes, commits exactos, revisión SharedUI, protocolo, huella pública de firma APK y hashes.
- SHA256SUMS.txt y RELEASE-NOTES.md: integridad y notas públicas.

WEBVERSION y ANDROIDVERSION pueden ser diferentes. Consulta las versiones y la compatibilidad declaradas en el manifiesto de la descarga.

## Verificar antes de instalar

Descarga los hashes, manifiesto y notas de la misma release que el paquete.

~~~powershell
Get-FileHash .\MagicTheSortering-Companion-ANDROIDVERSION.apk -Algorithm SHA256
~~~

Compara el resultado completo con la entrada del mismo nombre en SHA256SUMS.txt y distribution-manifest.json. En Linux, si has descargado todos los archivos referenciados:

~~~bash
sha256sum -c SHA256SUMS.txt
~~~

Un hash detecta corrupción o cambios respecto a la lista; no sustituye la confianza en el canal de descarga ni una firma. Android verifica además el certificado de la APK. El instalador Windows aún no dispone de Authenticode; puede mostrar SmartScreen. No se incluyen bases personales, catálogos, certificados TLS de instancia, contraseñas ni keystores.

## Windows

Ejecuta Setup como administrador y abre el onboarding desde el menú Inicio. Instala el servicio MagicTheSortering y guarda datos/configuración en %ProgramData%\MagicTheSortering. El ZIP portable se extrae en una carpeta nueva; antes de ejecutar, selecciona una carpeta de datos propia:

~~~powershell
$env:DOTNET_ENVIRONMENT='Production'
$env:InstancePaths__DataRoot=Join-Path $env:LOCALAPPDATA 'MagicTheSortering'
.\MagicTheSortering.Web.exe
~~~

Para actualizar el servicio, instala el nuevo Setup conservando rutas y datos. En portable, detén el proceso, cambia los binarios y conserva DataRoot. No copies bases ni PKI desde otra instancia.

## Linux x64 / ARM64

Comprueba uname -m: x86_64 usa x64, aarch64 usa ARM64. Los paquetes requieren glibc y systemd; no son para Alpine/musl ni ARM de 32 bits.

~~~bash
tar -xzf MagicTheSortering-WEBVERSION-linux-arm64.tar.gz
cd MagicTheSortering-WEBVERSION-linux-arm64
sudo bash ./install.sh
systemctl status magicthe-sortering
~~~

El instalador mantiene /opt/magicthe-sortering (binarios), /var/lib/magicthe-sortering (datos) y /etc/magicthe-sortering (configuración). Revisa los puertos en el firewall. Actualiza con el nuevo paquete y el mismo install.sh; no elimines /var/lib ni /etc.

## Primera conexión y Docker

El servicio genera su identidad y CA de instancia al primer arranque. Abre http://localhost:8008/server en el host; comprueba la dirección/puertos mostrados y la confianza del certificado antes de usar HTTPS.

La primera autorización administrativa se genera en la consola del servidor con --create-admin-invitation y la misma configuración, rutas y conexión SQLite del servicio. El código caduca en diez minutos y se introduce en https://SERVIDOR:PUERTO/admin/setup. Ejecutar el navegador en el mismo equipo no le concede administración automáticamente.

Windows instalado:

~~~powershell
$env:DOTNET_ENVIRONMENT='Production'
$env:InstancePaths__DataRoot=Join-Path $env:ProgramData 'MagicTheSortering'
& 'C:\Program Files\MagicTheSortering\MagicTheSortering.Web.exe' --create-admin-invitation
~~~

Linux instalado:

~~~bash
sudo -u magicthe-sortering env DOTNET_ENVIRONMENT=Production \
  /opt/magicthe-sortering/MagicTheSortering.Web --create-admin-invitation
~~~

Docker: si ya dispones de una instalación, conserva el volumen `magic-the-sortering-data` al recrear el contenedor. No uses `docker compose down -v` para actualizar. Genera la primera invitación en la instancia existente con `docker compose exec app dotnet MagicTheSortering.Web.dll --create-admin-invitation`. Estas descargas no incluyen una imagen Docker; utiliza las instrucciones que acompañan a tu instalación para actualizarla.

## Companion y datos

Instala la APK descargada. Para actualizar, instálala encima (o adb install -r), con el mismo ApplicationId y certificado y un versionCode mayor; no desinstales ni borres almacenamiento. Una APK Debug no sustituye a una APK de producción.

En Configuración puedes importar catalog.db y, por separado, inventario SQLite .db o backup portable .mtsbackup del servidor. Se valida el contenido y se pide confirmación antes de sustituir inventario existente. No se reemplazan mazos locales, operaciones pendientes, preferencias ni catálogo al importar inventario.

En Web, un administrador genera la invitación temporal de emparejamiento. Companion puede leerla con el escáner modal o pegarla; verifica la huella HTTPS y solicita el inventario completo inicial. El catálogo se descarga separadamente. Los avisos SignalR y la recuperación por cursor permiten sincronización reactiva mientras la app está activa; sin red se conservan la consulta y edición local de mazos.

Una importación manual no es un snapshot sincronizado: exige volver a establecer la base completa antes de aplicar deltas. El cambio de certificado, instancia o Epoch requiere revisión explícita, sin mezclar colecciones automáticamente.

## Backups, compatibilidad y problemas

Antes de actualizar Web, exporta un .mtsbackup. Conserva además una copia protegida coherente de los directorios de datos/configuración para recuperar PKI, claves e identidad; el backup portable no contiene esos secretos. Una copia de archivos con SQLite activa puede ser inconsistente: detén el servicio o usa su backup.

La compatibilidad se declara por protocolo en el manifiesto: actualmente directo v1 (rango 1–1) y backup portable v1. No deduzcas compatibilidad de que las versiones visibles sean iguales. Las migraciones de Web pueden impedir volver a binarios anteriores sin restaurar una copia coherente.

Si falla la conexión: revisa servicio, /health, IP, puertos, firewall, certificado y autorización del navegador. Si Android rechaza una actualización, comprueba firma y versionCode; no borres tus datos para forzarla. El catálogo puede superar 1 GB y las imágenes no cacheadas pueden faltar offline.

## Recuperación y avisos desde 1.0.1

Web y Companion 1.0.1 consultan versiones estables oficiales. Web ofrece novedades, posposición e instrucciones de actualización por plataforma. Companion verifica manifiesto, SHA-256, paquete, versión y firma antes de abrir el instalador Android; requiere tus permisos y confirmación. Conserva datos y no instala en silencio.

Companion 1.0.0 no tiene ese código: instala manualmente la primera actualización con igual paquete y firma. Las compilaciones de pruebas con otro certificado necesitan un tratamiento compatible; no desinstales ni borres tu colección para forzar una APK oficial.

Después de restaurar una colección en otra Web, genera una invitación nueva y revisa la recuperación en Companion 1.0.1. Antes de adoptar Web se guarda una copia recuperable y se intentan integrar los cambios offline compatibles. Los incompatibles quedan en esa copia, con un resumen explícito. El protocolo sigue siendo v1; esta negociación requiere Web 1.0.1.
