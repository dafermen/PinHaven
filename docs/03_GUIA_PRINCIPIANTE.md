# Guía para un desarrollador principiante

## 1. Qué vas a construir

Una aplicación iPhone que recuerda sitios. La **vista** muestra información; el **modelo** define sus campos; el **servicio** hace una tarea como pedir el GPS; la **persistencia** conserva los datos al cerrar; un **DTO** transporta los datos sin depender de la base.

No necesitas un servidor ni claves de Google para esta versión. Sí necesitas un Mac para compilar SwiftUI y usar el SDK de iOS. Este ZIP contiene código fuente, no una aplicación instalable directamente desde Archivos en el iPhone.

## 2. Preparar el entorno

1. Instala Xcode 16 o posterior desde la fuente oficial de Apple, compatible con tu Mac.
2. Abre Xcode una vez y completa la instalación de componentes.
3. En **Xcode → Settings → Components/Platforms** instala un runtime de iOS Simulator si no hay uno disponible. El nombre de esta sección puede variar con la versión.
4. Descomprime el proyecto en una carpeta de trabajo.
5. Abre `PinHaven.xcodeproj`. No hace falta crear otro proyecto ni copiar archivos a mano.
6. En la barra superior elige **PinHaven** como esquema y un iPhone Simulator.
7. Pulsa ⌘R y espera a que termine la primera compilación.

Si Xcode solicita un equipo de firma al usar el simulador, revisa que el destino sea realmente un simulador. Para dispositivo físico configura **Signing & Capabilities → Team**, un bundle identifier propio y los ajustes de desarrollo requeridos por el iPhone. Las opciones de distribución dependen de tu cuenta de Apple.

## 3. Primer recorrido

1. Pulsa «Guardar mi primer sitio».
2. Nombre: `Sitio de prueba`.
3. Latitud: `40.7128`. Longitud: `-74.0060`. Son coordenadas de ejemplo, no tu ubicación personal.
4. Notas: `Entrada lateral`. Categoría: `Viajes`. Marca favorito.
5. Guarda; busca `entrada`; filtra favoritos.
6. Abre el detalle y verifica el enlace compartido.
7. Cierra y vuelve a abrir la app: el sitio debe permanecer.
8. Exporta un respaldo en una ubicación local de Archivos.

La simulación de GPS depende de **Features → Location** del simulador o de una ubicación GPX seleccionada en Xcode. Para capturar la posición real y evaluar precisión usa un iPhone físico.

## 4. Cómo leer el código

Empieza con `PlaceRecord.swift`: es Swift con datos y validación. Sigue con `Place.swift`: `@Model` le indica a SwiftData que debe persistir esta clase. Luego lee `HomeView`: `@Query` obtiene registros y actualiza la interfaz al cambiar datos.

En `PlaceEditor`, `@State` contiene el borrador de la pantalla. `@Environment(\.modelContext)` obtiene el contexto de persistencia. `@StateObject` mantiene vivo el servicio GPS durante la vida de la vista. No copies esos decoradores sin entender qué estado posee cada componente.

En `LocationService`, iOS comunica resultados mediante métodos de delegado. La solicitud puede tardar, fallar o ser rechazada: no hay que asumir una coordenada inmediata.

## 5. Tu primer cambio seguro

Objetivo: añadir la categoría **Salud**.

1. Crea una rama `feature/categoria-salud`.
2. En `PlaceEditor.categories`, añade `"Salud"`.
3. Compila, crea un sitio con esa categoría y verifica el filtro de Inicio.
4. Ejecuta ⌘U.
5. Actualiza la documentación si cambia el comportamiento y crea un commit claro.

No necesitas migrar la base para este cambio: `category` ya es una cadena. Si agregas una propiedad persistente nueva a una app distribuida, sí debes estudiar migraciones y probar datos anteriores.

## 6. Cómo depurar

- **No compila:** abre el Issue Navigator (⌘5), lee el primer error y corrígelo antes de los secundarios. Anota versión de Xcode y destino.
- **No hay GPS:** revisa permisos, ubicación simulada, señal y el mensaje de la app. También puedes escribir coordenadas.
- **No aparecen mapas:** comprueba red. La agenda no necesita mapa cargado para conservar datos existentes.
- **No aparece WhatsApp:** prueba en un iPhone donde esté instalado y disponible para compartir. La app usa el selector del sistema.
- **No se importa:** debe ser JSON exportado por PinHaven, con versión admitida y campos completos. No modifiques coordenadas ni identificadores al azar.
- **No abre la base:** no desinstales la app ni borres el almacén de un usuario para «arreglarlo». Conserva los datos y analiza el error.

## 7. Hábitos de trabajo

Haz una tarea por rama, escribe el resultado esperado antes del código y prueba el caso normal y el de error. Nunca subas datos reales, coordenadas del hogar, certificados ni perfiles de firma. Guarda un respaldo antes de experimentar con migraciones. Si no puedes ejecutar una prueba, regístrala como pendiente; no la marques aprobada.

## 8. Orden de aprendizaje recomendado

Swift básico y opcionales → estructuras/clases → SwiftUI y estado → listas/formularios → SwiftData → permisos y asincronía → pruebas → extensiones. Usa las referencias oficiales de `10_FUENTES.md` para profundizar.
