; ==============================================================================
; MÓDULO DE UTILIDADES GENERALES (UTILS)
; ==============================================================================
; Descripción: Funciones de soporte técnico, manipulación de sistema y ayudas
;              de formato utilizadas en toda la aplicación.
; ==============================================================================

/**
 * LeerComando: Ejecuta un comando de consola y devuelve su salida.
 * Útil para interactuar con herramientas de Windows como powercfg.
 * @param comando El comando a ejecutar en el símbolo del sistema.
 * @returns String con la salida del comando o vacío si falla.
 */
LeerComando(comando) {
    tmpFile := A_Temp . "\ahk_pwr_out.txt"
    ; Ejecutamos oculto y redirigimos la salida a un archivo temporal
    RunWait(A_ComSpec . " /c " . comando . " > `"" . tmpFile . "`"", , "Hide")
    try {
        ; Leemos con codificación CP850 para soportar caracteres especiales del CMD
        result := FileRead(tmpFile, "CP850")
        FileDelete(tmpFile)
        return result
    }
    catch {
        return ""
    }
}

/**
 * AplicarModoOscuro: Fuerza el uso de la interfaz oscura en una ventana.
 * @param Hwnd El identificador único de la ventana (Handle).
 */
AplicarModoOscuro(Hwnd) {
    ; DWMWA_USE_IMMERSIVE_DARK_MODE (Atributo 20 en Windows 10/11)
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", Hwnd, "uint", 20, "int*", 1, "uint", 4)
}

/**
 * LiberarRAM: Reduce el consumo de memoria física de la aplicación.
 * Útil después de realizar operaciones pesadas o mostrar interfaces complejas.
 */
LiberarRAM() {
    ; Envía el conjunto de trabajo de la aplicación a la memoria virtual (página)
    DllCall("psapi\EmptyWorkingSet", "ptr", -1)
}

/**
 * HotkeyAHKAHumano: Convierte los símbolos de AHK en nombres de teclas legibles.
 * @param hk Atajo en formato AHK (ej: "^!p").
 * @returns El mismo atajo en formato humano (ej: "CTRL + ALT + P").
 */
HotkeyAHKAHumano(hk) {
    if (hk = "") {
        return ""
    }

    ; Reemplazamos los modificadores estándar por sus nombres
    hk := StrReplace(hk, "+", "SHIFT + ")
    hk := StrReplace(hk, "^", "CTRL + ")
    hk := StrReplace(hk, "!", "ALT + ")
    hk := StrReplace(hk, "#", "WIN + ")
    hk := StrReplace(hk, "<", "IZQ ")
    hk := StrReplace(hk, ">", "DER ")

    ; Formateamos espacios y convertimos todo a mayúsculas para mejor estética
    hk := Trim(RegExReplace(hk, "\s+\+\s+", " + "))
    return StrUpper(hk)
}

; ==============================================================================
; PERSISTENCIA DE INICIO (GESTIÓN DEL REGISTRO DE WINDOWS)
; ==============================================================================

/**
 * EsInicioAutomatico: Comprueba si la aplicación está registrada para iniciar con Windows.
 * @returns Booleano (True si existe la entrada en el Registro).
 */
EsInicioAutomatico() {
    try {
        RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "PowerSwitchMode")
        return true
    } catch {
        return false
    }
}

/**
 * AlternarInicioAutomatico: Registra o elimina la aplicación del inicio automático.
 * @param activar Booleano que indica si se debe dar de alta o de baja.
 */
AlternarInicioAutomatico(activar) {
    regPath := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
    if activar {
        ; Si la app está compilada, registramos el .exe; si no, registramos el motor AHK + el script
        pathApp := A_IsCompiled ? A_ScriptFullPath : "`"" . A_AhkPath . "`" `"" . A_ScriptFullPath . "`""
        RegWrite(pathApp, "REG_SZ", regPath, "PowerSwitchMode")
    } else {
        try RegDelete(regPath, "PowerSwitchMode")
    }
}
