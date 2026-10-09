(function(){
if(customElements.get('hc-street'))return;
const RM=()=>window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches;
const lerp=(a,b,t)=>a+(b-a)*t,hx=h=>{const n=parseInt(h.slice(1),16);return[n>>16&255,n>>8&255,n&255];},mixc=(a,b,t)=>{const A=hx(a),B=hx(b);return`rgb(${lerp(A[0],B[0],t)|0},${lerp(A[1],B[1],t)|0},${lerp(A[2],B[2],t)|0})`;};
const HAZE='#B89572';
let GRAIN=null;function grain(ctx){if(!GRAIN){const c=document.createElement('canvas');c.width=c.height=160;const g=c.getContext('2d'),d=g.createImageData(160,160);for(let i=0;i<d.data.length;i+=4){const v=Math.random()*255|0;d.data[i]=d.data[i+1]=d.data[i+2]=v;d.data[i+3]=26;}g.putImageData(d,0,0);GRAIN=c;}return ctx.createPattern(GRAIN,'repeat');}
function rr(c,x,y,w,h,r,f){c.beginPath();c.roundRect?c.roundRect(x,y,w,h,r):c.rect(x,y,w,h);c.fillStyle=f;c.fill();}
function R(c,x,y,w,h,f){c.fillStyle=f;c.fillRect(x,y,w,h);}
function circ(c,x,y,r,f){c.beginPath();c.arc(x,y,r,0,Math.PI*2);c.fillStyle=f;c.fill();}
function poly(c,p,f){c.beginPath();p.forEach((q,i)=>i?c.lineTo(q[0],q[1]):c.moveTo(q[0],q[1]));c.closePath();c.fillStyle=f;c.fill();}
function puff(c,x,y,r,col,a){c.globalAlpha=a;circ(c,x,y,r,col);c.globalAlpha=1;}
function wheel(c,x,y,r){circ(c,x,y,r,'#1E2226');circ(c,x,y,r*.45,'#8A9096');}
const hz=(col,s,k)=>mixc(col,HAZE,(1-s)*k);
function sky(c,W,H,s){const g=c.createLinearGradient(0,0,0,H);g.addColorStop(0,mixc('#6B5641','#3D8BD6',s));g.addColorStop(.62,mixc('#A5845E','#8CC6EE',s));g.addColorStop(1,mixc('#CFAE84','#D6ECF8',s));c.fillStyle=g;c.fillRect(0,0,W,H);
 const sx=W*.78,sy=lerp(H*.36,H*.16,s),gl=c.createRadialGradient(sx,sy,4,sx,sy,120);gl.addColorStop(0,s>.5?'rgba(255,240,190,.9)':'rgba(236,150,80,.75)');gl.addColorStop(1,'rgba(255,220,160,0)');c.fillStyle=gl;c.fillRect(sx-130,sy-130,260,260);circ(c,sx,sy,26,mixc('#E0894A','#FFE9A0',s));}
function clouds(c,W,H,s,t){if(s<.45)return;c.globalAlpha=(s-.45)*1.6;[[.12,.14,1],[.42,.08,.8],[.66,.2,1.2]].forEach(([x,y,k],i)=>{const cx=((x*W+t*6*(i+1))%(W+300))-150,cy=y*H;[[0,0,34],[30,-12,40],[66,0,30],[36,8,34]].forEach(p=>circ(c,cx+p[0]*k,cy+p[1]*k,p[2]*k,'#FFFFFF'));});c.globalAlpha=1;
 for(let i=0;i<5;i++){const bx=((i*230+t*22)%(W+100))-50,by=H*(.18+.05*Math.sin(i*2+t*.4));c.strokeStyle=`rgba(30,40,46,${(s-.45)*1.4})`;c.lineWidth=2;c.beginPath();c.moveTo(bx-8,by-3);c.quadraticCurveTo(bx-4,by-6,bx,by);c.quadraticCurveTo(bx+4,by-6,bx+8,by-3);c.stroke();}}
function city(c,W,H,s,y0,seed){let x=0,i=seed||3;while(x<W){i=(i*9301+49297)%233280;const r=i/233280,w=34+r*50,h=40+((i*7)%100);R(c,x,y0-h,w,h+2,hz(r<.5?'#9FB0BD':'#B7C3CB',s,.85));x+=w+4+r*8;}}
function indiaGate(c,x,y,s){const col=hz('#C98F5E',s,.6),dk=hz('#8E5E3A',s,.6),w=120,h=150;R(c,x-w/2-8,y-8,w+16,8,dk);R(c,x-w/2,y-h,w,h,col);R(c,x-w/2-4,y-h-6,w+8,8,dk);R(c,x-w/2+12,y-h-26,w-24,20,col);R(c,x-w/2+26,y-h-38,w-52,12,dk);
 c.beginPath();c.moveTo(x-24,y);c.lineTo(x-24,y-78);c.arc(x,y-78,24,Math.PI,0);c.lineTo(x+24,y);c.closePath();c.fillStyle=hz('#5A3E2A',s,.6);c.fill();R(c,x-w/2,y-h+22,w,3,dk);}
function qutub(c,x,y,s){let w=46,yy=y;const tones=['#B9724A','#C47E54','#B9724A','#E7DDD0','#E7DDD0'];for(let i=0;i<5;i++){const h=58-i*6,w2=w-7;poly(c,[[x-w/2,yy],[x+w/2,yy],[x+w2/2,yy-h],[x-w2/2,yy-h]],hz(tones[i],s,.6));c.strokeStyle=hz('#7E4B2E',s,.6);c.lineWidth=1;for(let k=-2;k<=2;k++){c.beginPath();c.moveTo(x+k*w/6,yy);c.lineTo(x+k*w2/6,yy-h);c.stroke();}R(c,x-w2/2-4,yy-h-4,w2+8,4,hz('#7E4B2E',s,.6));yy-=h+4;w=w2;}R(c,x-6,yy-12,12,12,hz('#E7DDD0',s,.6));}
function sigBridge(c,x,y,s){const col=hz('#E8ECEE',s,.55),cab=hz('#C9D0D4',s,.55);R(c,x-260,y-30,520,8,hz('#B5BDC2',s,.55));const top=[x+30,y-230];poly(c,[[x-40,y-22],[x-26,y-22],[top[0]+4,top[1]],[top[0]-6,top[1]+14]],col);poly(c,[[x+40,y-22],[x+54,y-22],[top[0]+10,top[1]+10],[top[0]+2,top[1]]],col);
 c.strokeStyle=cab;c.lineWidth=1;for(let i=1;i<=9;i++){const py=top[1]+14+i*7,px=top[0]-3-i*3;c.beginPath();c.moveTo(px,py);c.lineTo(x-40-i*22,y-30);c.stroke();c.beginPath();c.moveTo(px+6,py);c.lineTo(x+60+i*18,y-30);c.stroke();}}
function viaduct(c,W,H,s,y,t){const col=hz('#BFC4C6',s,.35),dk=hz('#8F9597',s,.35);for(let x=90;x<W;x+=220){R(c,x-10,y+14,20,H-y,dk);poly(c,[[x-34,y+14],[x+34,y+14],[x+12,y+30],[x-12,y+30]],dk);}R(c,0,y,W,16,col);R(c,0,y,W,3,hz('#E0E3E4',s,.35));
 const tx=RM()?W*.25:((t*70)%(W+700))-650;for(let k=0;k<4;k++){const x=tx+k*156;rr(c,x,y-34,150,34,k===0?[14,4,0,0]:k===3?[4,14,0,0]:3,hz('#E9ECEE',s,.3));R(c,x,y-12,150,5,'#D6337A');for(let w=x+12;w<x+140;w+=22)R(c,w,y-28,14,11,hz('#2F3E46',s,.3));}}
function lamp(c,x,yb,s){const pole='#3B3D3C';R(c,x-2,yb-160,4,160,pole);c.strokeStyle=pole;c.lineWidth=4;c.beginPath();c.moveTo(x,yb-158);c.quadraticCurveTo(x+4,yb-176,x+30,yb-172);c.stroke();R(c,x+22,yb-172,18,6,pole);
 const a=.18+.5*(1-s),g=c.createRadialGradient(x+31,yb-164,2,x+31,yb-164,110);g.addColorStop(0,`rgba(224,137,43,${a})`);g.addColorStop(1,'rgba(224,137,43,0)');c.fillStyle=g;c.fillRect(x-80,yb-275,220,220);circ(c,x+31,yb-166,4,s>.6?'#F5E6C8':'#F6B25A');}
function road(c,W,H,s,y){R(c,0,y,W,H-y,hz('#4A4B4A',s,.25));R(c,0,y-10,W,10,hz('#A89C8A',s,.3));for(let x=0;x<W;x+=24)R(c,x,y-4,12,6,x%48?'#E8C53A':'#1E2226');for(let x=30;x<W;x+=80)R(c,x,y+(H-y)*.55,40,4,hz('#D9D2B8',s,.2));}
function bus(c,x,y,s,t){const g=hz('#3D8C52',s,.2);rr(c,x,y-86,270,78,10,g);rr(c,x+6,y-80,258,34,4,'#26343A');for(let w=x+60;w<x+260;w+=50)R(c,x+w-x,y-80,4,34,g);R(c,x+262,y-80,6,30,'#F2A33A');for(let d=0;d<4;d++)R(c,x+263,y-76+d*7,4,2,'#7A3E08');rr(c,x+14,y-44,34,34,3,'#26343A');R(c,x,y-12,270,4,hz('#2C6B3D',s,.2));rr(c,x+150,y-98,90,12,6,hz('#DDE3E5',s,.2));
 rr(c,x+70,y-100,26,14,3,'#E8EEF2');R(c,x+76,y-100,14,3,'#2DD4BF');const k=RM()?.5:(t*.8)%1;c.strokeStyle=`rgba(45,212,191,${1-k})`;c.lineWidth=2;c.beginPath();c.arc(x+83,y-100,8+k*24,Math.PI,0);c.stroke();wheel(c,x+56,y-8,15);wheel(c,x+214,y-8,15);
 for(let i=0;i<6;i++){const q=RM()?.4:((t*.7+i*.17)%1);puff(c,x-8-q*80,y-14-q*30,5+q*18,'#5F5A55',.55*(1-q));}}
function auto(c,x,y,s){const cy=hz('#E8C53A',s,.2),gr=hz('#2E7D32',s,.2);c.beginPath();c.moveTo(x+6,y-40);c.quadraticCurveTo(x+10,y-78,x+60,y-80);c.quadraticCurveTo(x+100,y-78,x+104,y-44);c.lineTo(x+6,y-40);c.fillStyle=cy;c.fill();rr(c,x+2,y-42,108,28,6,gr);R(c,x+14,y-68,6,28,'#1E2226');R(c,x+90,y-68,5,26,'#1E2226');rr(c,x+96,y-40,20,12,3,gr);circ(c,x+114,y-30,4,'#FFF3C4');wheel(c,x+22,y-10,11);wheel(c,x+100,y-10,10);}
function erick(c,x,y,s){R(c,x+4,y-78,96,8,hz('#DCE6EE',s,.2));R(c,x+8,y-70,4,40,'#1E2226');R(c,x+92,y-70,4,40,'#1E2226');rr(c,x,y-36,104,22,5,hz('#2F4A6A',s,.2));R(c,x+30,y-50,40,14,hz('#6D7F8E',s,.2));wheel(c,x+20,y-10,10);wheel(c,x+88,y-10,10);}
function sprinkler(c,x,y,s,t){rr(c,x,y-70,170,56,26,hz('#E8EEF2',s,.2));R(c,x+10,y-50,150,5,'#3E7C5A');rr(c,x+172,y-84,62,70,8,hz('#3E7C5A',s,.2));rr(c,x+188,y-78,40,24,4,'#BFE3F2');R(c,x-6,y-14,244,6,'#2B2F33');wheel(c,x+36,y-8,14);wheel(c,x+120,y-8,14);wheel(c,x+206,y-8,14);R(c,x-14,y-30,14,6,'#51575C');
 for(let i=0;i<22;i++){const q=RM()?.5:((t*1.4+i*.047)%1),a=-.3-(i%7)*.12;const px=x-14-Math.cos(a)*q*110,py=y-27+Math.sin(-a)*q*-40+q*q*50;c.globalAlpha=1-q;circ(c,px,py,2.2,'#7CC7EE');c.globalAlpha=1;}}
function smogGun(c,x,y,s,t){rr(c,x,y-44,190,30,4,hz('#DDE1E3',s,.2));rr(c,x+192,y-78,60,64,8,hz('#E59A3A',s,.2));rr(c,x+206,y-72,38,22,4,'#BFE3F2');wheel(c,x+34,y-8,14);wheel(c,x+150,y-8,14);wheel(c,x+222,y-8,14);
 c.save();c.translate(x+80,y-58);c.rotate(-.45);rr(c,-46,-22,92,44,20,hz('#8C9296',s,.2));circ(c,-46,0,21,hz('#5F666C',s,.2));c.restore();R(c,x+70,y-56,20,14,'#51575C');
 for(let i=0;i<18;i++){const q=RM()?.5:((t*.8+i*.055)%1);puff(c,x+30-q*170,y-100-q*70+Math.sin(i)*10,4+q*22,'#EEF4F7',.7*(1-q));}}
function site(c,x,y,s,t){const net=hz('#2F7D4A',s,.3);R(c,x,y-230,240,230,hz('#9A9A96',s,.35));c.globalAlpha=.88;R(c,x-4,y-224,248,224,net);c.globalAlpha=1;c.strokeStyle='rgba(20,60,34,.5)';c.lineWidth=1;for(let k=-240;k<260;k+=12){c.beginPath();c.moveTo(x+k,y);c.lineTo(x+k+224,y-224);c.stroke();}
 for(let f=0;f<4;f++)R(c,x-4,y-224+f*56,248,4,hz('#6E6F6B',s,.3));const cx=x+290,cr=hz('#E2A83C',s,.35);R(c,cx,y-330,12,330,cr);for(let yy=y-320;yy<y;yy+=16){c.strokeStyle=hz('#B98322',s,.35);c.beginPath();c.moveTo(cx,yy);c.lineTo(cx+12,yy+16);c.stroke();}
 R(c,cx-230,y-340,300,10,cr);R(c,cx+40,y-336,26,20,'#51575C');R(c,cx-150,y-330,2,90,'#3B3D3C');R(c,cx-158,y-240,18,10,'#3B3D3C');
 for(let i=0;i<10;i++){const q=RM()?.4:((t*.18+i*.1)%1);puff(c,x+40+i*22+q*60,y-10-q*90,10+q*34,'#C9AE86',.6*(1-q));}}
function landfill(c,x,y,s,t){const a=hz('#7A6E5E',s,.3),b=hz('#948672',s,.3);poly(c,[[x,y],[x+120,y-150],[x+260,y-230],[x+420,y-210],[x+560,y-120],[x+660,y]],a);
 for(let k=0;k<4;k++){c.strokeStyle=b;c.lineWidth=5;c.beginPath();c.moveTo(x+60+k*30,y-40-k*45);c.quadraticCurveTo(x+330,y-80-k*50,x+620-k*40,y-30-k*40);c.stroke();}
 [[x+300,y-226],[x+360,y-222],[x+200,y-180]].forEach(([fx,fy],i)=>{for(let j=0;j<5;j++){const h=10+((j*7+Math.floor(t*8)+i)%5)*4;poly(c,[[fx+j*6-4,fy],[fx+j*6+4,fy],[fx+j*6,fy-h]],j%2?'#FFC34A':'#F08C35');}
  for(let j=0;j<9;j++){const q=RM()?.4:((t*.22+j*.11+i*.3)%1);puff(c,fx+q*160,fy-20-q*170,8+q*40,'#3F3B37',.55*(1-q));}});
 for(let i=0;i<7;i++){const ang=t*.5+i,bx=x+320+Math.cos(ang)*(90+i*14),by=y-300+Math.sin(ang*1.3)*30;c.strokeStyle='#23272A';c.lineWidth=2.5;c.beginPath();c.moveTo(bx-10,by-3);c.quadraticCurveTo(bx-5,by-8,bx,by);c.quadraticCurveTo(bx+5,by-8,bx+10,by-3);c.stroke();}}
function person(c,x,y,shirt,pant,sc){sc=sc||1;circ(c,x,y-38*sc,6*sc,'#8A5A3C');R(c,x-6*sc,y-31*sc,12*sc,16*sc,shirt);R(c,x-5*sc,y-15*sc,4*sc,15*sc,pant);R(c,x+1*sc,y-15*sc,4*sc,15*sc,pant);}
function van(c,x,y,s){rr(c,x,y-80,190,66,10,hz('#EEF1F2',s,.2));rr(c,x+140,y-72,44,26,5,'#BFE3F2');R(c,x,y-44,190,6,'#2F4A6A');c.font='600 16px "Geist Mono",monospace';c.fillStyle='#2F4A6A';c.fillText('I-3',x+20,y-54);wheel(c,x+40,y-10,14);wheel(c,x+150,y-10,14);}
function school(c,x,y,s,t){const wall=hz('#EFE3C8',s,.3),roof=hz('#B85A3E',s,.3);R(c,x,y-200,420,200,wall);R(c,x-10,y-212,440,16,roof);R(c,x+170,y-250,80,50,wall);R(c,x+166,y-258,88,10,roof);
 const shut=((t/2.5)|0)%2;for(let r=0;r<2;r++)for(let k=0;k<6;k++){const wx=x+22+k*66,wy=y-180+r*72;R(c,wx,wy,40,44,shut?'#BFE3F2':'#34424A');if(shut){R(c,wx+19,wy,2,44,wall);R(c,wx,wy+21,40,2,wall);}}
 R(c,x-150,y-260,4,260,'#6E6F6B');const fx=x-146,fy=y-258;R(c,fx,fy,54,12,'#FF9933');R(c,fx,fy+12,54,12,'#FFFFFF');R(c,fx,fy+24,54,12,'#138808');c.strokeStyle='#1F3A93';c.lineWidth=1.5;c.beginPath();c.arc(fx+27,fy+18,4,0,7);c.stroke();}
function assembly(c,x,y){for(let r=0;r<3;r++)for(let k=0;k<11;k++)person(c,x+k*22+r*8,y+r*18,'#F4F4F2','#2B3A67',.62);person(c,x-40,y+10,'#8A3B5A','#3B2A2A',.8);}
function fields(c,W,H,s,y,t){const cols=['#C9A85A','#B89A52','#A8904E','#98894C'];for(let i=0;i<4;i++)R(c,0,y+i*14,W,14,hz(cols[i],s,.4));
 for(let i=0;i<9;i++){const fx=40+i*(W/9),fy=y+4+(i%3)*12;for(let j=0;j<4;j++)poly(c,[[fx+j*7-4,fy],[fx+j*7+4,fy],[fx+j*7,fy-8-((j+Math.floor(t*8)+i)%3)*4]],j%2?'#FFC34A':'#F08C35');
  for(let j=0;j<7;j++){const q=RM()?.4:((t*.15+j*.14+i*.07)%1);puff(c,fx+q*260,fy-10-q*110,6+q*30,'#6E6456',.5*(1-q));}}}
const SEGS={
 skyline(c,W,H,s,t){sky(c,W,H,s);clouds(c,W,H,s,t);const hy=H*.74;city(c,W,H,s,hy,3);indiaGate(c,W*.16,hy,s);qutub(c,W*.47,hy,s);sigBridge(c,W*.8,hy,s);viaduct(c,W,H,s,H*.79,t);road(c,W,H,s,H*.93);lamp(c,W*.3,H*.93,s);lamp(c,W*.66,H*.93,s);},
 dust(c,W,H,s,t){sky(c,W,H,s);city(c,W,H,s,H*.62,7);site(c,W*.08,H*.8,s,t);road(c,W,H,s,H*.8);sprinkler(c,W*.52,H*.95,s,t);lamp(c,W*.9,H*.8,s);},
 traffic(c,W,H,s,t){sky(c,W,H,s);city(c,W,H,s,H*.5,11);viaduct(c,W,H,s,H*.36,t);road(c,W,H,s,H*.7);lamp(c,W*.12,H*.7,s);bus(c,W*.06,H*.95,s,t);auto(c,W*.6,H*.95,s);erick(c,W*.8,H*.9,s);},
 burning(c,W,H,s,t){sky(c,W,H,s);city(c,W,H,s,H*.72,5);landfill(c,W*.02,H*.78,s,t);road(c,W,H,s,H*.78);van(c,W*.62,H*.95,s);person(c,W*.9,H*.95,'#2F4A6A','#2E3A46',1.4);R(c,W*.9-6,H*.95-44,12,4,'#E8C53A');},
 stubble(c,W,H,s,t){sky(c,W,H,s);fields(c,W,H,s,H*.46,t);R(c,0,H*.62,W,H*.38,hz('#8FA96A',s,.3));school(c,W*.42,H*.86,s,t);assembly(c,W*.1,H*.84);R(c,0,H*.93,W,H*.07,hz('#A89C8A',s,.3));},
 smoggun(c,W,H,s,t){sky(c,W,H,s);city(c,W,H,s,H*.62,9);road(c,W,H,s,H*.72);smogGun(c,W*.35,H*.95,s,t);lamp(c,W*.1,H*.72,s);}
};
class HcStreet extends HTMLElement{
 static get observedAttributes(){return['seg','stage'];}
 connectedCallback(){if(this.cv)return;this.style.display='block';const r=this.attachShadow({mode:'open'});r.innerHTML='<canvas style="width:100%;height:100%;display:block"></canvas>';this.cv=r.querySelector('canvas');this._vis=true;
  try{this.io=new IntersectionObserver(e=>{this._vis=e[e.length-1].isIntersecting;},{rootMargin:'150px'});this.io.observe(this);}catch(e){}
  this.t0=performance.now();const f=()=>{if(this._vis!==false&&!document.hidden)this.draw();this.tm=setTimeout(f,RM()?600:50);};f();}
 disconnectedCallback(){clearTimeout(this.tm);this.io&&this.io.disconnect();this.cv=null;}
 draw(){const W=this.clientWidth,H=this.clientHeight;if(!W||!H||!this.cv)return;const dpr=Math.min(2,devicePixelRatio||1);if(this.cv.width!==Math.round(W*dpr)||this.cv.height!==Math.round(H*dpr)){this.cv.width=Math.round(W*dpr);this.cv.height=Math.round(H*dpr);}
  const c=this.cv.getContext('2d'),k=H/500,LW=W/k,t=RM()?0:(performance.now()-this.t0)/1000,s=Math.max(0,Math.min(1,+(this.getAttribute('stage')||0)));
  c.setTransform(dpr*k,0,0,dpr*k,0,0);c.clearRect(0,0,LW,500);(SEGS[this.getAttribute('seg')||'skyline']||SEGS.skyline)(c,LW,500,s,t);
  const fg=c.createLinearGradient(0,150,0,500);fg.addColorStop(0,`rgba(196,160,118,0)`);fg.addColorStop(1,`rgba(196,160,118,${.42*(1-s)})`);c.fillStyle=fg;c.fillRect(0,0,LW,500);
  c.setTransform(dpr,0,0,dpr,0,0);c.fillStyle=grain(c);c.fillRect(0,0,W,H);}
}
customElements.define('hc-street',HcStreet);
})();
