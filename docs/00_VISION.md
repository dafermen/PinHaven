# Visión del proyecto

## Problema

Los sitios quedan dispersos entre mapas, chats, capturas y recuerdos. La dirección postal no siempre identifica una entrada, un parqueadero o un punto de encuentro. Hace falta una agenda que permita recordar un sitio con palabras personales y consultarlo localmente.

## Propuesta

Guardar un punto exacto, darle un nombre comprensible y añadir contexto. Recuperarlo rápidamente, abrir indicaciones en el mapa preferido y compartirlo sin que el receptor necesite instalar PinHaven.

Ejemplo: Darío está en un restaurante. Abre la app, elige «Usar mi ubicación actual», escribe «Empanadas cerca del trabajo», marca favorito y guarda. Después busca «empanadas», abre la ficha y comparte un enlace con Diana.

## Público y plataforma

Personas que necesitan un directorio personal y desarrolladores principiantes que aprenderán con un proyecto real. Primera plataforma: iPhone con iOS 17 o superior. Idioma principal: **English (en)**, con **Español (es)** como opción inicial. Nombre elegido: **PinHaven**. Eslogan: **Your places, always close.** La documentación técnica se mantiene en español. Localización del código inicial pendiente en F1-T10.

## Principios

1. Capturar rápido; los detalles pueden completarse después.
2. La coordenada es la ubicación; la dirección es información complementaria.
3. Sin registro ni servidor para el directorio.
4. Pedir GPS solamente por una acción del usuario y ofrecer captura manual.
5. No inventar datos ausentes en enlaces ni confundir el centro visible del mapa con el punto del negocio.
6. Cada fase debe dejar una app utilizable, con su propia aceptación.
7. Documentar errores y limitaciones con lenguaje claro.

## Metas comprobables

- Guardar un sitio con nombre y coordenadas, sin dirección obligatoria.
- Recuperar el registro tras cerrar y volver a abrir la app.
- Encontrarlo por notas y etiquetas, ignorando tildes y mayúsculas.
- Consultar y editar el directorio sin conexión.
- Exportar e importar sin sobrescribir silenciosamente registros existentes.

La meta de experiencia es guardar un sitio en unos pocos toques; el tiempo real se medirá en la prueba con usuarios. No se presenta una medición inventada.

## Decisiones abiertas

Confirmación del nombre en App Store Connect, licencia, identificador definitivo, idiomas adicionales futuros, política comercial, diseño del icono, distribución en App Store y requisitos finales de protección de respaldos. Las decisiones abiertas no impiden desarrollar y probar el MVP local.
