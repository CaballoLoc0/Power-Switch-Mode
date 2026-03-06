#Requires AutoHotkey v2.0
#SingleInstance Ignore
KeyHistory 0
ListLines false

; ============================================================
; Power Switch Mode
; Autor: Martin F. Cervini
; Email: marfercer@gmail.com
; IG: @tinchoxp_
; Version: 1.0 - 2026
; ============================================================

; --- SETTINGS ---
AppDataFolder := A_AppData . "\Power Switch Mode"
if not DirExist(AppDataFolder)
    DirCreate(AppDataFolder)

SETTINGS_FILE := AppDataFolder . "\config.ini"
DEFAULT_HOTKEY := "^!p" ; Ctrl + Alt + P

HOTKEY_SWITCH := IniRead(SETTINGS_FILE, "General", "Atajo", DEFAULT_HOTKEY)

; Obtener planes dinámicamente del sistema
PLANES := []
ObtenerPlanesSistema()

; --- TRAY MENU ---
A_IconTip := "Power Switch Mode | Por: @TinchoXP_"
A_TrayMenu.Delete()
A_TrayMenu.Add("Cambiar Plan Ahora", CambiarPlan)
A_TrayMenu.Add("Configurar Atajo", (*) => MostrarConfiguracion())
A_TrayMenu.Add()
A_TrayMenu.Add("Acerca de", (*) => MostrarAcercaDe())
A_TrayMenu.Add()
A_TrayMenu.Add("Salir", (*) => ExitApp())
if not A_IsCompiled {
    try TraySetIcon(A_ScriptDir . "\power_switch_icon.png")
}
A_TrayMenu.Default := "Acerca de"

; --- HOTKEYS ---
Hotkey HOTKEY_SWITCH, CambiarPlan
DllCall("psapi\EmptyWorkingSet", "ptr", -1)

; ==============================================================
; CAMBIAR PLAN
; ==============================================================
CambiarPlan(*) {
    Global PLANES
    try {
        ObtenerPlanesSistema()

        if (PLANES.Length <= 1) {
            MostrarBanner("Solo hay 1 plan disponible", "Rojo")
            return
        }

        ; Obtener GUID del plan activo
        linea := LeerComando("powercfg /getactivescheme")

        indiceActual := 0
        for index, plan in PLANES {
            if InStr(linea, plan.guid) {
                indiceActual := index
                break
            }
        }

        ; Siguiente plan (cíclico)
        siguienteIndice := (indiceActual >= PLANES.Length || indiceActual = 0) ? 1 : indiceActual + 1
        planSiguiente := PLANES[siguienteIndice]

        ; Cambiar plan
        RunWait "powercfg /setactive " . planSiguiente.guid, , "Hide"
        ; Determinar color del plan
        colorPlan := "White"
        if InStr(planSiguiente.nombre, "Máximo")
            colorPlan := "F24F2C" ; Rojo
        else if InStr(planSiguiente.nombre, "Alto")
            colorPlan := "F2B32C" ; Naranja
        else if InStr(planSiguiente.nombre, "Equilibrado")
            colorPlan := "31C950" ; Verde
        else if InStr(planSiguiente.nombre, "Economizador")
            colorPlan := "4EA8DE" ; Celeste

        nombreLimpio := Trim(RegExReplace(planSiguiente.nombre, "i)\s*rendimiento\s*", ""))
        MostrarBanner(nombreLimpio, colorPlan)
    } catch Error as err {
        MostrarBanner("Error: " . err.Message, "Rojo")
    }
    DllCall("psapi\EmptyWorkingSet", "ptr", -1)
}

; ==============================================================
; BANNER
; ==============================================================
MostrarBanner(mensaje, colorHex := "White") {
    static MyGui := 0
    if MyGui
        MyGui.Destroy()
    MyGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    
    esError := (colorHex = "Rojo")
    MyGui.BackColor := esError ? "0x330000" : "0x1A1A1A"

    ; 1. Título principal (Subtítulo s9, limpio y en Negrita para destacar sin sombra)
    MyGui.SetFont("s9 c7393B3 Bold", "Segoe UI Variable Display") 
    MyGui.AddText("x18 y15 w250 BackgroundTrans", "POWER SWITCH MODE")

    ; 2. Subtítulo 
    MyGui.SetFont("s10 c999999", "Segoe UI Variable Text")
    MyGui.AddText("x18 y+8 w250 BackgroundTrans", "Rendimiento:")

    ; 3. Símbolo y nombre del plan (Único campo completamente Centrado)
    simbolo := esError ? "⚠ " : "🗲 "
    textColor := esError ? "White" : colorHex

    MyGui.SetFont("s18 c" . textColor . " Bold", "Segoe UI Variable Display")
    MyGui.AddText("x0 y+2 w280 Center BackgroundTrans", simbolo . mensaje)

    MonitorGetWorkArea(1, &Left, &Top, &Right, &Bottom)
    BannerW := 280
    BannerH := 115
    FinalX := Right - BannerW - 20
    FinalY := Bottom - BannerH - 20

    MyGui.Show("x" . FinalX . " y" . FinalY . " w" . BannerW . " h" . BannerH . " NoActivate")
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", MyGui.Hwnd, "uint", 33, "int*", 2, "uint", 4)

    SetTimer(CerrarBanner, -3000)
    CerrarBanner() {
        try MyGui.Destroy()
        DllCall("psapi\EmptyWorkingSet", "ptr", -1)
    }
}

