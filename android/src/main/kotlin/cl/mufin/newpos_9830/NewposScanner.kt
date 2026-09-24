package cl.mufin.newpos_9830

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.pos.device.scanner.OnScanListener
import com.pos.device.scanner.Scanner
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * Lectura de códigos (scanner) del Newpos 9830, en modo single-shot y headless
 * (sin preview): decodifica un código y devuelve su texto.
 *
 * ponytail: sin vista de preview. Si un modelo requiere cámara con preview,
 * el host debe embeber la View de `Scanner.initScanner(context, bundle)` —
 * upgrade path documentado, no implementado aquí.
 *
 * Llamar desde un hilo secundario.
 */
class NewposScanner(private val context: Context) {
    companion object {
        private const val TAG = "NewposScanner"
    }

    /**
     * Escanea un código con timeout. Devuelve el texto decodificado o null.
     *
     * ponytail: la unidad del timeout de `Scanner.startScan(int, listener)` sigue
     * sin confirmarse. Medido en un 9830 real (2026-09-24) con `scanOnce(30)` y
     * sin presentar codigo: devolvio `code=-1` a los 9 s, o sea ni los 30 ms que
     * daria interpretar el valor como milisegundos (el bug que si tenia magcard,
     * ver NewposMagcard) ni los 30 s que pidio el llamador. Se deja como esta:
     * no falla en la practica y no hay evidencia de que convertir mejore nada.
     * Para cerrarlo hace falta medir con un codigo de barras real y varios
     * timeouts distintos; el SDK tampoco documenta que significa -1.
     */
    fun scanOnce(timeoutSeconds: Int): String? {
        if (!NewposSdk.ensureReady(context)) return null
        val scanner = Scanner.getInstance()
        val latch = CountDownLatch(1)
        val out = AtomicReference<String?>(null)
        return try {
            scanner.initScanner(Bundle())
            scanner.startScan(timeoutSeconds, OnScanListener { code, data ->
                if (code == Scanner.SCANNER_SUCCESS && data != null) {
                    out.set(String(data, Charsets.UTF_8))
                } else {
                    Log.w(TAG, "scan code=$code")
                }
                latch.countDown()
            })
            latch.await(timeoutSeconds.toLong() + 2, TimeUnit.SECONDS)
            out.get()
        } catch (e: Exception) {
            Log.e(TAG, "scanOnce falló", e)
            null
        } finally {
            runCatching { scanner.stopScan() }
            runCatching { scanner.release() }
        }
    }

    fun stop() {
        runCatching { Scanner.getInstance().stopScan() }
    }
}
