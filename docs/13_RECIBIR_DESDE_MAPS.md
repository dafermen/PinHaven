# Recibir ubicaciones desde Google Maps o Apple Maps

Implementación: 5 de noviembre de 2026. Validación y pendientes concretos en el estado de entrega.

## En el iPhone, después de instalar el nuevo build

1. Abre un lugar en Google Maps y pulsa Compartir.
2. En la lista de aplicaciones elige PinHaven. Si no aparece, entra en Más y habilítalo si iOS ofrece esa opción.
3. Revisa nombre, categoría y el pin del mapa. Puedes escribir dirección, notas y favorito.
4. Si el enlace no tiene coordenadas verificables, pulsa Buscar o corregir punto en el mapa. Se busca el nombre recibido cuando existe; elige un resultado o toca el mapa.
5. Pulsa Guardar y después Listo. La extensión confirma que dejó el lugar en la bandeja local.
6. Abre PinHaven: la app incorpora los lugares confirmados y muestra cuántos añadió.

La extensión no fuerza la apertura de la app principal. Tampoco escribe directamente en su base. Un lugar pendiente no aparecerá en la agenda ni en su exportación JSON hasta que abras PinHaven y termine la importación.

## Qué reconoce y qué no

Acepta un enlace HTTPS de Google Maps o Apple Maps, como URL o dentro de texto. Soporta coordenadas explícitas en query/q/destination y ll/coordinate de Apple; además interpreta un único par !3d/!4d en la ruta /maps/place de Google. Nunca usa @lat,lon (centro de la cámara) como ubicación del negocio. No interpreta cualquier URL de Google ni convierte IDs de negocio a coordenadas mediante una API de pago.

Para enlaces cortos sigue solo redirecciones HTTP en hosts de mapas permitidos. Usa HEAD, sin descargar ni analizar HTML, sin cookies ni credenciales; máximo seis peticiones, cinco redirecciones seguidas y presupuesto total de 15 segundos. Rechaza cambios a HTTP, hosts externos, credenciales en URL, puertos ajenos a 443 y bucles. Los enlaces originales se conservan, hasta 4.000 caracteres; los destinos de redirección se limitan a 8.192.

Google puede devolver un ID, página de consentimiento, una redirección no admitida o un formato diferente. En esos casos no se adivina el punto: se pide elegirlo en el mapa. El nombre/dirección solo se rellenan si aparecen en el contenido recibido o en parámetros reconocidos, sin afirmar enriquecimiento completo de Google Places.

## Activar App Groups y firma en el Mac

El proyecto contiene tres targets: PinHaven, PinHavenTests y PinHavenShare. Se mantienen el Team 7799N4RYUG y el bundle identifier principal com.innovalogic.pinhaven. La extensión usa com.innovalogic.pinhaven.share.

1. Actualiza el repositorio y abre PinHaven.xcodeproj.
2. En Signing & Capabilities de PinHaven y PinHavenShare selecciona tu equipo y firma automática.
3. En ambos targets verifica App Groups y el grupo group.com.innovalogic.pinhaven. Si no existe, créalo con el botón + de Xcode o en Identifiers → App Groups del portal Apple Developer; asócialo a ambos identificadores.
4. Permite a Xcode actualizar los perfiles de aprovisionamiento. La extensión necesita su propio identificador y perfil, del mismo equipo. No crees una app independiente de PinHavenShare en App Store Connect.
5. Ejecuta Product → Test, después instala y prueba en iPhone.
6. Genera un nuevo build de Xcode Cloud con Test y Archive. El Archive debe incluir PlugIns/PinHavenShare.appex; los perfiles de ambos targets deben autorizar el grupo.

Los entitlements, capabilities y generador están preparados en Git, pero esto no demuestra que Apple haya registrado el grupo o emitido los perfiles. Si Cloud muestra que un perfil no admite App Groups o no contiene el grupo, completa los pasos de firma y vuelve a ejecutar el build. No elimines la app para solucionar firma: conserva tus datos y un respaldo.

