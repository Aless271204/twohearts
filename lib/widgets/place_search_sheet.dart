import 'package:flutter/material.dart';
import '../services/geographic_location_service.dart';
import '../theme/app_theme.dart';
import 'twohearts_ui.dart';

class PlaceSearchSheet extends StatefulWidget{
  final String initialQuery;
  const PlaceSearchSheet({super.key,this.initialQuery=''});
  @override State<PlaceSearchSheet> createState()=>_PlaceSearchSheetState();
}
class _PlaceSearchSheetState extends State<PlaceSearchSheet>{
  late final TextEditingController _query;
  List<GeoPlace> _places=[];bool _busy=false,_searched=false;String? _error;
  @override void initState(){super.initState();_query=TextEditingController(text:widget.initialQuery);}
  @override void dispose(){_query.dispose();super.dispose();}
  Future<void> _search()async{
    if(_busy)return;
    if(_query.text.trim().length<3){setState(()=>_error='Escribe al menos tres letras para buscar.');return;}
    setState((){_busy=true;_error=null;});
    try{final results=await GeographicLocationService.instance.search(_query.text);if(mounted)setState((){_places=results;_searched=true;});}
    catch(_){if(mounted)setState(()=>_error='No pudimos buscar. Comprueba tu conexión y vuelve a intentar.');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context)=>SafeArea(child:Padding(padding:EdgeInsets.fromLTRB(20,0,20,20+MediaQuery.viewInsetsOf(context).bottom),child:ConstrainedBox(constraints:BoxConstraints(maxHeight:(MediaQuery.sizeOf(context).height-MediaQuery.viewInsetsOf(context).bottom-100).clamp(180,460).toDouble()),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Encuentra tu lugar',style:TextStyle(fontSize:23,fontWeight:FontWeight.w700,color:Color(0xFF24212A))),
    const SizedBox(height:8),const Text('Escribe una ciudad o dirección con su país y elige el resultado correcto. La búsqueda utiliza Photon / OpenStreetMap.',style:TextStyle(fontSize:12,height:1.4,color:Color(0xFF58515B))),
    const SizedBox(height:16),TextField(controller:_query,style:const TextStyle(color:Color(0xFF202027)),textInputAction:TextInputAction.search,onSubmitted:(_)=>_search(),decoration:const InputDecoration(hintText:'Ej. Quito, Ecuador',prefixIcon:Icon(Icons.search))),
    const SizedBox(height:12),HeartButton(label:_busy?'Buscando…':'Buscar ubicación',icon:Icons.place_outlined,onPressed:_busy?null:_search),
    const SizedBox(height:10),if(_error!=null)Text(_error!,style:const TextStyle(color:Color(0xFF813748))),
    if(_searched&&_places.isEmpty&&!_busy)const Text('No encontramos ese lugar. Añade la ciudad y el país.',style:TextStyle(color:Color(0xFF4D4650))),
    ListView.separated(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:_places.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(context,index){final place=_places[index];return ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.location_on_outlined,color:AppTheme.primary),title:Text(place.label,style:const TextStyle(fontSize:14,color:Color(0xFF25232B))),subtitle:const Text('Elegir esta ubicación',style:TextStyle(fontSize:11,color:Color(0xFF615863))),onTap:()async{await GeographicLocationService.instance.remember(_query.text,place);if(context.mounted)Navigator.pop(context,place);});}),
  ])))));
}
