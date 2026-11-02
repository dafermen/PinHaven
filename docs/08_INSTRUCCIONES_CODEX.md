# Instrucciones para continuar con Codex

Copia el siguiente prompt al abrir este repositorio en Codex. Las reglas de este documento orientan la continuidad; no sustituyen instrucciones del propietario ni políticas del entorno.

---

Trabaja en el proyecto **PinHaven**, aplicación nativa iPhone en Swift/SwiftUI, iOS 17+, con directorio local de ubicaciones. El propietario es Darío; la documentación debe ser clara para un estudiante de desarrollo y estar en español.

Antes de modificar, lee README.md, docs/01_REQUISITOS.md, docs/02_ARQUITECTURA.md, docs/04_FASES_Y_TAREAS.md y docs/09_ESTADO_ENTREGA.md. Inspecciona el código actual y conserva cambios ajenos.

El nombre elegido es PinHaven. Inglés (`en`) es el idioma principal del producto y español (`es`) su opción inicial. Mantén la documentación del desarrollador en español. Implementa F1-T10 según docs/11_IDIOMAS.md: el código inicial aún no está localizado. No traduzcas datos escritos por el usuario ni cambies categorías persistidas sin un plan de compatibilidad.

**Primera prioridad:** si tienes Mac con Xcode, compila y ejecuta `bash scripts/test_ios.sh`. Corrige errores reales de compilación o comportamiento y registra evidencia. Si no tienes Xcode, dilo expresamente y no marques pruebas iOS como aprobadas.

El MVP incluye persistencia SwiftData local, GPS puntual, selección/búsqueda MapKit, nombres, dirección opcional, notas, etiquetas, categorías, favoritos, búsqueda/filtros, enlaces, compartir e importar/exportar JSON. El código está escrito, pendiente de aceptación iOS. No hay backend ni sincronización. No añadas CloudKit, analítica, publicidad, cuentas, IA ni seguimiento continuo sin una nueva instrucción del propietario.

Avanza de forma incremental según el roadmap. Implementa una tarea revisable cada vez. Para el primer sprint implementa F1-T10 y termina F1-T08 y F1-T09; después inicia fotos mediante F2-T01 y F2-T02. No hagas a la vez todas las fases.

Mantén una coordenada independiente de la dirección postal. El nombre es obligatorio; dirección, notas y etiquetas son opcionales. No trates 0,0 como ausencia. No conviertas un viewport de Google Maps en ubicación del negocio. Conserva el enlace y pide elegir punto cuando no se resuelva.

No destruyas ni reemplaces silenciosamente la base si falla la apertura. Cualquier evolución de datos distribuidos requiere migraciones y pruebas con una copia anterior. Importar un respaldo no debe sobrescribir datos sin decisión explícita.

La política local exige CloudKit desactivado y revisión de exclusión de backups. Compartir/exportar es una acción explícita y puede enviar datos a la app elegida. No prometas que búsquedas y mapas remotos funcionan sin internet.

Si modificas archivos Swift del proyecto o targets, actualiza y ejecuta `scripts/generate_project.py` cuando corresponda; el proyecto Xcode generado debe incluir todos los archivos. Si cambias firma/bundle identifier en Xcode, refleja esos cambios también en el generador antes de regenerar.

Agrega pruebas cuando haya lógica de dominio o riesgo de pérdida de datos; no uses pruebas que solo repitan texto del código. Ejecuta la validación estructural y los checks disponibles. Reporta por separado implementado, ejecutado, aprobado y pendiente.

Al finalizar, actualiza estado, backlog, changelog y documentación afectada. Entrega cambios, motivo, validación y limitaciones sin afirmar publicación en GitHub o App Store si no ocurrió.

---
