import '../../widgets/twohearts_ui.dart';
import 'package:flutter/material.dart';
import '../../widgets/rose_ui.dart';
import '../../theme/app_theme.dart';
import '../../services/game_service.dart';
import '../../services/inventory_service.dart';
import '../shop_screen/shop_screen.dart';
import 'pebble_runner_test.dart';
import 'duo_game_screen.dart';

class GameHubScreen extends StatefulWidget {
  final bool previewMode;
  const GameHubScreen({super.key,this.previewMode=false});
  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  final inventory = InventoryService.instance;
  @override
  void initState() {
    super.initState();
    inventory.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    inventory.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if(widget.previewMode)return;
    await GameService.instance.retryPendingRunnerRewards();
    await inventory.refresh().catchError((Object _) {});
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _featuredForest(),
          const SizedBox(height: 20),
          const Text('Todos los juegos', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Expanded(child:_tile('Ping pong\nen pareja',1,()=>_open(const DuoGameScreen(game:'pong')))),
            const SizedBox(width:10),
            Expanded(child:_tile('¿Quién nos\nconoce mejor?',2,()=>_open(const DuoGameScreen(game:'quiz')))),
          ]),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => _open(const ShopScreen()),
            icon: const Icon(Icons.checkroom),
            label: const Text('Personalizar · Tienda e inventario'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(onPressed:()=>showDialog(context:context,builder:(_)=>const AlertDialog(title:Text('Recompensas'),content:Text('En los juegos en pareja, quien gana recibe 20 LoveCoins y su pareja 8, hasta 300 al día. En el bosque, las monedas se guardan al terminar una carrera validada.'))),icon:const Icon(Icons.info_outline,size:16),label:const Text('Cómo se ganan monedas')),

        ],
      ),
    ),
  );
  Widget _tile(String title,int panel,VoidCallback action)=>ClipRRect(borderRadius:BorderRadius.circular(20),child:SizedBox(height:224,child:Stack(fit:StackFit.expand,children:[
    GameArt(panel:panel),
    const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0x63000000),Color(0x00000000),Color(0x53000000)]))),
    Positioned(left:12,top:12,right:12,child:Text(title,style:const TextStyle(color:Colors.white,fontSize:15,height:1.2,fontWeight:FontWeight.w700))),
    Positioned(left:12,right:12,bottom:12,child:HeartButton(label:'Jugar',onPressed:action)),
  ])));
  Widget _featuredForest() => SizedBox(height: 326, child: ClipRRect(borderRadius: BorderRadius.circular(26), child: Stack(fit: StackFit.expand, children: [
    const GameArt(panel: 0),
    const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x08000000), Color(0xB5223B2E)]))),
    Positioned(left: 20, right: 20, bottom: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Corre con tu mascota', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Un bosque lleno de vida. Salta, recoge corazones y supera tu récord.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
      const SizedBox(height: 12),
      HeartButton(label:'Jugar',icon:Icons.play_arrow_rounded,onPressed:()=>_open(const PebbleRunnerTest())),
    ])),
  ])));
}