; ==============================================================
; CONFIGURACIÓN
; ==============================================================
MostrarConfiguracion() {
    Global HOTKEY_SWITCH
    ConfigGui := Gui("-MinimizeBox -MaximizeBox +AlwaysOnTop", "Configurar Atajo")
    AplicarModoOscuro(ConfigGui.Hwnd)
    ConfigGui.BackColor := "0x1A1A1A"
    
    ConfigGui.SetFont("s10 cWhite", "Segoe UI Variable Text")
    ConfigGui.AddText("w300", "Presiona la combinación de teclas que deseas usar:")
    
    MyHotkeyCtrl := ConfigGui.AddHotkey("w300 h30", HOTKEY_SWITCH)
    
    ConfigGui.SetFont("s9 c888888")
    ConfigGui.AddText("w300 Center", "(Ejemplo: Ctrl+Alt+P)")
    
    ConfigGui.SetFont("s10 cDefault")
    BtnSave := ConfigGui.AddButton("w100 h30 x115", "Guardar")
    BtnSave.OnEvent("Click", (*) => Guardar(MyHotkeyCtrl.Value))
    
    ConfigGui.Show("w330")

    Guardar(NuevoAtajo) {
        Global HOTKEY_SWITCH
        if (NuevoAtajo = "") {
            MsgBox("Por favor, ingresa una combinación válida.", "Atención", "Icon!")
            return
        }
        try {
            Hotkey HOTKEY_SWITCH, "Off"
            Hotkey NuevoAtajo, CambiarPlan, "On"
            IniWrite(NuevoAtajo, SETTINGS_FILE, "General", "Atajo")
            HOTKEY_SWITCH := NuevoAtajo
            ConfigGui.Destroy()
            MostrarBanner("Nuevo atajo: " . NuevoAtajo)
        } catch Error as err {
            MsgBox("Error: " . err.Message, "Error", "IconX")
        }
    }
}

; ==============================================================
; ACERCA DE
; ==============================================================
MostrarAcercaDe() {
    static AboutGui := 0
    if AboutGui {
        AboutGui.Show()
        return
    }
    AboutGui := Gui("-MinimizeBox -MaximizeBox +AlwaysOnTop", "Acerca de")
    AplicarModoOscuro(AboutGui.Hwnd)
    AboutGui.OnEvent("Close", (*) => (AboutGui := 0))
    AboutGui.BackColor := "0x1A1A1A"

    ; Icono Centrado (Ventana 400 - Icono 64 = 336 / 2 = 168)
    try {
        if A_IsCompiled
            AboutGui.AddPicture("w64 h-1 x168 y25 Icon1", A_ScriptFullPath)
        else
            AboutGui.AddPicture("w64 h-1 x168 y25", A_ScriptDir . "\power_switch_icon.png") 
    }

    ; Título
    AboutGui.SetFont("s20 cWhite Bold", "Segoe UI Variable Display")
    AboutGui.AddText("x0 y+15 w400 Center", "Power Switch Mode")

    ; Eslogan
    AboutGui.SetFont("s10 c888888", "Segoe UI Variable Text")
    AboutGui.AddText("x0 y+5 w400 Center", "Gestión de energía eficiente y rápida")

    ; Autor
    AboutGui.SetFont("s11 cWhite w600", "Segoe UI Variable Text")
    AboutGui.AddText("x0 y+25 w400 Center", "Autor: Martin F. Cervini")

    ; Links
    AboutGui.SetFont("s10 c4EA8DE Underline", "Segoe UI Variable Text")
    LinkMail := AboutGui.AddText("x0 y+10 w400 Center", "marfercer@gmail.com")
    LinkMail.OnEvent("Click", (*) => Run("mailto:marfercer@gmail.com"))

    LinkIG := AboutGui.AddText("x0 y+5 w400 Center", "@tinchoxp_")
    LinkIG.OnEvent("Click", (*) => Run("https://instagram.com/tinchoxp_"))

    ; Copyright
    AboutGui.SetFont("s9 c555555", "Segoe UI Variable Text")
    AboutGui.AddText("x0 y+30 w400 Center", "v1.0 - Copyright © 2026")

    AboutGui.Show("w400 h360")
}

; ==============================================================
; UTILIDADES
; ==============================================================
ObtenerPlanesSistema() {
    Global PLANES := []
    output := LeerComando("powercfg /l")
    for linea in StrSplit(output, "`n", "`r") {
        if RegExMatch(linea, "i)([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}).*\((.+?)\)", &match) {
            nombre := Trim(StrReplace(match[2], "*", ""))
            PLANES.Push({ nombre: nombre, guid: match[1] })
        }
    }
}

; Lee la salida de un comando usando cmd + archivo temporal
LeerComando(comando) {
    tmpFile := A_Temp . "\ahk_pwr_out.txt"
    RunWait(A_ComSpec . " /c " . comando . " > `"" . tmpFile . "`"", , "Hide")
    try {
        result := FileRead(tmpFile, "CP850")
        FileDelete(tmpFile)
        return result
    }
    catch {
        return ""
    }
}

AplicarModoOscuro(Hwnd) {
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", Hwnd, "uint", 20, "int*", 1, "uint", 4)
}
