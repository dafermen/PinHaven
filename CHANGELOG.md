# Cambios

## Icono de aplicación para distribución — 2026-11-03

Añadido AppIcon de 1024×1024 RGB opaco al catálogo de recursos y seleccionado en Debug/Release. Generador actualizado y validaciones de formato y pertenencia al target para evitar volver a exportar una app sin icono. Aceptación de App Store Connect pendiente de nuevo build.

## Identidad de firma para Xcode Cloud — 2026-11-03

Sincronizados proyecto y generador con com.innovalogic.pinhaven y el Team seleccionado por el propietario; tests con sufijo .tests. Registrado Archive remoto aprobado y exportaciones fallidas del Build 1 por identificador de ejemplo. Nueva ejecución Cloud pendiente.

## Primera compilación y XCTest aprobados — 2026-11-03

Ejecución desde Terminal confirmada mediante xcresult: build y siete pruebas aprobados con Xcode 15.2 e iPhone SE (3rd generation), iOS 17.2. F1-T08 aprobada; aceptación manual y localización pendientes. README actualizado con el entorno comprobado.

## Diagnóstico inicial Mac — 2026-11-03

El script de pruebas conserva los fallos de CoreSimulator sin añadir un traceback JSON; comprueba Python 3 y respuestas inválidas. Cuatro escenarios de control del script verificados con herramientas simuladas. Registrada validación estructural y los bloqueos reales de CoreSimulator/macros SwiftData en el entorno restringido; build y XCTest continúan pendientes.

## Preparación Windows/Mac — 2026-11-02

Importación de la base 0.1.0; guía para Windows, Mac y Xcode Cloud; reglas del repositorio, UTF-8/LF y exclusión de credenciales. Generador y validador adaptados a Windows con rutas POSIX y el mismo intérprete Python. Funciones iOS y localización pendientes de validación en Mac.


## Actualización de identidad — 0.1.0, no publicada

Nombre elegido: **PinHaven**. Documentación, archivos, targets, esquema Xcode, identificadores de ejemplo y rutas actualizados. Inglés establecido como idioma principal y español como opción inicial; localización de interfaz pendiente en F1-T10. No implica reserva del nombre ni publicación en App Store.

## 0.1.0 — 2026-10-31 — implementación inicial, no publicada

Agenda local SwiftData; captura GPS, selección y búsqueda MapKit; fichas con notas, etiquetas, categoría y favorito; búsqueda/filtros; lista/mapa; compartir y abrir indicaciones; lectura limitada de enlaces; exportación/importación JSON. Proyecto Xcode, pruebas preparadas y documentación en español para estudiantes. Compilación y aceptación iOS pendientes.

## Direcciones y apertura de mapas — 2026-11-04

Sugerencias MapKit en el campo dirección; resolución explícita con cancelación y límite de 15 segundos. Al elegir un resultado se actualizan coordenadas y dirección postal, incluida ciudad/estado/ZIP cuando el proveedor los devuelve. La selección de mapa usa el mismo formateador. No cambia la base ni el formato del respaldo.

Google Maps: coma codificada en URLs, apertura directa de la aplicación con fallback universal, acciones separadas para ver el punto y calcular ruta y alternativa web. Compartir sitio entrega un URL, evitando enviar texto completo a una aplicación de mapas como consulta. Copiar dirección y enlace conserva el formato de texto.

Dos casos XCTest nuevos para enlaces/coordenadas y dirección postal. Comprobación estructural aprobada en Windows; compilación y nueve XCTest de esta revisión pendientes de Mac/CI. No se confirma una causa única del error mostrado en Google Maps.

## Búsqueda cercana y compartir a Google Maps — 2026-11-04

Botón Buscar direcciones cerca de mí: obtiene GPS puntual independiente del punto del sitio, actualiza las sugerencias sin volver a escribir y muestra la zona usada. Interruptor para buscar cerca o en otra ciudad. Región de 40 km de lado aplicada también a la resolución; iOS 18+ con SDK compatible exige la región, iOS 17 la usa como referencia. Sin referencia no se presupone una ubicación.

Compartir sitio abre un menú propio con Google Maps, indicaciones, compartir con otras apps y copiar enlace. No depende de que Google Maps publique una extensión en la hoja de iOS. Prueba adicional de región, diez XCTest preparados. Compilación/pruebas de esta revisión pendientes de CI; la revisión anterior 3bf4119 aprobó GitHub Actions.

## Ajustes de interfaz por revisión en iPhone — 2026-11-04

Compartir con otras apps abre directamente la hoja de iOS; se elimina el menú intermedio y sus acciones duplicadas. Google Maps y copiar quedan una sola vez en la ficha. Copiar muestra Enlace copiado durante dos segundos y lo anuncia con VoiceOver; repetir reinicia el aviso.

Las sugerencias aparecen justo bajo el campo dirección. Priorizar direcciones cercanas se conserva arriba del campo; el GPS y la ayuda quedan después de resultados, con explicaciones en un desplegable cerrado inicialmente. Sin cambios de almacenamiento ni geocodificación.
