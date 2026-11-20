<p align="center">
<img src="../img/keenquad-header.png" alt="KeenQuad" width="800">
</p>
<h3 align="center">Resoluciones HiDPI nítidas para tu pantalla, con un clic desde la barra de menús</h3>
<p align="center">
<a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/KeenQuad?style=flat" alt="Última versión"></a> <a href="https://github.com/33to9/KeenQuad/releases"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/total?style=flat" alt="Descargas totales"></a> <a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/latest/total?style=flat" alt="Descargas de la última versión"></a> <a href="https://github.com/33to9/KeenQuad/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/KeenQuad?style=flat" alt="Licencia"></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.ko.md">한국어</a> · <a href="README.fr.md">Français</a> · <b>Español</b>
</p>

> **KeenQuad** es una pequeña app de la barra de menús que cambia tu pantalla entre resoluciones HiDPI, incluidas las nítidas que Ajustes del Sistema no muestra.
> En muchas pantallas externas, una resolución como 1600 × 1000 aparece en Ajustes del Sistema solo en su versión 1x, que se ve borrosa. macOS también tiene una versión HiDPI que se ve nítida, pero solo las apps que leen la lista completa de modos de pantalla pueden cambiar a ella. Eso es justo lo que hace KeenQuad, y nada más.

## Por qué la misma resolución puede verse borrosa o nítida

Cada tamaño suele aparecer dos veces en la lista de modos de pantalla de macOS. En un panel de 2560 × 1600, para 1600 × 1000:

| Versión | Cómo la dibuja macOS | Se ve |
|---|---|---|
| 1x | Renderiza 1600 × 1000 píxeles y los estira hasta el panel | Borrosa |
| HiDPI | Renderiza 3200 × 2000 píxeles y los reduce hasta el panel | Nítida |

Ajustes del Sistema › Pantallas solo muestra los modos de la interfaz pública, que oculta muchas versiones HiDPI. Si eliges 1600 × 1000 ahí, obtienes la versión 1x. Cuando el modo actual es uno HiDPI elegido con KeenQuad, Ajustes del Sistema muestra seleccionado el que tiene el mismo nombre; si vuelves a hacer clic en él, pasas a la versión borrosa.

Para saber cuál usas, ejecuta `system_profiler SPDisplaysDataType`: en HiDPI, **Resolution** es el doble de **UI Looks like**.

## Funciones

- Muestra todas las resoluciones HiDPI de cada pantalla, incluidas las ocultas, y marca la actual y el tamaño píxel a píxel del panel
- Un clic para cambiar. Si no confirmas una resolución nueva en 15 segundos, vuelve sola a la anterior, así que una pantalla en negro se arregla sola
- Si usas una resolución 1x borrosa, el menú ofrece **Cambiar a la versión nítida** del mismo tamaño, con el mismo tamaño de escritorio
- Las resoluciones que mantienes siguen ahí tras salir, cerrar sesión y reiniciar; macOS las guarda, así que nada se ejecuta en segundo plano
- Abrir al iniciar sesión y **Buscar actualizaciones…**
- English, 简体中文, 繁體中文, 日本語, Deutsch, 한국어, Français y Español; sigue el idioma del sistema, o elige uno en el menú

## Requisitos del sistema

- Un Mac con chip de Apple
- macOS 14 o posterior

## Instalación

### Opción 1: instalación en una línea (recomendada, sin aviso de Gatekeeper)

