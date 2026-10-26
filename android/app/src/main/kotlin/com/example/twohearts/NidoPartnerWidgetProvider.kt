package com.example.twohearts

import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.io.File
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

object PartnerWidget {
    const val JOB = 72103
    const val REFRESH_JOB = 72104
    private const val PREFS = "nido_partner_widget"
    fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    fun configure(context: Context, url: String, key: String, token: String, user: String) {
        val previousUser=prefs(context).getString("user",null)
        if(previousUser!=null && previousUser!=user) clear(context)
        // Credentials stay inside this application's private storage. The token can only read
        // the latest note from the linked partner; it is not a Supabase session or refresh token.
        prefs(context).edit().putString("url", url).putString("key", key).putString("token", token).putString("user", user).apply()
        val job = JobInfo.Builder(JOB, ComponentName(context, NidoPartnerWidgetJob::class.java))
            .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY).setPeriodic(30L * 60 * 1000).build()
        (context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler).schedule(job)
        refresh(context, true)
    }
    fun refresh(context: Context, force: Boolean = false) {
        if (prefs(context).getString("token", null) == null) return
        val previous = prefs(context).getLong("last_refresh", 0)
        if (!force && System.currentTimeMillis() - previous < 120000) return
        prefs(context).edit().putLong("last_refresh", System.currentTimeMillis()).apply()
        val job = JobInfo.Builder(REFRESH_JOB, ComponentName(context, NidoPartnerWidgetJob::class.java))
            .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY).setMinimumLatency(0).build()
        (context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler).schedule(job)
    }
    @Synchronized fun store(context: Context, json: JSONObject) {
        json.optJSONObject("couple_stats")?.let { prefs(context).edit().putString("couple_stats",it.toString()).apply() }
        if(json.has("partner_mood"))NidoReminders.mood(context,json.optJSONObject("partner_mood"))
        val file = File(context.filesDir, "partner-note.png")
        var hasImage = false
        if (json.optString("kind") == "image") {
            val content = json.optString("content")
            if (content.length <= 1400000) {
                try {
                    val bytes = android.util.Base64.decode(content, android.util.Base64.DEFAULT)
                    val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
                    if (options.outWidth in 1..2048 && options.outHeight in 1..2048) {
                        file.writeBytes(bytes); hasImage = true
                    }
                } catch (_: Exception) { }
            }
        }
        if (!hasImage) file.delete()
        prefs(context).edit().putString("text", if (hasImage) "Una imagen de tu pareja 💗" else json.optString("content", "" ).take(500))
            .putString("sent_at", json.optString("sent_at", "")).putBoolean("image", hasImage).apply()
        redraw(context)
    }
    @Synchronized fun clear(context: Context) {
        NidoReminders.clear(context)
        NidoWidgetDesign.revokePrivacy(context)
        val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
        scheduler.cancel(JOB); scheduler.cancel(REFRESH_JOB)
        prefs(context).edit().clear().apply(); File(context.filesDir, "partner-note.png").delete(); redraw(context)
    }
    fun redraw(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        listOf(false,true).forEach { locked -> NidoWidgetDesign.kinds.forEach { kind ->
            val ids=manager.getAppWidgetIds(ComponentName(context,NidoWidgetDesign.provider(kind,locked)))
            ids.forEach { NidoWidgetDesign.update(context,manager,it,kind) }
        } }
    }
}

