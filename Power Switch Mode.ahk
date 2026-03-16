#Requires AutoHotkey v2.0
#SingleInstance Ignore ; Evita que se abran múltiples instancias de la aplicación
KeyHistory 0           ; Desactiva el historial de teclas para mejorar el rendimiento
ListLines false        ; Desactiva el registro de líneas para mayor velocidad

; ==============================================================================
; POWER SWITCH MODE - PUNTO DE ENTRADA PRINCIPAL
; ==============================================================================
; Autor: Martin F. Cervini
; Descripción: Aplicación premium para la gestión rápida de planes de energía
;              y monitoreo de batería en sistemas Windows.
; Versión: 1.3.1
; ==============================================================================

; --- 1. LIBRERÍAS Y COMPONENTES DE UI ---
; Cargamos las dependencias necesarias para la lógica y la interfaz
#Include "lib\Utils.ahk"            ; Funciones de utilidad general
#Include "lib\PowerPlans.ahk"       ; Lógica de gestión de planes de energía
#Include "lib\BatteryMonitor.ahk"    ; Monitoreo de estado de batería
#Include "ui\Banner.ahk"            ; Sistema de notificaciones visuales (Banners)
#Include "ui\SettingsGui.ahk"       ; Interfaz de configuración y "Acerca de"

; --- 2. CONFIGURACIÓN E INICIALIZACIÓN ---
; Definimos la ruta de la carpeta de datos en AppData del usuario
AppDataFolder := A_AppData . "\Power Switch Mode"
if not DirExist(AppDataFolder)
    DirCreate(AppDataFolder)

; Definimos el archivo de configuración (.ini) y el atajo por defecto
SETTINGS_FILE := AppDataFolder . "\config.ini"
DEFAULT_HOTKEY := "^!p" ; Atajo por defecto: Ctrl + Alt + P

; Leemos el atajo guardado o usamos el por defecto si no existe
HOTKEY_SWITCH := IniRead(SETTINGS_FILE, "General", "Atajo", DEFAULT_HOTKEY)

; --- AJUSTES ESPECÍFICOS DE BATERÍA ---
; Leemos las preferencias del usuario para las alarmas de batería
MONITOR_VISIBLE := (IniRead(SETTINGS_FILE, "Battery", "AlarmaVisual", "1") = "1")
MONITOR_SOUND := (IniRead(SETTINGS_FILE, "Battery", "AlarmaSonora", "1") = "1")
ALARM_LEVEL := IniRead(SETTINGS_FILE, "Battery", "NivelBateria", "97")
SOUND_TYPE := IniRead(SETTINGS_FILE, "Battery", "TipoSonido", "Premium")

; Mapa de sonidos disponibles para las notificaciones
SOUNDS := Map(
    "Premium", "C:\Windows\Media\Windows Notify System Generic.wav",
    "Brisa", "C:\Windows\Media\Windows Background.wav",
    "Eco", "C:\Windows\Media\Windows Navigation Start.wav",
    "Ding", "C:\Windows\Media\ding.wav"
)

; --- VARIABLES DE CONTROL OPERATIVO ---
ALARM_FIRED := false      ; Indica si la alarma de carga baja ya se activó
FULL_ALARM_FIRED := false ; Indica si la alarma de carga completa ya se activó
PLANES := []              ; Almacenará la lista de planes de energía detectados

; Inicializamos datos del sistema
ObtenerPlanesSistema()    ; Escanea los planes de energía de Windows
TIENE_BATERIA := SistemaTieneBateria() ; Detecta si el equipo tiene hardware de batería

; --- 3. CONSTRUCCIÓN DEL MENÚ DE LA BANDEJA (TRAY MENU) ---
; Personalizamos el menú que aparece al interactuar con el icono
A_IconTip := "Power Switch Mode | Por: @TinchoXP_"
A_TrayMenu.Delete() ; Limpiamos el menú estándar de AHK

; 3a. ACCIONES PRINCIPALES
A_TrayMenu.Add("Cambiar Plan Ahora", CambiarPlan)
A_TrayMenu.Default := "Cambiar Plan Ahora" ; Lo ponemos en NEGRITA y es la acción por defecto
A_TrayMenu.Add() ; Separador visual

