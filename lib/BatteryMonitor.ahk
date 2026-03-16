; ==============================================================================
; MÓDULO DE MONITOREO DE BATERÍA (BATTERY MONITOR)
; ==============================================================================
; Descripción: Gestiona la detección de hardware de batería, el monitoreo en
;              tiempo real del nivel de carga y el disparo de alarmas configurables.
; ==============================================================================

/**
 * SistemaTieneBateria: Comprueba si el equipo cuenta con hardware de batería funcional.
 * @returns Booleano (True si se detecta una batería válida).
 */
SistemaTieneBateria() {
    ; Consultamos el estado de energía mediante la API de Windows
    static lpSystemPowerStatus := Buffer(12)
    if !DllCall("GetSystemPowerStatus", "Ptr", lpSystemPowerStatus)
        return false

    ; BatteryFlag: El valor 128 indica ausencia física de batería
    batteryFlag := NumGet(lpSystemPowerStatus, 1, "UChar")
    batteryPercent := NumGet(lpSystemPowerStatus, 2, "UChar")

    ; En equipos de escritorio (desktop), los valores suelen ser 128 o 255 (desconocido)
    if (batteryFlag = 128 || batteryPercent = 255)
        return false

    return true
}

; --- GESTIÓN DE PREFERENCIAS DE ALARMA ---

/**
 * AlternarAlarmaVisual: Activa o desactiva la notificación por banner.
 */
AlternarAlarmaVisual(*) {
    global MONITOR_VISIBLE, SETTINGS_FILE, MenuBateria
    MONITOR_VISIBLE := !MONITOR_VISIBLE
    IniWrite(MONITOR_VISIBLE ? "1" : "0", SETTINGS_FILE, "Battery", "AlarmaVisual")

    ; Actualizamos el visual del menú
    if MONITOR_VISIBLE
        MenuBateria.Check("𝗔𝗹𝗮𝗿𝗺𝗮 𝗩𝗶𝘀𝘂𝗮𝗹")
    else
        MenuBateria.Uncheck("𝗔𝗹𝗮𝗿𝗺𝗮 𝗩𝗶𝘀𝘂𝗮𝗹")

    GestionarTemporizador() ; Reiniciamos el servicio si es necesario
}

/**
 * AlternarAlarmaSonora: Activa o desactiva el sonido al llegar al nivel de alerta.
 */
AlternarAlarmaSonora(*) {
    global MONITOR_SOUND, SETTINGS_FILE, MenuBateria
    MONITOR_SOUND := !MONITOR_SOUND
    IniWrite(MONITOR_SOUND ? "1" : "0", SETTINGS_FILE, "Battery", "AlarmaSonora")

    if MONITOR_SOUND
        MenuBateria.Check("𝗔𝗹𝗮𝗿𝗺𝗮 𝗦𝗼𝗻𝗼𝗿𝗮")
    else
        MenuBateria.Uncheck("𝗔𝗹𝗮𝗿𝗺𝗮 𝗦𝗼𝗻𝗼𝗿𝗮")

    GestionarTemporizador()
}

/**
 * CambiarNivelAlarma: Establece el porcentaje de carga en el que se disparará la alerta.
 * @param nivel Valor string ("80", "95", "97", "100").
 */
CambiarNivelAlarma(nivel) {
    global ALARM_LEVEL, SETTINGS_FILE, ALARM_FIRED
    ALARM_LEVEL := nivel
    IniWrite(nivel, SETTINGS_FILE, "Battery", "NivelBateria")
    ALARM_FIRED := false ; Permitimos que la alarma vuelva a sonar con el nuevo nivel
    ActualizarChecksNivel()
    MostrarBanner("Alarma nivel: " . nivel . "%", "4EA8DE", "Battery")
}

/**
 * ActualizarChecksNivel: Ajusta visualmente el submenú de niveles en el Tray.
 */
ActualizarChecksNivel() {
    global ALARM_LEVEL, MenuBateria
    try {
        MenuBateria.Uncheck("Nivel: 80%")
        MenuBateria.Uncheck("Nivel: 95%")
        MenuBateria.Uncheck("Nivel: 97%")
        MenuBateria.Uncheck("Nivel: 100%")
        MenuBateria.Check("Nivel: " . ALARM_LEVEL . "%")
    }
}

/**
 * CambiarSonido: Cambia el tono de la notificación sonora.
 * @param tipo Nombre del perfil de sonido (Premium, Brisa, Eco, Ding).
 */
