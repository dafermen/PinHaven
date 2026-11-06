# Estado real de la entrega 0.1.0

Fecha de referencia del proyecto: **31 de octubre de 2026**, hora de Nueva York. Nombre elegido por el propietario: **PinHaven**. Nombre de proyecto y esquema Xcode: `PinHaven`.

## Entregado

- Código fuente SwiftUI con SwiftData local; doce archivos de aplicación.
- Proyecto `.xcodeproj` listo para abrir, esquema compartido y generador reproducible sin dependencias externas.
- Un archivo XCTest con siete casos de lógica/persistencia preparados.
- Workflow macOS para compilar y ejecutar pruebas al subir a GitHub.
- Documentación de visión, requisitos, arquitectura, guía de estudiante, fases/tareas, pruebas, privacidad, GitHub y prompt de continuidad.
- Backlog CSV con identificadores, estado y dependencias, y plantillas de colaboración.

## Funciones con código

Crear/editar/borrar, GPS puntual, pin manual, búsqueda MapKit, lista/mapa, favoritos, categorías/etiquetas/notas, búsqueda, filtros, compartir por selector nativo, abrir mapas, lectura limitada de URL pegada y respaldo JSON.

## Nombre e idiomas

Documentación, carpeta, proyecto Xcode, targets, tests, generador, configuración y ejemplos de GitHub actualizados a PinHaven. Se mantiene el nombre en ambos idiomas. Inglés principal y español como opción están definidos; implementación de localización pendiente en F1-T10. Esta actualización cambia la identidad del proyecto y la especificación; no afirma que todos los textos del código inicial ya estén traducidos.

## Validación heredada del paquete original (Linux)

Verificación estructural automatizada de Python, XML/plist, esquema y referencias del proyecto, enlaces internos de documentación y correspondencia del backlog. El generador Xcode se ejecutó y su salida se verificó como reproducible. Ver `VALIDACION_ESTRUCTURAL.txt` en la raíz para el resultado concreto.

## Validación que falta

No hay Swift, Xcode, simulador ni SDK iOS en este entorno Linux. No se compiló el código Swift ni se ejecutó XCTest. La revisión estática y la estructura correcta no demuestran compilación. F1-T10 (idiomas), F1-T08 y F1-T09 siguen pendientes: build, siete pruebas, uso real, GPS, WhatsApp, accesibilidad, persistencia y exclusión de respaldos.

El paquete original no incluía un push. El 2 de noviembre de 2026 se publicó la base en https://github.com/dafermen/PinHaven, rama main, commit inicial bd8c0a6. No existe build firmado, IPA, TestFlight ni publicación App Store. La búsqueda pública preliminar no encontró una ficha con el nombre exacto; falta confirmar disponibilidad en App Store Connect. No se ha reservado el nombre. No se promete un proyecto libre de errores de compilación antes de abrirlo en Xcode.

## Próxima acción concreta

En un Mac: abrir `PinHaven.xcodeproj`, seleccionar simulador iPhone, pulsar ⌘R y luego ⌘U. Registrar Xcode/iOS y corregir hallazgos. Después ejecutar la matriz manual en iPhone físico. Si se quiere publicar el código, seguir `07_GITHUB_Y_COLABORACION.md` con el repositorio exacto del propietario.

## Preparación en Windows — 2 de noviembre de 2026

El ZIP de referencia se importó como base, sin activar por sus instrucciones nuevas fases del producto. Se adaptaron los scripts para rutas Windows/POSIX, UTF-8/LF y uso del intérprete Python actual; se añadió la guía Windows/Mac/Cloud. El repositorio remoto dafermen/PinHaven existe y es público; se encontró vacío al iniciar. El informe heredado de Linux corresponde al paquete original, no a esta sesión.

La evidencia actual se registra en VALIDACION_WINDOWS.txt. No se dispone de Swift, Xcode ni simulador iOS en Windows; compilación y XCTest siguen sin ejecutar. El backlog funcional conserva sus estados: la preparación de herramientas no equivale a aceptación de las funciones. Xcode Cloud no está configurado.

Resultado Windows: 93 comprobaciones estructurales aprobadas. Sintaxis Bash comprobada con Git Bash; analizador YAML no disponible. Proyecto Xcode reproducible. Base subida a origin/main; no se afirma resultado de GitHub Actions, compilación iOS ni XCTest.

## Primera validación Mac — 3 de noviembre de 2026

