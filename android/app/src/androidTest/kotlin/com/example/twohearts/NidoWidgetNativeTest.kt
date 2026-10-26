package com.example.twohearts
import android.appwidget.*
import android.content.*
import android.content.res.Configuration
import android.graphics.*
import android.os.Bundle
import android.view.View
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
@RunWith(AndroidJUnit4::class)
class NidoWidgetNativeTest {
 @Test fun quotesMatchDart() {
  val c=InstrumentationRegistry.getInstrumentation().targetContext
  val vectors=JSONArray(c.assets.open("widget-quote-vectors.json").bufferedReader().use{it.readText()})
  for(i in 0 until vectors.length()) { val v=vectors.getJSONObject(i); val a=v.getJSONArray("members")
   assertEquals(v.getInt("expected"),NidoWidgetMath.quoteIndex((0 until a.length()).map{a.getString(it)},v.getLong("day"),v.getInt("count")))
  }
 }
 @Test fun nativeArtworkAndPrivacy() {
  val c=InstrumentationRegistry.getInstrumentation().targetContext
  val output=File(c.getExternalFilesDir(null),"widget-proof");output.mkdirs()
  val prefs=PartnerWidget.prefs(c)
  prefs.edit().putString("text","PRIVATE_NOTE_SENTINEL").putString("couple_stats",JSONObject().put("start","2024-11-13").put("km",9876.5).put("located_at","2026-10-26T10:30:00Z").toString()).commit()
  assertFalse(NidoWidgetDesign.render(c,10,"note",320,110,locked=true).description.contains("PRIVATE_NOTE_SENTINEL"))
  assertFalse(NidoWidgetDesign.render(c,10,"distance",320,110,locked=true).description.contains("9876"))
  for((i,kind) in NidoWidgetDesign.kinds.withIndex()) for(lock in listOf(false,true)) {
   val style=NidoWidgetDesign.Style(color=i,pet=i%4+1,companion=if(i==0)2 else 0)
   val art=NidoWidgetDesign.render(c,10,kind,if(lock)320 else 240,if(lock)110 else 240,style,true,lock)
   assertTrue(art.bitmap.width<=512 && art.bitmap.height<=512)
   File(output,"${kind}-${if(lock)"lock" else "home"}.png").outputStream().use{art.bitmap.compress(Bitmap.CompressFormat.PNG,100,it)}
   art.bitmap.recycle()
  }
  val config=Configuration(c.resources.configuration);config.fontScale=1.4f;val large=c.createConfigurationContext(config)
  val art=NidoWidgetDesign.render(large,10,"quote",320,180,NidoWidgetDesign.Style(3,1,1,0),true)
  File(output,"quote-wide-large-font.png").outputStream().use{art.bitmap.compress(Bitmap.CompressFormat.PNG,100,it)}
  art.bitmap.recycle()
  NidoWidgetDesign.save(c,100,NidoWidgetDesign.Style(2,3,4,3,true,true))
  assertEquals(2,NidoWidgetDesign.style(c,100).color);assertTrue(NidoWidgetDesign.style(c,100).revealNote)
  assertFalse(NidoWidgetDesign.style(c,101).revealNote)
  NidoWidgetDesign.revokePrivacy(c)
  assertFalse(NidoWidgetDesign.style(c,100).revealNote)
  assertFalse(NidoWidgetDesign.style(c,100).revealDistance)
  NidoWidgetDesign.delete(c,100);prefs.edit().clear().commit()
 }
 @Test fun remoteViewsInflateInRealHost() {
  val inst=InstrumentationRegistry.getInstrumentation();val c=inst.targetContext
  val manager=AppWidgetManager.getInstance(c);val host=AppWidgetHost(c,2034)
  try {
   inst.runOnMainSync {
    host.startListening()
    for(kind in NidoWidgetDesign.kinds) {
     val id=host.allocateAppWidgetId();val component=ComponentName(c,NidoWidgetDesign.provider(kind))
     val options=Bundle().apply{putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,220);putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT,220)}
     assertTrue("Bind permission missing",manager.bindAppWidgetIdIfAllowed(id,component,options))
     NidoWidgetDesign.update(c,manager,id,kind)
     val view=host.createView(c,id,manager.getAppWidgetInfo(id))
     view.measure(View.MeasureSpec.makeMeasureSpec(440,View.MeasureSpec.EXACTLY),View.MeasureSpec.makeMeasureSpec(440,View.MeasureSpec.EXACTLY));view.layout(0,0,440,440)
     host.deleteAppWidgetId(id)
    }
    host.stopListening()
   }
  } finally {host.deleteHost()}
 }
}
