# Plan de pruebas

## Estado de la evidencia

No se dispone de Swift, Xcode ni SDK iOS en el entorno que generó esta entrega. **XCTest y la compilación iOS no se han ejecutado.** Hay verificación de estructura del repositorio, sintaxis de scripts Python, plist/XML, archivos referenciados, reproducibilidad del proyecto y referencias documentales. Ver reporte generado en `VALIDACION_ESTRUCTURAL.txt`.

## Automatizadas preparadas

`PinHavenTests/PinHavenTests.swift` contiene siete pruebas: rangos y nombres; búsqueda sin tildes; enlaces y hosts no admitidos; destino compartido; JSON válido/corrupto/versiones/duplicados; restauración sin sobrescribir; persistencia de disco tras reabrir contenedor.

En Mac ejecuta `bash scripts/test_ios.sh`. El script selecciona un iPhone Simulator disponible y ejecuta `xcodebuild test`. También puedes usar ⌘U. Asegúrate de tener un runtime iOS compatible con iOS 17+. El workflow de GitHub Actions ejecutará el mismo script en macOS cuando se suba el repositorio. Ese workflow todavía no tiene un resultado real.

## Matriz manual

Todos los casos siguientes están **pendientes** hasta ejecutarse en Mac/iPhone.

| ID | Preparación y acción | Resultado esperado |
|---|---|---|
| M01 | Primera apertura sin sitios | Mensaje inicial y botón para guardar |
| M02 | Crear nombre y coordenadas 0,0 | Guarda y muestra punto; no trata cero como ausencia |
| M03 | Nombre vacío o espacios | No guarda |
| M04 | Latitud 91, longitud 181, texto o campos vacíos | Error claro, sin registro inválido |
| M05 | Guardar, cerrar forzadamente y reabrir | Datos conservados |
| M06 | Editar y cancelar | El original no cambia |
| M07 | Editar y guardar | Cambios persistidos y lista actualizada |
| M08 | Borrar y cancelar; luego confirmar | Conserva en primer caso; elimina en segundo |
| M09 | Buscar CAFÉ como cafe, término en nota y etiqueta | Encuentra el mismo registro |
| M10 | Combinar favorito, categoría y texto | Mismos resultados en mapa/lista |
| M11 | GPS no determinado, conceder permiso | Punto y precisión aproximada; no guardar sin revisión |
| M12 | GPS denegado/restringido | Mensaje y captura manual utilizable |
| M13 | GPS aproximado o señal baja | Precisión visible y posibilidad de corregir |
| M14 | Solicitud sin fix durante 25 segundos | Mensaje de timeout y posibilidad de reintentar |
| M15 | Buscar dirección con red; seleccionar | Datos revisables antes de guardar |
| M16 | Buscar sin red | Error; datos previos intactos |
| M17 | Pegar enlaces admitidos, corto, malicioso y viewport | Solo extrae puntos explícitos admitidos; no solicita red |
| M18 | Compartir con WhatsApp instalado | Selector disponible, texto y punto correcto; no incluye notas |
| M19 | Google Maps instalado y sin instalar | App o navegador abre destino; no se exige Google SDK |
| M20 | Abrir indicaciones Apple Maps | Destino coincide con coordenadas guardadas |
| M21 | Exportar e importar a instalación de prueba vacía | Todos los sitios recuperados |
| M22 | Importar dos veces y UUID existente editado | Segunda importación no duplica ni sobrescribe |
| M23 | JSON malformado, versión desconocida o coordenada inválida | Rechaza sin importación parcial |
| M24 | Cancelar importación/exportación | Datos intactos |
| M25 | Modo avión con registros existentes | Consultar, buscar, editar y favoritos operativos; no exigir mapas |
| M26 | VoiceOver y tamaño de letra grande | Acciones identificables y contenido usable |
| M27 | Reiniciar dispositivo, desbloquear y abrir | Base abre; no requiere borrar datos |
| M28 | Inspeccionar configuración local y backup en dispositivo de prueba | Sin CloudKit; exclusión de carpeta aplicada y efecto comprobado |
| M29 | Probar fallo de guardado en un entorno de prueba | Error visible; rollback sin reportar éxito |
| M31 | Ejecutar toda la interfaz en inglés y español | Etiquetas, permisos, errores y accesibilidad traducidos; datos del usuario intactos |
| M30 | Migración de versión futura usando copia 0.1 | Solo para F2; preservar todos los datos |

