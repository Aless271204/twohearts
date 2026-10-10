import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twohearts/services/app_language.dart';
import 'package:twohearts/services/scene_audio_policy.dart';
import 'package:twohearts/widgets/twohearts_ui.dart';

void main(){
  testWidgets('Navigation reserves a small footer and preserves all five tabs at 320px', (tester) async {
    tester.view.physicalSize=const Size(320,700);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    var selected=-1;
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:const Text('Contenido'),bottomNavigationBar:HeartNavigation(selected:2,onSelect:(i)=>selected=i))));
    expect(tester.getSize(find.byType(HeartNavigation)).height,62);
    final content=tester.getTopLeft(find.text('Contenido'));expect(content.dy,lessThan(100));
    for(var i=0;i<HeartNavigation.tabs.length;i++){
      await tester.tap(find.text(HeartNavigation.tabs[i].label));expect(selected,i);
    }
    expect(tester.takeException(),isNull);
  });
  testWidgets('Quote card and action wrap safely with enlarged text', (tester) async {
    tester.view.physicalSize=const Size(320,700);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home:MediaQuery(data:const MediaQueryData(textScaler:TextScaler.linear(1.4)),child:Scaffold(body:Padding(padding:const EdgeInsets.all(20),child:HeartQuoteCard(text:'Cada mensaje tuyo hace que la distancia sea un poco más pequeña.',sendLabel:'Enviar a mi pareja',onSend:(){}))))));
    expect(tester.takeException(),isNull);
  });
  test('Activity audio loses ownership when hidden, covered, inactive or closed',(){
    final policy=SceneAudioPolicy();addTearDown(policy.dispose);
    policy.update(tab:4);expect(policy.activitiesVisible,isTrue);
    policy.update(covered:true);expect(policy.activitiesVisible,isFalse);
    policy.update(covered:false);expect(policy.activitiesVisible,isTrue);
    for(final state in [AppLifecycleState.inactive,AppLifecycleState.hidden,AppLifecycleState.paused,AppLifecycleState.detached]){
      policy.didChangeAppLifecycleState(state);expect(policy.activitiesVisible,isFalse);
      policy.didChangeAppLifecycleState(AppLifecycleState.resumed);expect(policy.activitiesVisible,isTrue);
    }
    policy.update(tab:3);expect(policy.activitiesVisible,isFalse);
  });
  test('Language persists and translates the same daily phrase',()async{
    SharedPreferences.setMockInitialValues({'app_language':'pt'});
    final language=AppLanguage();addTearDown(language.dispose);await language.initialize();
    expect(language.code,'pt');expect(language.quotes.first['text'],startsWith('Cada mensagem'));
    await language.select('en');expect(language.quotes.first['text'],startsWith('Every message'));
    final restored=AppLanguage();addTearDown(restored.dispose);await restored.initialize();expect(restored.code,'en');
    await language.select('invalid');expect(language.code,'en');
  });
}
