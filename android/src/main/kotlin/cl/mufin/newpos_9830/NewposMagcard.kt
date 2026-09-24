package cl.mufin.newpos_9830

import android.content.Context
import android.util.Log
import com.pos.device.magcard.MagCardCallback
import com.pos.device.magcard.MagCardReader
import com.pos.device.magcard.MagneticCard
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * Lectura de banda magnética (3 tracks) del Newpos 9830.
 *
 * ⚠️ SENSIBLE (PCI): los tracks contienen el PAN y datos de la tarjeta en claro.
 * NO persistir ni loguear el resultado. El wrapper solo lee; el uso responsable
 * es del consumidor.
 *
 * Llamar desde un hilo secundario.
 */
class NewposMagcard(private val context: Context) {
    companion object {
        private const val TAG = "NewposMagcard"
    }

    /**
     * Espera el swipe de una tarjeta con timeout y devuelve los 3 tracks.
     * @return mapa {track1,track2,track3, state1,state2,state3} o null si timeout/cancelado.
     */
    fun readTracks(timeoutSeconds: Int): Map<String, Any?>? {
        if (!NewposSdk.ensureReady(context)) return null
        val reader = MagCardReader.getInstance()
        val latch = CountDownLatch(1)
        val result = AtomicReference<Map<String, Any?>?>(null)
        return try {
            // startSearchCard espera MILISEGUNDOS, no segundos. Pasarle 30 hacia
            // que el lector escuchara 30 ms y devolviera TIMEOUT_ERROR (2) antes
            // de que nadie alcanzara a deslizar la tarjeta.
            reader.startSearchCard(timeoutSeconds * 1000, MagCardCallback { code, card ->
                if (code == MagCardCallback.SUCCESS && card != null) {
                    result.set(cardToMap(card))
                } else {
                    Log.w(TAG, "readTracks code=$code")
                }
                latch.countDown()
            })
            latch.await(timeoutSeconds.toLong() + 2, TimeUnit.SECONDS)
            result.get()
        } catch (e: Exception) {
            Log.e(TAG, "readTracks falló", e)
            null
        } finally {
            runCatching { reader.stopSearchCard() }
        }
    }

    private fun cardToMap(card: MagneticCard): Map<String, Any?> {
        fun track(n: Int): Pair<String?, Int> {
            val t = card.getTrackInfos(n) ?: return null to -1
            return t.data to t.state
        }
        val (d1, s1) = track(MagneticCard.TRACK_1)
        val (d2, s2) = track(MagneticCard.TRACK_2)
        val (d3, s3) = track(MagneticCard.TRACK_3)
        return mapOf(
            "track1" to d1, "state1" to s1,
            "track2" to d2, "state2" to s2,
            "track3" to d3, "state3" to s3,
        )
    }
}