## Registro de resultados

Para cada ejecución anota fecha, commit, versión de Xcode, iOS, dispositivo, ID de caso, resultado, pasos y error. No publiques coordenadas personales ni respaldos reales en issues. Si se encuentra un fallo, crea tarea con reproducción y vuelve a ejecutar los casos afectados después del arreglo.

## Puerta de salida del MVP

Build y siete pruebas verdes en Xcode; M01–M29 y M31 aceptados o excepciones justificadas; copia local de recuperación comprobada; ningún fallo que pierda datos; privacidad real coherente con lo anunciado. App Store tiene además su propia fase de preparación, firma y revisión.

## Regresión: direcciones y Google Maps (2026-11-04)

1. Escribir una dirección de prueba con ciudad o ZIP. Elegir una sugerencia: comprobar calle, ciudad/estado/ZIP cuando estén disponibles y pin en el mapa. Guardar y reabrir; coordenadas y texto deben persistir juntos.
2. Escribir una calle común sin ciudad: comprobar desambiguación con subtítulos. Si no hay un único punto, usar búsqueda de mapa; nunca elegir silenciosamente un candidato.
3. Editar rápidamente el texto durante una resolución y cerrar/cancelar el editor: ninguna respuesta antigua debe reemplazar el borrador ni guardar datos.
4. Probar sin internet y resolución fallida: mensaje recuperable; el registro guardado permanece intacto. Recuperar conexión y volver a elegir una sugerencia.
5. Seleccionar un punto manual y guardar sin dirección: sigue permitido. Una edición meramente textual no debe mover el punto.
6. Con Google Maps instalado: Ver punto y Cómo llegar deben apuntar al mismo destino guardado. Repetir sin Google Maps instalado y con Abrir Google Maps en la web. Probar coordenadas negativas y 0,0.
7. Compartir sitio a Mensajes/WhatsApp y abrir el enlace recibido; al compartir hacia Google Maps se entrega un URL y no una consulta con nombre+dirección+enlace. Copiar dirección y enlace conserva los tres elementos.
8. Ejecutar los nueve XCTest con `bash scripts/test_ios.sh`. Los dos nuevos verifican formato postal y construcción/decodificación de enlaces; no sustituyen las pruebas reales de MapKit ni Google Maps.

Usar datos públicos de prueba; no adjuntar ubicaciones personales a logs ni casos de prueba.

## Regresión: referencia GPS y menú de compartir

- Crear un sitio sin coordenadas, escribir una dirección parcial y pulsar Buscar direcciones cerca de mí: aceptar permiso, verificar zona/precisión y renovación de sugerencias sin reescribir; el punto del sitio sigue vacío hasta seleccionar una sugerencia.
- Editar un sitio en otra ciudad: pedir GPS cercano no debe mover el punto guardado ni cambiar su dirección. Cancelar conserva el registro.
- Rechazar permiso o esperar timeout: mensaje recuperable y posibilidad de buscar con ciudad/ZIP o mapa. Sin coordenadas no se presume 0,0.
- Desactivar Priorizar direcciones cercanas: buscar una dirección de otra ciudad; reactivar usa la referencia local. Probar iOS 17 (preferencia) y 18+ (región requerida).
- Compartir sitio debe mostrar Google Maps siempre en el menú de PinHaven. Abrir ubicación y Cómo llegar usan el punto guardado; sin app instalada se usa enlace universal. Compartir con otras apps abre la hoja de iOS y no garantiza que Google Maps aparezca en ella.
- Ejecutar los diez XCTest de esta revisión y comprobar sugerencias/GPS con datos públicos en dispositivo real.

