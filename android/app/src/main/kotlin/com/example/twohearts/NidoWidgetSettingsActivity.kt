package com.example.twohearts

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.*

/** Local appearance only. Private note/location data never leave application storage. */
class NidoWidgetSettingsActivity : Activity() {
    private var widgetId=AppWidgetManager.INVALID_APPWIDGET_ID
    private var selected=NidoWidgetDesign.Style()
    private var locked=false
    private lateinit var preview: ImageView
    private var previewBitmap: android.graphics.Bitmap?=null
    private fun dp(v:Int)=(v*resources.displayMetrics.density).toInt()
    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        setResult(RESULT_CANCELED)
        widgetId=intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,AppWidgetManager.INVALID_APPWIDGET_ID)
        val scroll=ScrollView(this);scroll.setBackgroundColor(Color.rgb(255,248,241))
        val column=LinearLayout(this).apply { orientation=LinearLayout.VERTICAL;setPadding(dp(22),dp(24),dp(22),dp(24)) }
        scroll.addView(column);setContentView(scroll)
        fun label(text:String,size:Float=16f)=TextView(this).apply { this.text=text;textSize=size;setTextColor(Color.rgb(83,57,60));setPadding(0,dp(10),0,dp(10));column.addView(this) }
        label("Tus widgets, tu NIDO",26f)
        val kind=NidoWidgetDesign.kind(this,widgetId)
        if(kind==null) {
            label("Puedes cambiar el marco, el color y las mascotas de cada widget cuando quieras.")
            val manager=AppWidgetManager.getInstance(this)
            listOf(false,true).forEach { lockFamily ->
            label(if(lockFamily) "Pantalla de bloqueo" else "Pantalla de inicio",20f)
            NidoWidgetDesign.kinds.forEachIndexed { i,key ->
                val ids=manager.getAppWidgetIds(ComponentName(this,NidoWidgetDesign.provider(key,lockFamily)))
                ids.forEachIndexed { number,id ->
                    column.addView(Button(this).apply { text="Personalizar ${NidoWidgetDesign.names[i]} ${number+1}";setOnClickListener {
                        startActivity(Intent(this@NidoWidgetSettingsActivity,NidoWidgetSettingsActivity::class.java).putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,id))
                    } })
                }
                column.addView(Button(this).apply { text="+ ${NidoWidgetDesign.names[i]}";setOnClickListener {
                    if(lockFamily) { Toast.makeText(this@NidoWidgetSettingsActivity,"Busca NIDO en los widgets de la pantalla de bloqueo de tu teléfono. Su disponibilidad depende del sistema.",Toast.LENGTH_LONG).show() } else if(Build.VERSION.SDK_INT>=26 && manager.isRequestPinAppWidgetSupported) {
                        manager.requestPinAppWidget(ComponentName(this@NidoWidgetSettingsActivity,NidoWidgetDesign.provider(key)),null,null)
                    } else Toast.makeText(this@NidoWidgetSettingsActivity,"Mantén pulsada la pantalla de inicio → Widgets → NIDO",Toast.LENGTH_LONG).show()
                } })
            }
            }
            label("También puedes editar un widget tocando su lápiz. Si tu teléfono no permite añadirlo desde aquí, búscalo en el selector de widgets de Android.",13f)
            return
        }
        locked=NidoWidgetDesign.isLock(this,widgetId)
        selected=if(state!=null) NidoWidgetDesign.Style(state.getInt("color"),state.getInt("frame"),state.getInt("pet"),state.getInt("companion"),state.getBoolean("revealNote"),state.getBoolean("revealDistance")) else NidoWidgetDesign.style(this,widgetId)
        preview=ImageView(this).apply { adjustViewBounds=true;contentDescription="Vista previa del marco con datos de ejemplo" }
        column.addView(preview,LinearLayout.LayoutParams(-1,dp(260)))
        label("Vista previa con datos de ejemplo",12f)
        fun selector(title:String,items:List<String>,value:Int,change:(Int)->Unit) {
            label(title,14f)
            val spinner=Spinner(this)
            spinner.adapter=ArrayAdapter(this,android.R.layout.simple_spinner_dropdown_item,items)
            spinner.setSelection(value)
            spinner.onItemSelectedListener=object:AdapterView.OnItemSelectedListener {
                override fun onNothingSelected(parent:AdapterView<*>?) {}
                override fun onItemSelected(parent:AdapterView<*>?,view:View?,position:Int,id:Long) { change(position);redraw(kind) }
            }
            column.addView(spinner,LinearLayout.LayoutParams(-1,dp(48)))
        }
        selector("Color",NidoWidgetDesign.colors,selected.color){selected=selected.copy(color=it)}
        selector("Detalles del marco",NidoWidgetDesign.frames,selected.frame){selected=selected.copy(frame=it)}
        selector("Tu mascota",NidoWidgetDesign.pets,selected.pet){selected=selected.copy(pet=it)}
        selector("Su compañía",NidoWidgetDesign.pets,selected.companion){selected=selected.copy(companion=it)}
        if(locked) {
            label("En bloqueo, los datos privados están ocultos por defecto. Si los muestras, cualquiera que vea tu pantalla podrá leerlos.",13f)
            if(kind=="note") column.addView(CheckBox(this).apply { text="Mostrar notas y fotos sin desbloquear";isChecked=selected.revealNote;setOnCheckedChangeListener { _,checked->selected=selected.copy(revealNote=checked);redraw(kind) } })
            if(kind=="distance") column.addView(CheckBox(this).apply { text="Mostrar distancia en bloqueo";isChecked=selected.revealDistance;setOnCheckedChangeListener { _,checked->selected=selected.copy(revealDistance=checked);redraw(kind) } })
        }
        column.addView(Button(this).apply { text="Guardar diseño";setOnClickListener {
            // The widget may have been removed while the editor was open.
            if(NidoWidgetDesign.kind(this@NidoWidgetSettingsActivity,widgetId)==null) { finish();return@setOnClickListener }
            NidoWidgetDesign.save(this@NidoWidgetSettingsActivity,widgetId,selected)
            NidoWidgetDesign.update(this@NidoWidgetSettingsActivity,AppWidgetManager.getInstance(this@NidoWidgetSettingsActivity),widgetId,kind)
            setResult(RESULT_OK,Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,widgetId));finish()
        } })
        label("Este diseño es solo para este widget. Puedes volver a editarlo desde su lápiz o desde Ajustes de NIDO.",13f)
        redraw(kind)
    }
    private fun redraw(kind:String) {
        // ImageView may retain the prior bitmap on its render thread; allow GC to release it.
        previewBitmap=NidoWidgetDesign.render(this,widgetId,kind,if(locked) 320 else 240,if(locked) 110 else 240,selected,true,locked).bitmap
        preview.setImageBitmap(previewBitmap)
    }
    override fun onSaveInstanceState(out:Bundle) {
        super.onSaveInstanceState(out);out.putInt("color",selected.color);out.putInt("frame",selected.frame);out.putInt("pet",selected.pet);out.putInt("companion",selected.companion);out.putBoolean("revealNote",selected.revealNote);out.putBoolean("revealDistance",selected.revealDistance)
    }
    override fun onDestroy() { if(::preview.isInitialized) preview.setImageDrawable(null);previewBitmap=null;super.onDestroy() }
}
