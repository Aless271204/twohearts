import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/geographic_location_service.dart';
import '../../../widgets/place_search_sheet.dart';
import '../../../widgets/twohearts_ui.dart';
import '../../../theme/app_theme.dart';

class CoupleMapWidget extends StatefulWidget {
  final String myCity,partnerCity;
  final List<String> travelCities;
  final bool realtimeEnabled;
  final ValueChanged<bool>? onRealtimeToggle;
  const CoupleMapWidget({super.key,required this.myCity,required this.partnerCity,this.travelCities=const[],this.realtimeEnabled=false,this.onRealtimeToggle});
  @override State<CoupleMapWidget> createState()=>_CoupleMapWidgetState();
}
class _CoupleMapWidgetState extends State<CoupleMapWidget>{
  final _controller=MapController();
  GeoPlace? _mine,_partner;
  List<GeoPlace> _travels=[];
  LatLng? _gps;
  bool _loading=true,_locating=false,_tileError=false,_mapReady=false;
  String? _error;
  int _generation=0,_tileEpoch=0;
  @override void initState(){super.initState();_resolve();if(widget.realtimeEnabled)_locate();}
  @override void didUpdateWidget(CoupleMapWidget old){
    super.didUpdateWidget(old);
    if(old.myCity!=widget.myCity || old.partnerCity!=widget.partnerCity || old.travelCities.join('|')!=widget.travelCities.join('|'))_resolve();
    if(widget.realtimeEnabled&&!old.realtimeEnabled)_locate();
    if(!widget.realtimeEnabled&&old.realtimeEnabled){_gps=null;_fit();}
  }
  @override void dispose(){_generation++;_controller.dispose();super.dispose();}
  LatLng? get _myPoint=>_gps??_mine?.point;
  List<LatLng> get _points=>[if(_myPoint!=null)_myPoint!,if(_partner!=null)_partner!.point];
  Future<void> _resolve()async{
    final generation=++_generation;
    setState(()=>_loading=true);
    final service=GeographicLocationService.instance;
    GeoPlace? mine,partner;final travels=<GeoPlace>[];String? error;
    try{mine=await service.resolve(widget.myCity);}catch(_){mine=await service.cached(widget.myCity);error='No pudimos consultar tu ubicación. Reintenta con conexión.';}
    try{partner=await service.resolve(widget.partnerCity);}catch(_){partner=await service.cached(widget.partnerCity);error??='No pudimos consultar la ubicación de tu pareja.';}
    if(!mounted||generation!=_generation)return;
    setState((){_mine=mine;_partner=partner;_travels=[];_loading=false;_error=error;});_fit();
    for(final city in widget.travelCities.take(12)){
      if(!mounted||generation!=_generation)return;
      try{final place=await service.resolve(city);if(place!=null)travels.add(place);}catch(_){}
    }
    if(mounted&&generation==_generation)setState(()=>_travels=travels);
  }
  void _fit(){
    if(!_mapReady||!mounted)return;
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(!mounted||!_mapReady)return;
      final points=_points;
      if(points.length==1 || (points.length==2 && const Distance().as(LengthUnit.Meter,points[0],points[1])<100)){
        _controller.move(points.first,12);
      }else if(points.length>1){_controller.fitCamera(CameraFit.coordinates(coordinates:points,padding:const EdgeInsets.fromLTRB(58,85,82,40),maxZoom:13));}
    });
  }
  Future<void> _locate()async{
    if(_locating)return;setState(()=>_locating=true);
    try{
      if(!await Geolocator.isLocationServiceEnabled())throw const FormatException('Activa la ubicación de tu dispositivo.');
      var permission=await Geolocator.checkPermission();
      if(permission==LocationPermission.denied)permission=await Geolocator.requestPermission();
      if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever)throw const FormatException('No se concedió el permiso de ubicación.');
      final position=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.medium,timeLimit:Duration(seconds:20)));
      if(!mounted||!widget.realtimeEnabled)return;
      setState((){_gps=LatLng(position.latitude,position.longitude);_error=null;});_fit();
    }catch(e){if(mounted)setState(()=>_error=e is FormatException?e.message:'No pudimos obtener tu ubicación.');}
    finally{if(mounted)setState(()=>_locating=false);}
  }
  Future<void> _choose(bool mine)async{
    final query=mine?widget.myCity:widget.partnerCity;
    final place=await showModalBottomSheet<GeoPlace>(context:context,useRootNavigator:true,isScrollControlled:true,showDragHandle:true,builder:(_)=>PlaceSearchSheet(initialQuery:query));
    if(place==null||!mounted)return;
    // A correction is local to the displayed registered place; profile editing
    // remains responsible for saving a new address to the couple's account.
    if(query.isNotEmpty)await GeographicLocationService.instance.remember(query,place);
    if(!mounted)return;setState((){if(mine)_mine=place;else _partner=place;});_fit();
  }
  Widget _placeCard(bool mine){
    final place=mine?_mine:_partner;
    final input=mine?widget.myCity:widget.partnerCity;
    return Expanded(child:InkWell(onTap:()=>_choose(mine),borderRadius:BorderRadius.circular(16),child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white.withAlpha(235),borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(mine?Icons.favorite_rounded:Icons.favorite_border_rounded,size:16,color:mine?AppTheme.primary:const Color(0xFF517D74)),const SizedBox(width:5),Text(mine?'Tú':'Tu pareja',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:Color(0xFF24212A)))]),
      const SizedBox(height:6),Text(place?.label??(input.isEmpty?'Registra su ubicación':_loading?'Buscando ubicación…':'Ubicación sin confirmar'),maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,height:1.3,color:Color(0xFF514A56))),
    ]))));
  }
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(20,10,20,0),child:Container(
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),border:Border.all(color:const Color(0xFFF1DCE4)),boxShadow:heartShadow),
    clipBehavior:Clip.antiAlias,
    child:Stack(children:[
      Positioned.fill(child:Image.asset('assets/images/ui/nido-wallpaper.png',fit:BoxFit.cover)),
      Positioned.fill(child:ColoredBox(color:const Color(0xC9FFF9FA))),
      Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Cerca, incluso a la distancia',style:TextStyle(fontSize:17,fontWeight:FontWeight.w700,color:Color(0xFF432F40))),
        const SizedBox(height:4),const Text('Dos lugares reales. Un mismo hogar.',style:TextStyle(fontSize:12,color:Color(0xFF6D5665))),
        const SizedBox(height:12),
        ClipRRect(borderRadius:BorderRadius.circular(20),child:SizedBox(height:240,child:Stack(children:[
          FlutterMap(mapController:_controller,options:MapOptions(initialCenter:const LatLng(20,-25),initialZoom:1.4,minZoom:1,maxZoom:18,backgroundColor:const Color(0xFFEAF2F0),interactionOptions:const InteractionOptions(flags:InteractiveFlag.drag|InteractiveFlag.pinchZoom|InteractiveFlag.doubleTapZoom|InteractiveFlag.scrollWheelZoom),onMapReady:(){_mapReady=true;_fit();}),children:[
            TileLayer(key:ValueKey(_tileEpoch),evictErrorTileStrategy:EvictErrorTileStrategy.dispose,urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'com.example.twohearts',maxNativeZoom:19,panBuffer:0,errorTileCallback:(tile,error,stack){if(!_tileError&&mounted)WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)setState(()=>_tileError=true);});}),
            if(_points.length==2)PolylineLayer(polylines:[Polyline(points:_points,color:AppTheme.primary.withAlpha(180),strokeWidth:2,pattern:StrokePattern.dotted())]),
            MarkerLayer(markers:[
              for(final place in _travels)Marker(point:place.point,width:24,height:24,child:const Icon(Icons.location_on_rounded,color:Color(0xFF5B8C7E),size:24)),
              if(_myPoint!=null)Marker(point:_myPoint!,width:42,height:48,alignment:Alignment.topCenter,child:_MapPin(color:AppTheme.primary,label:'Tú',onTap:()=>_choose(true))),
              if(_partner!=null)Marker(point:_partner!.point,width:42,height:48,alignment:Alignment.topCenter,child:_MapPin(color:const Color(0xFF517D74),label:'Tu pareja',onTap:()=>_choose(false))),
            ]),
            Align(
              alignment: Alignment.bottomRight,
              child: Material(
                color: Colors.white.withAlpha(240),
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text('\u00a9 OpenStreetMap contributors', style: TextStyle(fontSize: 10, color: Color(0xFF25252A))),
                  ),
                ),
              ),
            ),
          ]),
          if(_loading)const Positioned(top:12,left:12,child:SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:AppTheme.primary))),
          Positioned(top:10,right:10,child:HeartIconButton(icon:Icons.center_focus_strong_rounded,tooltip:'Ver nuestras ubicaciones',onPressed:_fit)),
        ]))),
        const SizedBox(height:10),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[_placeCard(true),const SizedBox(width:8),_placeCard(false)]),
        const SizedBox(height:8),Row(children:[const Icon(Icons.my_location_rounded,size:16,color:Color(0xFF5D716A)),const SizedBox(width:6),const Expanded(child:Text('Usar mi ubicación actual',style:TextStyle(fontSize:12,color:Color(0xFF33313A)))),if(_locating)const SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2)),Switch.adaptive(value:widget.realtimeEnabled,onChanged:widget.onRealtimeToggle,activeTrackColor:AppTheme.primary)]),
        if(_error!=null)Text(_error!,style:const TextStyle(fontSize:12,color:Color(0xFF773747))),
        if(_tileError)Row(children:[const Expanded(child:Text('No pudimos cargar la cartografía. Comprueba la conexión.',style:TextStyle(fontSize:11,color:Color(0xFF4B424B)))),TextButton(onPressed:(){setState((){_tileError=false;_tileEpoch++;});},child:const Text('Reintentar'))]),
      ])),
    ]),
  ));
}
class _MapPin extends StatelessWidget{
  final Color color;final String label;final VoidCallback onTap;
  const _MapPin({required this.color,required this.label,required this.onTap});
  @override Widget build(BuildContext context)=>Semantics(label:label,button:true,child:GestureDetector(onTap:onTap,child:Stack(alignment:Alignment.topCenter,children:[Icon(Icons.location_on,size:48,color:color),const Positioned(top:8,child:Icon(Icons.favorite,size:19,color:Colors.white))])));
}
