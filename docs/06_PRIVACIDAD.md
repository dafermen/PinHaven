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