Entorno observado: macOS 13.7.8 (22H730), Xcode 15.2 (15C500b), SDK iOS Simulator 17.2. El README solicita Xcode 16 o posterior; solo se encontró Xcode 15.2 en /Applications. No se cambió el Xcode activo ni la configuración de firma.

- `python3 scripts/validate_repository.py`: 93 comprobaciones estructurales aprobadas; parser YAML no disponible.
- `bash scripts/test_ios.sh`: no inició XCTest. CoreSimulatorService rechazó la conexión incluso después de conceder acceso a sus carpetas de datos y logs.
- Compilación directa con `xcodebuild -project PinHaven.xcodeproj -scheme PinHaven -sdk iphonesimulator -configuration Debug -derivedDataPath /private/tmp/pinhaven-derived CODE_SIGNING_ALLOWED=NO build`: terminó con código 65. `sandbox-exec: sandbox_apply: Operation not permitted` impidió cargar el plugin de macros SwiftData; después aparecieron errores de macros y conformidad de Place. No se atribuyen esos diagnósticos derivados a defectos confirmados del modelo.
- Se corrigió el script para detenerse ante un fallo de simctl, conservar el diagnóstico original y evitar un traceback JSON secundario. También comprueba Python 3 y detecta respuestas JSON inválidas.
- Validación del script: sintaxis Bash aprobada y cuatro escenarios con herramientas simuladas aprobados (fallo de servicio, JSON inválido, sin iPhone y selección de iPhone disponible). Estos escenarios no ejecutan ni sustituyen XCTest.

F1-T08 continúa pendiente; F1-T09 y F1-T10 también. No hay compilación aprobada ni prueba funcional de la app. El proyecto generado y los archivos Swift no se modificaron.

Próximo paso: ejecutar `bash scripts/test_ios.sh` desde Terminal en la carpeta del proyecto, fuera del entorno restringido de esta sesión, y comprobar si CoreSimulator y las macros funcionan allí. Si falla también, abrir Xcode/Simulator y revisar instalación y runtime. Preparar un entorno que cumpla Xcode 16+ según README, comprobando antes sus requisitos de macOS. No se instaló ni actualizó software del sistema en esta sesión.

## Validación desde Terminal confirmada — 3 de noviembre de 2026

El propietario ejecutó `bash scripts/test_ios.sh` desde Terminal, fuera del entorno restringido, y obtuvo `** TEST SUCCEEDED **`. Se inspeccionó el resultado con `xcrun xcresulttool`, incluidos los estados individuales de las siete pruebas.

- Xcode 15.2 (15C500b), macOS 13.7.8; simulador iPhone SE (3rd generation), iOS 17.2.
- Build: succeeded. XCTest: 7 casos Success, sin fallos.
- Cobertura funcional de los casos: límites de coordenadas/nombres; búsqueda sin tildes ni mayúsculas; enlaces admitidos/no confiables; destinos compartidos; respaldo JSON y corrupción; importación sin sobrescribir; persistencia al reabrir el almacén.
- Ocho advertencias de build: `not stripping binary because it is signed`, correspondientes a bibliotecas de XCTest incluidas por Xcode.
- Evidencia local (ignorada por Git): `DerivedData/Logs/Test/Test-PinHaven-2026.11.03_08-55-15--0500.xcresult`.

F1-T08 queda aprobada para este entorno y revisión. Los bloqueos descritos en el intento anterior corresponden a la ejecución restringida del agente; no impidieron la ejecución desde Terminal. Esta evidencia confirma que la base actual compila y pasa XCTest con Xcode 15.2; no se necesita actualizar Xcode para reproducir este resultado concreto. F1-T09 (aceptación manual en iPhone real) y F1-T10 (localización) siguen pendientes. No implica validación de GPS real, permisos, accesibilidad ni publicación.

## Xcode Cloud: configuración y primer Archive — 3 de noviembre de 2026

El propietario completó la conexión de PinHaven a Xcode Cloud. Los artefactos de Build 1 muestran `ARCHIVE SUCCEEDED` con Xcode 27.2 y SDK iOS 27.2; las exportaciones fallaron al buscar perfiles y registrar `com.example.pinhaven`. El Archive descargado conserva ese identificador de ejemplo. No ejecutó XCTest.

La configuración local seleccionada en Xcode por el propietario usa `com.innovalogic.pinhaven` y Team `7799N4RYUG`. Se trasladaron esos valores al generador y se regeneró el proyecto; tests usa `com.innovalogic.pinhaven.tests`. Debug y Release conservan firma automática. La validación estructural posterior aprobó 93 comprobaciones y reproducibilidad. No se repitieron localmente build/XCTest tras cambiar identidad; la siguiente ejecución Cloud debe validar esta revisión.

