import 'package:flutter/material.dart';
import '../core/pet_model_catalog.dart';
import '../services/shared_pet_service.dart';

class PetFamilySheet extends StatefulWidget {
  const PetFamilySheet({super.key});
  @override
  State<PetFamilySheet> createState()=>_PetFamilySheetState();
}
class _PetFamilySheetState extends State<PetFamilySheet> {
  final _pet=SharedPetService.instance;
  final _name=TextEditingController();
  late String _species;
  bool _busy=false;
  String? _error;
  @override
  void initState(){super.initState();_species=_pet.species;_name.text=_pet.name;}
  @override
  void dispose(){_name.dispose();super.dispose();}
  Future<void> _save(String action) async {
    setState((){_busy=true;_error=null;});
    try {await _pet.change(action,_species,_name.text);if(mounted)Navigator.pop(context);}
    catch(_){if(mounted)setState(()=>_error='No se guardó el cambio. Revisa la conexión y los requisitos de adopción.');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context){
    final owned=_pet.pets.any((p)=>p['species']==_species);
    final count=_pet.pets.length;
    final requiredLevel=count<=1?8:count==2?16:24;
    final requiredDays=count<=1?3:count==2?7:14;
    final canAdopt=count<4&&_pet.familyLevel>=requiredLevel&&_pet.careDays>=requiredDays;
    return SafeArea(child:SingleChildScrollView(padding:EdgeInsets.fromLTRB(20,20,20,20+MediaQuery.of(context).viewInsets.bottom),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(_pet.selectionConfirmed?'Vuestras mascotas':'Elijan su primera mascota',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      Text('Nivel compartido ${_pet.familyLevel} · ${_pet.careDays} días de cuidado'),
      const SizedBox(height:12),
      Wrap(spacing:10,runSpacing:10,children:PetModelCatalog.models.keys.map((s){
        final adopted=_pet.pets.any((p)=>p['species']==s);
        return SizedBox(width:145,child:InkWell(onTap:_busy?null:(){setState((){_species=s;final matching=_pet.pets.where((p)=>p['species']==s);_name.text=matching.isEmpty?'':matching.first['name'] as String? ?? '';});},child:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),border:Border.all(color:s==_species?Colors.green:Colors.black12,width:2)),child:Column(children:[
          Image.asset('assets/images/pets/$s.png',height:110,fit:BoxFit.contain),
          Text(PetModelCatalog.labels[s]!),Text(adopted?'Adoptada':_pet.selectionConfirmed?'Por adoptar':'Disponible',style:const TextStyle(fontSize:11)),
        ]))));
      }).toList()),
      const SizedBox(height:12),
      TextField(controller:_name,maxLength:24,enabled:!_busy,decoration:const InputDecoration(labelText:'El nombre lo eligen ustedes',hintText:'Sin nombre todavía')),
      if(_error!=null)Text(_error!,style:const TextStyle(color:Colors.red)),
      if(!_pet.selectionConfirmed)FilledButton(onPressed:_busy?null:()=>_save('choose'),child:const Text('Elegir nuestra mascota'))
      else if(owned)...[
        FilledButton(onPressed:_busy?null:()=>_save('rename'),child:const Text('Guardar nombre y llevar a la habitación')),
        Text('Etapa: ${PetModelCatalog.stageFor((_pet.pets.firstWhere((p)=>p['species']==_species)['level'] as int?)??1)}',textAlign:TextAlign.center),
      ]else...[
        Text('Necesitan nivel compartido $requiredLevel y $requiredDays días distintos de cuidado. La nueva mascota empieza como cría.'),
        FilledButton(onPressed:_busy||!canAdopt?null:()=>_save('adopt'),child:const Text('Adoptar')),
      ],
    ])));
  }
}
