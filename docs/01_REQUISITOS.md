# Requisitos y alcance

«Implementado» significa que hay código en esta entrega; no equivale a aceptación en Xcode.

## Historias y criterios del MVP

| ID | Historia | Criterios de aceptación | Estado |
|---|---|---|---|
| HU01 | Guardar donde estoy | Acción explícita; pedir permiso cuando corresponda; mostrar precisión; manejar rechazo y tiempo de espera | Implementado, por validar |
| HU02 | Guardar un punto manual | Tocar mapa o escribir coordenadas; aceptar 0,0; rechazar latitud fuera de ±90 y longitud fuera de ±180 | Implementado, por validar |
| HU03 | Buscar establecimiento | Buscar con MapKit; elegir resultado; revisar nombre y dirección antes de guardar; mostrar error sin conexión | Implementado, por validar |
| HU04 | Describir un sitio | Nombre no vacío; dirección y notas opcionales; categoría, etiquetas y favorito | Implementado, por validar |
| HU05 | Encontrar registros | Buscar nombre, dirección, notas, categoría o etiquetas; ignorar tildes y mayúsculas; combinar filtros | Implementado, por validar |
| HU06 | Consultar lista y mapa | Mismos resultados filtrados; abrir ficha desde lista o marcador; vacío con acción clara | Implementado, por validar |
| HU07 | Editar y eliminar | Cancelar edición conserva datos; borrar exige confirmación; error de guardado no se oculta | Implementado, por validar |
| HU08 | Compartir sitio | Acciones directas sin duplicados; compartir texto con nombre, dirección y URL universal mediante hoja iOS; copiar nombre/dirección/enlace con confirmación; no incluir notas privadas | Implementado, por validar |
| HU09 | Iniciar indicaciones | Abrir destino en Apple Maps o Google Maps mediante URL; navegador como alternativa del enlace | Implementado, por validar |
| HU10 | Respaldar y restaurar | Exportar todos; validar JSON y versión; confirmar importación; mismo UUID se omite | Implementado, por validar |
| HU11 | Aprovechar enlace pegado | Extraer coordenadas explícitas de formatos admitidos; enlaces pegados conservan la ruta manual; extensión recibe y expande enlaces limitados; revisar antes de guardar | Implementado, por validar |

## Idiomas

El idioma base del producto es inglés (`en`); español (`es`) es la primera traducción disponible que se debe implementar. Nombre PinHaven en ambos idiomas. La localización de textos, permisos, accesibilidad, errores y formatos está pendiente en F1-T10, con alcance en [Idiomas](11_IDIOMAS.md).

## Requisitos no funcionales

| ID | Requisito | Cómo verificar |
|---|---|---|
| RN01 | Datos persistidos en el dispositivo | Reabrir app sin red y consultar registros |
| RN02 | Sin sincronización propia en nube | `cloudKitDatabase: .none`, sin capacidades iCloud ni backend |
| RN03 | Sin seguimiento continuo | Solo permiso When In Use y `requestLocation()` por acción |
| RN04 | Accesibilidad básica | Etiquetas de botones; VoiceOver, Dynamic Type y contraste se prueban en dispositivo |
| RN05 | Integridad al importar | Límites, validación completa previa y rollback al fallar el guardado |
| RN06 | Errores recuperables | Avisos de permisos, red, persistencia y datos inválidos |
| RN07 | Mantenibilidad | Código separado por responsabilidad; guía y pruebas |

## Campos y límites actuales

Nombre obligatorio hasta 200 caracteres; dirección hasta 2.000; notas hasta 20.000; etiquetas hasta 2.000; categoría hasta 100; URL original hasta 4.000. Coordenadas finitas y dentro del rango geográfico. Categorías iniciales fijas, etiquetas como texto separado por comas. Coordenadas manuales con punto decimal.

## Fuera del MVP

Fotos, cámara, interpretar cualquier URL, scraping de Google, enriquecimiento de Google Places, historial automático, ubicación en tiempo real, mapas propios descargables, rutas internas, colecciones y orden por proximidad. Exportación manual adelantada al MVP por la importancia de recuperar datos locales. El aviso de posibles duplicados se incorpora como alcance adicional autorizado; no realiza fusiones automáticas.

## Casos especiales

- GPS denegado: se puede escribir coordenadas o elegir el punto en mapa.
- Precisión baja: se informa la precisión y se permite corregir el punto.
- Sin internet: agenda local operativa; búsqueda, mapas nuevos y envío por WhatsApp pueden no funcionar.
- Sin dirección postal: guardar coordenadas y nombre.
- Link no admitido: conservar referencia, pedir selección manual; no adivinar ubicación.
- UUID ya existente en importación: omitir incluso si el respaldo contiene una edición más reciente. Resolución de conflictos futura.
- Mismo lugar con UUID diferente: al crear/editar o recibir desde Maps se avisa de posibles duplicados. La restauración de un respaldo JSON conserva su política por UUID, sin aviso geográfico.
- Importar el mismo archivo repetidamente: no duplica identificadores.
- Eliminar la app: datos locales pueden perderse; recuperación mediante respaldo manual.

## Alcance adicional autorizado: recibir desde Maps

Extensión de compartir para un URL/texto de Google Maps o Apple Maps. Revisión de nombre, dirección opcional, categoría, notas, favorito y punto antes de confirmar. Si faltan coordenadas, selección manual/MapKit obligatoria. Confirmación escribe en bandeja local de App Group; al abrir PinHaven se importa sin duplicar UUID ni sobrescribir datos. Resolver enlaces cortos solo por redirecciones HTTPS acotadas, sin scraping. No forzar la apertura de la app ni migrar la base existente. Ver [guía de recepción](13_RECIBIR_DESDE_MAPS.md).

## Bandeja visible y posibles duplicados — 13 de noviembre de 2026

La bandeja debe estar accesible aunque esté vacía; mostrar cantidad pendiente y permitir revisar, corregir, reintentar o descartar con confirmación. Los archivos dañados se conservan hasta una acción explícita. Los sitios claramente nuevos siguen incorporándose al abrir la app; los posibles duplicados quedan pendientes.

Se considera posible duplicado un punto a 50 m o menos, el mismo nombre normalizado a 200 m o menos, o el mismo enlace de mapa admitido ignorando parámetros de seguimiento conocidos. Los enlaces de rutas y páginas principales no se comparan como identidad. La distancia es en línea recta, sin solicitar GPS. Es una advertencia: locales distintos pueden compartir edificio.

Crear/recibir permite abrir el existente, revisar y confirmar Actualizar ubicación o Guardar otro sitio. Actualizar conserva UUID, creación, nombre, notas, etiquetas, categoría y favorito; aplica coordenadas y dirección/enlace no vacíos. Editar un sitio excluye su UUID del aviso y permite guardar sus propios cambios sin fusionarlo con otro. Cancelar conserva agenda y pendiente.

La intención de incorporación se registra antes de modificar la agenda y se marca completada antes de retirar el pendiente. Una intención incompleta exige revisión explícita; si el sitio vinculado existe, se abre su estado guardado. Repetir una entrada completada no sobrescribe ni resucita un sitio eliminado. No se cambia el esquema SwiftData. La copia de seguridad JSON no incluye pendientes ni confirmaciones internas.
