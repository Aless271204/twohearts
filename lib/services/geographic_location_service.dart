import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeoPlace {
  final String label;
  final LatLng point;
  const GeoPlace(this.label,this.point);
  Map<String,dynamic> toJson()=>{'label':label,'lat':point.latitude,'lon':point.longitude};
  static GeoPlace? fromJson(Map<String,dynamic> value){
    final lat=value['lat'],lon=value['lon'],label=value['label'];
    if(lat is! num || lon is! num || label is! String || label.trim().isEmpty || !lat.isFinite || !lon.isFinite || lat.abs()>90 || lon.abs()>180)return null;
    return GeoPlace(label,LatLng(lat.toDouble(),lon.toDouble()));
  }
}

/// Converts registered places to genuine geographical coordinates. Never
/// supplies a guessed/default location for an unresolved address.
class GeographicLocationService {
  static final instance=GeographicLocationService();
  final http.Client client;
  GeographicLocationService({http.Client? client}):client=client??http.Client();
  final Map<String,Future<List<GeoPlace>>> _pending={};
  Future<void> _queue=Future.value();
  DateTime _lastRequest=DateTime.fromMillisecondsSinceEpoch(0);
  String _key(String query)=>'twohearts_geo_v1:${query.trim().toLowerCase()}';
  Future<GeoPlace?> cached(String query)async{
    if(query.trim().isEmpty)return null;
    final raw=(await SharedPreferences.getInstance()).getString(_key(query));
    if(raw==null)return null;
    try{return GeoPlace.fromJson(Map<String,dynamic>.from(jsonDecode(raw)));}catch(_){return null;}
  }
  Future<void> remember(String query,GeoPlace place)async{
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString(_key(query),jsonEncode(place.toJson()));
    await prefs.setString(_key(place.label),jsonEncode(place.toJson()));
  }
  Future<GeoPlace?> resolve(String query)async{
    if(query.trim().isEmpty)return null;
    final saved=await cached(query);if(saved!=null)return saved;
    final results=await search(query);
    if(results.isEmpty)return null;
    await remember(query,results.first);return results.first;
  }
  Future<List<GeoPlace>> search(String query){
    final normalized=query.trim();if(normalized.length<3)return Future.value([]);
    return _pending.putIfAbsent(normalized,()=>_search(normalized).whenComplete((){_pending.remove(normalized);}));
  }
  Future<List<GeoPlace>> _search(String query)async{
    final before=_queue;final ready=Completer<void>();_queue=ready.future;
    try{
      await before;
      final remaining=const Duration(seconds:1)-DateTime.now().difference(_lastRequest);
      if(remaining>Duration.zero)await Future<void>.delayed(remaining);
      _lastRequest=DateTime.now();
      final response=await client.get(Uri.https('photon.komoot.io','/api/',{'q':query,'limit':'5'})).timeout(const Duration(seconds:12));
      if(response.statusCode!=200)throw const FormatException('No pudimos consultar ese lugar.');
      return parseResponse(jsonDecode(response.body));
    }finally{ready.complete();}
  }
  static List<GeoPlace> parseResponse(dynamic data){
    if(data is! Map || data['features'] is! List)return [];
    final places=<GeoPlace>[];
    for(final feature in data['features']){
      if(feature is! Map)continue;
      final geometry=feature['geometry'],properties=feature['properties'];
      if(geometry is! Map || geometry['type']!='Point' || properties is! Map)continue;
      final coordinates=geometry['coordinates'];
      if(coordinates is! List || coordinates.length<2)continue;
      final parts=<String>[];
      for(final key in ['name','street','housenumber','city','state','country']){
        final value=properties[key];if(value is String && value.trim().isNotEmpty && !parts.contains(value))parts.add(value.trim());
      }
      final place=GeoPlace.fromJson({'label':parts.join(', '),'lat':coordinates[1],'lon':coordinates[0]});
      if(place!=null && !places.any((p)=>p.label==place.label && p.point==place.point))places.add(place);
    }
    return places;
  }
}