CambiarSonido(tipo) {
    global SOUND_TYPE, SETTINGS_FILE, SOUNDS
    SOUND_TYPE := tipo
    IniWrite(tipo, SETTINGS_FILE, "Battery", "TipoSonido")
    ActualizarChecksSonido()
    ; Reproducimos una vista previa del sonido elegido
    if FileExist(SOUNDS[tipo])
        SoundPlay SOUNDS[tipo]
}

/**
 * ActualizarChecksSonido: Ajusta visualmente el submenú de sonidos en el Tray.
 */
ActualizarChecksSonido() {
    global SOUND_TYPE, MenuSonidos
    try {
        MenuSonidos.Uncheck("Notificación (Premium)")
        MenuSonidos.Uncheck("Suave (Brisa)")
        MenuSonidos.Uncheck("Súper Sutil (Eco)")
        MenuSonidos.Uncheck("Clásico (Ding)")

        nombre := (SOUND_TYPE = "Premium") ? "Notificación (Premium)" :
            (SOUND_TYPE = "Brisa") ? "Suave (Brisa)" :
                (SOUND_TYPE = "Eco") ? "Súper Sutil (Eco)" : "Clásico (Ding)"
        MenuSonidos.Check(nombre)
    }
}

; --- LÓGICA DE MONITOREO ACTIVO ---

/**
 * GestionarTemporizador: Activa o detiene el monitoreo según las alarmas configuradas.
 */
GestionarTemporizador() {
    global MONITOR_VISIBLE, MONITOR_SOUND
    ; Si alguna alarma está activa, iniciamos el timer cada 50 segundos aproximadamente
    if (MONITOR_VISIBLE || MONITOR_SOUND) {
        SetTimer(MonitorearBateria, 50000)
        MonitorearBateria() ; Ejecución inicial inmediata
    } else {
        SetTimer(MonitorearBateria, 0) ; Apagamos el timer para ahorrar recursos
    }
    LiberarRAM()
}

/**
 * MonitorearBateria: Función periódica que verifica el nivel de carga analizando la API.
 */
MonitorearBateria() {
    global ALARM_FIRED, FULL_ALARM_FIRED, ALARM_LEVEL, MONITOR_VISIBLE, MONITOR_SOUND, SOUNDS, SOUND_TYPE

    static lpSystemPowerStatus := Buffer(12)
    if !DllCall("GetSystemPowerStatus", "Ptr", lpSystemPowerStatus)
        return

    ACStatus := NumGet(lpSystemPowerStatus, 0, "UChar") ; 0=Desconectado, 1=Cargando
    BatteryLifePercent := NumGet(lpSystemPowerStatus, 2, "UChar")

    ; PROTECCIÓN: Si el valor es 255, indica estado desconocido (ej: batería removida)
    if (BatteryLifePercent = 255) {
        ALARM_FIRED := false
        FULL_ALARM_FIRED := false
        return
    }

    ; Al desconectar el cargador (ACStatus = 0), reseteamos los estados de alarma
    if (ACStatus = 0) {
        ALARM_FIRED := false
        FULL_ALARM_FIRED := false
    }

    ; 1. ALARMA PRINCIPAL (Nivel configurado por el usuario)
    ; Se dispara si el cargador está conectado y se alcanza o supera el umbral
    if (ACStatus = 1 && !ALARM_FIRED && BatteryLifePercent >= Integer(ALARM_LEVEL)) {
        ALARM_FIRED := true
        if MONITOR_VISIBLE
            MostrarBanner("Nivel alcanzado (" . BatteryLifePercent . "%)", "31C950", "Battery", 6000, true)
        if MONITOR_SOUND && FileExist(SOUNDS[SOUND_TYPE])
            SoundPlay SOUNDS[SOUND_TYPE]
        LiberarRAM()
    }

    ; 2. ALARMA DE SEGURIDAD (Si llega al 100% y el umbral era inferior)
    ; Esta alarma es crítica para evitar sobrecarga prolongada
    if (ACStatus = 1 && !FULL_ALARM_FIRED && BatteryLifePercent >= 100 && Integer(ALARM_LEVEL) < 100) {
        FULL_ALARM_FIRED := true
        if MONITOR_VISIBLE
            MostrarBanner("¡CARGA COMPLETA! (100%)", "Rojo", "Battery", 10000, true)
        if MONITOR_SOUND && FileExist(SOUNDS[SOUND_TYPE])
            SoundPlay SOUNDS[SOUND_TYPE]
        LiberarRAM()
    }

    ; Histéresis: Solo permitimos re-activar la alarma si el nivel baja un 2% del umbral
    if (BatteryLifePercent < Integer(ALARM_LEVEL) - 2) {
        ALARM_FIRED := false
    }
}
