import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:integration_test/integration_test.dart';
import '../lib/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Farolitos actual 3D scene and touch puzzles on Android', (
    tester,
  ) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    final ready = Completer<WebViewController>();
    await tester.pumpWidget(FitReview(ready));
    await tester.pump(const Duration(seconds: 1));
    final c = await ready.future.timeout(const Duration(seconds: 45));
    Future<void> wait(String expression) async {
      for (var i = 0; i < 120; i++) {
        try {
          if ((await c.runJavaScriptReturningResult(expression)).toString() ==
              'true')
            return;
        } catch (_) {}
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pump();
      }
      print(
        'QA_DIAGNOSTIC: ${await c.runJavaScriptReturningResult("JSON.stringify({url:location.href,text:document.body.innerText,failure:window.qaFailure,errors:window.qaErrors})")}',
      );
      print('QA_FRAME=maze_failure');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
      fail('Timed out: $expression');
    }

    Future<void> capture(String name) async {
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      print('QA_FRAME=$name');
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
    }

    await wait("document.getElementById('solo')?.onclick!=null");
    await c.runJavaScript(
      "window.qaErrors=[];addEventListener('error',e=>qaErrors.push(e.message));window.qaDone=false;window.qaFailure=null;window.qaApp={adventureSnapshot:()=>window.nidoAdventureSnapshot()}",
    );
    await wait("typeof window.nidoAdventureSnapshot==='function'");
    await c.runJavaScript("document.getElementById('solo').click()");
    await wait("document.getElementById('helpPanel').hidden===false");
    await c.runJavaScript("document.getElementById('begin').click()");
    await wait('qaApp.adventureSnapshot().draws>0');
    await wait('qaApp.adventureSnapshot().audioReady>=10');
    await wait('qaApp.adventureSnapshot().artReady===4');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pump();
    await capture('maze_explore');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    // Navigate by the same pointer and keyboard input as a player; no teleporting.
    await c.runJavaScript(r'''
(async()=>{try{
 const sleep=ms=>new Promise(r=>setTimeout(r,ms)),snap=()=>qaApp.adventureSnapshot();
 async function until(fn){for(let i=0;i<80;i++){if(fn())return;await sleep(35);}throw Error('Input timed out: '+JSON.stringify({p:snap().state.players[0],paused:snap().paused,context:document.getElementById('open').textContent}));}
 function face(dx,dz){const desired=Math.atan2(-dx,-dz),delta=Math.atan2(Math.sin(desired-snap().yaw),Math.cos(desired-snap().yaw)),view=document.getElementById('look');view.dispatchEvent(new PointerEvent('pointerdown',{pointerId:1,clientX:400,clientY:180}));view.dispatchEvent(new PointerEvent('pointermove',{pointerId:1,clientX:400-delta/.006,clientY:180}));view.dispatchEvent(new PointerEvent('pointerup',{pointerId:1}));}
 async function choose(action,id){const buttons=[...document.querySelectorAll('#interactions button')],button=buttons.find(b=>b.dataset.action===action&&b.dataset.chest===String(id)),seq=snap().state.players[0].sequence??0;if(!button)throw Error('Missing interaction '+action+' '+id);if(buttons.length===1)document.getElementById('open').click();else button.click();await until(()=>(snap().state.players[0].sequence??0)>seq||!document.getElementById('puzzle').hidden);await sleep(250);}
 function path(s,target){const p=s.players[0],q=[[p.x,p.z,[]]],seen=new Set([p.z*s.size+p.x]);for(let i=0;i<q.length;i++){const[x,z,steps]=q[i];if(x===target.x&&z===target.z)return steps;for(const[dx,dz]of[[1,0],[-1,0],[0,1],[0,-1]]){const nx=x+dx,nz=z+dz,id=nz*s.size+nx;if(nx<0||nz<0||nx>=s.size||nz>=s.size||s.grid[id]||seen.has(id))continue;seen.add(id);q.push([nx,nz,[...steps,[dx,dz]]]);}}throw Error('No route');}
 async function go(target,before=false){const steps=path(snap().state,target);for(const[dx,dz]of(before?steps.slice(0,-1):steps)){
  let s=snap().state,p=s.players[0];const nx=p.x+dx,nz=p.z+dz,trap=s.traps.find(t=>!t.used&&t.x===nx&&t.z===nz);if(trap)await choose('disarm',trap.id);
  s=snap().state;p=s.players[0];const b=s.bridges?.find(b=>!b.secured&&b.x===nx&&b.z===nz);if(b)await choose('activate',b.id);
  face(dx,dz);window.dispatchEvent(new KeyboardEvent('keydown',{code:'KeyW'}));try{await until(()=>{const q=snap().state.players[0];return q.x!==p.x||q.z!==p.z;});}finally{window.dispatchEvent(new KeyboardEvent('keyup',{code:'KeyW'}));}
  const q=snap().state.players[0];if(q.x!==nx||q.z!==nz)throw Error('Unexpected movement');await sleep(300);
 }const p=snap().state.players[0];face(target.x-p.x,target.z-p.z);await sleep(200);}
 window.qaGo=go;window.qaChoose=choose;
 const target=snap().state.chests[0];await go(target,true);await choose('open',target.id);await until(()=>!document.getElementById('puzzle').hidden);window.qaDone=true;
}catch(e){window.qaFailure=String(e);window.qaDone=true;}})();

  ''');
    await wait('window.qaDone');
    if ((await c.runJavaScriptReturningResult('window.qaFailure')).toString() !=
        'null') {
      print('QA_FRAME=maze_failure');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
    }
    expect(
      (await c.runJavaScriptReturningResult('window.qaFailure')).toString(),
      'null',
    );
    await capture('maze_puzzle');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pump();
    await c.runJavaScript(r'''
   const s=qaApp.adventureSnapshot().state,c=s.chests[0];c.pattern.forEach((v,i)=>{for(let n=0;n<v;n++)document.getElementById('dials').children[i].click();});document.getElementById('solve').click();
  ''');
    await wait('qaApp.adventureSnapshot().state.keys===1');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump();
    await capture('maze_lantern_lit');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await c.runJavaScript(
      "window.qaDone=false;qaGo(qaApp.adventureSnapshot().state.bridges[0].plate).then(()=>qaApp.adventureSnapshot().state.bridges[0].secured?null:qaChoose('activate',0)).then(()=>{const s=qaApp.adventureSnapshot().state,b=s.bridges[0],p=s.players[0],yaw=Math.atan2(-(b.x-p.x),-(b.z-p.z)),d=yaw-qaApp.adventureSnapshot().yaw,v=document.getElementById('look');v.dispatchEvent(new PointerEvent('pointerdown',{pointerId:1,clientX:400,clientY:180}));v.dispatchEvent(new PointerEvent('pointermove',{pointerId:1,clientX:400-d/.006,clientY:180}));v.dispatchEvent(new PointerEvent('pointerup',{pointerId:1}));window.qaDone=true;}).catch(e=>{window.qaFailure=String(e);window.qaDone=true;})",
    );
    await wait('window.qaDone');
    await capture('maze_bridge');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    expect(
      (await c.runJavaScriptReturningResult(
        'JSON.stringify(qaErrors)',
      )).toString(),
      contains('[]'),
    );
  });
}
