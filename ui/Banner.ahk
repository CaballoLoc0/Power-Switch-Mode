; ==============================================================================
; MÓDULO DE INTERFAZ DE USUARIO - BANNER
; ==============================================================================
; Descripción: Gestiona la creación y visualización de notificaciones flotantes
;              estilizadas (banners) en la esquina inferior derecha de la pantalla.
; ==============================================================================

/**
 * MostrarBanner: Crea y muestra una notificación visual temporal.
 * @param mensaje  Texto principal a mostrar.
 * @param colorHex Color del texto (ej: "White", "31C950", "Rojo").
 * @param tipo     Categoría de la notificación ("Power", "Battery", "Keyboard", "System", "Error").
 * @param duracion Tiempo en milisegundos antes de que el banner se cierre solo.
 * @param parpadeo Booleano para activar un efecto de parpadeo en el mensaje.
 */
MostrarBanner(mensaje, colorHex := "White", tipo := "Power", duracion := 5500, parpadeo := false) {
    static MyGui := 0

    ; Si ya hay un banner abierto, lo destruimos para mostrar el nuevo
    if MyGui
        MyGui.Destroy()

    ; Creamos la ventana: Siempre arriba, sin bordes, sin botón en la barra de tareas
    MyGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")

    ; Configuración de color de fondo (Rojizo si es error, Gris oscuro por defecto)
    esError := (colorHex = "Rojo")
    MyGui.BackColor := esError ? "0x330000" : "0x1A1A1A"

    ; --- BOTÓN DE CIERRE (X) ---
    ; Ubicado en la esquina superior derecha, permite cerrar el banner manualmente
    BtnClose := MyGui.AddText("x265 y8 w30 h25 Center BackgroundTrans c888888", "✕")
    BtnClose.SetFont("s10 Bold", "Segoe UI Variable Text")
    BtnClose.OnEvent("Click", (*) => CerrarBanner())

    ; --- 1. TÍTULO PRINCIPAL (HEADER) ---
    ; Identidad visual de la aplicación
    MyGui.SetFont("s8 c7393B3 Bold", "Segoe UI Variable Display")
    TituloCtrl := MyGui.AddText("x25 y15 w250 BackgroundTrans", "POWER SWITCH MODE")

    ; --- 2. SUBTÍTULO DINÁMICO ---
    ; Varía según la categoría de la información para dar contexto
    subtitulo := (tipo = "Keyboard") ? "Atajo Actualizado:" :
        (tipo = "Battery") ? "Carga de Batería:" :
            (tipo = "Power") ? "Modo de Rendimiento:" : "Estado del Sistema:"

    MyGui.SetFont("s9 c888888", "Segoe UI Variable Text")
    SubtituloCtrl := MyGui.AddText("x0 y+28 w320 Center BackgroundTrans", subtitulo)

    ; --- 3. DEFINICIÓN DE ICONO SEGÚN TIPO ---
    ; Seleccionamos el símbolo visual que acompaña al mensaje
    simbolo := "🗲 " ; Por defecto: Rayo de Energía
    if (tipo = "Battery")
        simbolo := "🔋 "
    else if (tipo = "Keyboard")
        simbolo := "⌨ "
    else if (tipo = "System")
        simbolo := "⊞ " ; Icono de Windows
    else if (tipo = "Error" || colorHex = "Rojo")
        simbolo := "⚠ "

    textColor := esError ? "White" : colorHex

    ; --- 4. MENSAJE PRINCIPAL ---
    ; Ajustamos el tamaño de fuente si el mensaje es muy largo para que quepa bien
    fontSize := (StrLen(mensaje) > 15) ? "14" : "18"
    MyGui.SetFont("s" . fontSize . " c" . textColor . " Bold", "Segoe UI Variable Display")
    MensajeCtrl := MyGui.AddText("x0 y+10 w320 Center BackgroundTrans", simbolo . mensaje)

    ; --- CÁLCULO DE POSICIÓN ---
    ; Ubicamos el banner en la esquina inferior derecha del monitor principal
    MonitorGetWorkArea(1, &Left, &Top, &Right, &Bottom)
    BannerW := 320
    BannerH := 165
    FinalX := Right - BannerW - 25
    FinalY := Bottom - BannerH - 25

    ; Mostramos la ventana sin quitarle el foco a la ventana actual del usuario
    MyGui.Show("x" . FinalX . " y" . FinalY . " w" . BannerW . " h" . BannerH . " NoActivate")

    ; Efectos visuales de Windows (bordes redondeados y otros atributos DWM)
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", MyGui.Hwnd, "uint", 33, "int*", 2, "uint", 4)
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", MyGui.Hwnd, "uint", 38, "int*", 2, "uint", 4)

    ; --- SISTEMA DE PARPADEO (BLINK) ---
    ; Si el parpadeo está activo, el mensaje principal alternará visibilidad para captar atención
    if parpadeo {
        EfectoParpadeo.contador := 0
        EfectoParpadeo() {
            try {
                if !MyGui
                    return

                EfectoParpadeo.contador++
                MensajeCtrl.Visible := !MensajeCtrl.Visible

                if (EfectoParpadeo.contador >= 6) { ; Realiza 3 ciclos de parpadeo
                    SetTimer(EfectoParpadeo, 0)
                    MensajeCtrl.Visible := true ; Nos aseguramos que quede visible al final
                }
            }
        }
        SetTimer(EfectoParpadeo, 300)
    }

    ; Programamos el cierre automático del banner
    SetTimer(CerrarBanner, -duracion)

    ; Función interna para limpiar y cerrar el banner
    CerrarBanner() {
        try MyGui.Destroy()
        LiberarRAM() ; Optimización de memoria después de usar la UI
    }
}
