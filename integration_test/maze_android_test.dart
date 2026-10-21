import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:integration_test/integration_test.dart';
import '../lib/main.dart';
void main(){
 IntegrationTestWidgetsFlutterBinding.ensureInitialized();
 testWidgets('Farolitos actual 3D scene and touch puzzles on Android',(tester) async{
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
  final ready=Completer<WebViewController>();await tester.pumpWidget(FitReview(ready));await tester.pump(const Duration(seconds:1));
  final c=await ready.future.timeout(const Duration(seconds:45));
  Future<void> wait(String expression)async{for(var i=0;i<120;i++){try{if((await c.runJavaScriptReturningResult(expression)).toString()=='true')return;}catch(_){}await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:500)));await tester.pump();}fail('Timed out: $expression');}
  await wait("document.getElementById('solo')?.onclick!=null");
  await c.runJavaScript("window.qaErrors=[];addEventListener('error',e=>qaErrors.push(e.message));window.qaDone=false;window.qaFailure=null;import('./main.js?revision=lantern-garden-2').then(m=>window.qaApp=m)");await wait('!!window.qaApp');
  await c.runJavaScript("document.getElementById('solo').click()");await wait("document.getElementById('helpPanel').hidden===false");await c.runJavaScript("document.getElementById('begin').click()");
  await wait('qaApp.adventureSnapshot().draws>0');await tester.runAsync(()=>Future<void>.delayed(const Duration(seconds:3)));await tester.pump();print('QA_FRAME=maze_explore');
  await tester.runAsync(()=>Future<void>.delayed(const Duration(seconds:3)));
  // Navigate by the same pointer and keyboard input as a player; no teleporting.
  await c.runJavaScript(r'''
  (async()=>{try{
   const sleep=ms=>new Promise(r=>setTimeout(r,ms));
   const snap=()=>qaApp.adventureSnapshot();
   function path(s,target){const p=s.players[0],q=[[p.x,p.z,[]]],seen=new Set([p.z*s.size+p.x]);for(let i=0;i<q.length;i++){const [x,z,steps]=q[i];if(x===target.x&&z===target.z)return steps;for(const [dx,dz] of [[1,0],[-1,0],[0,1],[0,-1]]){const nx=x+dx,nz=z+dz,id=nz*s.size+nx;if(nx<0||nz<0||nx>=s.size||nz>=s.size||s.grid[id]||seen.has(id))continue;seen.add(id);q.push([nx,nz,[...steps,[dx,dz]]]);}}throw Error('No route');}
   for(const [dx,dz] of path(snap().state,snap().state.chests[0])){
    let s=snap().state,p=s.players[0];const trap=s.traps.find(t=>!t.used&&Math.abs(t.x-p.x)+Math.abs(t.z-p.z)<=1);if(trap){document.getElementById('open').click();await sleep(320);}
    s=snap().state;p=s.players[0];const b=s.bridges?.find(b=>!b.secured&&Math.abs(b.plate.x-p.x)+Math.abs(b.plate.z-p.z)<=1);if(b){document.getElementById('open').click();await sleep(320);}
    const desired=Math.atan2(-dx,-dz),delta=Math.atan2(Math.sin(desired-snap().yaw),Math.cos(desired-snap().yaw));
    const look=document.getElementById('look');look.dispatchEvent(new PointerEvent('pointerdown',{pointerId:1,clientX:400,clientY:180}));look.dispatchEvent(new PointerEvent('pointermove',{pointerId:1,clientX:400-delta/.006,clientY:180}));look.dispatchEvent(new PointerEvent('pointerup',{pointerId:1}));
    window.dispatchEvent(new KeyboardEvent('keydown',{code:'KeyW'}));await sleep(80);window.dispatchEvent(new KeyboardEvent('keyup',{code:'KeyW'}));await sleep(280);
   }
   document.getElementById('open').click();await sleep(600);
   if(document.getElementById('puzzle').hidden)throw Error('Puzzle did not open');
   window.qaDone=true;
  }catch(e){window.qaFailure=String(e);window.qaDone=true;}})();
  ''');
  await wait('window.qaDone');expect((await c.runJavaScriptReturningResult('window.qaFailure')).toString(),'null');
  print('QA_FRAME=maze_puzzle');await tester.runAsync(()=>Future<void>.delayed(const Duration(seconds:3)));await tester.pump();
  await c.runJavaScript(r'''
   const s=qaApp.adventureSnapshot().state,c=s.chests[0];c.pattern.forEach((v,i)=>{for(let n=0;n<v;n++)document.getElementById('dials').children[i].click();});document.getElementById('solve').click();
  ''');await wait('qaApp.adventureSnapshot().state.keys===1');await tester.runAsync(()=>Future<void>.delayed(const Duration(seconds:2)));await tester.pump();print('QA_FRAME=maze_lantern_lit');await tester.runAsync(()=>Future<void>.delayed(const Duration(seconds:3)));
  expect((await c.runJavaScriptReturningResult('JSON.stringify(qaErrors)')).toString(),contains('[]'));
 });
}
