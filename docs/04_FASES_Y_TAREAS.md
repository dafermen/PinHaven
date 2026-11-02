# Fases, actividades y tareas

## Estados

**I:** implementado, pendiente de compilación y aceptación iOS. **D:** documentación entregada. **P:** pendiente. Ninguna tarea I debe considerarse terminada para una publicación hasta completar F1-T08, F1-T09 y la localización F1-T10.

## F0 — Definición y preparación

**Objetivo:** un repositorio comprensible para empezar. Resultado: documentación, proyecto y criterios de aceptación.

| ID | Tarea | Estado | Aceptación / dependencia |
|---|---|---|---|
| F0-T01 | Definir visión, usuarios y alcance | D | Visión y MVP delimitados |
| F0-T02 | Escribir historias y criterios | D | Cada comportamiento tiene aceptación |
| F0-T03 | Diseñar modelo y arquitectura | D | Campos, DTO, persistencia y flujos explicados |
| F0-T04 | Crear proyecto Xcode y esquema compartido | I | Abrir y listar targets en Xcode; validar en F1-T08 |
| F0-T05 | Preparar README, guía y plantillas GitHub | D | Un estudiante puede seguir el inicio |

## F1 — Agenda local funcional (0.1.0)

**Objetivo:** guardar, encontrar, consultar y compartir sitios. Resultado: MVP local aceptado en iPhone. La implementación se incluye; aceptación pendiente.

| ID | Tarea | Estado | Aceptación / dependencia |
|---|---|---|---|
| F1-T01 | Persistencia local y errores de apertura | I | Reabrir sin perder datos; sin CloudKit |
| F1-T02 | Formulario, edición y borrado | I | Validaciones; cancelar no modifica; borrado confirmado |
| F1-T03 | Captura GPS y permisos | I | Rechazo, timeout y precisión visibles |
| F1-T04 | Selección y búsqueda MapKit | I | Revisar punto antes de guardar; error de red claro |
| F1-T05 | Lista, mapa, búsqueda y filtros | I | Mismos resultados, tildes y favoritos |
| F1-T06 | Enlaces, compartir e indicaciones | I | Abrir destino correcto; sin notas privadas por defecto |
| F1-T07 | Respaldo JSON e importación | I | Restaurar, rechazar inválidos y omitir UUID existentes |
| F1-T08 | Compilar y ejecutar XCTest en Mac | P | Build y pruebas verdes; registrar Xcode/iOS |
| F1-T09 | Aceptación manual en iPhone | P | Matriz de pruebas; privacidad y GPS reales |
| F1-T10 | Inglés principal y español opcional | P | Localizar interfaz, permisos, errores y accesibilidad; comprobar ambos idiomas sin modificar datos guardados |

## F2 — Fotos y organización (0.2.0)

**Objetivo:** reconocer lugares visualmente. Resultado: fichas con foto y organización mejorada. Depende de F1-T08/T09.

| ID | Tarea | Estado | Criterio |
|---|---|---|---|
| F2-T01 | Migración versionada del modelo | P | Datos 0.1 se abren sin pérdida |
| F2-T02 | Seleccionar foto con PhotosPicker | P | Copia local, cancelar y borrar sin archivos huérfanos |
| F2-T03 | Capturar foto con cámara | P | Permiso contextual; rechazo recuperable |
| F2-T04 | Miniaturas y almacenamiento de imágenes | P | Compresión, límites y EXIF/ubicación revisados |
| F2-T05 | Colecciones y estado quiero ir/ya fui | P | Filtros combinables y migración |
| F2-T06 | Respaldo con imágenes y nueva versión | P | Recuperación completa y límites contra archivos dañados |

## F3 — Captura desde otras apps (0.3.0)

**Objetivo:** Apple Maps/Google Maps/Safari → Compartir → PinHaven. Resultado: recibir y revisar sin abrir manualmente el formulario principal.

| ID | Tarea | Estado | Criterio |
|---|---|---|---|
| F3-T01 | Target Share Extension y App Groups | P | Firma correcta, contenedor compartido y pruebas |
| F3-T02 | Bandeja local de entradas pendientes | P | Escritura atómica y consumo sin duplicados; migrar base existente |
| F3-T03 | Leer URL/texto con NSItemProvider | P | Casos reales de Maps, Google Maps y Safari |
| F3-T04 | Resolución segura de enlaces cortos | P | Allowlist, HTTPS, límite de redirecciones/tiempo/tamaño; confirmación si falta punto |
| F3-T05 | Formulario breve de confirmación | P | Nombre, categoría, guardar o cancelar |
| F3-T06 | Fixtures de enlaces y pruebas reales | P | Ningún viewport se presenta como destino exacto |

Diseño preferido: extensión escribe una entrada en una bandeja de archivos local compartida; app principal valida e importa. Evitar escrituras concurrentes no coordinadas a la base. El uso de App Groups obliga a planificar migración del almacén existente, no a comenzar una agenda vacía.

## F4 — Recuperación inteligente (0.4.0)

| ID | Tarea | Estado | Criterio |
|---|---|---|---|
| F4-T01 | Orden por distancia con GPS puntual | P | Sin permiso funciona agenda; distancia en línea recta claramente identificada |
| F4-T02 | Aviso por posible duplicado geográfico | P | Ofrecer conservar, editar o cancelar; nunca fusionar sin elección |
| F4-T03 | Resolver conflictos al importar | P | Comparar versiones; elegir conservar/reemplazar/duplicar |
| F4-T04 | Medir rendimiento y accesibilidad | P | Datos de prueba grandes, VoiceOver y tamaños de texto |

## F5 — Preparar distribución (1.0)

| ID | Tarea | Estado | Criterio |
|---|---|---|---|
| F5-T01 | Confirmar disponibilidad de PinHaven, licencia e identidad | P | Nombre elegido confirmado en App Store Connect, bundle ID propio e icono |
| F5-T02 | Auditar privacidad y manifest | P | Declaraciones App Store coherentes con todas las dependencias |
| F5-T03 | Material de tienda y soporte | P | Política de privacidad, URL soporte, capturas y descripción |
| F5-T04 | TestFlight y correcciones | P | Pruebas reales, recuperación y migraciones verificadas |
| F5-T05 | Publicar con aprobación del propietario | P | Checklist completo y versión firmada |

## Definición de terminado por tarea

Código implementado, compilación correcta, aceptación del caso normal y de error, pruebas pertinentes ejecutadas, documentación actualizada y revisión del diff sin datos personales. Una casilla no se cierra por existir el archivo.

## Próximo sprint recomendado

1. F1-T10: implementar inglés principal y español opcional según la especificación de idiomas.
2. F1-T08: abrir el proyecto, corregir cualquier incompatibilidad de SDK y ejecutar pruebas.
3. F1-T09: validar guardar/editar/compartir en iPhone y la exclusión de respaldo.
4. Corregir hallazgos y registrar evidencia.
5. Iniciar F2-T01 y F2-T02, manteniendo el resto fuera del sprint.

No se fijan fechas hasta conocer disponibilidad del estudiante y acceso a un Mac. Para un principiante, reservar tiempo explícito para aprendizaje, depuración y validación, además de escribir código.