; 3c. SECCIÓN DE BATERÍA (Solo se muestra si hay batería detectada)
if TIENE_BATERIA {
    MenuBateria := Menu()
    MenuBateria.Add("𝗔𝗹𝗮𝗿𝗺𝗮 𝗩𝗶𝘀𝘂𝗮𝗹", AlternarAlarmaVisual)
    if MONITOR_VISIBLE
        MenuBateria.Check("𝗔𝗹𝗮𝗿𝗺𝗮 𝗩𝗶𝘀𝘂𝗮𝗹")

    MenuBateria.Add("𝗔𝗹𝗮𝗿𝗺𝗮 𝗦𝗼𝗻𝗼𝗿𝗮", AlternarAlarmaSonora)
    if MONITOR_SOUND
        MenuBateria.Check("𝗔𝗹𝗮𝗿𝗺𝗮 𝗦𝗼𝗻𝗼𝗿𝗮")

    MenuBateria.Add() ; Separador interno
    MenuBateria.Add("Nivel: 80%", (*) => CambiarNivelAlarma("80"))
    MenuBateria.Add("Nivel: 95%", (*) => CambiarNivelAlarma("95"))
    MenuBateria.Add("Nivel: 97%", (*) => CambiarNivelAlarma("97"))
    MenuBateria.Add("Nivel: 100%", (*) => CambiarNivelAlarma("100"))
    ActualizarChecksNivel()

    MenuBateria.Add() ; Separador interno
    MenuSonidos := Menu()
    MenuSonidos.Add("Notificación (Premium)", (*) => CambiarSonido("Premium"))
    MenuSonidos.Add("Suave (Brisa)", (*) => CambiarSonido("Brisa"))
    MenuSonidos.Add("Súper Sutil (Eco)", (*) => CambiarSonido("Eco"))
    MenuSonidos.Add("Clásico (Ding)", (*) => CambiarSonido("Ding"))
    ActualizarChecksSonido()
    MenuBateria.Add("𝗧𝗶𝗽𝗼 𝗱𝗲 𝗦𝗼𝗻𝗶𝗱𝗼", MenuSonidos)

    ; Agregamos el submenú de batería al menú principal con estilo resaltado (Unicode)
    A_TrayMenu.Add("𝗔𝗹𝗲𝗿𝘁𝗮𝘀 𝗱𝗲 𝗕𝗮𝘁𝗲𝗿𝗶𝗮", MenuBateria)
    A_TrayMenu.Add() ; Separador visual
}

; 3d. CONFIGURACIÓN E INFORMACIÓN
A_TrayMenu.Add("Configurar Atajo", (*) => MostrarConfiguracion())

; 3b. INTEGRACIÓN CON EL SISTEMA
A_TrayMenu.Add("Iniciar con Windows", AlternarInicioDesdeTray)
if EsInicioAutomatico()
    A_TrayMenu.Check("Iniciar con Windows")
A_TrayMenu.Add() ; Separador visual
A_TrayMenu.Add("𝗔𝗰𝗲𝗿𝗰𝗮 𝗱𝗲", (*) => MostrarAcercaDe())
A_TrayMenu.Add("Salir", (*) => ExitApp())

; --- 4. DESPLIEGUE Y MANEJO DE EVENTOS ---
; Configuramos el icono de la aplicación
if not A_IsCompiled {
    iconPath := A_ScriptDir . "\assets\power_switch_icon.png"
    if !FileExist(iconPath)
        iconPath := A_ScriptDir . "\assets\power_switch_icon.ico"
    try TraySetIcon(iconPath)
}

; Iniciamos los servicios de monitoreo en segundo plano
if TIENE_BATERIA
    GestionarTemporizador()

; Registramos los mensajes del sistema y atajos globales
OnMessage(0x404, TRAY_CLICK) ; Escucha clics en el icono de la bandeja (WM_USER + 4)
Hotkey HOTKEY_SWITCH, CambiarPlan ; Registra el atajo de teclado global
LiberarRAM() ; Optimización inicial de memoria

; --- 5. FUNCIONES DE RETORNO (CALLBACKS) ---

; TRAY_CLICK: Maneja las interacciones del ratón con el icono de la bandeja
TRAY_CLICK(wParam, lParam, msg, hwnd) {
    ; 0x202 = WM_LBUTTONUP (Clic izquierdo soltado)
    ; Permitimos que el menú se abra tanto con clic izquierdo como derecho
    if (lParam = 0x202)
        A_TrayMenu.Show()
}

; AlternarInicioDesdeTray: Maneja la opción de ejecución automática al iniciar Windows
AlternarInicioDesdeTray(*) {
    actual := EsInicioAutomatico()
    AlternarInicioAutomatico(!actual) ; Cambia el estado en el Registro de Windows

    ; Actualizamos el visual del menú (tilde)
    if !actual
        A_TrayMenu.Check("Iniciar con Windows")
    else
        A_TrayMenu.Uncheck("Iniciar con Windows")

    ; Notificamos al usuario con un banner estilizado
    msg := "Inicio con Windows: " . (!actual ? "Activado" : "Desactivado")
    color := !actual ? "31C950" : "4e6a7b" ; Verde para activar, Azul Acero para desactivar
    MostrarBanner(msg, color, "System", 3000)
}
