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
