# PinHaven 📍

**Your places, always close.** Agenda personal de ubicaciones para iPhone, desarrollada en Swift y SwiftUI. Guarda un restaurante, una entrada o un punto sin dirección postal y recupéralo por su nombre, notas o etiquetas.

**Estado: 0.1.0 — compilación y 17 XCTest aprobados en CI macOS el 5 de noviembre de 2026.** Xcode 16.4, SDK de simulador iOS 18.5; incluye compilación y embedding de PinHavenShare. La recepción desde Maps requiere App Groups/perfiles de Apple y aceptación en iPhone real. Localización pendiente. Este repositorio contiene código, no un instalador IPA.

## Identidad e idiomas

Nombre elegido por el propietario: **PinHaven**. Idioma principal del producto: **English (en)**; idioma adicional inicial: **Español (es)**. La documentación para el desarrollador sigue en español.

La localización de la interfaz todavía está pendiente en F1-T10; el código inicial conserva textos en español. No se presenta como una interfaz bilingüe ya implementada. La aceptación del nombre en App Store Connect está pendiente.

## Qué incluye esta entrega

- Recibir un lugar desde Google Maps/Apple Maps → Compartir → PinHaven, confirmar el punto y abrir la app para incorporarlo. Requiere App Groups y un nuevo build firmado; ver [guía de recepción](docs/13_RECIBIR_DESDE_MAPS.md).
- Lista de sitios y vista de mapa con acceso a sus fichas.
- Crear, editar y eliminar sitios con confirmación; almacenamiento local SwiftData.
- Captura puntual de GPS, selección tocando el mapa y búsqueda con MapKit.
- Buscar direcciones cerca de mí usa GPS solo como referencia, con opción de buscar en otra ciudad.
- Sugerencias al escribir la dirección: elegir una actualiza dirección postal y coordenadas juntas (por validar en iPhone).
- Nombre, dirección opcional, coordenadas, notas, categoría, etiquetas y favorito.
- Búsqueda sin distinguir mayúsculas ni tildes; filtros combinables por categoría y favorito.
- Orden por modificación reciente o por nombre.
- Acciones directas para Google Maps y Compartir con otras apps, sin menú intermedio. Compartir envía un mensaje de texto con nombre, dirección y enlace. Copiar confirma «Enlace copiado».
- Abrir indicaciones con Apple Maps o enlaces universales de Google Maps.
- Pegar enlaces con coordenadas explícitas compatibles. Los enlaces cortos no se resuelven en esta versión.
- Exportar todos los sitios a JSON e importar nuevos identificadores con confirmación.
- Manejo de errores de permisos, guardado, búsqueda e importación.

## Qué sigue pendiente

Fotos y cámara, colecciones, cercanía y duplicados geográficos. La recepción por extensión y resolución limitada de enlaces cortos tienen código y pruebas preparadas; falta aceptación real desde Maps y configuración de App Groups en Apple. Tampoco incluye seguimiento en tiempo real, servidor, usuarios, IA ni publicación en App Store. Las diferencias entre idea y alcance están en [requisitos](docs/01_REQUISITOS.md).

## Ejecutar

Necesitas **Mac con Xcode y SDK de iOS 17 o superior, y simulador o iPhone con iOS 17+**. La base actual se compiló y pasó sus siete pruebas con Xcode 15.2; valida cualquier otra versión antes de darla por compatible. No hay paquetes externos que instalar.

1. Clona `https://github.com/dafermen/PinHaven.git` y abre `PinHaven.xcodeproj`.
2. Selecciona el esquema `PinHaven` y un simulador iPhone.
3. Pulsa **Run** (⌘R).
4. La configuración del propietario usa `com.innovalogic.pinhaven` y su equipo en **Signing & Capabilities**. Para otro propietario, cambia equipo e identificador también en el generador. No actives iCloud.
5. Guarda un sitio de prueba, cierra y abre la app y verifica su persistencia.
6. Ejecuta las pruebas con **Product → Test** (⌘U).

Guía explicada desde cero: [Primeros pasos](docs/03_GUIA_PRINCIPIANTE.md). Si Xcode no abre el proyecto, puedes regenerarlo con `python3 scripts/generate_project.py`.

Guía para este entorno: [Windows, Mac y Xcode Cloud](docs/12_WINDOWS_MAC_Y_CLOUD.md).

## Documentación

| Documento | Propósito |
|---|---|
| [Visión](docs/00_VISION.md) | Problema, objetivos y decisiones de producto |
| [Requisitos](docs/01_REQUISITOS.md) | Historias, alcance y aceptación |
| [Arquitectura](docs/02_ARQUITECTURA.md) | Componentes, flujo y modelo de datos |
| [Guía principiante](docs/03_GUIA_PRINCIPIANTE.md) | Instalación, lectura del código y primer cambio |
| [Fases y tareas](docs/04_FASES_Y_TAREAS.md) | Plan incremental con dependencias |
| [Pruebas](docs/05_PLAN_DE_PRUEBAS.md) | Matriz manual, automatización y límites de validación |
| [Privacidad](docs/06_PRIVACIDAD.md) | Datos locales, servicios externos y respaldos |
| [GitHub](docs/07_GITHUB_Y_COLABORACION.md) | Crear el repositorio y trabajar por ramas |
| [Continuar con Codex](docs/08_INSTRUCCIONES_CODEX.md) | Prompt y reglas de continuidad |
| [Estado](docs/09_ESTADO_ENTREGA.md) | Evidencia real y trabajo pendiente |
| [Fuentes](docs/10_FUENTES.md) | Referencias oficiales consultadas |
| [Idiomas](docs/11_IDIOMAS.md) | Inglés principal, español opcional y criterios de localización |
| [Backlog CSV](docs/BACKLOG.csv) | Tareas listas para llevar a GitHub Projects |

## Validación

En Windows con Python 3: `python scripts/validate_repository.py`. En Mac/Linux: `python3 scripts/validate_repository.py`.
En Mac con Xcode: `bash scripts/test_ios.sh` o ⌘U. El workflow incluido ejecutará esas verificaciones cuando el repositorio se suba a GitHub con Actions habilitado; aún no ha corrido.

## Privacidad y recuperación

Sin cuenta, backend, analítica ni sincronización CloudKit. La carpeta de datos se marca para excluirla de los respaldos automáticos; su efecto debe comprobarse en un dispositivo real. Buscar y visualizar mapas usa servicios externos. Compartir y exportar son acciones explícitas del usuario. Elige almacenamiento local al exportar si quieres evitar la nube.

**Eliminar la app puede eliminar todos tus sitios. Exporta un respaldo antes.** El JSON no está cifrado y contiene tus ubicaciones y notas. Detalles en [privacidad](docs/06_PRIVACIDAD.md).

## Derechos de uso

Nombre elegido: PinHaven. Falta confirmar disponibilidad en App Store Connect. No se ha comprobado disponibilidad comercial ni se ha decidido una licencia de distribución. No se incluye una licencia abierta por defecto; acordarla antes de aceptar contribuciones públicas o publicar código para reutilización.