## Revisión de interfaz más reciente: compartir directo y sugerencias visibles

Estos criterios reemplazan el menú de compartir propuesto en las secciones anteriores:

1. Tocar Compartir con otras apps en la ficha abre la hoja nativa de iOS directamente, sin menú de PinHaven intermedio. Google Maps y copiar aparecen una sola vez en la ficha.
2. Copiar dirección y enlace: pegar y comprobar contenido; aparece Enlace copiado durante dos segundos. Repetir rápidamente debe mantener el aviso dos segundos desde la última pulsación. VoiceOver anuncia la confirmación. El aviso no bloquea otros botones.
3. Con teclado abierto y una dirección parcial, las sugerencias van inmediatamente después del campo, sin textos largos entre ambos. Probar pantalla pequeña, texto grande y VoiceOver. Elegir una sigue actualizando dirección y punto.
4. Priorizar direcciones cercanas permanece visible antes del campo. Buscar cerca de mí mantiene su función. Zona de búsqueda y ayuda empieza cerrada y al abrirla permite consultar referencia, precisión y explicaciones.

## Compartir texto con WhatsApp: prueba de integración pendiente

- Pulsar Compartir con otras apps: se abre directamente la hoja de iOS. Elegir WhatsApp, destinatario y Enviar. Comprobar dentro del chat que aparece nombre, dirección y enlace, y comprobar recepción con el destinatario.
- Probar dirección vacía, nombre con tildes/emoji, dirección con varios renglones y coordenadas negativas. El enlace debe abrir el punto correcto y no deben incluirse notas privadas.
- Cancelar desde la hoja y desde WhatsApp: no mostrar éxito ni error ficticio; la ficha y los datos permanecen intactos.
- Si iOS reporta error, comprobar aviso después de cerrar la hoja y usar Copiar dirección y enlace. Si WhatsApp muestra reloj o pendiente, comprobar conexión/envío dentro de WhatsApp; el callback de la hoja no confirma entrega.
- Probar también Mensajes u otra app receptora. La prueba efectiva de envío la realiza el propietario con un destinatario elegido; Windows no reproduce WhatsApp iOS.

## Recepción Google Maps → PinHaven (F3)

- Instalar sobre la versión anterior y comprobar sitios existentes antes y después. No borrar app/base.
- Verificar PinHaven en Compartir de Google Maps, Apple Maps y Safari con URL y con texto. Si no aparece, revisar Más, activation rule y embedding.
- Revisar nombre/categoría/notas y pin, guardar, volver a Google Maps y abrir PinHaven: importar una vez. Abrir de nuevo: sin duplicados. Cancelar: sin entrada nueva.
- Probar enlace explícito, !3d/!4d, solo viewport, enlaces cortos, IDs sin coordenadas, sin internet, hosts no permitidos y contenido ambiguo. Pedir punto manual sin inferir negocio desde viewport. Una búsqueda prellenada no se selecciona automáticamente.
- Simular cierre entre guardado y retirada de entrada, entrada corrupta y perfil sin grupo: preservar datos y dar error recuperable. Los XCTest incluyen fixtures de parser/redirecciones y persistencia de bandeja.
- Revisar Test/Archive en Cloud, grupo habilitado en ambos perfiles, extensión incluida y versiones de bundles coherentes. La prueba de simulador sin firma no confirma aprovisionamiento ni aparición en Google Maps real.

Instrucciones paso a paso en [Recibir desde Maps](13_RECIBIR_DESDE_MAPS.md).

## Regresión q=nombre+dirección sin coordenadas

Compartir desde Google un negocio que devuelva q textual y ftid: ver nombre legible sin +, candidatos con dirección, elegir uno, comprobar pin y guardar. Sin elegir ningún candidato Guardar sigue desactivado. Probar resultados vacíos, sin red, cancelar búsqueda y selección manual. Confirmar que C%2B%2B se mantiene C++ y un centro @lat,lon/ftid nunca se convierte en punto. Las pruebas automatizadas usan texto ficticio.
