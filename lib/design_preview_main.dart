import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'design_preview_data.dart';
import 'services/app_language.dart';
import 'services/inventory_service.dart';
import 'services/shared_pet_service.dart';
import 'services/memory_album_service.dart';
import 'services/scene_audio_policy.dart';
import 'theme/app_theme.dart';
import 'widgets/twohearts_ui.dart';
import 'presentation/social_screen/social_screen.dart';
import 'presentation/shop_screen/inventory_screen.dart';
import 'presentation/memories_screen/memories_screen.dart';
import 'presentation/home_screen/home_screen.dart';
import 'presentation/activities_screen/activities_screen.dart';

/// Separate entry point. This build has no credentials for the real backend.
/// The APK and production web app always use lib/main.dart.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguage.instance.initialize();
  await Supabase.initialize(url:'http://127.0.0.1:9',anonKey:'twohearts-design-preview',authOptions:FlutterAuthClientOptions(autoRefreshToken:false,localStorage:const EmptyLocalStorage()));
  InventoryService.instance.catalog=InventoryService.mergeAccessoryConcepts(previewInventory);
  InventoryService.instance.coins=80;
  SharedPetService.instance.data={'species':'penguin','name':'','level':3,'hunger':85,'energy':90,'joy':95,'members':['example-1','example-2']};
  final router=GoRouter(observers:[SceneAudioRouteObserver()],routes:[
    GoRoute(path:'/',builder:(_,__)=>const DesignReview()),
    for(final path in ['/profile-screen','/pairing-screen']) GoRoute(path:path,builder:(context,_)=>Scaffold(appBar:AppBar(title:const Text('Previsualización')),body:Center(child:HeartButton(label:'Volver al diseño',onPressed:()=>context.pop())))),
  ]);
  runApp(ListenableBuilder(listenable:AppLanguage.instance,builder:(_,__)=>MaterialApp.router(title:'TwoHearts · Revisión de interfaz',debugShowCheckedModeBanner:false,theme:AppTheme.lightTheme,routerConfig:router,locale:AppLanguage.instance.locale,supportedLocales:const[Locale('es'),Locale('en'),Locale('pt')],localizationsDelegates:GlobalMaterialLocalizations.delegates)));
}

class DesignReview extends StatefulWidget {
  const DesignReview({super.key});
  @override State<DesignReview> createState()=>_DesignReviewState();
}
class _DesignReviewState extends State<DesignReview>{
  int selected=(int.tryParse(Uri.base.queryParameters['tab']??'2')??2).clamp(0,4);
  List<Map<String,dynamic>> get posts=>[for(var i=0;i<3;i++){
    'id':'preview-$i','created_at':DateTime.now().subtract(Duration(hours:i+2)).toIso8601String(),'content_type':'image','content_url':'example','preview_panel':i%2,'user_profiles':{'nickname':i==0?'Tú & Tu pareja':i==1?'Pareja viajera':'Nuestros recuerdos'},'caption':i==0?'Atardeceres más bonitos contigo. ♡':'Nuevas aventuras, mismos cómplices. ♡','likes_count':i==0?128:96,'comments_count':i==0?12:8,
  }];
  List<MemoryAlbum> get albums=>[for(var i=0;i<4;i++)MemoryAlbum(id:'preview-$i',userId:'example',coupleId:'example',albumName:['Costa italiana','Un viaje juntos','Nuestro verano','Días de montaña'][i],description:'Recuerdo de ejemplo',photoUrls:['twohearts-preview:${i%2}'],createdAt:DateTime.now())];
  @override
  void initState(){super.initState();SceneAudioPolicy.instance.update(tab:selected);}
  Widget get screen=>switch(selected){
    0=>SocialScreen(previewPosts:posts),
    1=>const ShopScreen(previewMode:true),
    2=>MemoriesScreen(previewAlbums:albums),
    3=>const HomeScreen(previewMode:true),
    _=>const ActivitiesScreen(previewMode:true),
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor:const Color(0xFFF8DFE3),
    body:SafeArea(child:Column(children:[
      Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),child:Row(children:[
        const Expanded(child:Text('TwoHearts · Vista de diseño con datos de ejemplo',style:TextStyle(fontSize:12,color:Color(0xFF775A68)))),
        DropdownButton<String>(value:AppLanguage.instance.code,underline:const SizedBox.shrink(),items:[for(final e in AppLanguage.names.entries)DropdownMenuItem(value:e.key,child:Text(e.value,style:const TextStyle(fontSize:12)))],onChanged:(v){if(v!=null)AppLanguage.instance.select(v);}),
      ])),
      Expanded(child:LayoutBuilder(builder:(context,c) => Center(
        child:SizedBox(width:math.min(c.maxWidth,430),height:math.min(c.maxHeight,900),
          child:ClipRRect(borderRadius:BorderRadius.circular(c.maxWidth>500?28:0),
            child:HeartSurface(child:Scaffold(
              backgroundColor:Colors.transparent,
              body:AnimatedSwitcher(duration:const Duration(milliseconds:180),child:KeyedSubtree(key:ValueKey(selected),child:screen)),
              bottomNavigationBar:HeartNavigation(selected:selected,onSelect:(i){SceneAudioPolicy.instance.update(tab:i);setState(()=>selected=i);}),
            )),
          ),
        ),
      ))),
    ])),
  );
}