La captura del editor de workflow muestra Test iOS con esquema PinHaven, Required to Pass, Use Scheme Setting y un destino, además de Archive. El propietario debe guardar el workflow; no hay evidencia todavía de una ejecución remota de los siete casos. Distribution Preparation se dejó en None en el editor para esta etapa. Sin resultado Cloud aprobado ni distribución/TestFlight confirmados.

## Build 5 e icono para distribución — 3 de noviembre de 2026

La captura del propietario muestra Test iOS aprobado en Cloud para 4eb5c9b. El xcresult adjunto de Archive no contiene pruebas: confirma build succeeded, cero errores y cero advertencias. Los logs confirman Archive y tres exportaciones aprobados; el IPA App Store usa com.innovalogic.pinhaven, versión 0.1.0 y build 5. Falló Prepare Build for App Store Connect con mensaje genérico, sin causa definitiva en los artefactos recibidos.

El IPA inspeccionado no incluía iconos ni catálogo compilado. Se añadió Assets.xcassets/AppIcon.appiconset con PNG RGB opaco de 1024×1024, pin blanco con casa sobre fondo verde azulado; se selecciona AppIcon en Debug/Release y se incluye el catálogo en Resources. Generador y proyecto regenerado sincronizados. No se modifican firma ni identificadores. El validador comprueba formato/tamaño, selección del icono y pertenencia a Resources; 99 comprobaciones estructurales aprobadas. Inspección visual del PNG realizada.

La falta de icono es un defecto confirmado del paquete; no se presenta como causa definitiva del mensaje genérico de Cloud. Se debe ejecutar una nueva revisión con Test y Archive y comprobar preparación y procesamiento en TestFlight. No se afirma distribución ni build completo aprobado tras este cambio.

Comprobación adicional: actool generó las entradas CFBundleIcons/CFBundleIconName y PNG derivados, pero terminó con código 1 al no poder localizar un runtime Simulator 17.2 en el entorno restringido. No se considera compilación completa del catálogo aprobada. El nuevo build Cloud debe confirmarla.

## Direcciones y Google Maps — 4 de noviembre de 2026

Tras sincronizar origin/main (ab9efc9), se implementaron sugerencias con MKLocalSearchCompleter y resolución mediante MKLocalSearch.Request(completion:). La elección explícita actualiza dirección y coordenadas; ciudad, estado, código postal y país se conservan cuando MapKit los proporciona. Si la respuesta es ambigua se pide seleccionar el punto en el mapa. Errores, respuestas obsoletas y cancelación no reemplazan el borrador. Resolución limitada a 15 segundos.

La dirección escrita a mano sigue siendo descriptiva: no se geocodifica automáticamente ni se sobrescribe la posición guardada sin selección. Los registros anteriores no cambian. Editar un registro y elegir una sugerencia permite corregirlo. Escribir ciudad o ZIP mejora la desambiguación; el proveedor puede omitir datos postales y no se inventan.

Se conserva el destino por coordenadas al abrir Google Maps. Se codifica la coma según documentación, se añade apertura por comgooglemaps con comprobación de instalación/fallback, vista del punto separada de indicaciones y alternativa web. Compartir sitio comparte un URL; Copiar dirección y enlace mantiene texto y enlace. La captura muestra coordenadas válidas en rango, pero no confirma su correspondencia con la dirección ni la causa del error en Google Maps.

Validación Windows: 103 comprobaciones estructurales aprobadas y proyecto reproducible. Nueve XCTest preparados (dos nuevos), sin ejecutar en esta sesión Windows. La evidencia anterior de Mac/Cloud no valida estos cambios. Ver pasos de prueba añadidos al plan. Firma, icono y bundle identifiers existentes conservados.

## GPS para sugerencias y menú de compartir — 4 de noviembre de 2026

Solicitud del propietario: sugerencias locales en vez de otros estados, y acceso a Google Maps desde Compartir. Implementado un GPS puntual separado que solo cambia la referencia de búsqueda; no escribe en coordenadas/dirección del borrador. Se activa mediante Buscar direcciones cerca de mí y usa el permiso de ubicación al usar la app. Al obtener el GPS se repite la consulta actual. El punto del sitio se usa como referencia inicial cuando existe; sin ninguno la UI lo explica. Se puede desactivar Priorizar direcciones cercanas para buscar en otra ciudad.

