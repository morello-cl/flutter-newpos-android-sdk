package cl.mufin.newpos_9830

import android.content.Context
import android.util.Log
import com.pos.device.config.DevConfig
import com.pos.device.sys.SystemManager

/**
 * Datos del terminal Newpos y detección de capacidades de hardware.
 * Reutilizable por el plugin y por el flavor de una app host.
 */
class NewposDevice(private val context: Context) {
    companion object {
        private const val TAG = "NewposDevice"
        const val BRAND = "NEWPOS"
    }

    /** Mapa con la ficha del equipo. Valores null si el SDK no responde. */
    fun info(): Map<String, Any?> {
        if (!NewposSdk.ensureReady(context)) return mapOf("brand" to BRAND)
        return try {
            mapOf(
                "brand" to BRAND,
                "model" to DevConfig.getMachine(),
                "serialNumber" to DevConfig.getSN(),
                "pn" to DevConfig.getPN(),
                "hardwareVersion" to DevConfig.getHardwareVersion(),
                "firmwareVersion" to DevConfig.getFirmwareVersion(),
                "imei" to runCatching { SystemManager.getImei(0) }.getOrNull(),
            )
        } catch (e: Exception) {
            Log.e(TAG, "info() falló", e)
            mapOf("brand" to BRAND)
        }
    }

    /** Nombres de los módulos de hardware presentes (msr, printer, barscanner, ic, sam…). */
    fun modules(): List<String> {
        if (!NewposSdk.ensureReady(context)) return emptyList()
        return try {
            DevConfig.getModules()?.map { it.name } ?: emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "modules() falló", e)
            emptyList()
        }
    }

    /**
     * true si el terminal declara el módulo (usar las constantes `module*` de Dart).
     *
     * Se resuelve contra [modules] y no con `DevConfig.getModuleByName`, que exige
     * el nombre con el casing exacto del enum y devolvía null para todo. El 9830
     * reporta los módulos en minúscula (`msr`, `barscanner`, `ic`), así que aquí
     * se compara sin distinguir mayúsculas.
     */
    fun hasModule(name: String): Boolean {
        if (!NewposSdk.ensureReady(context)) return false
        return modules().any { it.equals(name, ignoreCase = true) }
    }

    /** Idiomas que el firmware declara soportar (tags BCP-47, ej. "en-US", "zh-TW"). */
    fun supportedLocales(): List<String> {
        if (!NewposSdk.ensureReady(context)) return emptyList()
        return try {
            SystemManager.getAllLocales() ?: emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "supportedLocales() falló", e)
            emptyList()
        }
    }

    /**
     * Cambia el idioma del sistema del terminal. [tag] es un tag de idioma tipo
     * "en-US" / "zh-TW" (los que devuelve [supportedLocales]).
     * @return true si el terminal aplicó el cambio (false si no soporta el tag).
     */
    fun setLocale(tag: String): Boolean {
        if (!NewposSdk.ensureReady(context)) return false
        return runCatching { SystemManager.setDefaultLocale(tag) }.getOrDefault(false)
    }
}