/** Uses only saved, consented locations. All five designs share the same lifecycle. */
open class NidoPersonalWidgetProvider : AppWidgetProvider() {
    open val widgetKind = "note"
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context,intent)
        if(intent.action in listOf(Intent.ACTION_DATE_CHANGED,Intent.ACTION_TIME_CHANGED,Intent.ACTION_TIMEZONE_CHANGED)) {
            val manager=AppWidgetManager.getInstance(context)
            onUpdate(context,manager,manager.getAppWidgetIds(ComponentName(context,javaClass)))
        }
        if(intent.action=="com.example.twohearts.REFRESH_NOTE") PartnerWidget.refresh(context,true)
    }
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        if(ids.isNotEmpty() && widgetKind=="note") PartnerWidget.refresh(context)
        ids.forEach { NidoWidgetDesign.update(context,manager,it,widgetKind) }
    }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: android.os.Bundle) {
        super.onAppWidgetOptionsChanged(context,manager,id,options)
        NidoWidgetDesign.update(context,manager,id,widgetKind)
    }
    override fun onDeleted(context: Context, ids: IntArray) { ids.forEach { NidoWidgetDesign.delete(context,it) } }
    override fun onEnabled(context: Context) { super.onEnabled(context); PartnerWidget.refresh(context) }
}
class NidoPartnerWidgetProvider : NidoPersonalWidgetProvider()
class NidoCoupleWidgetProvider : NidoPersonalWidgetProvider() { override val widgetKind="days" }
class NidoAnniversaryWidgetProvider : NidoPersonalWidgetProvider() { override val widgetKind="anniversary" }
class NidoQuoteWidgetProvider : NidoPersonalWidgetProvider() { override val widgetKind="quote" }
class NidoDistanceWidgetProvider : NidoPersonalWidgetProvider() { override val widgetKind="distance" }

class NidoLockPartnerWidgetProvider : NidoPersonalWidgetProvider()
class NidoLockCoupleWidgetProvider : NidoPersonalWidgetProvider() { override val widgetKind="days" }
class NidoLockAnniversaryWidgetProvider : NidoPersonalWidgetProvider() { override val widgetKind="anniversary" }
class NidoLockQuoteWidgetProvider : NidoPersonalWidgetProvider() { override val widgetKind="quote" }
class NidoLockDistanceWidgetProvider : NidoPersonalWidgetProvider() { override val widgetKind="distance" }

class NidoPartnerWidgetJob : JobService() {
    private val executor = Executors.newSingleThreadExecutor()
    @Volatile private var stopped = false
    override fun onStartJob(params: JobParameters): Boolean {
        stopped = false
        executor.execute {
            var retry = false
            try {
                val prefs = PartnerWidget.prefs(this)
                val token = prefs.getString("token", null)
                val base = prefs.getString("url", null)
                val key = prefs.getString("key", null)
                if (token != null && base != null && key != null && base.startsWith("https://")) {
                    val connection = URL("$base/rest/v1/rpc/art_widget_note").openConnection() as HttpURLConnection
                    try {
                        connection.requestMethod = "POST"; connection.doOutput = true
                        connection.connectTimeout = 12000; connection.readTimeout = 12000
                        connection.setRequestProperty("apikey", key)
                        connection.setRequestProperty("Authorization", "Bearer $key")
                        connection.setRequestProperty("Content-Type", "application/json")
                        connection.outputStream.use { it.write(JSONObject().put("p_token", token).toString().toByteArray()) }
                        if (connection.responseCode == 200) {
                            val bytes = connection.inputStream.use { input ->
                                val output = ByteArrayOutputStream(); val buffer = ByteArray(8192)
                                while (output.size() <= 1500000) { val count = input.read(buffer); if (count < 0) break; output.write(buffer,0,count) }
                                output.toByteArray()
                            }
                            if (bytes.size <= 1500000 && !stopped && token == prefs.getString("token", null)) PartnerWidget.store(this, JSONObject(String(bytes, Charsets.UTF_8)))
                        } else retry = connection.responseCode >= 500
                    } finally { connection.disconnect() }
                }
            } catch (_: Exception) { retry = true }
            if (!stopped) jobFinished(params, retry)
        }
        return true
    }
    override fun onStopJob(params: JobParameters): Boolean { stopped = true; return true }
    override fun onDestroy() { stopped = true; executor.shutdownNow(); super.onDestroy() }
}
