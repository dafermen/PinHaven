# Privacidad, almacenamiento y recuperación

## Alcance de «local»

El directorio se guarda en el contenedor privado de la app, con SwiftData y CloudKit `.none`. No hay servidor propio, cuenta, analítica ni publicidad. No se guarda historial de movimiento ni se pide permiso de ubicación en segundo plano.

El servicio Core Location se solicita cuando el usuario toca «Usar mi ubicación actual». El resultado se muestra en el borrador; se persiste solamente cuando pulsa Guardar. La precisión es aproximada y puede variar por señal o permiso reducido.

## Respaldos del sistema

La app marca su carpeta privada de Application Support con `isExcludedFromBackup = true` y solicita protección completa de archivos al crearla. Se reaplica el atributo antes de abrir la base. Desactivar CloudKit por sí solo no habría excluido un respaldo del iPhone.

La exclusión y protección deben verificarse en un dispositivo real, incluidos archivos auxiliares SQLite, cierre/reapertura y actualizaciones. Apple limita el propósito de ese atributo y advierte sobre su uso en documentos del usuario: se ha aplicado a una carpeta privada de soporte y no a los archivos exportados. Esta decisión de producto debe revisarse antes de distribución. **No se presenta como garantía ya comprobada de que el sistema nunca copie ningún dato.**

Si la exclusión estricta no puede demostrarse en los dispositivos admitidos, corregir la implementación y ajustar la comunicación antes de anunciar «nunca se respalda en nube». Revisar también políticas del dispositivo administrado cuando corresponda.

## Servicios externos por acción

| Acción | Datos que pueden salir del dispositivo |
|---|---|
| Consultar lista, filtrar o editar | La app no necesita enviar el directorio |
| Cargar mapa y buscar con MapKit | Solicitudes de mapa, consulta y región al servicio de Apple |
| Abrir indicaciones | Coordenadas de destino a la app o sitio de mapas elegido |
| Compartir sitio | Nombre, dirección y enlace elegidos a la aplicación receptora |
| Exportar respaldo | Todos los sitios al destino de archivo elegido por el usuario |

No se utiliza Google Places ni se descarga información de Google en esta versión. Los enlaces de Google Maps son solamente URLs de apertura/compartición. Las notas no se incluyen en compartir sitio por defecto, pero sí están en el respaldo completo.

## Respaldo manual

Desde Ajustes → Datos y privacidad → Exportar todos los sitios. Elegir «En mi iPhone» o unidad local para evitar que el propio usuario lo coloque en iCloud Drive u otro proveedor. La app no puede prometer privacidad de un archivo enviado a WhatsApp o guardado por el usuario en un proveedor externo.

Formato JSON legible, **sin cifrado propio**. No incluirlo en Git ni enviarlo a soporte sin retirar datos privados. El cifrado de respaldos con contraseña es una mejora pendiente y exige diseño de recuperación y gestión de claves.

## Pérdida y eliminación

Desinstalar o perder el iPhone puede eliminar la única copia. Mantener respaldo manual en un medio adecuado. Eliminar un sitio borra el registro de la base; no implica borrado forense de SQLite, de respaldos previos ni de mensajes ya compartidos.

## App Store

El manifest inicial declara ausencia de tracking y recopilación propia; debe auditarse junto con el comportamiento real y las futuras APIs/dependencias antes de publicar. No equivale a una aprobación de Apple. Faltan URL de soporte, política pública final y declaraciones de privacidad en App Store Connect.

## Sugerencias de dirección (2026-11-04)

Mientras se escribe en el campo dirección (desde tres caracteres), el texto se consulta con MapKit de Apple para mostrar sugerencias. Si ya hay un punto en el borrador se usa como preferencia regional. Elegir una sugerencia solicita a MapKit el punto y la dirección postal. Requiere conexión; no se añade un servidor propio ni Google Places. El formato postal usa Contacts solo como formateador, sin leer contactos ni pedir permiso de contactos.

Compartir sitio entrega el enlace por coordenadas a la aplicación elegida. Copiar dirección y enlace incluye también el nombre y dirección. Abrir Google Maps o la alternativa web envía el destino a Google por acción explícita.

## Referencia cercana para direcciones

Buscar direcciones cerca de mí solicita GPS una vez por acción del usuario. Se mantiene como referencia temporal del editor y se pasa como región a MapKit; no mueve ni guarda el sitio y no activa seguimiento. Se cancela al cerrar el editor. La descripción del permiso incluye este uso y se puede buscar sin permiso indicando ciudad/ZIP.

## Contenido compartido con mensajería

Compartir con otras apps envía nombre, dirección y enlace del punto, como texto, a la aplicación que el usuario elija. No incluye notas privadas ni envía automáticamente a un destinatario. PinHaven no recibe confirmación de entrega de WhatsApp.

## Recibir desde Maps — 2026-11-05

Compartir hacia PinHaven es una acción explícita. La extensión recibe el URL/texto elegido, puede consultar redirecciones HEAD en los hosts de mapas permitidos y puede usar MapKit si eliges buscar/corregir el punto. No descarga ni analiza HTML, no envía a un servidor propio y no usa cookies ni credenciales en la sesión de resolución. No acepta enlaces de seguimiento de ubicación en tiempo real como un punto exacto.

La bandeja local de App Group puede contener nombre, dirección, notas y coordenadas confirmadas; se protege y excluye de backups automáticos. La app principal y su extensión son los únicos targets de este proyecto autorizados a ese grupo. Abrir la app importa los pendientes a SwiftData; exportar JSON solo incluye los registros importados. El cierre de la extensión no significa que la app ya haya importado la entrada. Sin iCloud ni seguimiento continuo.

## Consulta textual recibida de Google Maps

Si el enlace compartido identifica el lugar mediante nombre y dirección sin coordenadas, la extensión consulta automáticamente ese texto con MapKit para mostrar candidatos que el usuario debe confirmar. No se consulta Google Places ni se analiza HTML. El enlace no se guarda como lugar hasta confirmar un punto.

## Dirección aproximada del pin

Sugerir dirección de este punto envía las coordenadas del pin a la geocodificación de Apple por acción explícita. No obtiene GPS nuevo ni requiere acceso a contactos; el formateador Contacts no lee la agenda. No se añade backend, Google Places ni seguimiento. Las sugerencias al escribir consultan MapKit con texto y región del sitio; solo se guardan tras la confirmación del usuario.
