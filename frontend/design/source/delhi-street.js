(function(){
if(customElements.get('delhi-street'))return;
const WW=2400,WH=520,GY=440;
const hx=h=>{const n=parseInt(h.slice(1),16);return[n>>16&255,n>>8&255,n&255];};
const mix=(a,b,t)=>[0,1,2].map(i=>a[i]+(b[i]-a[i])*t);
const css=(c,a)=>`rgba(${c[0]|0},${c[1]|0},${c[2]|0},${a===undefined?1:a})`;
const RM=()=>window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches;
const HAZE=hx('#8A6A45');
const tint=(c,t,k)=>css(mix(hx(c),HAZE,(1-t)*k));
function rr(ctx,x,y,w,h,r){ctx.beginPath();ctx.moveTo(x+r,y);ctx.arcTo(x+w,y,x+w,y+h,r);ctx.arcTo(x+w,y+h,x,y+h,r);ctx.arcTo(x,y+h,x,y,r);ctx.arcTo(x,y,x+w,y,r);ctx.closePath();}
function R(ctx,x,y,w,h,c){ctx.fillStyle=c;ctx.fillRect(x,y,w,h);}
function wheel(ctx,x,y,r){ctx.fillStyle='#1E2226';ctx.beginPath();ctx.arc(x,y,r,0,7);ctx.fill();ctx.fillStyle='#8A9096';ctx.beginPath();ctx.arc(x,y,r*.4,0,7);ctx.fill();}
let GRAIN=null;function grain(){if(GRAIN)return GRAIN;const c=document.createElement('canvas');c.width=c.height=160;const g=c.getContext('2d'),d=g.createImageData(160,160);for(let i=0;i<d.data.length;i+=4){const v=Math.random()*255;d.data[i]=d.data[i+1]=d.data[i+2]=v;d.data[i+3]=26;}g.putImageData(d,0,0);return GRAIN=c;}
const V={
 bus(ctx,x,y,t){rr(ctx,x,y-52,170,46,8);ctx.fillStyle=tint('#2E8B57',t,.25);ctx.fill();R(ctx,x+6,y-44,158,16,tint('#EEF2EE',t,.2));for(let i=0;i<7;i++)R(ctx,x+12+i*22,y-42,16,12,'#2A3A40');R(ctx,x,y-20,170,4,tint('#F2C230',t,.2));ctx.fillStyle='#fff';ctx.font='600 10px Geist,sans-serif';ctx.fillText('DTC · CNG',x+10,y-10);
  R(ctx,x+72,y-62,26,10,'#0F766E');R(ctx,x+84,y-70,2,8,'#0F766E');wheel(ctx,x+30,y-4,9);wheel(ctx,x+138,y-4,9);},
 auto(ctx,x,y,t){ctx.fillStyle=tint('#F2C230',t,.25);rr(ctx,x+4,y-48,48,14,6);ctx.fill();R(ctx,x+6,y-34,4,20,'#1E2226');R(ctx,x+46,y-34,3,20,'#1E2226');ctx.fillStyle=tint('#2E7D32',t,.25);rr(ctx,x,y-20,58,14,4);ctx.fill();R(ctx,x+52,y-30,8,18,tint('#2E7D32',t,.25));wheel(ctx,x+10,y-4,6);wheel(ctx,x+48,y-4,6);},
 erick(ctx,x,y,t){ctx.fillStyle=tint('#3C7FB8',t,.25);rr(ctx,x,y-50,56,8,3);ctx.fill();R(ctx,x+3,y-42,2,26,'#5F666C');R(ctx,x+51,y-42,2,26,'#5F666C');R(ctx,x+6,y-22,44,10,tint('#D9DCDD',t,.25));R(ctx,x+10,y-30,14,8,tint('#B85A3E',t,.25));wheel(ctx,x+10,y-4,6);wheel(ctx,x+46,y-4,6);},
 sprinkler(ctx,x,y,t,f){ctx.fillStyle=tint('#3C7FB8',t,.2);rr(ctx,x,y-44,100,32,14);ctx.fill();R(ctx,x+100,y-48,34,36,tint('#F4F4F2',t,.2));R(ctx,x+108,y-44,20,12,'#2A3A40');ctx.fillStyle='#fff';ctx.font='600 10px Geist,sans-serif';ctx.fillText('MCD',x+10,y-24);R(ctx,x-2,y-12,138,4,'#3A3F43');wheel(ctx,x+22,y-4,8);wheel(ctx,x+112,y-4,8);
  for(let i=0;i<22;i++){const k=((f*.05+i*.37)%1);ctx.fillStyle=`rgba(150,205,240,${(1-k)*.8})`;ctx.fillRect(x-4-k*50,y-14+k*14+Math.sin(i)*3,2,2);}},
 gun(ctx,x,y,t,f){R(ctx,x,y-22,110,10,tint('#51575C',t,.2));R(ctx,x+110,y-40,30,28,tint('#F4F4F2',t,.2));R(ctx,x+116,y-36,18,10,'#2A3A40');ctx.save();ctx.translate(x+44,y-30);ctx.rotate(-.5);ctx.fillStyle=tint('#8C9296',t,.2);rr(ctx,-18,-14,44,28,8);ctx.fill();ctx.restore();R(ctx,x+36,y-30,16,10,'#5F666C');wheel(ctx,x+20,y-4,8);wheel(ctx,x+124,y-4,8);
  for(let i=0;i<40;i++){const k=((f*.04+i*.21)%1),a=-.5-Math.sin(i)*.25;ctx.fillStyle=`rgba(230,238,242,${(1-k)*.7})`;const d=10+k*120;ctx.beginPath();ctx.arc(x+60+Math.cos(a)*d,y-44+Math.sin(a)*d,1+k*4,0,7);ctx.fill();}}
};
class DelhiStreet extends HTMLElement{
 static get observedAttributes(){return['stage','focus'];}
 connectedCallback(){this.style.display='block';const r=this.shadowRoot||this.attachShadow({mode:'open'});this.cv=document.createElement('canvas');this.cv.style.cssText='width:100%;height:100%;display:block';r.replaceChildren(this.cv);
  this.vis=true;this.io=new IntersectionObserver(e=>{this.vis=e[e.length-1].isIntersecting;},{rootMargin:'100px'});this.io.observe(this);this.t0=performance.now();
  const loop=n=>{if(this.vis&&n-(this.l||0)>40){this.l=n;this.draw(n);}this.raf=requestAnimationFrame(loop);};this.raf=requestAnimationFrame(loop);}
 disconnectedCallback(){cancelAnimationFrame(this.raf);this.io&&this.io.disconnect();}
 attributeChangedCallback(){this.cv&&this.draw(performance.now());}
 draw(now){const Wp=this.clientWidth,Hp=this.clientHeight;if(!Wp||!Hp)return;const dpr=Math.min(2,devicePixelRatio||1);if(this.cv.width!==Math.round(Wp*dpr)||this.cv.height!==Math.round(Hp*dpr)){this.cv.width=Math.round(Wp*dpr);this.cv.height=Math.round(Hp*dpr);}
  const ctx=this.cv.getContext('2d'),t=Math.max(0,Math.min(1,+(this.getAttribute('stage')||0))),still=this.hasAttribute('still'),f=RM()?0:(now-this.t0)/40,fo=(this.getAttribute('focus')||'').split(',').map(Number);
  const z=fo.length>1&&!isNaN(fo[1])?fo[1]:1,s=Math.max(Wp/WW,Hp/WH)*z,cx=fo.length&&!isNaN(fo[0])&&this.getAttribute('focus')?fo[0]:WW/2;
  ctx.setTransform(dpr,0,0,dpr,0,0);ctx.fillStyle='#000';ctx.fillRect(0,0,Wp,Hp);ctx.setTransform(dpr*s,0,0,dpr*s,dpr*(Wp/2-cx*s),dpr*(Hp-WH*s));
  const top=mix(hx('#5A4530'),hx('#3F8FD8'),t),hor=mix(hx('#B89066'),hx('#D5ECF8'),t),g=ctx.createLinearGradient(0,0,0,GY);g.addColorStop(0,css(top));g.addColorStop(1,css(hor));ctx.fillStyle=g;ctx.fillRect(-2000,0,WW+4000,GY);
  ctx.fillStyle=css(mix(hx('#D8864A'),hx('#FFE9A8'),t),.9);ctx.beginPath();ctx.arc(1700,180-t*60,28,0,7);ctx.fill();
  ctx.fillStyle=tint('#B7A15E',t,.6);ctx.fillRect(-2000,300,2700,22);ctx.fillStyle=tint('#9C8E4E',t,.6);ctx.fillRect(-2000,318,2700,12);
  for(let i=0;i<9;i++){const x=40+i*72;ctx.fillStyle=`rgba(224,137,43,${.9-t*.7})`;ctx.fillRect(x,304,5,4);for(let k=0;k<6;k++){const q=((f*.01+k/6+i*.13)%1);ctx.fillStyle=`rgba(90,72,54,${(1-q)*.35*(1-t)})`;ctx.beginPath();ctx.arc(x+q*90,300-q*120,6+q*26,0,7);ctx.fill();}}
  const far=tint('#9FB3C2',t,.9);ctx.fillStyle=far;
  ctx.beginPath();ctx.moveTo(408,330);ctx.lineTo(414,150);ctx.lineTo(426,150);ctx.lineTo(432,330);ctx.fill();for(let i=0;i<5;i++)ctx.fillRect(404+i*1.2,180+i*30,36-i*2.4,4);
  ctx.fillRect(1080,220,150,110);ctx.fillRect(1072,212,166,12);ctx.fillRect(1120,196,70,18);ctx.beginPath();ctx.arc(1155,196,12,Math.PI,0);ctx.fill();ctx.fillStyle=tint('#B89066',t,.1);const hg=ctx.createLinearGradient(0,240,0,330);hg.addColorStop(0,css(mix(hx('#9E7D56'),hx('#C9DCEB'),t)));hg.addColorStop(1,css(hor));ctx.fillStyle=hg;ctx.beginPath();ctx.moveTo(1122,330);ctx.lineTo(1122,262);ctx.arc(1155,262,33,Math.PI,0);ctx.lineTo(1188,330);ctx.fill();
  ctx.fillStyle=tint('#8FA6B6',t,.85);for(let x=1300;x<1720;x+=34){const h=40+((x*7)%60);ctx.fillRect(x,330-h,26,h);}
  ctx.fillStyle=tint('#7E97A8',t,.7);for(let x=-100;x<1600;x+=40){if(x>380&&x<460||x>1060&&x<1250)continue;const h=18+((x*13)%34);ctx.fillRect(x,340-h,32,h);}
  ctx.fillStyle=tint('#8A9AA6',t,.6);ctx.fillRect(1720,330,700,110);ctx.fillStyle=tint('#6C8A9C',t,.5);ctx.fillRect(1720,356,700,84);
  ctx.strokeStyle=tint('#E4E8EB',t,.5);ctx.lineWidth=5;ctx.beginPath();ctx.moveTo(1880,352);ctx.lineTo(1935,140);ctx.lineTo(1990,352);ctx.stroke();ctx.lineWidth=1.2;for(let i=0;i<12;i++){ctx.beginPath();ctx.moveTo(1935,150+i*6);ctx.lineTo(1760+i*14,352);ctx.stroke();ctx.beginPath();ctx.moveTo(1935,150+i*6);ctx.lineTo(2010+i*14,352);ctx.stroke();}ctx.fillStyle=tint('#D9DCDD',t,.5);ctx.fillRect(1740,350,420,6);
  ctx.fillStyle=tint('#7A6A55',t,.45);ctx.beginPath();ctx.moveTo(2150,356);ctx.quadraticCurveTo(2280,210,2440,356);ctx.fill();ctx.fillStyle=tint('#8C7A62',t,.45);ctx.beginPath();ctx.moveTo(2200,356);ctx.quadraticCurveTo(2280,260,2380,356);ctx.fill();
  for(let k=0;k<10;k++){const q=((f*.008+k/10)%1);ctx.fillStyle=`rgba(70,60,52,${(1-q)*.45*(1-t*.8)})`;ctx.beginPath();ctx.arc(2285-q*80,262-q*150,8+q*30,0,7);ctx.fill();}
  ctx.fillStyle=`rgba(224,137,43,${.9-t*.6})`;ctx.fillRect(2276,262,8,5);
  ctx.fillStyle=tint('#C9CED3',t,.3);ctx.fillRect(-100,352,1720,12);for(let x=-60;x<1620;x+=120)ctx.fillRect(x,364,12,76);
  const tx=still?300:((f*2.2)%2400)-600;for(let k=0;k<4;k++){const x=tx+k*66;ctx.fillStyle=tint('#F3F3F3',t,.2);rr(ctx,x,332,62,20,5);ctx.fill();ctx.fillStyle=tint('#D6417B',t,.2);ctx.fillRect(x,344,62,4);ctx.fillStyle='#2A3A40';for(let w=0;w<4;w++)ctx.fillRect(x+6+w*14,336,9,6);}
  ctx.fillStyle=tint('#8C8274',t,.3);ctx.fillRect(560,250,200,190);ctx.fillStyle=tint('#2F7D4F',t,.25);ctx.fillRect(560,250,200,190);ctx.strokeStyle='rgba(20,60,36,.55)';ctx.lineWidth=1;for(let x=560;x<760;x+=8){ctx.beginPath();ctx.moveTo(x,250);ctx.lineTo(x,440);ctx.stroke();}for(let y=250;y<440;y+=8){ctx.beginPath();ctx.moveTo(560,y);ctx.lineTo(760,y);ctx.stroke();}
  ctx.strokeStyle=tint('#E2A83C',t,.3);ctx.lineWidth=4;ctx.beginPath();ctx.moveTo(800,440);ctx.lineTo(800,170);ctx.lineTo(620,170);ctx.moveTo(800,170);ctx.lineTo(860,170);ctx.stroke();ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(680,170);ctx.lineTo(680,230);ctx.stroke();
  for(let i=0;i<14;i++){const q=((f*.012+i/14)%1);ctx.fillStyle=`rgba(196,168,126,${(1-q)*.5})`;ctx.beginPath();ctx.arc(600+i*11+q*40,430-q*70,4+q*14,0,7);ctx.fill();}
  ctx.fillStyle=tint('#EDE2CB',t,.25);ctx.fillRect(900,300,200,140);ctx.fillStyle=tint('#B85A3E',t,.25);ctx.fillRect(894,292,212,10);for(let i=0;i<5;i++)ctx.fillRect(912+i*38,318,22,26);ctx.fillStyle='#2A3A40';for(let i=0;i<5;i++)ctx.fillRect(914+i*38,320,18,22);ctx.fillStyle=tint('#51575C',t,.2);ctx.fillRect(1120,300,3,140);ctx.fillStyle=tint('#E0892B',t,.2);ctx.fillRect(1123,300,24,6);ctx.fillStyle='#F4F4F2';ctx.fillRect(1123,306,24,6);ctx.fillStyle=tint('#1E8A4C',t,.2);ctx.fillRect(1123,312,24,6);
  for(let r=0;r<3;r++)for(let c=0;c<10;c++){const x=912+c*18,y=402+r*12;ctx.fillStyle=tint('#3C5A8A',t,.2);ctx.fillRect(x,y,8,9);ctx.fillStyle='#B98563';ctx.fillRect(x+1,y-5,6,5);}
  ctx.fillStyle=tint('#6A6A66',t,.15);ctx.fillRect(-2000,GY,WW+4000,WH-GY);ctx.fillStyle=tint('#B8B0A0',t,.15);ctx.fillRect(-2000,GY,WW+4000,8);ctx.fillStyle=tint('#E8E2CC',t,.15);for(let x=-2000;x<WW+2000;x+=60)ctx.fillRect(x,GY+44,30,3);
  const lane=(base,sp,y,fn)=>{const x=still?base:(((base+f*sp)%3200)+3200)%3200-400;fn(ctx,x,y,t,f);};
  lane(1260,1.2,GY+36,V.bus);lane(1480,1.6,GY+36,V.auto);lane(1150,1.0,GY+72,V.erick);lane(1560,1.4,GY+72,V.auto);lane(660,.8,GY+72,V.sprinkler);lane(420,.9,GY+36,V.gun);
  for(let x=100;x<WW;x+=260){ctx.fillStyle=tint('#51575C',t,.2);ctx.fillRect(x,GY-120,3,128);ctx.fillRect(x,GY-120,22,3);const gl=ctx.createRadialGradient(x+20,GY-114,2,x+20,GY-114,90);gl.addColorStop(0,`rgba(224,137,43,${.55*(1-t)+.1})`);gl.addColorStop(1,'rgba(224,137,43,0)');ctx.fillStyle=gl;ctx.beginPath();ctx.arc(x+20,GY-114,90,0,7);ctx.fill();ctx.fillStyle='#FFC977';ctx.fillRect(x+16,GY-117,8,4);}
  if(t<1){for(let b=0;b<4;b++){const y=200+b*70,o=(1-t)*(.16+b*.03);const fg=ctx.createLinearGradient(0,y-40,0,y+60);fg.addColorStop(0,'rgba(170,140,105,0)');fg.addColorStop(.5,`rgba(170,140,105,${o})`);fg.addColorStop(1,'rgba(170,140,105,0)');ctx.fillStyle=fg;ctx.fillRect(-2000,y-40,WW+4000,100);}}
  ctx.setTransform(dpr,0,0,dpr,0,0);ctx.globalAlpha=1;ctx.fillStyle=ctx.createPattern(grain(),'repeat');ctx.fillRect(0,0,Wp,Hp);}
}
customElements.define('delhi-street',DelhiStreet);
})();
