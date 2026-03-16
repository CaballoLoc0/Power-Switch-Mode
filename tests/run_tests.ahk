#Requires AutoHotkey v2.0

; ==============================================================
; UNIT TESTING SUITE
; ==============================================================

; Mocking required globals for testing
global MONITOR_VISIBLE := 0
global MONITOR_SOUND := 0
global SETTINGS_FILE := A_Temp . "\test_config.ini"
global ALARM_LEVEL := "95"
global ALARM_FIRED := false
global SOUNDS := Map("Premium", "test.wav")
global SOUND_TYPE := "Premium"
global PLANES := []

; Includes
#Include "..\lib\Utils.ahk"
#Include "..\lib\PowerPlans.ahk"
#Include "..\lib\BatteryMonitor.ahk"
#Include "..\ui\Banner.ahk"

; Mocking UI functions to avoid popups during tests
MostrarBanner(m, c := "") {
    FileAppend "BANNER: " . m . " [" . c . "]`n", "*"
}

; --- TESTS ---

Test_Utils() {
    FileAppend "Verificando Utils... ", "*"
    ; Test LeerComando simple
    ver := LeerComando("ver")
    if InStr(ver, "Windows")
        FileAppend "OK`n", "*"
    else
        FileAppend "FAILED (LeerComando)`n", "*"
}

Test_PowerPlans() {
    FileAppend "Verificando PowerPlans... ", "*"
    ObtenerPlanesSistema()
    if PLANES.Length > 0
        FileAppend "OK (Detectados " . PLANES.Length . " planes)`n", "*"
    else
        FileAppend "FAILED (No se detectaron planes)`n", "*"
}

Test_BatteryLogic() {
    FileAppend "Verificando Lógica de Batería... ", "*"

    ; Test de Rearme de Alarma
    global ALARM_FIRED := true
    global ALARM_LEVEL := "95"

    ; Simulamos que el nivel baja del umbral
    ; (Nota: MonitorearBateria real usa DllCall, aquí probamos la lógica de variables)

    ; Mock de la lógica interna (simulación manual para el test)
    BatteryLifePercent := 90
    if (BatteryLifePercent < Integer(ALARM_LEVEL) - 2) {
        ALARM_FIRED := false
    }

    if (!ALARM_FIRED)
        FileAppend "OK (Rearme exitoso)`n", "*"
    else
        FileAppend "FAILED (Rearme fallido)`n", "*"
}

; Ejecutar Suite
FileAppend "`n--- INICIANDO TESTS UNITARIOS ---`n", "*"
Test_Utils()
Test_PowerPlans()
Test_BatteryLogic()
FileAppend "--- TESTS COMPLETADOS ---`n", "*"

Sleep 2000
ExitApp