# GitHub y colaboración

## Estado

Este paquete está listo para convertirse en repositorio. **No se ha creado ni publicado un repositorio remoto**, porque no se indicó uno de destino. Se entrega una carpeta con proyecto, documentación, pruebas, workflow y plantillas. No contiene credenciales ni datos personales precargados.

## Crear el repositorio desde cero

1. Crea un repositorio en tu cuenta de GitHub, por ejemplo `PinHaven`. Recomendado inicialmente privado mientras decides nombre y licencia.
2. Para evitar conflictos, créalo vacío: sin README, licencia ni `.gitignore` automáticos; el paquete ya tiene su documentación.
3. Abre Terminal en la carpeta raíz descomprimida y ejecuta:

```bash
git init -b main
git add .
git commit -m "Initial local iPhone MVP and Spanish project documentation"
```

4. Copia la URL exacta de TU repositorio. Sustituye el ejemplo antes de ejecutar:

```bash
git remote add origin https://github.com/TU_USUARIO/PinHaven.git
git push -u origin main
```

No uses contraseñas o tokens dentro de estos archivos. Autentica con el mecanismo oficial configurado en tu Mac. Si el remoto ya tiene contenido, revisa sus ramas y archivos antes de subir; no uses force push para resolver diferencias.

## Trabajo cotidiano

```bash
git switch -c feature/F2-T02-fotos
# Realiza el cambio, compila y prueba.
git add .
git commit -m "Add local place photo selection"
git push -u origin feature/F2-T02-fotos
```

Abre un Pull Request a `main`. Explica el problema, comportamiento nuevo, pruebas ejecutadas y límites. Mantén las tareas pequeñas y no mezcles migración, rediseño y nuevas funciones en un solo cambio.

## Tablero de actividades

Crea columnas **Pendiente**, **En curso**, **En revisión** y **Terminado**. Usa `docs/BACKLOG.csv` como fuente para crear issues o preparar una importación con una herramienta que admita CSV; no se promete importación nativa directa de ese CSV en GitHub Projects.

Etiquetas sugeridas: `fase-1`, `fase-2`, `bug`, `documentacion`, `principiante`, `privacidad`, `ios`. Utiliza el identificador F?-T?? en el título de cada issue y las dependencias del roadmap.

## Automatización incluida

`.github/workflows/ios.yml` ejecuta validación estructural y `xcodebuild test` en macOS para pushes, pull requests y ejecución manual. No publica, firma ni despliega la app. Las pruebas y el workflow no han corrido en GitHub en esta entrega. Revisa disponibilidad y consumo de minutos de Actions de tu cuenta.

## Reglas del repositorio

No subir respaldos de sitios reales, certificados, perfiles de firma, credenciales, datos de GPS, DerivedData ni archivos del usuario de Xcode. La licencia debe decidirla el propietario antes de distribución pública. Antes de fusionar, build y pruebas pertinentes deben pasar.