Abre Terminal, pega esta línea y pulsa Retorno:

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/KeenQuad/main/install.sh | bash
```

El script descarga la última versión desde GitHub, comprueba su SHA-256, la instala en Aplicaciones y la abre. Los archivos descargados con curl no llevan la marca de cuarentena, así que macOS no bloquea la primera apertura. Si KeenQuad ya está instalado, se actualiza en su sitio y conserva el ajuste de abrir al iniciar sesión. El script es corto; puedes [leerlo](../install.sh) antes.

### Opción 2: ZIP

Descarga el último `KeenQuad_vX.Y.Z_macOS.zip` desde [Releases](https://github.com/33to9/KeenQuad/releases/latest), descomprímelo y mueve KeenQuad a la carpeta Aplicaciones.

La app no está notarizada por Apple, así que macOS bloquea la primera apertura una vez:
- **macOS 15 y posterior**: haz doble clic (aparece un aviso), abre **Ajustes del Sistema → Privacidad y seguridad**, desplázate hacia abajo y haz clic en **Abrir igualmente**
- **macOS 14**: haz clic derecho en la app → **Abrir**

### Actualizar

Elige **Buscar actualizaciones…** en el menú de KeenQuad. Si hay una versión nueva, KeenQuad muestra las novedades y abre la página de descarga. Para actualizar sin el aviso de Gatekeeper, vuelve a ejecutar la instalación en una línea.

## Cómo usar KeenQuad

Haz clic en el icono de KeenQuad en la barra de menús:

- Haz clic en una resolución para cambiar. Con una resolución nueva, KeenQuad pregunta **¿Mantener esta resolución?**: pulsa Retorno para mantenerla, Esc para volver a la anterior, o espera 15 segundos y vuelve sola. Las resoluciones que mantuviste antes se aplican al instante.
- **Cambiar a la versión nítida** aparece cuando la resolución actual es una 1x borrosa que tiene versión HiDPI.
- **Otras proporciones** contiene tamaños HiDPI cuya forma no coincide con el panel.
- **Idioma** y **Abrir al iniciar sesión** están al final del menú.

## Permisos

Ninguno. Cambiar de modo de pantalla no requiere grabación de pantalla, accesibilidad ni ningún otro permiso. Si macOS te pide aprobar el ítem de inicio, KeenQuad abre la página correspondiente de Ajustes del Sistema.

## Privacidad

KeenQuad no recopila nada y no tiene telemetría. Solo se conecta a internet cuando haces clic en **Buscar actualizaciones…**: una única solicitud a la API de GitHub para consultar la última versión, sin ninguna información sobre ti. Tus ajustes se guardan en `~/Library/Preferences/com.pivotfrag.keenquad.plist`.

## Desinstalar

1. En el menú de KeenQuad, desactiva **Abrir al iniciar sesión** y elige **Salir de KeenQuad**.
2. Elimina `/Applications/KeenQuad.app`.
3. Opcional: ejecuta `defaults delete com.pivotfrag.keenquad`.

La resolución que estés usando se mantiene; cámbiala en Ajustes del Sistema si quieres.

## Cómo funciona

KeenQuad lee y cambia los modos de pantalla mediante funciones privadas de CoreGraphics (`CGSGetNumberOfDisplayModes`, `CGSGetDisplayModeDescriptionOfLength`, `CGSConfigureDisplayMode`), las mismas que usa la herramienta de código abierto `displayplacer`. No crea resoluciones, no instala archivos de sustitución de pantalla ni pide la contraseña de administrador; solo cambia a modos que macOS ya tiene. Una resolución nueva se aplica primero solo mientras la app está abierta, así que si KeenQuad se fuerza a salir, macOS la revierte; solo se guarda de forma permanente cuando la mantienes.

Como usa funciones privadas, una futura actualización de macOS podría cambiarlas. Si algún día el menú aparece vacío, [abre una issue](https://github.com/33to9/KeenQuad/issues).

## Compilar desde el código fuente

Requisitos: herramientas de línea de comandos de Xcode (no hace falta Xcode).

```bash
git clone https://github.com/33to9/KeenQuad.git
cd KeenQuad/tray
./build.sh --install        # compilar e instalar en /Applications
./Tests/run-selftest.sh     # pruebas de reglas de solo lectura, no cambia nada
```

`./build.sh --package` crea `dist/KeenQuad_vX.Y.Z_macOS.zip` para publicar una versión. Las notas de desarrollo (en inglés) están en [`tray/README.md`](../tray/README.md).

## Licencia

Este proyecto está bajo la licencia **GPL-3.0-only** (consulta [LICENSE](../LICENSE)). El nombre KeenQuad y sus iconos no están cubiertos por la licencia; consulta [TRADEMARK.md](../TRADEMARK.md).

Copyright © 2026 [Pivotfrag LLC](https://pivotfrag.com)
