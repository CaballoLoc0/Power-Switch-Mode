; ==============================================================================
; MÓDULO DE INTERFAZ DE USUARIO - CONFIGURACIÓN Y ACERCA DE
; ==============================================================================
; Descripción: Gestiona las ventanas de interacción avanzada, como el cambio
;              de atajos de teclado y la información de créditos del autor.
; ==============================================================================

/**
 * MostrarConfiguracion: Abre la ventana para que el usuario elija un nuevo atajo.
 */
MostrarConfiguracion() {
    static ConfigGui := 0

    ; Si la ventana ya existe, simplemente la traemos al frente
    if ConfigGui {
        ConfigGui.Show()
        return
    }

    global HOTKEY_SWITCH

    ; Creamos la ventana de configuración
    ConfigGui := Gui("-MinimizeBox -MaximizeBox +AlwaysOnTop", "Configurar Atajo")
    AplicarModoOscuro(ConfigGui.Hwnd)
    ConfigGui.BackColor := "0x1A1A1A"
    ConfigGui.OnEvent("Close", CerrarConfig) ; Manejador para el botón de cerrar (X)

    ; DESACTIVAR el atajo global temporalmente para que no interfiera mientras se escribe el nuevo
    try {
        Hotkey(HOTKEY_SWITCH, "Off")
    }

    ConfigGui.SetFont("s10 cWhite", "Segoe UI Variable Text")
    ConfigGui.AddText("w300", "Presiona la combinación de teclas que deseas usar:")

    ; Control especial de AutoHotkey para capturar combinaciones de teclas
    MyHotkeyCtrl := ConfigGui.AddHotkey("w300 h30", HOTKEY_SWITCH)

    ConfigGui.SetFont("s9 c888888")
    ConfigGui.AddText("w300 Center", "(Ejemplo: Ctrl+Alt+P)")

    ; Botón de Guardar
    ConfigGui.SetFont("s10 cDefault")
    BtnSave := ConfigGui.AddButton("w100 h30 x115 Default", "Guardar")
    BtnSave.OnEvent("Click", (*) => Guardar(MyHotkeyCtrl.Value))

    ConfigGui.Show("w330")

    ; --- FUNCIONALIDAD INTERNA DE LA VENTANA ---

    Guardar(NuevoAtajo) {
        global HOTKEY_SWITCH
        if (NuevoAtajo = "") {
            ConfigGui.Opt("+OwnDialogs") ; Bloquea la ventana de config hasta cerrar el aviso
            MsgBox("Por favor, ingresa una combinación válida.", "Atención", "Icon!")
            return
        }
        try {
            ; Registramos el nuevo atajo en el sistema y lo guardamos en el .ini
            Hotkey NuevoAtajo, CambiarPlan, "On"
            IniWrite(NuevoAtajo, SETTINGS_FILE, "General", "Atajo")
            HOTKEY_SWITCH := NuevoAtajo

            ConfigGui.Destroy()
            ConfigGui := 0 ; Limpiamos la instancia para permitir recrearla luego

            ; Mostramos notificación de éxito con el atajo en formato legible
            atajoHumano := HotkeyAHKAHumano(NuevoAtajo)
            MostrarBanner(atajoHumano, "4EA8DE", "Keyboard")
        } catch Error as err {
            ConfigGui.Opt("+OwnDialogs")
            MsgBox("Error al asignar atajo: " . err.Message, "Error", "IconX")
            ; Intentamos reactivar el atajo anterior si hubo falla
            try Hotkey(HOTKEY_SWITCH, "On")
        }
    }

    CerrarConfig(*) {
        ; Si el usuario cierra sin guardar, nos aseguramos de reactivar el atajo actual
        try {
            Hotkey(HOTKEY_SWITCH, "On")
        }
        ConfigGui.Destroy()
        ConfigGui := 0
    }
}

/**
 * MostrarAcercaDe: Muestra la ventana de créditos e información de contacto.
 * Incluye efectos de cambio de cursor sobre los enlaces.
 */
MostrarAcercaDe() {
    static AboutGui := 0

    if AboutGui {
        AboutGui.Show()
        return
    }

    AboutGui := Gui("-MinimizeBox -MaximizeBox +AlwaysOnTop", "Acerca de")
    AplicarModoOscuro(AboutGui.Hwnd)
    AboutGui.OnEvent("Close", CerrarAcercaDe)
    AboutGui.BackColor := "0x1A1A1A"

    ; --- LOGOTIPO ---
    try {
        iconPath := A_ScriptDir . "\assets\power_switch_icon.ico"
        if !FileExist(iconPath)
            iconPath := A_ScriptDir . "\assets\power_switch_icon.png"

        if A_IsCompiled
            AboutGui.AddPicture("w64 h-1 x168 y25 Icon1", A_ScriptFullPath)
        else
            AboutGui.AddPicture("w64 h-1 x168 y25", iconPath)
    }

    ; --- TEXTOS INFORMATIVOS ---
    AboutGui.SetFont("s20 cWhite Bold", "Segoe UI Variable Display")
    AboutGui.AddText("x0 y+15 w400 Center", "Power Switch Mode")

    AboutGui.SetFont("s10 c888888", "Segoe UI Variable Text")
    AboutGui.AddText("x0 y+5 w400 Center", "Gestión de energía eficiente y rápida")

    AboutGui.SetFont("s11 cWhite w600", "Segoe UI Variable Text")
    AboutGui.AddText("x0 y+25 w400 Center", "Autor: Martin F. Cervini")

    ; --- ENLACES DE CONTACTO ---
    AboutGui.SetFont("s10 c4EA8DE Underline", "Segoe UI Variable Text")

    LinkMail := AboutGui.AddText("x0 y+10 w400 Center", "marfercer@gmail.com")
    LinkMail.OnEvent("Click", (*) => Run("mailto:marfercer@gmail.com"))

    LinkIG := AboutGui.AddText("x0 y+5 w400 Center", "@tinchoxp_")
    LinkIG.OnEvent("Click", (*) => Run("https://instagram.com/tinchoxp_"))

    ; ACTIVAMOS EL CAMBIO DE CURSOR AL PASAR POR LOS ENLACES
    ; 0x20 = WM_SETCURSOR
    OnMessage(0x20, ControlCursor)

    AboutGui.SetFont("s9 c555555", "Segoe UI Variable Text")
    AboutGui.AddText("x0 y+30 w400 Center", "v1.1 - Copyright © 2026")

    AboutGui.Show("w400 h360")

    ; --- FUNCIONES INTERNAS ---

    ; ControlCursor: Cambia el cursor a la mano de Windows (Hand) sobre los textos de enlace
    ControlCursor(wParam, lParam, msg, hwnd) {
        try {
            ; Comprobamos si el control que disparó el evento es alguno de nuestros links
            if (IsSet(LinkMail) && IsSet(LinkIG) && (wParam == LinkMail.Hwnd || wParam == LinkIG.Hwnd)) {
                ; 32649 = Identificador de Windows para el cursor de mano
                cursorH := DllCall("LoadCursor", "ptr", 0, "ptr", 32649, "ptr")
                DllCall("SetCursor", "ptr", cursorH)
                return 1 ; Indica al sistema que ya manejamos el cursor
            }
        }
    }

    CerrarAcercaDe(*) {
        ; Importante: Dejar de escuchar el mensaje de cursor al cerrar para liberar recursos
        OnMessage(0x20, ControlCursor, 0)
        AboutGui.Destroy()
        AboutGui := 0
    }
}
