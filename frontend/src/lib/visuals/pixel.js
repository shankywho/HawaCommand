// @ts-nocheck
// Vendored from Claude Design export (design/claude-design/source/pixel.js). Registers custom elements; loaded client-side by components/visuals/VisualsLoader.
(function(){
const __raf=f=>setTimeout(()=>f(performance.now()),30),__caf=clearTimeout;
if(window.HawaPixel)return;
const watch=el=>{el._vis=true;try{el._io=new IntersectionObserver(e=>{el._vis=e[e.length-1].isIntersecting;},{rootMargin:'200px'});el._io.observe(el);}catch(e){}};
const RM=()=>window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches;
const lerp=(a,b,t)=>a+(b-a)*t, clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const hx=h=>{const n=parseInt(h.slice(1),16);return[n>>16&255,n>>8&255,n&255];};
const mix=(a,b,t)=>[lerp(a[0],b[0],t),lerp(a[1],b[1],t),lerp(a[2],b[2],t)];
const css=(c,a)=>a===undefined?`rgb(${c[0]|0},${c[1]|0},${c[2]|0})`:`rgba(${c[0]|0},${c[1]|0},${c[2]|0},${a})`;
const shade=(c,k)=>[clamp(c[0]*k,0,255),clamp(c[1]*k,0,255),clamp(c[2]*k,0,255)];
const tri=(arr,t)=>t<.5?mix(arr[0],arr[1],t*2):mix(arr[1],arr[2],(t-.5)*2);
function rng(seed){return function(){seed|=0;seed=seed+0x6D2B79F5|0;let t=Math.imul(seed^seed>>>15,1|seed);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}
const BAYER=[0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5];
const SKY={top:['#5A4B3E','#7E8286','#2C86DA'].map(hx),mid:['#836D58','#A9A792','#5CB2EE'].map(hx),hor:['#B39571','#D3CAA3','#C6E9FB'].map(hx)};
const HAZE=hx('#A8927A');
const AQI_L=['#1E8A4C','#5E8F1B','#8A6D00','#B35609','#C02A2A','#7F1D3A'].map(hx);
const AQI_D=['#3FB871','#9CCB4E','#E8C53A','#F08C35','#E5484D','#C43A6B'].map(hx);
const band=v=>v<=30?0:v<=60?1:v<=90?2:v<=120?3:v<=250?4:5;
function skyColor(t,y){return y<.55?mix(tri(SKY.top,t),tri(SKY.mid,t),y/.55):mix(tri(SKY.mid,t),tri(SKY.hor,t),(y-.55)/.45);}
function paintSky(ctx,W,H,t,step){const img=ctx.createImageData(W,H),d=img.data;step=step||7;
 const rows=[];for(let y=0;y<H;y++)rows.push(skyColor(t,y/H));
 for(let y=0;y<H;y++){const c=rows[y];for(let x=0;x<W;x++){const b=(BAYER[(y&3)*4+(x&3)]/16-.5)*step,i=(y*W+x)*4;d[i]=Math.round((c[0]+b)/step)*step;d[i+1]=Math.round((c[1]+b)/step)*step;d[i+2]=Math.round((c[2]+b)/step)*step;d[i+3]=255;}}
 ctx.putImageData(img,0,0);}
function circ(ctx,cx,cy,r,col){for(let y=-r;y<=r;y++){const w=Math.floor(Math.sqrt(r*r-y*y));ctx.fillStyle=col;ctx.fillRect(Math.round(cx-w),Math.round(cy+y),w*2+1,1);}}
function makeCloud(R,w){const puffs=[];const n=3+Math.floor(R()*4);for(let i=0;i<n;i++){const px=(i+0.5)/n*w,r=w*(0.14+R()*0.14);puffs.push([px,-r*0.6-R()*r*0.4,r]);}
 const h=Math.ceil(Math.max(...puffs.map(p=>-p[1]+p[2])));const rows=[];
 for(let y=-h;y<=0;y++){let x0=1e9,x1=-1e9;puffs.forEach(([px,py,r])=>{const dy=y-py;if(Math.abs(dy)<=r){const dx=Math.sqrt(r*r-dy*dy);x0=Math.min(x0,px-dx);x1=Math.max(x1,px+dx);}});if(x1>x0)rows.push([y,Math.round(x0),Math.round(x1)]);}
 return rows;}
function drawCloud(ctx,x,y,rows,t,alpha){const body=mix(hx('#9A8670'),hx('#FFFFFF'),t),sh=mix(hx('#7E6C58'),hx('#D4ECFA'),t),hi=mix(hx('#B09C84'),hx('#FFFFFF'),t);const n=rows.length;
 rows.forEach(([ry,x0,x1],i)=>{ctx.fillStyle=css(i>n-3?sh:i<2?hi:body,alpha);ctx.fillRect(Math.round(x+x0),Math.round(y+ry),x1-x0,1);});}
function smogNoise(x,r,o){return Math.sin(x*.061+r*1.3+o)+Math.sin(x*.023+r*.7+2+o*.6)+Math.sin(x*.137+r*2.1-o*.3)*.6;}

/* ---------- px-sky ---------- */
class PxSky extends HTMLElement{
 connectedCallback(){this.style.display='block';this.style.overflow='hidden';
  const c=this.cv=document.createElement('canvas');c.style.cssText='width:100%;height:100%;display:block;image-rendering:pixelated';(this.shadowRoot||this.attachShadow({mode:'open'})).replaceChildren(c);watch(this);
  const R=rng(11);this.clouds=[];for(let i=0;i<9;i++){const w=22+Math.floor(R()*46);this.clouds.push({x:R()*420,y:0.12+R()*0.5,rows:makeCloud(R,w),w,v:0.6+R()*1.2});}
  this.birds=[];for(let i=0;i<6;i++)this.birds.push({x:R()*400,y:.12+R()*.25,v:4+R()*4,p:R()*6});
  this.parts=[];for(let i=0;i<220;i++)this.parts.push({x:R(),y:R(),vx:(R()-.3)*0.006,vy:(R()-.5)*0.004,s:R()<.2?2:1});
  this.t0=performance.now();this.last=0;const f=n=>{this.frame(n);this.raf=__raf(f);};this.raf=__raf(f);}
 disconnectedCallback(){__caf(this.raf);}
 stage(){if(this.hasAttribute('scroll')){const se=document.scrollingElement||document.documentElement;const max=se.scrollHeight-innerHeight;return max>0?clamp(se.scrollTop/max,0,1):0;}return clamp(+(this.getAttribute('stage')||0),0,1);}
 frame(now){if(now-this.last<50&&!RM())return;if(RM()&&this._rs===this.stage()+'|'+this.clientWidth)return;this._rs=this.stage()+'|'+this.clientWidth;this.last=now;
  const px=+(this.getAttribute('px')||4),W=Math.ceil(this.clientWidth/px),H=Math.ceil(this.clientHeight/px);if(!W||!H)return;
  if(this.cv.width!==W||this.cv.height!==H){this.cv.width=W;this.cv.height=H;}
  const ctx=this.cv.getContext('2d'),t=this.stage(),dt=RM()?0:(now-this.t0)/1000,sc=(document.scrollingElement||document.documentElement).scrollTop/px;
  {const q=Math.round(t*200)/200,key=W+'x'+H+'|'+q;if(this._sk!==key){this._sk=key;paintSky(ctx,W,H,q);this._img=ctx.getImageData(0,0,W,H);}else ctx.putImageData(this._img,0,0);}
  if(!this.hasAttribute('nosun')){const sx=W*.8,sy=lerp(H*.46,H*.16,t),core=mix(hx('#E07F43'),hx('#FFE17A'),t),glow=mix(hx('#C9875A'),hx('#FFF3B8'),t);
   circ(ctx,sx,sy,14,css(glow,lerp(.25,.2,t)));circ(ctx,sx,sy,10,css(glow,.35));circ(ctx,sx,sy,7,css(core));}
  this.clouds.forEach((c,i)=>{const x=((c.x+dt*c.v)%(W+80))-60,y=c.y*H-((sc*0.08*(i%3+1))%H);drawCloud(ctx,x,y,c.rows,t,lerp(.85,1,t));});
  const smog=clamp(1-t*1.25,0,1);
  if(smog>0)for(let b=0;b<4;b++){const yc=H*(.25+b*.2)-sc*(0.05+b*0.05)%H,col=mix(hx('#6E5B48'),hx('#9E8C74'),b/3);
   for(let r=0;r<16;r++){const y=Math.round(yc+r);if(y<0||y>=H)continue;let run=-1;for(let x=0;x<=W;x++){const on=x<W&&smogNoise(x+dt*(3+b*2),r*0.4+b*3,b)>0.2+Math.abs(r-8)/8*1.4;if(on&&run<0)run=x;if(!on&&run>=0){ctx.fillStyle=css(col,smog*.28);ctx.fillRect(run,y,x-run,1);run=-1;}}}}
  if(smog>0){ctx.fillStyle=css(HAZE,smog*.22);ctx.fillRect(0,0,W,H);}
  if(t>.6)this.birds.forEach(b=>{const x=((b.x+dt*b.v)%(W+20))-10,y=b.y*H+Math.sin(dt+b.p)*2,fl=Math.floor(dt*4+b.p)%2;ctx.fillStyle=css(hx('#23313A'),clamp((t-.6)*3,0,1));
   if(fl){ctx.fillRect(x,y,1,1);ctx.fillRect(x+1,y+1,1,1);ctx.fillRect(x+2,y,1,1);ctx.fillRect(x+3,y-1,1,1);ctx.fillRect(x-1,y-1,1,1);}else{ctx.fillRect(x-1,y+1,2,1);ctx.fillRect(x+1,y+1,1,1);ctx.fillRect(x+2,y+1,2,1);}});
  if(!RM()&&!this.hasAttribute('noparticles')){const n=Math.floor(this.parts.length*Math.pow(clamp(1-t*1.15,0,1),1.3));for(let i=0;i<n;i++){const p=this.parts[i];const x=((p.x+dt*p.vx)%1+1)%1*W,y=((p.y+dt*p.vy+Math.sin(dt*.5+i)*.004)%1+1)%1*H;ctx.fillStyle=i%3?'rgba(74,58,42,.5)':'rgba(120,98,72,.55)';ctx.fillRect(Math.round(x),Math.round(y),p.s,p.s);}}
 }
}
customElements.define('px-sky',PxSky);

/* ---------- px-skyline ---------- */
function tint(c,t,k){return mix(hx(c),HAZE,(1-t)*k);}
function drawSkyline(ctx,W,H,t,seed){const R=rng(seed||5),G=H-3;
 // far towers
 for(let x=0;x<W;){const w=4+Math.floor(R()*7),h=Math.round(H*(.12+R()*.38));if(R()<.3){x+=w;continue;}const c=tint(R()<.5?'#B7CAD8':'#C9D5DE',t,.75);ctx.fillStyle=css(c);ctx.fillRect(x,G-Math.round(H*.2)-h,w,h+Math.round(H*.2));ctx.fillStyle=css(shade(c,.88));for(let y=G-Math.round(H*.2)-h+2;y<G-8;y+=3)for(let xx=x+1;xx<x+w-1;xx+=2)ctx.fillRect(xx,y,1,1);x+=w+1+Math.floor(R()*4);}
 const sand=tint('#D8A673',t,.55),sandD=shade(sand,.78),sandL=shade(sand,1.1);
 // arch
 {const ax=Math.round(W*.2),aw=24,ah=30,ay=G-8-ah;ctx.fillStyle=css(sand);ctx.fillRect(ax,ay,aw,ah);ctx.fillStyle=css(sandL);ctx.fillRect(ax-1,ay,aw+2,2);ctx.fillRect(ax+2,ay-4,aw-4,4);ctx.fillStyle=css(sandD);ctx.fillRect(ax+6,ay+10,aw-12,ah-10);circ(ctx,ax+aw/2,ay+11,6,css(sandD));ctx.fillRect(ax,ay+6,aw,1);}
 // minaret
 {const mx=Math.round(W*.66),base=G-6;let y=base,w=9;const col=tint('#C47A4E',t,.55);for(let s=0;s<5;s++){const h=11-s;ctx.fillStyle=css(s%2?shade(col,.9):col);ctx.fillRect(mx-Math.floor(w/2),y-h,w,h);for(let k=1;k<w;k+=2){ctx.fillStyle=css(shade(col,.8));ctx.fillRect(mx-Math.floor(w/2)+k,y-h,1,h);}ctx.fillStyle=css(sandL);ctx.fillRect(mx-Math.floor(w/2)-1,y-h,w+2,1);y-=h;w=Math.max(3,w-1.5|0);}ctx.fillStyle=css(sandD);ctx.fillRect(mx-1,y-3,3,3);}
 // tv tower
 {const tx=Math.round(W*.9),c=tint('#C9CED3',t,.65);ctx.fillStyle=css(c);ctx.fillRect(tx,G-58,2,50);ctx.fillRect(tx-4,G-52,10,5);ctx.fillStyle=css(shade(c,.8));ctx.fillRect(tx-4,G-48,10,1);ctx.fillRect(tx,G-64,1,6);}
 // cranes
 [[.4,48],[.83,40]].forEach(([p,h])=>{const cx=Math.round(W*p),c=tint('#E2A83C',t,.6);ctx.fillStyle=css(c);for(let y=G-h;y<G-6;y++){ctx.fillRect(cx+(y%4<2?0:2),y,1,1);ctx.fillRect(cx,y,1,1);ctx.fillRect(cx+2,y,1,1);}ctx.fillRect(cx-8,G-h,36,2);ctx.fillRect(cx-8,G-h+2,5,2);ctx.fillStyle=css(tint('#51575C',t,.6));ctx.fillRect(cx+20,G-h+2,1,12);ctx.fillRect(cx+19,G-h+14,3,2);});
 // flyover
 {const c=tint('#AEB4B7',t,.45);ctx.fillStyle=css(c);for(let x=Math.round(W*.44);x<W*.62;x++){const u=(x-W*.44)/(W*.18),y=Math.round(G-10-Math.sin(u*Math.PI)*8);ctx.fillRect(x,y,1,2);if(x%10===0){ctx.fillStyle=css(shade(c,.8));ctx.fillRect(x,y+2,2,G-y);ctx.fillStyle=css(c);}}}
 // metro deck + pillars
 const deckY=G-14,mc=tint('#C3CAD0',t,.4);ctx.fillStyle=css(mc);ctx.fillRect(0,deckY,W,2);ctx.fillStyle=css(shade(mc,.78));for(let x=4;x<W;x+=16)ctx.fillRect(x,deckY+2,2,G-deckY);
 return deckY;}
function drawFore(ctx,W,H,t,seed){const R=rng((seed||5)+99),G=H-3;
 for(let x=-2;x<W;){const w=7+Math.floor(R()*10),h=6+Math.floor(R()*9),pal=['#EBD9BD','#E3C9A6','#D9B59A','#E8E1CF','#C9D3C0','#E6CFC3'];const c=tint(pal[Math.floor(R()*pal.length)],t,.35);
  ctx.fillStyle=css(c);ctx.fillRect(x,G-h,w,h);ctx.fillStyle=css(shade(c,1.08));ctx.fillRect(x,G-h,w,1);ctx.fillStyle=css(shade(c,.72));for(let y=G-h+3;y<G-1;y+=3)for(let xx=x+2;xx<x+w-1;xx+=3)ctx.fillRect(xx,y,1,1);
  if(R()<.5){ctx.fillStyle=css(tint('#30363A',t,.35));ctx.fillRect(x+2,G-h-3,3,3);}
  x+=w;if(R()<.5){const tc=tint(R()<.5?'#4E9A48':'#3E8A40',t,.4);circ(ctx,x+2,G-7,4,css(tc));circ(ctx,x+5,G-9,3,css(shade(tc,1.1)));ctx.fillStyle=css(tint('#6B4A2E',t,.3));ctx.fillRect(x+3,G-4,1,4);x+=6;}}
 ctx.fillStyle=css(tint('#8E8A80',t,.3));ctx.fillRect(0,G,W,3);[.12,.47,.81].forEach(q=>{const x=Math.round(W*q);ctx.fillStyle=css(tint('#E8C53A',t,.3));ctx.fillRect(x,G-6,7,2);ctx.fillStyle=css(tint('#2E7D32',t,.3));ctx.fillRect(x,G-4,8,3);ctx.fillStyle='#2B2F33';ctx.fillRect(x+1,G-1,2,1);ctx.fillRect(x+6,G-1,2,1);ctx.fillRect(x,G-4,1,3);});}
class PxSkyline extends HTMLElement{
 static get observedAttributes(){return['stage'];}
 connectedCallback(){this.style.display='block';const c=this.cv=document.createElement('canvas');c.style.cssText='width:100%;height:100%;display:block;image-rendering:pixelated';(this.shadowRoot||this.attachShadow({mode:'open'})).replaceChildren(c);watch(this);this.ro=new ResizeObserver(()=>this.draw(true));this.ro.observe(this);
  const f=n=>{this.anim(n);this.raf=__raf(f);};this.raf=__raf(f);}
 disconnectedCallback(){this.ro&&this.ro.disconnect();__caf(this.raf);}
 attributeChangedCallback(){if(this.cv)this.draw(true);}
 draw(force){if(!this.cv)return;const px=+(this.getAttribute('px')||3),W=Math.ceil(this.clientWidth/px),H=Math.ceil(this.clientHeight/px);if(!W||!H)return;
  const t=+(this.getAttribute('stage')||0);
  if(force||!this.bg){this.bg=document.createElement('canvas');this.bg.width=W;this.bg.height=H;const b=this.bg.getContext('2d');this.deck=drawSkyline(b,W,H,t,+(this.getAttribute('seed')||5));this.fg=document.createElement('canvas');this.fg.width=W;this.fg.height=H;drawFore(this.fg.getContext('2d'),W,H,t,+(this.getAttribute('seed')||5));this.cv.width=W;this.cv.height=H;this.W=W;this.H=H;this.t=t;}
 }
 anim(now){if(this._vis===false)return;if(!this.bg){this.draw(true);if(!this.bg)return;}if(now-(this.l||0)<66)return;this.l=now;const ctx=this.cv.getContext('2d'),W=this.W,H=this.H;ctx.clearRect(0,0,W,H);ctx.drawImage(this.bg,0,0);
  const x0=RM()?W*.3:((now/1000*14)%(W+80))-60,c=tint('#E9EEF1',this.t,.35),s=tint('#2F7FB8',this.t,.35);for(let k=0;k<3;k++){const x=Math.round(x0+k*17);ctx.fillStyle=css(c);ctx.fillRect(x,this.deck-5,16,5);ctx.fillStyle=css(s);ctx.fillRect(x,this.deck-2,16,1);ctx.fillStyle=css(shade(c,.7));for(let w=x+2;w<x+15;w+=3)ctx.fillRect(w,this.deck-4,2,1);}
  ctx.drawImage(this.fg,0,0);}
}
customElements.define('px-skyline',PxSkyline);

/* ---------- px-scene ---------- */
const S=[
 '.XXXX.','XX..XX','....XX','...XX.','..XX..','..XX..','......','..XX..'];
const RUP=['XXXXXX','...XX.','XXXXXX','...XX.','XXXX..','.XX...','..XX..','...XX.','....XX'];
function sprite(ctx,x,y,rows,col,k){k=k||1;ctx.fillStyle=col;rows.forEach((r,j)=>{for(let i=0;i<r.length;i++)if(r[i]==='X')ctx.fillRect(x+i*k,y+j*k,k,k);});}
function sceneSky(ctx,W,H,t){paintSky(ctx,W,H,t,6);}
function R(ctx,x,y,w,h,c){ctx.fillStyle=typeof c==='string'?c:css(c);ctx.fillRect(Math.round(x),Math.round(y),w,h);}
function puff(ctx,x,y,r,c,a){circ(ctx,x,y,r,css(hx(c),a));}
function truck(ctx,x,y,f,dir){ // sprinkler truck, 26x10
 R(ctx,x,y+1,18,7,'#E8EEF2');R(ctx,x,y+1,18,1,'#FFFFFF');R(ctx,x,y+5,18,1,'#3E7C5A');R(ctx,x+18,y,8,8,'#3E7C5A');R(ctx,x+20,y+1,5,3,'#BFE3F2');R(ctx,x-1,y+8,28,1,'#3A3F43');
 [x+3,x+13,x+21].forEach(w=>{R(ctx,w,y+8,4,3,'#2B2F33');R(ctx,w+1,y+9,2,1,'#8A9096');});
 for(let i=0;i<7;i++){const k=(f*.8+i*1.7)%9;R(ctx,x-2-k,y+6+k*.25+(i%2),1,1,'#6EC3F0');R(ctx,x-1-k*.7,y+9+k*.35,1,1,'#9ED8F5');}}
function person(ctx,x,y,body,vest){R(ctx,x+1,y,3,3,'#C08A60');R(ctx,x+1,y-1,3,1,'#2B2F33');R(ctx,x,y+3,5,6,body);if(vest){R(ctx,x,y+5,5,1,'#E8C53A');}R(ctx,x,y+9,2,4,'#2E3A46');R(ctx,x+3,y+9,2,4,'#2E3A46');}
function fire(ctx,x,y,f){const fl=[3,5,4,6,3];for(let i=0;i<5;i++){const h=fl[(i+f)%5];R(ctx,x+i*2,y-h,2,h,'#F08C35');R(ctx,x+i*2,y-h+2,2,Math.max(1,h-3),'#FFD24A');}}
function smoke(ctx,x,y,f,n,dark,drift){for(let i=0;i<n;i++){const k=((f*.5+i*4)%(n*4))/(n*4);puff(ctx,x+k*drift+Math.sin(i+f*.1)*1.5,y-k*26,2+k*6,dark?'#4A4642':'#8C8780',(1-k)*.75);}}
function building(ctx,x,y,w,h,c,win){R(ctx,x,y,w,h,c);R(ctx,x,y,w,1,css(shade(hx(c),1.08)));for(let yy=y+2;yy<y+h-2;yy+=3)for(let xx=x+2;xx<x+w-2;xx+=3)R(ctx,xx,yy,1,2,win||css(shade(hx(c),.72)));}
const SCENES={
 dust(c,W,H,f,t){sceneSky(c,W,H,t);R(c,0,44,W,12,'#B89668');R(c,0,44,W,1,'#CBAA7E');
  for(let i=0;i<3;i++){R(c,8+i*9,20,2,24,'#9A9A96');}R(c,8,20,20,2,'#B5B2AA');R(c,8,30,20,2,'#B5B2AA');
  const cx=38;for(let y=6;y<44;y++){R(c,cx,y,1,1,'#E2A83C');R(c,cx+2,y,1,1,'#E2A83C');if(y%3===0)R(c,cx+1,y,1,1,'#E2A83C');}R(c,cx-10,6,30,2,'#E2A83C');R(c,cx+14,8,1,10,'#51575C');R(c,cx+13,18,3,2,'#51575C');
  for(let i=0;i<9;i++){const k=((f*.4+i*3)%27)/27;puff(c,18+i*2+k*14,42-k*16,2+k*5,'#C9AE86',(1-k)*.8);}
  truck(c,62+((f*.3)%6),35,f);},
 traffic(c,W,H,f,t){sceneSky(c,W,H,t);building(c,4,14,14,30,'#D9CBB2');building(c,70,18,20,26,'#C9D3DA');R(c,0,42,W,14,'#6D6A66');for(let x=(f%8);x<W;x+=8)R(c,x,48,4,1,'#D9D2B8');
  const bx=26;R(c,bx,30,34,12,'#3F8F5F');R(c,bx,30,34,1,'#5BAA78');R(c,bx+2,32,30,4,'#BFE3F2');for(let w=bx+8;w<bx+32;w+=6)R(c,w,32,1,4,'#3F8F5F');R(c,bx+13,27,7,3,'#E8EEF2');R(c,bx+15,27,3,1,'#2DD4BF');if(f%6<3){R(c,bx+14,25,5,1,'rgba(45,212,191,.5)');}
  [bx+4,bx+26].forEach(w=>{R(c,w,41,5,4,'#2B2F33');R(c,w+2,42,1,1,'#8A9096');});
  for(let i=0;i<6;i++){const k=((f*.6+i*3)%18)/18;puff(c,bx-2-k*16,39-k*8,1+k*4,'#5E5A55',(1-k)*.8);}
  R(c,68,35,14,3,'#E8C53A');R(c,68,38,2,6,'#2B2F33');R(c,80,38,1,6,'#2B2F33');R(c,70,39,9,4,'#BFE3F2');R(c,68,43,15,5,'#2E7D32');R(c,82,41,2,5,'#2E7D32');R(c,69,48,3,2,'#2B2F33');R(c,80,48,3,2,'#2B2F33');},
 burning(c,W,H,f,t){sceneSky(c,W,H,t);R(c,0,44,W,12,'#9C8B6E');R(c,0,44,W,1,'#AF9D7E');
  for(let y=0;y<8;y++){const w=28-y*3;R(c,16+y*1.5,43-y,w,1,y%2?'#6F6558':'#817565');}R(c,20,40,3,2,'#4F6E8C');R(c,32,38,4,2,'#B8B0A0');fire(c,24,38,f);smoke(c,30,32,f,8,true,24);
  person(c,66,30,'#2F4A6A',true);R(c,62,34,4,5,'#F2EFE8');R(c,63,35,2,1,'#8B9AA3');R(c,63,37,2,1,'#8B9AA3');
  R(c,74,34,18,9,'#E8EEF2');R(c,86,32,6,11,'#E8EEF2');R(c,87,34,4,3,'#BFE3F2');R(c,74,38,18,1,'#2F4A6A');R(c,76,42,4,3,'#2B2F33');R(c,86,42,4,3,'#2B2F33');},
 stubble(c,W,H,f,t){sceneSky(c,W,H,t);for(let i=0;i<4;i++)R(c,0,30+i*4,W,4,['#C9B26A','#B7A45C','#A89A56','#9C9454'][i]);
  for(let i=0;i<5;i++){const x=6+i*9;R(c,x,31,2,2,f%4<2?'#F08C35':'#FFD24A');smoke(c,x+1,30,f+i*3,4,false,30);}
  const sx=58;R(c,sx,22,34,24,'#EDE0C8');R(c,sx-2,20,38,3,'#B85A3E');R(c,sx+14,14,6,6,'#EDE0C8');R(c,sx+16,16,2,2,'#8B9AA3');
  for(let i=0;i<4;i++){const open=((f/6|0)%8)<(i+1)*2?0:1;R(c,sx+3+i*8,27,5,6,open?'#2E3A46':'#BFE3F2');if(!open){R(c,sx+5+i*8,27,1,6,'#EDE0C8');}}R(c,sx+14,37,6,9,'#6B4A2E');R(c,0,46,W,10,'#7FA35A');
  c.fillStyle='rgba(168,146,122,.18)';c.fillRect(0,0,W,46);},
 smoggun(c,W,H,f,t){sceneSky(c,W,H,t);R(c,0,44,W,12,'#6D6A66');R(c,20,32,26,10,'#E8EEF2');R(c,46,30,10,12,'#3E7C5A');R(c,48,32,6,4,'#BFE3F2');R(c,22,42,4,3,'#2B2F33');R(c,40,42,4,3,'#2B2F33');R(c,50,42,4,3,'#2B2F33');
  R(c,24,24,10,8,'#8C9296');R(c,26,26,6,4,'#5F666C');for(let i=0;i<14;i++){const k=((f*.5+i*2)%28)/28;puff(c,30-k*26,24-k*14+Math.sin(i)*3,1+k*4,'#DDE8EE',(1-k)*.9);}},
 question(c,W,H,f,t){sceneSky(c,W,H,t);const k=4,bx=W/2-14,by=8+(f%12<6?0:1);R(c,bx-4,by-2,32,38,'#F2EFE8');R(c,bx-4,by-2,32,2,'#FFFFFF');R(c,bx-4,by+34,32,2,'#B8B0A0');sprite(c,bx+2,by+2,S,'#0B1215',k);},
 coin(c,W,H,f,t){sceneSky(c,W,H,t);const cx=W/2,cy=28+(f%10<5?0:-1);circ(c,cx,cy+2,17,'#9A6F12');circ(c,cx,cy,17,'#E5B53C');circ(c,cx,cy,14,'#F2CC5C');sprite(c,cx-9,cy-13,RUP,'#9A6F12',3);},
 grid(c,W,H,f,t){sceneSky(c,W,H,t);R(c,8,6,W-16,H-12,'#F2EFE8');const cols=10,rows=5,cw=(W-20)/cols,ch=(H-18)/rows;for(let i=0;i<cols;i++)for(let j=0;j<rows;j++){const v=((i*7+j*13)%17);const hot=(i===6&&j===2)||(i===3&&j===1)||(i===7&&j===3);R(c,10+i*cw,8+j*ch,cw-1,ch-1,hot?(f%8<4?'#C02A2A':'#7F1D3A'):v>11?'#E5CDB0':'#E8E4DA');}},
 taxi(c,W,H,f,t){sceneSky(c,W,H,t);building(c,4,16,16,28,'#D5DDE2');building(c,72,12,18,32,'#E6D5B8');R(c,0,42,W,14,'#6D6A66');
  for(let i=0;i<12;i++){const x=6+i*4;R(c,x,46,2,1,i%3?'#E5484D':'#F08C35');}
  const tx=50;R(c,tx,34,24,8,'#E8C53A');R(c,tx+4,30,14,4,'#3F8F5F');R(c,tx+6,31,4,2,'#BFE3F2');R(c,tx+12,31,4,2,'#BFE3F2');R(c,tx+8,27,6,3,'#E8EEF2');R(c,tx+10,27,2,1,'#2DD4BF');R(c,tx+2,42,4,3,'#2B2F33');R(c,tx+18,42,4,3,'#2B2F33');},
 alerts(c,W,H,f,t){sceneSky(c,W,H,t);R(c,W/2-1,30,3,26,'#51575C');R(c,W/2-14,6,28,28,'#2B2F33');const cols=['#2F7FB8','#E8C53A','#F08C35','#C02A2A'],on=(f/6|0)%4;cols.forEach((col,i)=>{R(c,W/2-10+(i%2)*11,10+(i>>1)*11,9,9,i===on?col:css(shade(hx(col),.35)));});},
 opendata(c,W,H,f,t){sceneSky(c,W,H,t);R(c,0,46,W,10,'#7FA35A');R(c,20,10,40,26,'#2B2F33');R(c,22,12,36,22,'#F2EFE8');const b=[8,12,6,14,10,16,9];b.forEach((h,i)=>R(c,25+i*4.6,32-h,3,h,i===5?'#2F7FB8':'#8B9AA3'));R(c,38,36,3,10,'#51575C');person(c,66,33,'#B85A3E');person(c,74,33,'#3F8F5F');},
 tower(c,W,H,f,t){sceneSky(c,W,H,t);R(c,0,46,W,10,'#B8B0A0');const x=W/2-10;R(c,x,4,20,42,'#C9CED3');R(c,x-3,40,26,6,'#AEB4B7');for(let j=0;j<5;j++)for(let i=0;i<3;i++){R(c,x+2+i*6,8+j*6,4,4,'#5F666C');}
  c.strokeStyle='#0B1215';c.lineWidth=3;c.beginPath();c.moveTo(x-12,2);c.lineTo(x+32,50);c.moveTo(x+32,2);c.lineTo(x-12,50);c.stroke();},
 podtower(c,W,H,f,t){sceneSky(c,W,H,t);R(c,0,48,W,8,'#B8B0A0');const x=W-34;R(c,x,2,22,46,'#C9CED3');R(c,x-3,42,28,6,'#AEB4B7');for(let j=0;j<6;j++)for(let i=0;i<3;i++)R(c,x+2+i*7,6+j*6,4,4,'#5F666C');
  R(c,10,38,26,9,'#3F8F5F');R(c,12,40,22,3,'#BFE3F2');R(c,19,35,6,3,'#E8EEF2');R(c,21,35,2,1,'#2DD4BF');R(c,13,47,4,2,'#2B2F33');R(c,29,47,4,2,'#2B2F33');if(f%6<3)R(c,20,33,4,1,'rgba(45,212,191,.6)');}
};
class PxScene extends HTMLElement{
 static get observedAttributes(){return['kind','stage'];}
 connectedCallback(){this.style.display='block';const c=this.cv=document.createElement('canvas');c.width=96;c.height=56;c.style.cssText='width:100%;height:100%;display:block;image-rendering:pixelated;object-fit:cover';(this.shadowRoot||this.attachShadow({mode:'open'})).replaceChildren(c);watch(this);this.f=0;
  const loop=n=>{if(this._vis!==false&&n-(this.l||0)>110){this.l=n;this.draw();if(!RM())this.f++;}this.raf=__raf(loop);};this.raf=__raf(loop);}
 disconnectedCallback(){__caf(this.raf);}
 attributeChangedCallback(){this.cv&&this.draw();}
 draw(){const fn=SCENES[this.getAttribute('kind')||'dust'];if(!fn)return;const ctx=this.cv.getContext('2d');fn(ctx,96,56,this.f,+(this.getAttribute('stage')||.6));}
}
customElements.define('px-scene',PxScene);

/* ---------- iso box renderer ---------- */
const C30=Math.cos(Math.PI/6);
function mkProj(W,H,s,th,cx,cy,ox,oy){const co=Math.cos(th),si=Math.sin(th);return{s,co,si,P(x,y,z){const X=x-cx,Y=y-cy,xr=X*co-Y*si,yr=X*si+Y*co;return[ox+(xr-yr)*C30*s,oy+(xr+yr)*.5*s-z*s];},depth(x,y,z){const X=x-cx,Y=y-cy;return(X*co-Y*si)+(X*si+Y*co)+z*.9;}};}
function boxFaces(ctx,pr,b){const{x,y,z,w,d,h}=b,c=b.c,P=pr.P;
 const n=[[1,0,[[x+w,y,z],[x+w,y+d,z],[x+w,y+d,z+h],[x+w,y,z+h]],'px'],[-1,0,[[x,y,z],[x,y+d,z],[x,y+d,z+h],[x,y,z+h]],'nx'],[0,1,[[x,y+d,z],[x+w,y+d,z],[x+w,y+d,z+h],[x,y+d,z+h]],'py'],[0,-1,[[x,y,z],[x+w,y,z],[x+w,y,z+h],[x,y,z+h]],'ny']];
 n.forEach(([nx,ny,pts,key])=>{if(b.hide&&b.hide[key])return;const rx=nx*pr.co-ny*pr.si,ry=nx*pr.si+ny*pr.co;if(rx+ry<=0.001)return;const k=0.66+0.2*(rx-ry+1.4)/2.8;poly(ctx,pts.map(p=>P(...p)),css(shade(c,k)),b.line);});
 if(!(b.hide&&b.hide.top))poly(ctx,[[x,y,z+h],[x+w,y,z+h],[x+w,y+d,z+h],[x,y+d,z+h]].map(p=>P(...p)),css(b.top||shade(c,1.06)),b.line);}
function poly(ctx,pts,fill,line){ctx.beginPath();pts.forEach((p,i)=>i?ctx.lineTo(p[0],p[1]):ctx.moveTo(p[0],p[1]));ctx.closePath();ctx.fillStyle=fill;ctx.fill();if(line){ctx.strokeStyle=line;ctx.lineWidth=1;ctx.stroke();}else{ctx.strokeStyle=fill;ctx.lineWidth=.6;ctx.stroke();}}
function label(ctx,x,y,text,opt){opt=opt||{};ctx.font=`500 ${opt.size||12}px Geist, system-ui, sans-serif`;const w=ctx.measureText(text).width+16,h=(opt.size||12)+10;const bx=Math.round(x+(opt.dx||10)),by=Math.round(y-h/2);
 ctx.fillStyle=opt.bg||'#FAF9F6';ctx.strokeStyle=opt.border||'#0B1215';ctx.lineWidth=1;ctx.beginPath();ctx.roundRect?ctx.roundRect(bx+.5,by+.5,w,h,4):ctx.rect(bx+.5,by+.5,w,h);ctx.fill();ctx.stroke();
 if(opt.dot){ctx.fillStyle=opt.dot;ctx.fillRect(bx+8,by+h/2-3,6,6);}
 ctx.fillStyle=opt.color||'#0B1215';ctx.textBaseline='middle';ctx.fillText(text,bx+8+(opt.dot?10:0),by+h/2+.5);return w;}
function vox(){const m=new Map();const api={m,add(x,y,z,c){m.set(x+','+y+','+z,{x,y,z,w:1,d:1,h:1,c:typeof c==='string'?hx(c):c});},box(x0,y0,z0,w,d,h,c){for(let x=x0;x<x0+w;x++)for(let y=y0;y<y0+d;y++)for(let z=z0;z<z0+h;z++)api.add(x,y,z,typeof c==='function'?c(x,y,z):c);},
 finalize(){const has=(x,y,z)=>m.has(x+','+y+','+z);const out=[];m.forEach(v=>{v.hide={top:has(v.x,v.y,v.z+1),px:has(v.x+1,v.y,v.z),nx:has(v.x-1,v.y,v.z),py:has(v.x,v.y+1,v.z),ny:has(v.x,v.y-1,v.z)};if(!(v.hide.top&&v.hide.px&&v.hide.nx&&v.hide.py&&v.hide.ny))out.push(v);});return out;}};return api;}

/* ---------- vx-city ---------- */
function buildCity(){const V=vox(),N=28;
 for(let x=0;x<N;x++)for(let y=0;y<N;y++){let c='#8FB06E';const road=(y>=12&&y<=15)||(x>=12&&x<=15),walk=(y===11||y===16||x===11||x===16);
  if(road)c=((y===13||y===14)&&x%4===0&&!(x>=12&&x<=15))||((x===13||x===14)&&y%4===0&&!(y>=12&&y<=15))?'#D9D2B8':'#6B6F72';else if(walk)c='#C9C2B2';else if(x<11&&y<11)c=(x>1&&x<10&&y>7)?'#D7B98A':'#8FB06E';else if(x>16&&y>16)c='#B8966A';else if(x<11&&y>16)c='#CFC6B4';
  V.add(x,y,0,c);}
 V.box(2,1,1,8,6,3,(x,y,z)=>(z===2&&((x+y)%2===0)&&(y===1||x===9||x===2||y===6))?'#6E94A8':'#EDE2CB');V.box(2,1,4,8,6,1,'#B85A3E');V.box(5,3,5,2,2,1,'#B85A3E');V.add(9,6,5,'#2DD4BF');
 for(let z=1;z<8;z++)V.add(1,9,z,'#8A8A8A');V.add(2,9,7,'#F2EFE8');V.add(3,9,7,'#F2EFE8');
 V.box(18,1,1,5,5,9,(x,y,z)=>(z%2===0&&(x===22||y===5))?'#7FA3BA':'#D5DDE2');V.box(23,4,1,4,5,6,(x,y,z)=>(z%2===1&&(x===26||y===8))?'#9C7F5E':'#E6D5B8');
 [[18,18],[24,18],[18,24],[24,24]].forEach(([x,y])=>V.box(x,y,1,1,1,5,'#9A9A96'));V.box(18,18,3,7,4,1,'#B5B2AA');V.box(18,18,6,7,7,1,(x,y)=>(x+y)%3?'#B5B2AA':'#9A9A96');
 V.box(20,25,1,3,2,1,'#D4B483');V.add(21,25,2,'#D4B483');
 for(let z=1;z<14;z++)V.add(26,26,z,'#E2A83C');for(let x=18;x<28;x++)V.add(x,26,14,'#E2A83C');V.add(27,26,13,'#51575C');for(let z=9;z<14;z++)V.add(20,26,z,'#51575C');
 V.box(1,18,1,4,4,3,'#E8C9A0');V.add(2,19,4,'#2B2F33');V.box(6,18,1,4,5,4,'#D9A98C');V.add(8,20,5,'#2B2F33');V.box(2,23,1,5,4,2,'#CBD6C4');V.add(3,24,3,'#2B2F33');
 [[10,9],[1,11],[17,11],[10,17],[27,11]].forEach(([x,y],i)=>{if(x===1&&y===11)return;V.add(x,y,1,'#6B4A2E');V.add(x,y,2,'#4E9A48');V.add(x,y,3,'#3E8A40');});
 [[9,26],[26,9]].forEach(([x,y])=>{V.add(x,y,1,'#6B4A2E');V.box(x,y,2,1,1,2,'#4E9A48');});
 return V;}
const CITY_HEAT=(x,y)=>150+230*Math.exp(-((x-22)**2+(y-22)**2)/30)+120*Math.exp(-((y-13.5)**2)/5)+40*Math.exp(-((x-5)**2+(y-4)**2)/40);
class VxCity extends HTMLElement{
 static get observedAttributes(){return['step','haze'];}
 connectedCallback(){this.style.display='block';this.style.position='relative';const c=this.cv=document.createElement('canvas');c.style.cssText='width:100%;height:100%;display:block';(this.shadowRoot||this.attachShadow({mode:'open'})).replaceChildren(c);watch(this);
  this.base=buildCity().finalize();const R=rng(3);this.sm=[];for(let i=0;i<110;i++)this.sm.push([R()*30-1,R()*30-1,3+R()*12,R()*6]);this.dust=[];for(let i=0;i<26;i++)this.dust.push([18+R()*8,18+R()*8,R()]);
  this.t0=performance.now();const f=n=>{if(this._vis!==false&&n-(this.l||0)>33){this.l=n;this.draw(n);}this.raf=__raf(f);};this.raf=__raf(f);}
 disconnectedCallback(){__caf(this.raf);}
 draw(now){const W=this.clientWidth,H=this.clientHeight;if(!W||!H)return;const dpr=Math.min(2,devicePixelRatio||1);if(this.cv.width!==Math.round(W*dpr)||this.cv.height!==Math.round(H*dpr)){this.cv.width=Math.round(W*dpr);this.cv.height=Math.round(H*dpr);}
  const ctx=this.cv.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,W,H);
  const t=RM()?0:(now-this.t0)/1000,step=this.hasAttribute('step')?+this.getAttribute('step'):-1,haze=+(this.getAttribute('haze')??1);
  const th=-0.18+Math.sin(t*0.12)*0.3,s=Math.min(W/52,H/40),pr=mkProj(W,H,s,th,14,14,W/2,H*.62);
  const heatOn=step>=1,verified=step>=6;
  const items=this.base.map(v=>{let b=v;if(heatOn&&v.z===0){const val=CITY_HEAT(v.x,v.y)*(verified&&v.x>15&&v.y>15?0.62:1);b=Object.assign({},v,{top:mix(shade(v.c,1.06),AQI_L[band(val)],.62)});}return{b,k:pr.depth(v.x+.5,v.y+.5,v.z)};});
  const busX=((t*2.2)%36)-6,moveTruck=step<0||step>=5,trY=moveTruck?(((t*1.6)%34)-4):4;
  const dyn=[];const bus=hx('#3F8F5F');for(let i=0;i<6;i++){dyn.push({x:busX+i,y:12,z:1,w:1,d:2,h:2,c:i===0||i===5?bus:[63,143,95],top:shade(bus,1.15)});}
  dyn.push({x:busX+2,y:12.5,z:3,w:2,d:1,h:.5,c:hx('#E8EEF2'),top:hx('#2DD4BF')});
  dyn.push({x:14,y:trY,z:1,w:2,d:1.4,h:1.6,c:hx('#3E7C5A')},{x:14,y:trY+1.4,z:1,w:2,d:3,h:1.6,c:hx('#E8EEF2')});
  dyn.forEach(b=>items.push({b,k:pr.depth(b.x+b.w/2,b.y+b.d/2,b.z)}));
  items.sort((a,b)=>a.k-b.k);items.forEach(i=>boxFaces(ctx,pr,i.b));
  if(moveTruck)for(let i=0;i<14;i++){const k=((t*3+i*.7)%3)/3,p=pr.P(15+Math.sin(i*2.1)*1.4*k,trY+4.6+k*2,1.2-k*.6);ctx.fillStyle=`rgba(110,195,240,${(1-k)*.85})`;ctx.fillRect(p[0]-1.5,p[1]-1.5,3,3);}
  this.dust.forEach((d,i)=>{const k=((t*.25+d[2])%1),p=pr.P(d[0]+k*2,d[1]-k,1+k*6);ctx.fillStyle=`rgba(201,174,134,${(1-k)*.8*(verified?.4:1)})`;const sz=2+k*5;ctx.fillRect(p[0]-sz/2,p[1]-sz/2,sz,sz);});
  const glow=(x,y,z,ph)=>{const p=pr.P(x,y,z),k=(t*.8+ph)%1;ctx.strokeStyle=`rgba(15,118,110,${1-k})`;ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(p[0],p[1],4+k*16,0,7);ctx.stroke();ctx.fillStyle='#2DD4BF';ctx.fillRect(p[0]-2,p[1]-2,4,4);};
  if(step<0||step===0){glow(busX+3,13,3.5,0);glow(9.5,6.5,6,.3);glow(15,trY+2,2.8,.6);}
  if(step>=4){ctx.setLineDash([5,4]);ctx.strokeStyle='#0F766E';ctx.lineWidth=2;ctx.beginPath();[[15,0],[15,17],[21,17],[21,21]].forEach((q,i)=>{const p=pr.P(q[0],q[1],1.05);i?ctx.lineTo(p[0],p[1]):ctx.moveTo(p[0],p[1]);});ctx.stroke();ctx.setLineDash([]);}
  if(haze>0&&!RM())this.sm.forEach((m,i)=>{const p=pr.P(m[0]+Math.sin(t*.3+m[3])*1.2,m[1],m[2]+Math.sin(t*.5+i)*.4);ctx.fillStyle=`rgba(96,78,58,${.34*haze*(verified?.35:1)})`;const sz=i%4?2:3;ctx.fillRect(p[0],p[1],sz,sz);});
  const P=pr.P;
  if(step===2){const a=P(22,22,7.5);label(ctx,a[0],a[1],'Dust · 0.82',{dot:'#8B9AA3'});const b=P(busX+3,13,3.5);label(ctx,b[0],b[1]-18,'Traffic · 0.69',{dot:'#8B9AA3'});}
  if(step===3){const a=P(6,4,6.5);label(ctx,a[0],a[1]-14,'Thu 08:00 · PM2.5 ~420 forecast');}
  if(step===4){const a=P(15,4,3);label(ctx,a[0],a[1],'Plan #214 · T-12 → site, 06:10');}
  if(step===5){const a=P(15,trY+2,3);label(ctx,a[0],a[1],'T-12 · spraying · 1,850 L');}
  if(step===6){const a=P(22,22,7.5);label(ctx,a[0],a[1],'PM10 −18% · 90 min · verified',{color:'#0F766E',border:'#0F766E'});}
 }
}
customElements.define('vx-city',VxCity);

/* ---------- vx-hexmap ---------- */
class VxHexmap extends HTMLElement{
 static get observedAttributes(){return['mix'];}
 connectedCallback(){this.style.display='block';const c=this.cv=document.createElement('canvas');c.style.cssText='width:100%;height:100%;display:block';(this.shadowRoot||this.attachShadow({mode:'open'})).replaceChildren(c);watch(this);
  const Rr=rng(9),hexes=[],Rad=6;for(let q=-Rad;q<=Rad;q++)for(let r=Math.max(-Rad,-q-Rad);r<=Math.min(Rad,-q+Rad);r++){const x=1.5*q,y=Math.sqrt(3)*(r+q/2);const peaks=[[4,-3,340],[-3,-4,280],[1,4,300],[-5,3,190]];let v=70+Rr()*45;peaks.forEach(([px,py,a])=>{v+=a*Math.exp(-((x-px)**2+(y-py)**2)/5);});hexes.push({x,y,v});}
  this.hexes=hexes;const near=(px,py)=>hexes.reduce((a,h)=>Math.hypot(h.x-px,h.y-py)<Math.hypot(a.x-px,a.y-py)?h:a);
  this.plan=[[-9,0],[-3,-4],[4,-3],[1,4]].map(p=>({x:p[0],y:p[1]}));this.planHex=[near(-3,-4),near(4,-3),near(1,4)];
  this.usual=[[-9,-8],[-3,-8],[3,-8],[9,-8]].map(p=>({x:p[0],y:p[1]+4}));
  this.t0=performance.now();const f=n=>{if(this._vis!==false&&n-(this.l||0)>33){this.l=n;this.draw(n);}this.raf=__raf(f);};this.raf=__raf(f);}
 disconnectedCallback(){__caf(this.raf);}
 draw(now){const W=this.clientWidth,H=this.clientHeight;if(!W||!H)return;const dpr=Math.min(2,devicePixelRatio||1);if(this.cv.width!==Math.round(W*dpr)||this.cv.height!==Math.round(H*dpr)){this.cv.width=Math.round(W*dpr);this.cv.height=Math.round(H*dpr);}
  const ctx=this.cv.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,W,H);
  const t=RM()?0.6:((now-this.t0)/1000/9)%1,m=clamp(+(this.getAttribute('mix')||0),0,1),s=Math.min(W/30,H/21),th=0.35+Math.sin((now-this.t0)/1000*.1)*.08,pr=mkProj(W,H,s,th,0,0,W/2,H*.64),P=pr.P;
  const base=[];for(let i=0;i<7;i++){const a=Math.PI/3*i;base.push([Math.cos(a)*10.8,Math.sin(a)*10.8]);}
  poly(ctx,base.slice(0,6).map(p=>P(p[0],p[1],-.6)),'#0E1417');
  const bt=base.slice(0,6).map(p=>P(p[0],p[1],0));poly(ctx,bt,'#151D21','#24303A');
  const pathLen=pts=>{let L=[0];for(let i=1;i<pts.length;i++)L.push(L[i-1]+Math.hypot(pts[i].x-pts[i-1].x,pts[i].y-pts[i-1].y));return L;};
  const along=(pts,u)=>{const L=pathLen(pts),d=u*L[L.length-1];for(let i=1;i<pts.length;i++)if(d<=L[i]){const k=(d-L[i-1])/(L[i]-L[i-1]);return{x:lerp(pts[i-1].x,pts[i].x,k),y:lerp(pts[i-1].y,pts[i].y,k),f:d/L[L.length-1]};}return pts[pts.length-1];};
  const pL=pathLen(this.plan),pTot=pL[pL.length-1];const hexF=h=>{let best=1e9,fi=0;for(let u=0;u<=1;u+=.01){const p=along(this.plan,u);const d=Math.hypot(p.x-h.x,p.y-h.y);if(d<best){best=d;fi=u;}}return fi;};
  if(!this._hf)this._hf=this.planHex.map(hexF);
  const items=[];const r=0.86;
  this.hexes.forEach(h=>{let v=h.v;const pi=this.planHex.indexOf(h);if(pi>=0){const f0=this._hf[pi],k=t>f0?clamp((t-f0)*6,0,1)*(t>.92?clamp((1-t)*12,0,1):1):0;v*=1-0.42*m*k-0.12*m;}
   if(Math.abs(h.y-(-4))<1.2)v*=1-0.06*(1-m);
   const hh=Math.max(.3,(v-100)/32),col=AQI_D[band(v)];items.push({k:pr.depth(h.x,h.y,0),draw(){const top=[],bot=[];for(let i=0;i<6;i++){const a=Math.PI/3*i+Math.PI/6;top.push([h.x+Math.cos(a)*r,h.y+Math.sin(a)*r]);}
    for(let i=0;i<6;i++){const a0=top[i],a1=top[(i+1)%6],nx=(a0[0]+a1[0])/2-h.x,ny=(a0[1]+a1[1])/2-h.y,rx=nx*pr.co-ny*pr.si,ry=nx*pr.si+ny*pr.co;if(rx+ry<=0)continue;poly(ctx,[P(a0[0],a0[1],0),P(a1[0],a1[1],0),P(a1[0],a1[1],hh),P(a0[0],a0[1],hh)],css(shade(hx('#000000').map((_,j)=>col[j]),0.55+0.25*(rx-ry+1)/2)));}
    poly(ctx,top.map(p=>P(p[0],p[1],hh)),css(col));}});});
  const truckAt=(pts,u,colr)=>{const p=along(pts,u);items.push({k:pr.depth(p.x,p.y,0)+.01,draw(){boxFaces(ctx,pr,{x:p.x-.45,y:p.y-.3,z:0,w:.9,d:.6,h:.55,c:colr,top:shade(colr,1.2),line:'#0E1417'});}});};
  if(m>0.02)truckAt(this.plan,t,hx('#2DD4BF'));if(m<0.98)truckAt(this.usual,(t*1.1)%1,hx('#8B9AA3'));
  items.sort((a,b)=>a.k-b.k);items.forEach(i=>i.draw());
  const dash=(pts,colr,a)=>{ctx.globalAlpha=a;ctx.setLineDash([4,4]);ctx.strokeStyle=colr;ctx.lineWidth=1.5;ctx.beginPath();pts.forEach((p,i)=>{const q=P(p.x,p.y,0.02);i?ctx.lineTo(q[0],q[1]):ctx.moveTo(q[0],q[1]);});ctx.stroke();ctx.setLineDash([]);ctx.globalAlpha=1;};
  dash(this.usual,'#8B9AA3',1-m*.8);dash(this.plan,'#2DD4BF',.2+m*.8);
 }
}
customElements.define('vx-hexmap',VxHexmap);

/* ---------- vx-pod (exploded HawaPod-M) + small models ---------- */
const POD=[
 {n:'IP54 enclosure',sub:'heated inlet, 5 V fan',x:0,y:0,w:12,d:8,h:2.4,c:'#D9DCDD'},
 {n:'Power stage',sub:'12 V → 5 V · 18650 backup',x:1,y:1,w:4,d:3,h:1.2,c:'#51575C'},
 {n:'ESP32-S3 board',sub:'TinyML spike model',x:1,y:1,w:10,d:6,h:.5,c:'#2F6B4A'},
 {n:'PMS5003',sub:'PM1 · PM2.5 · PM10',x:6,y:1.5,w:4.5,d:4,h:2,c:'#8C9296'},
 {n:'MiCS-6814 + ADS1115',sub:'NO₂ · CO · NH₃',x:1.5,y:1.5,w:3,d:3,h:1,c:'#3B4A55'},
 {n:'A7670C 4G LTE',sub:'MQTT/TLS → AWS IoT Core',x:2,y:4.5,w:4,d:2.5,h:.6,c:'#2F5D7C'},
 {n:'NEO-M8N GPS',sub:'position + speed',x:7,y:5,w:3,d:2.5,h:.8,c:'#C8A45A'},
 {n:'Lid + inlet tube',sub:'forward-facing, roof height',x:0,y:0,w:12,d:8,h:.8,c:'#E8EAEB'}
];
class VxPod extends HTMLElement{
 static get observedAttributes(){return['explode'];}
 connectedCallback(){this.style.display='block';const c=this.cv=document.createElement('canvas');c.style.cssText='width:100%;height:100%;display:block';(this.shadowRoot||this.attachShadow({mode:'open'})).replaceChildren(c);watch(this);this.e=0;this.t0=performance.now();
  const f=n=>{if(this._vis!==false&&n-(this.l||0)>33){this.l=n;this.draw(n);}this.raf=__raf(f);};this.raf=__raf(f);}
 disconnectedCallback(){__caf(this.raf);}
 target(){if(this.hasAttribute('scrub')){const r=this.getBoundingClientRect(),vh=innerHeight;return clamp((vh*.85-r.top)/(vh*.6),0,1);}return clamp(+(this.getAttribute('explode')||0),0,1);}
 draw(now){const W=this.clientWidth,H=this.clientHeight;if(!W||!H)return;const dpr=Math.min(2,devicePixelRatio||1);if(this.cv.width!==Math.round(W*dpr)||this.cv.height!==Math.round(H*dpr)){this.cv.width=Math.round(W*dpr);this.cv.height=Math.round(H*dpr);}
  const ctx=this.cv.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,W,H);
  this.e+=(this.target()-this.e)*(RM()?1:.12);const e=this.e,t=RM()?0:(now-this.t0)/1000,s=Math.min(W/(W<520?52:38),H/46),pr=mkProj(W,H,s,-0.35+Math.sin(t*.2)*.06,6,4,W*(W<520?.24:.34),H*.86);
  const Z0=[0,.4,1.6,2.1,2.1,2.1,2.1,2.4],ZX=[0,1.7,3.4,5.3,7.1,8.9,10.7,13];const placed=POD.map((p,i)=>Object.assign({},p,{z:Z0[i]+e*ZX[i]}));
  const order=placed.map((p,i)=>({p,i,k:p.z*10+pr.depth(p.x+p.w/2,p.y+p.d/2,0)*.01})).sort((a,b)=>a.k-b.k);
  order.forEach(({p,i})=>{boxFaces(ctx,pr,{x:p.x,y:p.y,z:p.z,w:p.w,d:p.d,h:p.h,c:hx(p.c),line:'rgba(11,18,21,.55)'});
   if(i===2){boxFaces(ctx,pr,{x:4.4,y:3,z:p.z+p.h,w:2,d:2,h:.3,c:hx('#2B2F33'),line:'rgba(11,18,21,.5)'});}
   if(i===7){boxFaces(ctx,pr,{x:8.5,y:1,z:p.z+p.h,w:1.6,d:1.6,h:2.6,c:hx('#E8EAEB'),line:'rgba(11,18,21,.55)'});boxFaces(ctx,pr,{x:8.5,y:-2.2,z:p.z+p.h+2.6,w:1.6,d:4.8,h:1.2,c:hx('#E8EAEB'),line:'rgba(11,18,21,.55)'});const a=pr.P(1.5,7,p.z+p.h);ctx.strokeStyle='#0B1215';ctx.beginPath();ctx.moveTo(a[0],a[1]);ctx.lineTo(a[0],a[1]-22);ctx.stroke();ctx.fillStyle='#0F766E';ctx.fillRect(a[0]-2,a[1]-25,5,5);}});
  if(e>.35){ctx.globalAlpha=clamp((e-.35)*2.5,0,1);const small=W<520,tf=small?'500 11px Geist, sans-serif':'500 12.5px Geist, sans-serif',sf=small?'10px "Geist Mono", monospace':'11px "Geist Mono", monospace';let mw=0;placed.forEach(q=>{ctx.font=tf;mw=Math.max(mw,ctx.measureText(q.n).width);ctx.font=sf;mw=Math.max(mw,ctx.measureText(q.sub).width);});const lx=Math.max(W*.42,Math.min(W*.64,W-mw-12));const L=placed.map(p=>{const a=pr.P(p.x+p.w,p.y+p.d/2,p.z+p.h/2);return{p,a,y:a[1]};}).sort((u,v)=>u.y-v.y);for(let i=1;i<L.length;i++)L[i].y=Math.max(L[i].y,L[i-1].y+34);const over=L[L.length-1].y-(H-20);if(over>0)L.forEach(l=>l.y-=over);for(let i=L.length-2;i>=0;i--)L[i].y=Math.min(L[i].y,L[i+1].y-34);
   L.forEach(l=>{const a=l.a;ctx.strokeStyle='rgba(11,18,21,.35)';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(a[0]+2,a[1]);ctx.lineTo(lx-30,a[1]);ctx.lineTo(lx-8,l.y);ctx.stroke();ctx.fillStyle='#0B1215';ctx.fillRect(a[0],a[1]-1.5,3,3);ctx.font=tf;ctx.textBaseline='middle';ctx.fillText(l.p.n,lx,l.y-7);ctx.font=sf;ctx.fillStyle='#5F6B70';ctx.fillText(l.p.sub,lx,l.y+8);});ctx.globalAlpha=1;}
 }
}
customElements.define('vx-pod',VxPod);
class VxModel extends HTMLElement{
 connectedCallback(){this.style.display='block';const c=this.cv=document.createElement('canvas');c.style.cssText='width:100%;height:100%;display:block';(this.shadowRoot||this.attachShadow({mode:'open'})).replaceChildren(c);watch(this);this.t0=performance.now();
  const f=n=>{if(this._vis!==false&&n-(this.l||0)>40){this.l=n;this.draw(n);}this.raf=__raf(f);};this.raf=__raf(f);}
 disconnectedCallback(){__caf(this.raf);}
 draw(now){const W=this.clientWidth,H=this.clientHeight;if(!W||!H)return;const dpr=Math.min(2,devicePixelRatio||1);if(this.cv.width!==Math.round(W*dpr)||this.cv.height!==Math.round(H*dpr)){this.cv.width=Math.round(W*dpr);this.cv.height=Math.round(H*dpr);}
  const ctx=this.cv.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,W,H);const t=RM()?0:(now-this.t0)/1000,kind=this.getAttribute('kind')||'pod-s',L='rgba(11,18,21,.5)';
  let B=[];if(kind==='pod-s'){B=[{x:0,y:0,z:0,w:12,d:8,h:.6,c:'#CFC6B4'},{x:1,y:1,z:.6,w:4,d:4,h:5,c:'#EDE2CB'},{x:1,y:1,z:5.6,w:4,d:4,h:.5,c:'#B85A3E'},{x:1.8,y:5,z:1.6,w:2.4,d:.2,h:2,c:'#D9DCDD'},{x:1.6,y:5,z:4.2,w:.8,d:.3,h:.8,c:'#2DD4BF'},{x:7,y:2,z:.6,w:4,d:4,h:3.5,c:'#D9DCDD'},{x:7.4,y:6,z:1.2,w:3.2,d:.1,h:2,c:'#2B2F33'},{x:7.6,y:6.1,z:2,w:1.2,d:.1,h:.6,c:'#2DD4BF'}];}
  else{B=[{x:0,y:0,z:0,w:14,d:6,h:.4,c:'#6B6F72'},{x:1,y:1,z:.4,w:8,d:4,h:3,c:'#E8EEF2'},{x:9,y:1,z:.4,w:4,d:4,h:3.6,c:'#3E7C5A'},{x:9.6,y:5,z:2.2,w:2.8,d:.1,h:1.2,c:'#BFE3F2'},{x:1,y:1,z:2,w:8,d:.1,h:.5,c:'#3E7C5A'},{x:4,y:2,z:3.4,w:2,d:2,h:.9,c:'#2B2F33'},{x:4.5,y:2.5,z:4.3,w:1,d:1,h:.25,c:'#2DD4BF'},{x:-1.4,y:2.4,z:1,w:2.4,d:1.2,h:1.2,c:'#8C9296'}];}
  const s=Math.min(W/22,H/16),pr=mkProj(W,H,s,-0.4+Math.sin(t*.3)*.2,kind==='pod-s'?6:7,kind==='pod-s'?4:3,W/2,H*.66);
  B.map(b=>Object.assign({},b,{c:hx(b.c),line:L,k:pr.depth(b.x+b.w/2,b.y+b.d/2,b.z)})).sort((a,b)=>a.k-b.k).forEach(b=>boxFaces(ctx,pr,b));
  const g=kind==='pod-s'?pr.P(2,5.3,4.6):pr.P(5,3,4.7),k=(t*.8)%1;ctx.strokeStyle=`rgba(15,118,110,${1-k})`;ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(g[0],g[1],3+k*12,0,7);ctx.stroke();
  if(kind!=='pod-s'&&!RM())for(let i=0;i<10;i++){const q=((t*1.5+i*.37)%1),p=pr.P(-1.4-q*3,3+Math.sin(i)*q*2,1.6-q*.8);ctx.fillStyle=`rgba(110,195,240,${1-q})`;ctx.fillRect(p[0]-1.5,p[1]-1.5,3,3);}
 }
}
customElements.define('vx-model',VxModel);
window.HawaPixel={SCENES:Object.keys(SCENES)};
})();