La app y extensión usan MARKETING_VERSION y CURRENT_PROJECT_VERSION coherentes. La configuración Cloud debe mantener el mismo número para ambos targets.

## Datos existentes y recuperación

La base SwiftData permanece en Application Support/PinHaven/places.store dentro de la app. No se migra ni se cambia su esquema. Solo la bandeja PendingPlaces se comparte por App Group; un JSON por UUID se escribe atómicamente y se excluye de respaldos automáticos, con protección completa de archivo.

La app valida versión, tamaño (128 KiB), UUID/nombre de archivo, origen y campos antes de importar. Primero guarda en SwiftData, luego retira la entrada. Si se interrumpe entre ambos pasos, el siguiente intento omite el UUID ya guardado; no sobrescribe ni duplica ese registro. Los archivos inválidos o que no pueden importarse se conservan y se avisa. Se procesan hasta 200 entradas por activación para limitar trabajo de arranque.

La extensión no modifica tus sitios anteriores. Eliminar la app puede eliminar también los pendientes. Exportar desde la app respalda los sitios ya importados, no los pendientes.

## Verificación

Automatización: estructura de tres targets, embedding, App Groups y versión común; fixtures de URL/viewport/redirecciones, bandeja corrupta y reintento sin duplicados. Las pruebas de red usan URLProtocol, sin contactos ni ubicaciones reales ni solicitudes externas.

En dispositivo: probar compartir desde Google Maps, Apple Maps y Safari; URL y texto; Cancelar; enlace corto sin internet; selección manual; segundo lugar; abrir/cerrar app con pendientes; actualización de una instalación anterior; firma/TestFlight y persistencia de sitios existentes.

Referencias oficiales:

- [App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [Compartir datos entre app y extensión](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html)
- [Share extensions](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html)

Ejemplos públicos contrastados mediante HEAD el 5 de noviembre de 2026, sin usar ubicaciones personales: [Stanton Park](https://www.nps.gov/planyourvisit/event-details.htm?id=C194BFE6-FC34-56FA-55A4B81EB72EB695) y [Fort Dupont Park](https://www.nps.gov/planyourvisit/event-details.htm?id=405AB1FF-9742-D78D-FC560691741E57E6). Sus redirecciones incluyeron coordenadas de lugar diferentes a la cámara; los fixtures de prueba conservan solo la parte relevante del URL.

## Google envía nombre y dirección, sin coordenadas

Algunos enlaces cortos redirigen a maps.google.com?q=nombre+dirección&ftid=... . La extensión convierte los + de formulario en espacios (sin cambiar %2B literal) y busca ese texto con MapKit. Muestra hasta cinco coincidencias: elige la correcta y comprueba dirección/pin para habilitar Guardar. No se guarda una coincidencia automáticamente. Si no hay coincidencias, usa Buscar o corregir punto en el mapa. Resolver un nombre con MapKit requiere red y puede devolver resultados diferentes de Google.

## Si Google comparte una ruta

Google puede enviar daddr (destino) y saddr (origen) en lugar de una ficha de negocio. La extensión muestra el punto de destino y un aviso; no convierte el origen ni el recorrido en el lugar guardado. Escribe un nombre descriptivo si lo deseas y confirma el pin. El enlace original puede seguir mostrando la ruta completa al abrirlo, porque se conserva como referencia. Si el destino es textual se muestran candidatos para elegir; si falta o es contradictorio se requiere selección manual.

Para compartir la ficha de un negocio, sal de Cómo llegar en Google Maps, abre la ficha del lugar y usa su botón Compartir.

## Asignar o corregir dirección

Con un punto elegido, pulsa Sugerir dirección de este punto y elige la propuesta si corresponde. Completa/corrige el número cuando sea necesario: esta opción cambia solo el texto y conserva el pin. También puedes escribir en Dirección y elegir una sugerencia cercana; esa selección actualiza dirección y coordenadas juntas. Revisa el mapa antes de Guardar. La edición de sitios usa las mismas opciones. La consulta inversa depende de Apple y puede no encontrar dirección o devolver una aproximación.
