# Trabajar desde Windows, Mac y Xcode Cloud

Preparación inicial: 2 de noviembre de 2026. Repositorio: https://github.com/dafermen/PinHaven.git

## Windows

Carpeta solicitada: `C:\Projects\PinHaven`. Abre esta carpeta como proyecto local al continuar el desarrollo.

```powershell
cd C:\Projects\PinHaven
git status
git pull --ff-only
python scripts/validate_repository.py
```

Puedes editar documentación, lógica y vistas desde Windows. La verificación estructural no compila Swift ni ejecuta XCTest. No ejecutes el generador sobre cambios de firma realizados únicamente desde Xcode: refleja primero esos valores en `scripts/generate_project.py`.

## Primer arranque en Mac

```bash
mkdir -p ~/Projects
cd ~/Projects
git clone https://github.com/dafermen/PinHaven.git
cd PinHaven
python3 scripts/validate_repository.py
open PinHaven.xcodeproj
```

Selecciona el esquema compartido PinHaven y un simulador iPhone con iOS 17 o posterior. Ejecuta Run y después Product → Test, o `bash scripts/test_ios.sh`. Registra versión de Xcode, runtime, resultado y fallos en el estado de entrega. Para dispositivo físico elige tu equipo de firma y un bundle identifier propio; actualiza también el generador. No incluyas certificados ni perfiles en Git.

## Alternar equipos

Antes de empezar: `git status` y `git pull --ff-only`. Trabaja en una rama como `git switch -c feat/descripcion`. Al terminar revisa `git diff`, valida, crea un commit y sube la rama con `git push -u origin HEAD`. En el otro equipo recupera esa rama con `git fetch origin` y `git switch nombre-de-rama`. Confirma y sube tus cambios antes de cambiar de equipo. No copies DerivedData ni sincronices la carpeta .git por servicios de archivos.

## Xcode Cloud, después de validar localmente

Requiere membresía en Apple Developer Program y permisos de la cuenta. Configura el primer workflow desde Xcode, concede acceso de la aplicación Xcode Cloud solo al repositorio PinHaven y empieza por compilación y pruebas de simulador con el esquema compartido. Configura firma y distribución después de validar el primer build. No hay workflow de Xcode Cloud activado por esta preparación.

El archivo `.github/workflows/ios.yml` es para GitHub Actions y es independiente de Xcode Cloud. No prueba que Cloud esté configurado. Cuando el workflow esté conectado, los pushes desde Windows podrán iniciar las compilaciones remotas según sus condiciones.

Referencias oficiales consultadas el 2 de noviembre de 2026:

- [Requisitos de Xcode Cloud](https://developer.apple.com/documentation/xcode/setting-up-your-project-to-use-xcode-cloud)
- [Primer workflow](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow)
- [Conectar GitHub](https://developer.apple.com/documentation/xcode/connecting-xcode-cloud-to-github)

## Pendientes para la primera sesión Mac

1. Compilar y ejecutar los siete casos XCTest existentes.
2. Probar creación, edición, persistencia, GPS y respaldos con datos de prueba.
3. Resolver hallazgos antes de marcar el MVP como validado.
4. Implementar localización inglés/español en una tarea posterior.
5. Configurar Xcode Cloud con la cuenta del propietario.

## Configuración realizada el 3 de noviembre de 2026

PinHaven ya está conectado a Xcode Cloud por el propietario. Proyecto y generador usan `com.innovalogic.pinhaven` (app), `com.innovalogic.pinhaven.tests` (tests), Team `7799N4RYUG` y firma automática. No regenerar con una copia antigua del generador: restauraría la identidad de ejemplo.

Build 1 aprobó Archive, pero falló exportación con `com.example.pinhaven`; ver evidencia en el estado de entrega. Para la siguiente ejecución, guardar el workflow con Test iOS, esquema PinHaven, un simulador disponible y Required to Pass. El editor muestra Distribution Preparation None; las pruebas remotas y una exportación corregida todavía deben verificarse.
