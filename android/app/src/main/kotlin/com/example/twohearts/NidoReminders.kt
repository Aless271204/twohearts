package com.example.twohearts

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONObject
import java.util.Calendar

object NidoReminders {
    private const val CHANNEL = "nido_care"
    private fun prefs(c: Context) = c.getSharedPreferences("nido_reminders", Context.MODE_PRIVATE)
    fun configure(c: Context, daily: Boolean, moods: Boolean, hour: Int, minute: Int) {
        prefs(c).edit().putBoolean("daily",daily).putBoolean("moods",moods).putInt("hour",hour.coerceIn(0,23)).putInt("minute",minute.coerceIn(0,59)).apply()
        schedule(c)
    }
    fun schedule(c: Context) {
        val manager=c.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending=PendingIntent.getBroadcast(c,72105,Intent(c,NidoReminderReceiver::class.java).setAction("nido.DAILY"),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        manager.cancel(pending)
        if(!prefs(c).getBoolean("daily",false))return
        val next=Calendar.getInstance().apply { set(Calendar.HOUR_OF_DAY,prefs(c).getInt("hour",19));set(Calendar.MINUTE,prefs(c).getInt("minute",0));set(Calendar.SECOND,0);set(Calendar.MILLISECOND,0);if(timeInMillis<=System.currentTimeMillis())add(Calendar.DAY_OF_YEAR,1) }
        manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,next.timeInMillis,pending)
    }
    private fun show(c: Context, id: Int, title: String, body: String) {
        if(Build.VERSION.SDK_INT>=33&&c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)return
        val manager=c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if(Build.VERSION.SDK_INT>=26)manager.createNotificationChannel(NotificationChannel(CHANNEL,"Momentos de NIDO",NotificationManager.IMPORTANCE_DEFAULT))
        val launch=PendingIntent.getActivity(c,id,Intent(c,MainActivity::class.java),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder=if(Build.VERSION.SDK_INT>=26)android.app.Notification.Builder(c,CHANNEL) else android.app.Notification.Builder(c)
        manager.notify(id,builder.setSmallIcon(R.drawable.ic_nido_notification).setContentTitle(title).setContentText(body).setContentIntent(launch).setAutoCancel(true).setVisibility(android.app.Notification.VISIBILITY_PRIVATE).build())
    }
    fun daily(c: Context) {
        if(!prefs(c).getBoolean("daily",false))return
        val day=Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
        val messages=arrayOf("Compartan una foto bonita de su día.","¿Un dibujo o una pequeña partida juntos?","Pregúntale qué fue lo mejor de su día.","Planeen un lugar que les gustaría visitar.","Guarden un recuerdo en su álbum.")
        show(c,72105,"Un ratito para ustedes ♥",messages[day%messages.size]);schedule(c)
    }
    fun mood(c: Context, json: JSONObject?) {
        val state=prefs(c);val stamp=json?.optString("updated_at").orEmpty();val old=state.getString("mood_at","").orEmpty()
        state.edit().putString("mood_at",stamp).apply()
        if(!state.getBoolean("moods",false)||stamp.isBlank()||old.isBlank()||stamp==old)return
        val label=mapOf("happy" to "feliz","calm" to "en calma","tired" to "con cansancio","sad" to "triste","stressed" to "con estrés","affectionate" to "con ganas de cariño")[json?.optString("mood")]?:return
        show(c,72106,"Tu pareja compartió cómo se siente","Hoy se siente $label. Un pequeño mensaje puede acompañarle.")
    }
    fun clear(c: Context) {configure(c,false,false,19,0);prefs(c).edit().clear().apply();(c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(72105);(c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(72106)}
}
class NidoReminderReceiver:BroadcastReceiver(){override fun onReceive(context:Context,intent:Intent){if(intent.action=="nido.DAILY")NidoReminders.daily(context) else NidoReminders.schedule(context)}}
