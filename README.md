# Power Switch Mode ⚡

![Versión](https://img.shields.io/badge/version-1.0-blue.svg)
![Plataforma](https://img.shields.io/badge/platform-Windows_10%20%7C%2011-lightgrey.svg)
![Lenguaje](https://img.shields.io/badge/language-AutoHotkey_v2-green.svg)

**Power Switch Mode** es una utilidad ultra-ligera para Windows desarrollada en AutoHotkey v2 que te permite alternar rápidamente entre los distintos planes de energía del sistema mediante un atajo de teclado global.

## ✨ Características Principales

- **Atajo Global Personalizable**: Cambiá de plan de energía en un instante (por defecto `Ctrl + Alt + P`).
- **Interfaz Gráfica Elegante**: Banner de notificación OSD (On-Screen Display) moderno con soporte nativo para Modo Oscuro y resaltado de colores según el tipo de rendimiento.
- **Detección Automática**: Reconoce y extrae automáticamente los planes de energía instalados en tu sistema operativo, sin necesidad de configuraciones previas manuales.
- **Ultra Ligero**: Diseñado enfocado en la minimización de consumo de memoria RAM, liberando recursos del sistema instantáneamente tras cada ejecución (`psapi\EmptyWorkingSet`).
- **Completamente Portátil**: Ejecutable autónomo sin requerimiento de instalación o configuración.

## 🚀 Instalación y Uso

1. Descargá el archivo compliado `Power Switch Mode.exe` desde la carpeta del proyecto.
2. Ejecutalo para iniciar la aplicación manualemente.

### 🔄 Iniciar con Windows (Automáticamente)
Para que el programa comience automáticamente cada vez que encendés tu computadora:
1. Hacé clic derecho sobre el archivo `Power Switch Mode.exe` y seleccioná **Crear acceso directo**.
2. Presioná la combinación de teclas `Win + R` en tu teclado para abrir la ventana *Ejecutar*.
3. Escribí exactamente el comando: `shell:startup` y apretá Enter. Se abrirá una carpeta de sistema.
4. **Copiá y pegá** el acceso directo que creaste recién dentro de esa carpeta.

**¡Listo!** El programa arrancará invisible y listo para usarse apenas inicies sesión en Windows.

3. Presioná `Ctrl + Alt + P` para ciclar instantáneamente entre tus planes de rendimiento activos.

*Si preferís usar el código fuente original, asegurate de tener instalado **AutoHotkey v2** y ejecutá `Power Switch Mode.ahk`.*

## ⚙️ Configuración

Podés cambiar el atajo de teclado en cualquier momento:
1. Ubicá el icono del rayo verde (🗲) en la bandeja del sistema (junto al reloj).
2. Hacé clic derecho y seleccioná **"Configurar Atajo"**.
3. Presioná tus teclas deseadas y hacé clic en guardar.

---
**Desarrollado con ❤️ en Argentina**  
**Autor:** Martin F. Cervini | **IG:** [@tinchoxp_](https://instagram.com/tinchoxp_)