La zona de 40 km de lado se aplica a MKLocalSearchCompleter y a la resolución. En iOS 18+ con compilador/SDK compatible se exige regionPriority.required; en iOS 17 solo se da preferencia regional, por lo que podrían aparecer coincidencias lejanas. No se garantiza que Apple tenga todas las direcciones ni que una dirección de casa coincida exactamente: comprobar pin y ZIP sigue siendo necesario.

Compartir sitio ahora muestra un menú propio con Abrir ubicación en Google Maps y Cómo llegar con Google Maps, además de Compartir con otras apps y copiar. No se promete insertar Google Maps en la hoja nativa de iOS ni guardar automáticamente el sitio en favoritos de Google.

Se añade prueba de región con referencia ausente, inválida, válida y 0,0. Diez XCTest preparados; la revisión previa 3bf4119 está aprobada en GitHub Actions. Esta revisión requiere su propia compilación y prueba, y un nuevo build para iPhone/TestFlight.

## Simplificación de compartir y visibilidad de sugerencias — 4 de noviembre de 2026

A partir de las capturas del propietario se eliminó el menú Compartir sitio añadido en la revisión anterior. La ficha conserva una acción por operación: Compartir con otras apps (ShareLink directo), ver punto Google, indicaciones Google/Apple, web y copiar. Se elimina también el texto que explicaba el menú. Copiar muestra un aviso no bloqueante Enlace copiado por dos segundos y anuncio accesible; las pulsaciones repetidas renuevan su duración.

En el editor, Priorizar direcciones cercanas permanece visible antes del campo dirección, y las sugerencias siguen inmediatamente al campo sin controles ni ayuda intercalados. Buscar cerca de mí y el desplegable Zona de búsqueda y ayuda aparecen después. Las explicaciones largas están ocultas inicialmente para dejar espacio con teclado abierto. Se conserva el comportamiento GPS y la referencia separada.

Verificación local: 103 comprobaciones estructurales y diff sin errores de formato; sin compilación ni simulador disponibles en Windows. Estos cambios visuales necesitan revisión con teclado y VoiceOver en iPhone y un nuevo build. No se añadieron pruebas unitarias que repliquen la disposición de vistas.

## Revisión de compartir a WhatsApp — 4 de noviembre de 2026

El propietario informa que al compartir a WhatsApp el mensaje parece no salir. La implementación anterior entregaba un URL mediante ShareLink; no hay evidencia suficiente para atribuir la causa a PinHaven, la extensión o la conexión de WhatsApp.

Se reemplazó esa ruta por LocationShareSheet (UIActivityViewController) con un solo elemento String generado por MapLinks.shareText: nombre, dirección si existe y URL por coordenadas. Se captura el texto al pulsar Compartir, sin notas, GPS nuevo, destinatarios ni envío automático. Se conserva la apertura directa de la hoja iOS.

completionWithItemsHandler permite detectar errores reportados por iOS. Se muestra un error recuperable después de cerrar la hoja con alternativa de copiar/pegar. No se afirma mensaje enviado o entregado cuando la extensión termina. Cancelar simplemente cierra. No se envían mensajes reales durante la validación Windows.

Comprobar en iPhone con WhatsApp instalado y en un chat elegido por el propietario: la llegada del mensaje, la apertura del enlace y los estados de WhatsApp. Esta revisión no se considera validada en WhatsApp hasta esa comprobación.

Validacion Windows de esta revision: 105 comprobaciones estructurales aprobadas y generador reproducible. Swift/XCTest y WhatsApp iOS no ejecutados en este entorno.


## Observación pendiente: contactos frecuentes de WhatsApp — 4 de noviembre de 2026

Prueba reportada por el propietario:

- Compartir con otras apps → elegir WhatsApp → elegir contacto → Enviar: el mensaje sale inmediatamente.
- Compartir con otras apps → elegir directamente un contacto frecuente/sugerido de la hoja de iOS → Enviar: no parece salir en ese momento; al abrir WhatsApp después, el mensaje se envía.

La causa no está confirmada. El comportamiento apunta a la integración entre sugerencias de iOS y WhatsApp; no atribuirlo como defecto confirmado de PinHaven ni interpretar el cierre de la extensión como entrega.

Decisión explícita del propietario: no modificar el código por esta observación; conservarla para más adelante. Alternativa actual: elegir primero WhatsApp y luego el contacto, evitando los contactos sugeridos de la primera fila. Si se retoma, registrar versiones de iOS/WhatsApp y comparar ambas rutas antes de proponer cambios.

