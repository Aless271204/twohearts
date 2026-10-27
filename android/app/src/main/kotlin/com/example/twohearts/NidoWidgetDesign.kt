package com.example.twohearts

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.os.Bundle
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

/** All decoration fits inside the widget. No GL, WebView, animation or network render. */
object NidoWidgetDesign {
    val kinds = listOf("note", "days", "anniversary", "quote", "distance")
    val names = listOf("Para ti", "Días juntos", "Próximo aniversario", "Frase diaria", "Tan cerca de ti")
    val colors = listOf("Rosa", "Salvia", "Lavanda", "Mantequilla", "Avena")
    val frames = listOf("Corazones", "Flores", "Estrellas", "Costuras")
    val pets = listOf("Sin mascota", "Pollito", "Pingüino", "Osito", "Cerdito")
    data class Style(val color: Int = 1, val frame: Int = 0, val pet: Int = 1, val companion: Int = 2, val revealNote: Boolean = false, val revealDistance: Boolean = false)
    data class Artwork(val bitmap: Bitmap, val description: String)
    fun prefs(c: Context) = c.getSharedPreferences("nido_widget_appearance", Context.MODE_PRIVATE)
    fun style(c: Context, id: Int): Style {
        val type=kind(c,id)
        val defaultColor=when(type){"days"->4;"anniversary"->0;"quote"->3;"distance"->2;else->1}
        val defaultPet=when(type){"days"->3;"anniversary"->4;"distance"->2;else->1}
        val p=prefs(c)
        return Style(p.getInt("$id-color",defaultColor).coerceIn(colors.indices),p.getInt("$id-frame",0).coerceIn(frames.indices),
            p.getInt("$id-pet",defaultPet).coerceIn(pets.indices),p.getInt("$id-companion",if(type=="note")2 else 0).coerceIn(pets.indices),
            p.getBoolean("$id-revealNote",false),p.getBoolean("$id-revealDistance",false))
    }
    fun save(c: Context, id: Int, s: Style) { prefs(c).edit().putInt("$id-color",s.color).putInt("$id-frame",s.frame)
        .putInt("$id-pet",s.pet).putInt("$id-companion",s.companion).putBoolean("$id-revealNote",s.revealNote).putBoolean("$id-revealDistance",s.revealDistance).apply() }
    fun revokePrivacy(c:Context) { val p=prefs(c);val edit=p.edit();p.all.keys.filter{it.endsWith("-revealNote")||it.endsWith("-revealDistance")}.forEach{edit.putBoolean(it,false)};edit.apply() }
    fun delete(c: Context, id: Int) { val e=prefs(c).edit(); listOf("color","frame","pet","companion","revealNote","revealDistance").forEach { e.remove("$id-$it") }; e.apply() }
    fun kind(c: Context, id: Int): String? = when(AppWidgetManager.getInstance(c).getAppWidgetInfo(id)?.provider?.className?.substringAfterLast('.')?.replace("Lock", "")) {
        "NidoPartnerWidgetProvider" -> "note"; "NidoCoupleWidgetProvider" -> "days"
        "NidoAnniversaryWidgetProvider" -> "anniversary"; "NidoQuoteWidgetProvider" -> "quote"; "NidoDistanceWidgetProvider" -> "distance"; else -> null
    }
    fun isLock(c: Context,id: Int): Boolean = AppWidgetManager.getInstance(c).getAppWidgetInfo(id)?.provider?.className?.contains("Lock")==true ||
        (AppWidgetManager.getInstance(c).getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_HOST_CATEGORY,1) and AppWidgetProviderInfo.WIDGET_CATEGORY_KEYGUARD)!=0
    fun provider(kind: String,locked: Boolean=false): Class<*> = if(locked) when(kind) {
        "days"->NidoLockCoupleWidgetProvider::class.java; "anniversary"->NidoLockAnniversaryWidgetProvider::class.java
        "quote"->NidoLockQuoteWidgetProvider::class.java; "distance"->NidoLockDistanceWidgetProvider::class.java;else->NidoLockPartnerWidgetProvider::class.java
    } else when(kind) {
        "days" -> NidoCoupleWidgetProvider::class.java; "anniversary" -> NidoAnniversaryWidgetProvider::class.java
        "quote" -> NidoQuoteWidgetProvider::class.java; "distance" -> NidoDistanceWidgetProvider::class.java
        else -> NidoPartnerWidgetProvider::class.java
    }
    fun update(c: Context, manager: AppWidgetManager, id: Int, kind: String) {
        val options=manager.getAppWidgetOptions(id)
        val landscape=c.resources.configuration.orientation==android.content.res.Configuration.ORIENTATION_LANDSCAPE
        val width=options.getInt(if(landscape)AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,220).coerceIn(140,600)
        val height=options.getInt(if(landscape)AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT,220).coerceIn(110,600)
        val locked=isLock(c,id)
        val art=render(c,id,kind,width,height,locked=locked)
        val v=RemoteViews(c.packageName,R.layout.nido_personal_widget)
        v.setImageViewBitmap(R.id.nido_widget_art,art.bitmap)
        v.setContentDescription(R.id.nido_widget_art,art.description)
        val flags=PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        v.setOnClickPendingIntent(R.id.nido_widget_art, PendingIntent.getActivity(c,id,
            Intent(c,MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),flags))
        v.setViewVisibility(R.id.nido_widget_edit,if(locked) View.GONE else View.VISIBLE)
        v.setOnClickPendingIntent(R.id.nido_widget_edit,PendingIntent.getActivity(c,id,
            Intent(c,NidoWidgetSettingsActivity::class.java).putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,id),flags))
        v.setViewVisibility(R.id.nido_widget_refresh,if(kind=="note" && !locked) View.VISIBLE else View.GONE)
        v.setOnClickPendingIntent(R.id.nido_widget_refresh,PendingIntent.getBroadcast(c,id,
            Intent(c,NidoPartnerWidgetProvider::class.java).setAction("com.example.twohearts.REFRESH_NOTE"),flags))
        manager.updateAppWidget(id,v)
    }
    fun render(c: Context,id: Int,kind: String,width: Int,height: Int,design: Style=style(c,id), demo: Boolean=false, locked: Boolean=false): Artwork {
        if(locked) return renderLock(c,id,kind,width,height,design,demo)
        val w=width.toFloat(); val h=height.toFloat()
        val scale=512f/maxOf(w,h) // At most 1 MiB per bitmap, independent of screen density.
        val bitmap=Bitmap.createBitmap((w*scale).toInt().coerceAtLeast(1),(h*scale).toInt().coerceAtLeast(1),Bitmap.Config.ARGB_8888)
        val canvas=Canvas(bitmap); canvas.scale(scale,scale)
        val paper=Color.rgb(255,252,246)
        val palettes=listOf("#F4CAD0","#C8D8B7","#D2CCE9","#F5D98E","#DCC9AD")
        val border=Color.parseColor(palettes[design.color.coerceIn(palettes.indices)])
        val ink=Color.rgb(76,55,57); val accent=Color.rgb(132,72,91)
        val paint=Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color=paper;canvas.drawRoundRect(RectF(7f,7f,w-7,h-7),24f,24f,paint)
        val frameId=when(design.color){0->R.drawable.widget_frame_rose;2->R.drawable.widget_frame_lavender;3->R.drawable.widget_frame_butter;4->R.drawable.widget_frame_oat;else->R.drawable.widget_frame_sage}
        val frame=BitmapFactory.decodeResource(c.resources,frameId)
        val cut=(frame.width*.26f).toInt();val cutY=(frame.height*.26f).toInt()
        val edge=minOf(w,h)*.26f
        val xs=intArrayOf(0,cut,frame.width-cut,frame.width);val ys=intArrayOf(0,cutY,frame.height-cutY,frame.height)
        val dx=floatArrayOf(0f,edge,w-edge,w);val dy=floatArrayOf(0f,edge,h-edge,h)
        for(x in 0..2) for(y in 0..2) {
            if(x==1 && y==1) continue
            canvas.drawBitmap(frame,Rect(xs[x],ys[y],xs[x+1],ys[y+1]),RectF(dx[x],dy[y],dx[x+1],dy[y+1]),paint)
        }
        frame.recycle()
        // Small ornaments lie on the outer frame, away from the content and controls.
        for (n in 0..3) {
            val x=14f;val y=h*(.25f+n*.14f)
            paint.color=accent
            when(design.frame) {
                1 -> { for(a in 0..4) { val angle=a*1.256637; canvas.drawCircle(x+(kotlin.math.cos(angle)*3).toFloat(),y+(kotlin.math.sin(angle)*3).toFloat(),2f,paint) };paint.color=Color.WHITE;canvas.drawCircle(x,y,1.4f,paint) }
                2 -> { canvas.drawLine(x-3,y,x+3,y,paint);canvas.drawLine(x,y-3,x,y+3,paint) }
                3 -> { paint.strokeWidth=1f;canvas.drawLine(x-1,y-3,x+1,y+3,paint) }
                else -> { canvas.drawCircle(x-1.2f,y,1.7f,paint);canvas.drawCircle(x+1.2f,y,1.7f,paint);val p=Path();p.moveTo(x-2.5f,y);p.lineTo(x,y+3);p.lineTo(x+2.5f,y);canvas.drawPath(p,paint) }
            }
        }
        fun text(value: String, top: Float, boxHeight: Float, size: Float, color: Int=ink, serif: Boolean=false, align: Layout.Alignment=Layout.Alignment.ALIGN_CENTER): Float {
            val margin=maxOf(23f,minOf(55f,w*.16f))
            val available=(w-2*margin).toInt().coerceAtLeast(40)
            val tp=TextPaint(Paint.ANTI_ALIAS_FLAG);tp.color=color
            tp.typeface=if(serif) Typeface.create("serif",Typeface.NORMAL) else Typeface.create("sans-serif-medium",Typeface.NORMAL)
            // Honour accessibility font scaling within the available layout.
            var actual=size*(c.resources.configuration.fontScale.coerceIn(1f,1.6f))
            fun layout()=StaticLayout.Builder.obtain(value,0,value.length,tp,available).setAlignment(align)
                .setIncludePad(false).setMaxLines(8).setEllipsize(android.text.TextUtils.TruncateAt.END).build()
            tp.textSize=actual; var block=layout()
            while(block.height>boxHeight && actual>10f) { actual-=1f;tp.textSize=actual;block=layout() }
            if(block.height>boxHeight) {
                val lineHeight=(tp.fontMetrics.descent-tp.fontMetrics.ascent).coerceAtLeast(1f)
                val lines=(boxHeight/lineHeight).toInt().coerceIn(1,8)
                block=StaticLayout.Builder.obtain(value,0,value.length,tp,available).setAlignment(align)
                    .setIncludePad(false).setMaxLines(lines).setEllipsize(android.text.TextUtils.TruncateAt.END).build()
            }
            canvas.save();canvas.clipRect(margin,top,w-margin,top+boxHeight);canvas.translate(margin,top+maxOf(0f,(boxHeight-block.height)/2));block.draw(canvas);canvas.restore()
            return block.height.toFloat()
        }
        text("NIDO",if(h<210f) 11f else 19f,12f,9f,accent)
        val title=names[kinds.indexOf(kind).coerceAtLeast(0)]
        text(title,if(h<210f) 30f else 45f,22f,15f,serif=true)
        val hasPets=design.pet!=0 || design.companion!=0
        val bottom=if(hasPets) minOf(h*.30f,w*.30f) else 18f
        val contentBottom=(h-bottom-8).coerceAtLeast(85f)
        val contentTop=if(h<210f) 58f else 75f; val contentHeight=(contentBottom-contentTop).coerceAtLeast(20f)
        val prefs=PartnerWidget.prefs(c)
        val stats=if(demo) JSONObject().put("start",LocalDate.now().minusDays(365).toString()).put("km",12.4).put("located_at",OffsetDateTime.now().minusHours(1).toString()) else try { JSONObject(prefs.getString("couple_stats","{}").orEmpty()) } catch(_:Exception){JSONObject()}
        val start=try { LocalDate.parse(stats.optString("start").take(10)) } catch(_:Exception){null}
        val today=LocalDate.now();val days=NidoWidgetMath.days(start,today)
        var description=title
        when(kind) {
            "days" -> {
                val value=days?.let{String.format(Locale.getDefault(),"%,d",it)}?:"—"
                text(value,contentTop,contentHeight*.60f,46f,accent,true)
                text(if(days!=null) "días eligiéndonos" else "Su historia empieza aquí",contentTop+contentHeight*.60f,contentHeight*.20f,12f)
                val date=start?.takeIf{days!=null}?.format(DateTimeFormatter.ofPattern("dd MMM yyyy",Locale("es")))
                val footer=if(date!=null) "Desde $date" else "Añadan su aniversario en NIDO"
                text(footer,contentTop+contentHeight*.80f,contentHeight*.20f,10f)
                description="$value días juntos. $footer"
            }
            "anniversary" -> {
                val next=NidoWidgetMath.anniversary(start,today)
                val left=next?.let{java.time.temporal.ChronoUnit.DAYS.between(today,it)}
                text(if(left==0L) "¡Hoy!" else left?.toString()?:"—",contentTop,contentHeight*.52f,42f,accent,true)
                text(if(left==0L) "Un año más de nosotros" else "días para celebrar",contentTop+contentHeight*.52f,contentHeight*.23f,12f)
                val date=next?.format(DateTimeFormatter.ofPattern("dd 'de' MMMM",Locale("es")))?:"Añadan su aniversario en NIDO"
                text(date,contentTop+contentHeight*.75f,contentHeight*.25f,11f)
                description=if(next==null) "Añadan su aniversario en NIDO" else "Próximo aniversario: $date. ${left} días."
            }
            "distance" -> {
                val at=try { OffsetDateTime.parse(stats.optString("located_at")).atZoneSameInstant(ZoneId.systemDefault()) } catch(_:Exception){null}
                val km=stats.optDouble("km",-1.0)
                val available=km.isFinite() && km>=0 && at!=null
                val value=if(available) String.format(Locale.getDefault(),"%.1f km",km) else "—"
                text(value,contentTop,contentHeight*.45f,31f,accent,true)
                text(if(available) "Dos lugares, un mismo Nido" else "Distancia no disponible",contentTop+contentHeight*.45f,contentHeight*.20f,11f)
                val date=if(available) "Ubicación guardada · ${at!!.format(DateTimeFormatter.ofPattern("dd/MM HH:mm"))}" else "Compartan su ubicación desde NIDO"
                text(date,contentTop+contentHeight*.65f,contentHeight*.35f,10f)
                description="$value. $date"
            }
            "quote" -> {
                val members=try{JSONArray(prefs.getString("quote_members","[]")).let { a->(0 until a.length()).map{a.optString(it)} }}catch(_:Exception){emptyList<String>()}
                val quotes=try{JSONArray(c.assets.open("couple_quotes_es.json").bufferedReader().use{it.readText()})}catch(_:Exception){JSONArray()}
                val q=if(members.isNotEmpty() && quotes.length()>0) quotes.getJSONObject(NidoWidgetMath.quoteIndex(members,LocalDate.now(ZoneOffset.UTC).toEpochDay(),quotes.length())) else null
                val body=if(demo) "Que el alma que hablar puede con los ojos, también puede besar con la mirada." else q?.optString("text")?:"Abre NIDO para preparar su frase de hoy."
                val source=if(demo) "G. A. Bécquer · Rima XX" else q?.optString("source").orEmpty()
                text("“$body”",contentTop,contentHeight*.76f,19f,serif=true)
                text(source,contentTop+contentHeight*.76f,contentHeight*.24f,10f)
                description="$body. $source"
            }
            else -> {
                val file=File(c.filesDir,"partner-note.png")
                val photo=if(!demo && prefs.getBoolean("image",false) && file.exists()) BitmapFactory.decodeFile(file.absolutePath) else null
                if(photo!=null) {
                    val ratio=minOf((w-46)/photo.width,contentHeight/photo.height)
                    val pw=photo.width*ratio;val ph=photo.height*ratio
                    canvas.drawBitmap(photo,null,RectF((w-pw)/2,contentTop+(contentHeight-ph)/2,(w+pw)/2,contentTop+(contentHeight+ph)/2),paint)
                    photo.recycle();description="Foto o dibujo de tu pareja. Toca para abrir NIDO."
                } else {
                    val body=if(demo) "Te quiero. Incluso en nuestros días más normales." else prefs.getString("text","").orEmpty().ifBlank{"Aquí caben una foto, un dibujo y muchos te quiero."}
                    text(body,contentTop,contentHeight,20f,serif=true);description=body
                }
            }
        }
        fun pet(which:Int,left:Boolean) {
            val resource=when(which){1->R.drawable.widget_pet_chick;2->R.drawable.widget_pet_penguin;3->R.drawable.widget_pet_bear;4->R.drawable.widget_pet_pig;else->return}
            val b=BitmapFactory.decodeResource(c.resources,resource)
            val size=minOf(w*.23f,h*.25f); val crop=Rect(0,0,b.width,(b.height*.68f).toInt()); val ph=size*crop.height()/b.width
            val x=if(left) 9f else w-size-9
            canvas.drawBitmap(b,crop,RectF(x,h-ph-8,x+size,h-8),paint);b.recycle()
        }
        pet(design.pet,true);pet(design.companion,false)
        return Artwork(bitmap,description)
    }
    private fun renderLock(c:Context,id:Int,kind:String,width:Int,height:Int,style:Style,demo:Boolean):Artwork {
        val w=width.toFloat();val h=height.toFloat();val factor=512f/maxOf(w,h)
        val bmp=Bitmap.createBitmap((w*factor).toInt().coerceAtLeast(1),(h*factor).toInt().coerceAtLeast(1),Bitmap.Config.ARGB_8888)
        val canvas=Canvas(bmp);canvas.scale(factor,factor)
        val backgrounds=intArrayOf(Color.rgb(247,218,218),Color.rgb(54,76,62),Color.rgb(72,77,116),Color.rgb(248,231,181),Color.rgb(237,223,199))
        val dark=style.color==1 || style.color==2
        val ink=if(dark) Color.rgb(255,247,231) else Color.rgb(76,53,51)
        val p=Paint(Paint.ANTI_ALIAS_FLAG);p.color=backgrounds[style.color.coerceIn(0,4)]
        canvas.drawRoundRect(RectF(2f,2f,w-2,h-2),18f,18f,p)
        p.color=Color.rgb(198,165,111);p.style=Paint.Style.STROKE;p.strokeWidth=1f;canvas.drawRoundRect(RectF(4f,4f,w-4,h-4),16f,16f,p);p.style=Paint.Style.FILL
        val badge=minOf(h*.57f,if(style.companion!=0) 44f else 55f)
        fun badge(which:Int,x:Float) {
            val res=when(which){1->R.drawable.widget_pet_chick;2->R.drawable.widget_pet_penguin;3->R.drawable.widget_pet_bear;4->R.drawable.widget_pet_pig;else->return}
            val pet=BitmapFactory.decodeResource(c.resources,res)
            canvas.save();val clip=Path();clip.addCircle(x+badge/2,h/2,badge/2,Path.Direction.CW);canvas.clipPath(clip)
            p.color=Color.rgb(255,243,222);canvas.drawCircle(x+badge/2,h/2,badge/2,p)
            canvas.drawBitmap(pet,Rect(0,0,pet.width,(pet.height*.70).toInt()),RectF(x,(h-badge)/2,x+badge,(h+badge)/2),p)
            canvas.restore();pet.recycle()
        }
        badge(style.pet,12f)
        badge(style.companion,if(style.pet!=0) 12f+badge*.60f else 12f)
        val left=if(style.pet!=0 || style.companion!=0) badge*(if(style.pet!=0 && style.companion!=0)1.60f else 1f)+24f else 17f
        val tw=(w-left-16).toInt().coerceAtLeast(45)
        fun label(t:String,y:Float,bh:Float,size:Float,italic:Boolean=false) {
            val tp=TextPaint(Paint.ANTI_ALIAS_FLAG);tp.color=ink
            tp.typeface=Typeface.create(if(italic) "serif" else "sans-serif-medium",if(italic) Typeface.ITALIC else Typeface.NORMAL)
            var sizeNow=size*c.resources.configuration.fontScale.coerceIn(1f,1.5f)
            fun make()=StaticLayout.Builder.obtain(t,0,t.length,tp,tw).setIncludePad(false).setAlignment(Layout.Alignment.ALIGN_CENTER)
                .setMaxLines(3).setEllipsize(android.text.TextUtils.TruncateAt.END).build()
            tp.textSize=sizeNow;var layout=make()
            while(layout.height>bh && sizeNow>10) {sizeNow-=1f;tp.textSize=sizeNow;layout=make()}
            canvas.save();canvas.clipRect(left,y,w-16,y+bh);canvas.translate(left,y+maxOf(0f,(bh-layout.height)/2));layout.draw(canvas);canvas.restore()
        }
        val prefs=PartnerWidget.prefs(c)
        val stats=if(demo) JSONObject().put("start",LocalDate.now().minusDays(712).toString()).put("km",12.4).put("located_at",OffsetDateTime.now().minusHours(1).toString()) else try{JSONObject(prefs.getString("couple_stats","{}").orEmpty())}catch(_:Exception){JSONObject()}
        val start=try{LocalDate.parse(stats.optString("start").take(10))}catch(_:Exception){null}
        val today=LocalDate.now();val days=NidoWidgetMath.days(start,today)
        var main="";var caption="";var description=""
        when(kind) {
            "days"->{main=days?.toString()?:"—";caption=if(days==null) "Añadan su aniversario en NIDO" else "días juntos"}
            "anniversary"->{val next=NidoWidgetMath.anniversary(start,today);val n=next?.let{java.time.temporal.ChronoUnit.DAYS.between(today,it)}
                main=if(n==0L) "¡Hoy!" else n?.let{"$it días"}?:"—";caption=next?.format(DateTimeFormatter.ofPattern("dd 'de' MMMM",Locale("es")))?:"Añadan su aniversario en NIDO"}
            "distance"->{
                val at=try{OffsetDateTime.parse(stats.optString("located_at")).atZoneSameInstant(ZoneId.systemDefault())}catch(_:Exception){null};val km=stats.optDouble("km",-1.0)
                if(!style.revealDistance){main="Nuestra distancia";caption="Desbloquea para verla"}
                else if(km.isFinite()&&km>=0&&at!=null){main=String.format(Locale.getDefault(),"%.1f km",km);caption="Guardada · ${at.format(DateTimeFormatter.ofPattern("dd/MM HH:mm"))}"}
                else{main="Sin ubicación";caption="Compartan ubicación desde NIDO"}
            }
            "note"->{
                if(!style.revealNote){main="Un detalle para ti";caption="Desbloquea para verlo"}
                else{main=if(demo) "Te guardé un abrazo" else prefs.getString("text","").orEmpty().ifBlank{"Tu próxima nota vivirá aquí"};caption="Para ti · NIDO"}
                // Photo bytes are not read at all without explicit lock-screen consent.
                if(style.revealNote && !demo && prefs.getBoolean("image",false)){
                    val file=File(c.filesDir,"partner-note.png");val photo=if(file.exists()) BitmapFactory.decodeFile(file.absolutePath) else null
                    if(photo!=null){val ratio=minOf(tw.toFloat()/photo.width,(h-25)/photo.height);val pw=photo.width*ratio;val ph=photo.height*ratio
                        canvas.drawBitmap(photo,null,RectF(left+(tw-pw)/2,8f,left+(tw+pw)/2,8f+ph),p);photo.recycle();main="";caption="Foto o dibujo de tu pareja"}
                }
            }
            "quote"->{val members=try{JSONArray(prefs.getString("quote_members","[]")).let{a->(0 until a.length()).map{a.optString(it)}}}catch(_:Exception){emptyList<String>()}
                val quotes=try{JSONArray(c.assets.open("couple_quotes_es.json").bufferedReader().use{it.readText()})}catch(_:Exception){JSONArray()}
                val q=if(members.isNotEmpty()&&quotes.length()>0) quotes.getJSONObject(NidoWidgetMath.quoteIndex(members,LocalDate.now(ZoneOffset.UTC).toEpochDay(),quotes.length())) else null
                main=if(demo) "Por una mirada, un mundo; por una sonrisa, un cielo." else q?.optString("text")?:"Abre NIDO para preparar su frase diaria."
                caption=if(demo) "G. A. Bécquer" else q?.optString("source").orEmpty()
            }
        }
        label(main,8f,h*.64f,if(kind=="quote"||kind=="note") 15f else 27f,kind=="quote")
        label(caption,h*.70f,h*.23f,10f)
        description="$main. $caption"
        return Artwork(bmp,description)
    }

}
