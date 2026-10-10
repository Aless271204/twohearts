import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/inventory_service.dart';
import 'inventory_scene.dart';

/// Shared by the app and its browser review. Content stays editable and live.
const heartGradient = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFF6592), Color(0xFFFF326D)]);
const heartShadow = [BoxShadow(color: Color(0x20EC4878), blurRadius: 12, offset: Offset(0, 4))];

class HeartButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  const HeartButton({super.key, required this.label, this.icon, this.onPressed, this.outlined = false});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: outlined || onPressed == null ? null : heartGradient, color: outlined ? Colors.white.withAlpha(220) : onPressed == null ? AppTheme.primaryContainer : null, borderRadius: BorderRadius.circular(99), border: Border.all(color: outlined ? const Color(0xFFFFB6CB) : Colors.transparent), boxShadow: outlined ? null : heartShadow),
    child: TextButton(onPressed: onPressed, style: TextButton.styleFrom(foregroundColor: outlined ? AppTheme.primary : Colors.white, disabledForegroundColor: const Color(0xFF87717B), minimumSize: const Size(44, 40), padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10), shape: const StadiumBorder()), child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [if(icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 6)], Flexible(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))])),
  );
}

class HeartIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const HeartIconButton({super.key, required this.icon, required this.tooltip, this.onPressed});
  @override
  Widget build(BuildContext context) => Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withAlpha(240), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0BE75480), blurRadius: 10, offset: Offset(0, 3))]), child: IconButton(onPressed: onPressed, tooltip: tooltip, icon: Icon(icon, size: 23, color: const Color(0xFF302A38))));
}

class HeartHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  const HeartHeader({super.key, required this.title, this.subtitle, this.leading, this.actions = const []});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 12), child: Row(children: [if(leading != null) ...[leading!, const SizedBox(width: 9)], Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -.6, height: 1.15)), if(subtitle != null) ...[const SizedBox(height: 5), Text(subtitle!, style: const TextStyle(fontSize: 14, color: AppTheme.primary))]])), for(final action in actions) Padding(padding: const EdgeInsets.only(left: 7), child: action)]));
}

class HeartSurface extends StatelessWidget {
  final Widget child;
  const HeartSurface({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFBFC), Color(0xFFFFF2F4)])), child: child);
}

class HeartNavigation extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const HeartNavigation({super.key, required this.selected, required this.onSelect});
  static const tabs = [(label:'Social',icon:Icons.people_outline_rounded),(label:'Tienda',icon:Icons.storefront_outlined),(label:'Nido',icon:Icons.home_outlined),(label:'Mascota',icon:Icons.pets_outlined),(label:'Actividades',icon:Icons.sports_esports_outlined)];
  @override
  Widget build(BuildContext context) => Container(
    height:62 + MediaQuery.paddingOf(context).bottom,
    padding: EdgeInsets.fromLTRB(8, 5, 8, MediaQuery.paddingOf(context).bottom + 6),
    decoration: const BoxDecoration(color: Color(0xFFFFFCFD), borderRadius: BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Color(0x0FE95680), blurRadius: 16, offset: Offset(0,-3))]),
    child: Row(children: [
      for (var i=0; i<tabs.length; i++) Expanded(child: Semantics(
        selected: selected==i, button: true, label: tabs[i].label,
        child: InkWell(onTap: ()=>onSelect(i), borderRadius: BorderRadius.circular(99),
          child: Center(child: AnimatedContainer(
            duration: const Duration(milliseconds:200), width:64, height:51,
            decoration: BoxDecoration(gradient: selected==i ? heartGradient : null, borderRadius:BorderRadius.circular(99), boxShadow:selected==i?heartShadow:null),
            child: Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Icon(tabs[i].icon,size:23,color:selected==i?Colors.white:const Color(0xFF514D61)),
              const SizedBox(height:3),
              FittedBox(fit:BoxFit.scaleDown,child:Text(tabs[i].label,maxLines:1,style:TextStyle(fontSize:10,fontWeight:FontWeight.w500,color:selected==i?Colors.white:const Color(0xFF514D61)))),
            ]),
          )),
        ),
      )),
    ]),
  );
}

/// The model and furniture share one room coordinate system. Its feet sit on
/// the rug at 83% of the room height, independently of device dimensions.
class PetRoomStage extends StatelessWidget {
  final Map<String, InventoryItem> loadout;
  final Widget pet;
  final VoidCallback? onTap;
  const PetRoomStage({super.key, required this.loadout, required this.pet, this.onTap});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context,c) => Stack(fit: StackFit.expand,children:[
    InventoryScene(loadout:loadout),
    Positioned(left:c.maxWidth*.31,top:c.maxHeight*.795,width:c.maxWidth*.38,height:c.maxHeight*.06,child:DecoratedBox(decoration:BoxDecoration(borderRadius:BorderRadius.circular(99),gradient:const RadialGradient(colors:[Color(0x350D0710),Color(0x00100710)],radius:.7)))),
    Positioned(left:c.maxWidth*.065,right:c.maxWidth*.065,top:c.maxHeight*.105,height:c.maxHeight*.88,child:GestureDetector(onTap:onTap,child:pet)),
  ]));
}

class HeartQuoteCard extends StatelessWidget {
  final String text,sendLabel;
  final VoidCallback? onSend,onMore;
  const HeartQuoteCard({super.key,required this.text,required this.sendLabel,this.onSend,this.onMore});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius:BorderRadius.circular(22),child:Stack(children:[
    Positioned.fill(child:CustomPaint(painter:_CloudsPainter())),
    Padding(padding:const EdgeInsets.fromLTRB(24,18,24,14),child:Column(children:[
      Text(text,textAlign:TextAlign.center,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w500,fontStyle:FontStyle.italic,height:1.35,color:Color(0xFF891F49))),
      const SizedBox(height:12),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[Flexible(child:HeartButton(label:sendLabel,icon:Icons.send_rounded,outlined:true,onPressed:onSend)),if(onMore!=null)...[const SizedBox(width:8),IconButton(onPressed:onMore,tooltip:'Otra frase',icon:const Icon(Icons.refresh_rounded,color:AppTheme.primary,size:20))]]),
    ])),
  ]));
}

class _CloudsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas,Size s){
    canvas.drawRect(Offset.zero&s,Paint()..shader=const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFFFFD9E5),Color(0xFFFFEEE7)]).createShader(Offset.zero&s));
    for(var i=0;i<11;i++){
      final x=s.width*i/10,y=s.height*(.93-(i%3)*.06),r=s.width*(.09+(i%2)*.015);
      canvas.drawCircle(Offset(x,y),r,Paint()..color=const Color(0x77FFFFFF));
      canvas.drawCircle(Offset(x,y+15),r*.8,Paint()..color=const Color(0x99FFF9F3));
    }
    final heart=Path()..moveTo(0,8)..cubicTo(-17,-5,-20,12,0,27)..cubicTo(20,12,17,-5,0,8);
    canvas.save();canvas.translate(s.width*.06,s.height*.20);canvas.rotate(-.25);canvas.drawPath(heart,Paint()..color=const Color(0xFFFF6592)..style=PaintingStyle.stroke..strokeWidth=2.5);canvas.restore();
  }
  @override bool shouldRepaint(_CloudsPainter oldDelegate)=>false;
}