## Recepción desde Google Maps/Apple Maps — 5 de noviembre de 2026

Autorización del propietario: implementar Compartir → PinHaven. Se añadió un target Share Extension, recepción de URL/texto, revisión de punto/nombre/categoría/notas/favorito, resolución limitada de enlaces cortos y bandeja local de App Group. La extensión confirma la entrada; la app la importa al abrir/volver activa. No se fuerza el lanzamiento de la app desde la extensión. Los detalles de operación y configuración están en [guía de recepción](13_RECIBIR_DESDE_MAPS.md).

Se conservan el almacén privado SwiftData, esquema y registros anteriores. App Groups solo comparte JSON pendientes. La app valida y guarda antes de retirarlos; reintentos con el mismo UUID no sobrescriben ni duplican. No se modificó la ruta de compartir hacia WhatsApp: la observación de contactos frecuentes sigue registrada sin cambio de código por ese motivo.

Firma declarada: Team 7799N4RYUG; app com.innovalogic.pinhaven; extensión com.innovalogic.pinhaven.share; grupo group.com.innovalogic.pinhaven. Ambos targets deben estar asociados al grupo en Apple Developer y tener perfiles compatibles. El código no acredita registro ni emisión de esos perfiles. No se debe eliminar la app para resolver firma.

Pruebas nuevas: parser de origen/texto, coordenadas exactas vs viewport, validación/corrupción de bandeja, reintento tras guardado y fixtures de redirecciones sin red real. La validación estructural aprobó 157 comprobaciones en Windows. Compilación/XCTest en CI se registran al terminar; uso real en Maps y firma/TestFlight quedan separados.

Comprobación adicional de red (HEAD, sin seguir redirecciones ni descargar páginas): dos enlaces públicos de parques de NPS devolvieron 302 hacia /maps/place con un único par !3d/!4d distinto del viewport @lat,lon. Se añadieron fixtures saneados, sin parámetros de seguimiento. Esto verifica esos formatos públicos, no toda URL ni la extensión en un iPhone. Total preparado: 17 casos XCTest. La estructura actual pasa 161 comprobaciones tras añadir enlaces de documentación.

### Evidencia de compilación y pruebas de F3

