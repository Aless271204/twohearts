import 'package:flutter/material.dart';
import '../../../core/pet_model_catalog.dart';

class PetSelectionWidget extends StatelessWidget {
  final String? selectedPet;
  final ValueChanged<String> onPetSelected;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onConfirm;
  final bool isLoading;
  const PetSelectionWidget({super.key,required this.selectedPet,required this.onPetSelected,required this.onNameChanged,required this.onConfirm,required this.isLoading});
  @override
  Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Text('Elijan su primera mascota',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    const Text('Será su compañera en la habitación y en los juegos. Más adelante podrán adoptar otras.'),
    const SizedBox(height:12),
    SizedBox(height:220,child:GridView.count(crossAxisCount:2,childAspectRatio:1.3,mainAxisSpacing:8,crossAxisSpacing:8,children:PetModelCatalog.models.keys.map((s)=>InkWell(onTap:isLoading?null:()=>onPetSelected(s),child:Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(14),border:Border.all(color:selectedPet==s?Colors.green:Colors.black12,width:2)),child:Column(children:[Expanded(child:Image.asset('assets/images/pets/$s.png',fit:BoxFit.contain)),Text(PetModelCatalog.labels[s]!)])))).toList())),
    TextFormField(maxLength:24,onChanged:onNameChanged,decoration:const InputDecoration(labelText:'Nombre elegido por ustedes',hintText:'Pueden ponerlo después')),
    FilledButton(onPressed:selectedPet==null||isLoading?null:onConfirm,child:Text(isLoading?'Preparando su mascota…':'Elegir mascota')),
  ]);
}
