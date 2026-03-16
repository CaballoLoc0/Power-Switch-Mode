; ==============================================================================
; MÓDULO DE GESTIÓN DE PLANES DE ENERGÍA (POWER PLANS)
; ==============================================================================
; Descripción: Controla la detección, enumeración y cambio de los planes de
;              rendimiento de Windows mediante llamadas a la API nativa.
; ==============================================================================

/**
 * ObtenerPlanesSistema: Escanea los planes de energía disponibles en el equipo.
 * @param forzar Booleano que indica si se debe ignorar el caché y re-escanear.
 */
ObtenerPlanesSistema(forzar := false) {
    static planesCache := []

    ; Si ya tenemos los planes cargados y no se fuerza el refresco, usamos el caché
    if (planesCache.Length > 0 && !forzar) {
        global PLANES := planesCache
        return
    }

    global PLANES := []
    ; Ejecutamos el comando nativo de Windows para listar esquemas de energía
    output := LeerComando("powercfg /l")

    ; Procesamos la salida línea por línea buscando GUIDs y nombres
    for linea in StrSplit(output, "`n", "`r") {
        ; Buscamos el patrón del GUID (8-4-4-4-12 caracteres) y el nombre entre paréntesis
        if RegExMatch(linea, "i)([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}).*\((.+?)\)", &match) {
            nombre := Trim(StrReplace(match[2], "*", "")) ; El asterisco indica el plan activo
            PLANES.Push({ nombre: nombre, guid: match[1] })
        }
    }
    planesCache := PLANES
}

/**
 * SwitchPlanNative: Activa un plan de energía usando la API de bajo nivel.
 * Es mucho más rápido y silencioso que llamar a powercfg.exe externamente.
 * @param guidString El GUID del plan a activar.
 * @returns Booleano indicando si la operación fue exitosa.
 */
SwitchPlanNative(guidString) {
    ; Convertir el string del GUID a una estructura binaria de 16 bytes (CLSID)
    static CLSID_Size := 16
    pBuffer := Buffer(CLSID_Size)

    ; LLamada a ole32 para parsear el string GUID
    if (DllCall("ole32\CLSIDFromString", "Str", "{" . guidString . "}", "Ptr", pBuffer) != 0)
        return false

    ; Llamada nativa a PowrProf.dll para establecer el nuevo esquema activo
    ; El primer parámetro 0 indica que el cambio es para el usuario actual
    return (DllCall("PowrProf\PowerSetActiveScheme", "Ptr", 0, "Ptr", pBuffer) = 0)
}

/**
 * CambiarPlan: Función principal que cicla entre los planes disponibles.
 * Calcula el siguiente plan, lo activa y lanza la notificación visual.
 */
CambiarPlan(*) {
    global PLANES
    try {
        ; Nos aseguramos de tener la lista de planes actualizada
        ObtenerPlanesSistema()

        if (PLANES.Length <= 1) {
            MostrarBanner("Solo hay 1 plan disponible", "Rojo")
            return
        }

        ; Obtenemos el GUID del plan que está activo actualmente
        linea := LeerComando("powercfg /getactivescheme")

        indiceActual := 0
        for index, plan in PLANES {
            if InStr(linea, plan.guid) {
                indiceActual := index
                break
            }
        }

        ; Cálculo del siguiente índice de forma circular (luego del último vuelve al primero)
        siguienteIndice := (indiceActual >= PLANES.Length || indiceActual = 0) ? 1 : indiceActual + 1
        planSiguiente := PLANES[siguienteIndice]

        ; Intentamos el cambio nativo. Si falla, refrescamos la lista y reintentamos.
        if !SwitchPlanNative(planSiguiente.guid) {
            ObtenerPlanesSistema(true) ; Forzamos un re-escaneo profundo

            ; Re-buscamos el índice basado en la nueva lista
            for index, plan in PLANES {
                if InStr(linea, plan.guid) {
                    indiceActual := index
                    break
                }
            }
            siguienteIndice := (indiceActual >= PLANES.Length || indiceActual = 0) ? 1 : indiceActual + 1
            planSiguiente := PLANES[siguienteIndice]
            SwitchPlanNative(planSiguiente.guid)
        }

        ; --- SELECCIÓN DE ESTÉTICA SEGÚN EL PLAN ---
        ; Asignamos colores representativos para mejorar la identificación rápida
        colorPlan := "White"
        if InStr(planSiguiente.nombre, "Máximo")
            colorPlan := "F24F2C" ; Rojo Intenso
        else if InStr(planSiguiente.nombre, "Alto")
            colorPlan := "F2B32C" ; Naranja Energía
        else if InStr(planSiguiente.nombre, "Equilibrado")
            colorPlan := "31C950" ; Verde Eficiencia
        else if InStr(planSiguiente.nombre, "Economizador")
            colorPlan := "4EA8DE" ; Celeste Ahorro

        ; Limpiamos el nombre para que el banner sea más elegante
        nombreLimpio := Trim(RegExReplace(planSiguiente.nombre, "i)\s*rendimiento\s*", ""))

        ; Mostramos la notificación visual (Banner)
        MostrarBanner(nombreLimpio, colorPlan, "Power", 5500)

    } catch Error as err {
        MostrarBanner("Error: " . err.Message, "Rojo")
    }

    ; Optimización de memoria post-proceso
    LiberarRAM()
}