Revisión de código validada: 8b728f812cbc62602b5eb0e71b24499a840b8f99. [GitHub Actions aprobado](https://github.com/dafermen/PinHaven/actions/runs/42046751625), job 127311667649, 5 de noviembre de 2026. Xcode 16.4 y SDK iPhoneSimulator 18.5. xcodebuild test con CODE_SIGNING_ALLOWED=NO: app y extensión compilan, se valida PinHavenShare.appex embebida y pasan 17 XCTest (10 previos + 7 de ShareCaptureTests), cero fallos, TEST SUCCEEDED.

Se mantienen advertencias previas de aislamiento del delegate de AddressSearch frente a Swift 6 y mensajes de herramientas de Apple; el proyecto usa Swift 5. No se declara compilación sin advertencias ni compatibilidad de lenguaje Swift 6. Estas pruebas sin firma no prueban perfiles de distribución, App Group registrado ni recepción real en Google Maps/iPhone.

La inspección del navegador de Windows para revisar Apple Developer se detuvo porque la herramienta no pudo verificar con suficiente certeza la URL de Chrome. No se modificó nada en Apple Developer ni App Store Connect. Configuración pendiente en el Mac/portal: grupo group.com.innovalogic.pinhaven asociado a app y extensión, perfiles compatibles y nuevo Archive/instalación. La guía 13 explica esos pasos.

## Recepción Google Maps con dirección pero sin coordenadas — 2026-11-05

La prueba del propietario mostró Guardar desactivado y nombre con signos +. La consulta HEAD autorizada al enlace de la captura devolvió una redirección a maps.google.com con q=nombre+dirección y ftid; no contenía coordenadas explícitas. Es un formato distinto de /maps/place con !3d/!4d. No se deducen coordenadas de ftid ni del viewport.

Se corrige la decodificación de query como formulario (signos + a espacios, manteniendo %2B literal). Al llegar a una consulta textual de mapas, el expansor deja de hacer peticiones: pasa el texto a MKLocalSearch. La extensión muestra hasta cinco candidatos con nombre/dirección, sin seleccionar ninguno automáticamente. Elegir uno fija el punto y completa la dirección postal; después se revisa el pin y se guarda. Si no hay resultados/conexión, permanece la selección manual de mapa.

La búsqueda de candidatos tiene límite de 12 segundos y se cancela al salir. Se añaden dos casos de prueba con datos genéricos para el formato textual, los + literales y las redirecciones sin descargar HTML. No se incorporan URLs personales a fixtures. La aceptación de este caso en iPhone sigue pendiente del nuevo build.

Validación de la corrección: código ee90ed1c3a53c53e4456f9af8a3e08f40cf4ef2d compilado con 19 XCTest aprobados, cero fallos, TEST SUCCEEDED en https://github.com/dafermen/PinHaven/actions/runs/42161658093 . La variante compartida hacia WhatsApp también se comprobó mediante HEAD y devolvió el mismo formato textual. No se modificó el envío saliente a WhatsApp. PR #2 pendiente de integrar y de probar en iPhone; la documentación posterior no cambia el código validado.

## Google comparte una ruta con daddr/saddr — 2026-11-06

La nueva captura corresponde a un enlace corto que redirige por HEAD a una ruta de Google Maps con coordenadas de destino en daddr y origen en saddr. No es el caso q textual del PR #2. Se verificó además que el commit de integración del PR #2, 63e5c68, aprobó Test y Archive de Xcode Cloud; esa evidencia no identifica el build instalado en el iPhone.

Se añade reconocimiento de daddr/destination en enlaces de rutas admitidos. Solo se obtiene el destino; nunca se usa saddr ni un q alternativo si el destino es inválido o contradictorio. Para destinos textuales se busca solo ese texto con MapKit y se pide elegir candidato. El formulario indica que se recibió una ruta y propone Destino compartido cuando no hay nombre: se revisa el pin y se puede renombrar. El enlace original, que puede representar toda la ruta, se conserva como referencia.

Tres pruebas nuevas con datos ficticios cubren destino vs origen/query, origen sin destino, 0,0, destino inválido, duplicados contradictorios, destino textual y redirección sin descargar página. No se almacenan las coordenadas personales de la captura en fixtures. Sin cambios de App Groups, SwiftData ni envío a WhatsApp.

Validación PR #3: código d697f5f82384e4835d98c9be08201b17e2d24ce1 compilado y 22 XCTest aprobados, cero fallos, TEST SUCCEEDED en https://github.com/dafermen/PinHaven/actions/runs/42220107709 . Los destinos inválidos o ausentes no recurren al origen ni al q auxiliar. Queda pendiente integrar y comprobar en un nuevo build iPhone. La documentación posterior no cambia el código validado.

## Direcciones alrededor del pin — 2026-11-06

El propietario confirmó ambas opciones: consultar la dirección del pin y sugerencias cercanas mientras escribe, tanto al recibir desde Google Maps como al editar. Se añadió PointAddressLookup con CLGeocoder y un componente compartido que muestra direcciones para aplicar explícitamente sin cambiar coordenadas. La dirección puede ser aproximada o faltar; se mantiene editable y opcional. El número postal no se garantiza.

La extensión añade autocompletado AddressSearch referenciado al pin; el editor conserva su autocompletado y da prioridad inicial al punto del sitio. Zona de 4 km de lado para el pin; buscar cerca de mí sigue siendo una acción separada, con retorno explícito a la zona del sitio. Elegir autocompletado actualiza dirección y coordenadas juntas; elegir una dirección obtenida desde el pin solo cambia el texto del borrador. Ningún cambio se persiste sin Guardar.

Las consultas inversas son puntuales por botón, con cancelación, límite de 12 segundos e invalidación al cambiar el punto/salir. Cuatro pruebas nuevas cubren punto 0,0, limpieza de respuestas, radio, cancelación/respuesta tardía, cambio de punto y error/entrada inválida usando un proveedor simulado sin red ni ubicaciones personales. Validación Windows: 169 comprobaciones estructurales. Compilación y total de 26 XCTest pendientes de CI al preparar esta revisión. Sin cambios de firma, App Groups ni esquema de datos.

Validación PR #4: código 709fa3076968d135d2bf0caa653760042f35b6e7 compilado y 26 XCTest aprobados, cero fallos, TEST SUCCEEDED en https://github.com/dafermen/PinHaven/actions/runs/42248884632 (job 127998306153). Se comprobaron ambos targets app/extensión. Posteriores cambios de documentación no alteran el código validado. Pendientes: integrar y verificar geocodificación real, teclado y selección en iPhone.
