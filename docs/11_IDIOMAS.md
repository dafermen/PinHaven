# Idiomas de PinHaven

## Decisión del propietario

- Nombre del producto y proyecto: **PinHaven**, igual en todos los idiomas.
- Idioma principal: **English (en)**.
- Idioma adicional inicial: **Español (es)**.
- Documentación para el desarrollador: español, para facilitar el aprendizaje.
- Eslogan inglés: **Your places, always close.**
- Adaptación española: **Tus lugares, siempre cerca.**

## Estado real

La configuración de desarrollo indica inglés como idioma principal. El código inicial todavía contiene textos de interfaz en español; **no hay localización bilingüe completa en esta entrega**. F1-T10 debe implementarla antes de aceptar el MVP. No se cambia el texto de los registros del usuario al cambiar idioma.

## Alcance de F1-T10

1. Centralizar textos de interfaz en un catálogo de cadenas compatible con la versión de Xcode elegida.
2. Escribir textos originales en inglés y traducción española: listas, formularios, vacíos, búsqueda, filtros, acciones y confirmaciones.
3. Localizar errores propios, mensajes de permisos y etiquetas de accesibilidad. Los errores del sistema respetarán el comportamiento de iOS; no garantizar traducción literal del proveedor.
4. Admitir selección de idioma por aplicación mediante los ajustes de idioma de iOS. Al inicio no se requiere un selector propio dentro de PinHaven.
5. Comprobar inglés, español y fallback a inglés cuando el idioma preferido no esté soportado.
6. Usar formatos de fecha y números adecuados al idioma. Las coordenadas manuales actuales exigen punto decimal: explicar esa regla claramente o implementar un parser probado para ambos formatos sin confundir coma decimal y separador de coordenadas.
7. Mantener estables UUID, coordenadas, nombres, direcciones, notas y etiquetas del usuario. Categorías actuales están persistidas como cadenas en español: definir compatibilidad de claves estables antes de traducirlas; no crear filtros que mezclen categorías equivalentes.
8. Preservar el formato JSON versionado; no traducir claves de respaldo. Verificar exportación/importación después de cambiar idioma.
9. Añadir validación manual y pruebas pertinentes de fallback, búsqueda y categorías. Actualizar estado con evidencia real de Xcode/iPhone.

## Vocabulario de referencia

| Español | English |
|---|---|
| Mis sitios | My Places |
| Guardar sitio | Save Place |
| Favoritos | Favorites |
| Usar mi ubicación actual | Use Current Location |
| Buscar o seleccionar en el mapa | Search or Choose on Map |
| Observaciones | Notes |
| Etiquetas | Tags |
| Cómo llegar | Directions |
| Compartir sitio | Share Place |
| Datos y privacidad | Data & Privacy |
| Exportar todos los sitios | Export All Places |
| Importar un respaldo | Import Backup |
| Guardar / Cancelar / Eliminar | Save / Cancel / Delete |

## Criterios de aceptación

Ambos idiomas cubren el flujo completo de crear, editar, buscar, filtrar, compartir y respaldar. No quedan textos propios mezclados. Cambiar idioma y reiniciar no altera datos. VoiceOver tiene etiquetas coherentes. Inglés es la base, español es la opción adicional. La documentación técnica puede permanecer en español sin que eso determine el idioma de la app.
