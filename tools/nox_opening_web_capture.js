async (page) => {
 const results=await Promise.all([{w:360,h:800,dpr:2,ja:true},{w:405,h:900,dpr:2,ja:true},{w:720,h:900,dpr:1,ja:false}].map(async o=>{
 const context=await page.context().browser().newContext({viewport:{width:o.w,height:o.h},deviceScaleFactor:o.dpr,isMobile:o.dpr===2,hasTouch:o.dpr===2,...(o.w===360?{recordVideo:{dir:'docs/previews/opening_v01/video',size:{width:360,height:800}}}:{})});
 const p=await context.newPage();const errors=[];
 p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 await p.goto('http://127.0.0.1:8768');await p.waitForTimeout(3500);
 if(o.ja){await p.touchscreen.tap(o.w-67,23);await p.waitForTimeout(400);}
 if(o.dpr===2){await p.touchscreen.tap(o.w/2,o.h-87);}else{await p.mouse.click(o.w/2,o.h-175);}
 const start=Date.now();
 const times=[1500,4700,8500,12000,15700,18300,21200];
 for(let i=0;i<times.length;i++){
 await p.waitForTimeout(Math.max(0,times[i]-(Date.now()-start)));
 await p.screenshot({path:`docs/previews/opening_v01/${o.w}_scene${String(i+1).padStart(2,'0')}.png`,scale:'css'});
 }
 const metrics=await p.evaluate(()=>({width:innerWidth,height:innerHeight,dpr:devicePixelRatio,canvas:document.querySelector('canvas').getBoundingClientRect().toJSON()}));
 if(o.w<=480){
 await p.touchscreen.tap(o.w/2,o.h/2+265);await p.waitForTimeout(350);
 await p.screenshot({path:`docs/previews/gr07_stable_v01/${o.w}_gr01.png`,scale:'css'});
 await p.touchscreen.tap(o.w-52,32);await p.waitForTimeout(150);
 await p.touchscreen.tap(o.w-50,Math.round(o.h*0.17+39));await p.waitForTimeout(350);
 await p.screenshot({path:`docs/previews/gr07_stable_v01/${o.w}_gr07.png`,scale:'css'});
 }
 await context.close();return {viewport:o,errors,metrics};
 }));return results;
}
