// @ts-nocheck
// Vendored from Claude Design export (design/claude-design/source/hawa.js). Registers custom elements; loaded client-side by components/visuals/VisualsLoader.
(function(){
const __raf=f=>setTimeout(()=>f(performance.now()),30),__caf=clearTimeout;
if (window.Hawa) return;
const BB={w:76.83,e:77.36,s:28.40,n:28.89}, KX=97.8, KY=111.2;
const W_KM=(BB.e-BB.w)*KX, H_KM=(BB.n-BB.s)*KY;
function inPoly(x,y,p){let c=false;for(let i=0,j=p.length-1;i<p.length;j=i++){const[xi,yi]=p[i],[xj,yj]=p[j];if(((yi>y)!=(yj>y))&&(x<(xj-xi)*(y-yi)/(yj-yi)+xi))c=!c;}return c;}
const km=(lon,lat)=>[(lon-BB.w)*KX,(BB.n-lat)*KY];
const OUTLINE=[[77.10,28.885],[77.18,28.87],[77.22,28.845],[77.235,28.79],[77.265,28.735],[77.33,28.705],[77.345,28.66],[77.338,28.60],[77.305,28.555],[77.31,28.50],[77.245,28.43],[77.17,28.405],[77.12,28.465],[77.10,28.52],[77.04,28.515],[76.96,28.55],[76.845,28.565],[76.84,28.64],[76.90,28.705],[76.95,28.765],[77.02,28.81],[77.06,28.86]].map(p=>km(p[0],p[1]));
const YAMUNA=[[77.205,28.89],[77.222,28.82],[77.232,28.76],[77.245,28.70],[77.252,28.66],[77.256,28.62],[77.27,28.58],[77.295,28.54],[77.312,28.49],[77.33,28.43]].map(p=>km(p[0],p[1]));
const PLACES={rkpuram:['RK Puram',77.184,28.563],dwarka:['Dwarka',77.046,28.592],ito:['ITO',77.241,28.628]};
const HOTSPOTS=[
 {id:'ghazipur',place:'Ghazipur',lon:77.327,lat:28.622,pm:388,cause:'Burning',conf:0.74,sigma:1.3,ward:'East Delhi',suspect:'Landfill edge, open burning'},
 {id:'anand',place:'Anand Vihar',lon:77.316,lat:28.647,pm:212,cause:'Dust',conf:0.82,sigma:1.1,ward:'East Delhi',suspect:'Unpaved shoulder, ISBT road'},
 {id:'shahdara',place:'Shahdara',lon:77.289,lat:28.673,pm:341,cause:'Traffic',conf:0.69,sigma:1.4,ward:'Shahdara',suspect:'GT Road corridor, idling HGVs'},
 {id:'ito',place:'ITO',lon:77.241,lat:28.628,pm:296,cause:'Traffic',conf:0.77,sigma:1.2,ward:'Central',suspect:'Vikas Marg junction'},
 {id:'wazirpur',place:'Wazirpur',lon:77.165,lat:28.699,pm:402,cause:'Burning',conf:0.63,sigma:1.3,ward:'North West',suspect:'Industrial area, waste pile'},
 {id:'mundka',place:'Mundka',lon:77.031,lat:28.683,pm:437,cause:'Regional smoke',conf:0.71,sigma:2.2,ward:'West',suspect:'NW inflow, FIRMS fires upwind'},
 {id:'jahangirpuri',place:'Jahangirpuri',lon:77.171,lat:28.733,pm:364,cause:'Dust',conf:0.66,sigma:1.2,ward:'North West',suspect:'Construction site, C-block'},
 {id:'okhla',place:'Okhla',lon:77.271,lat:28.530,pm:318,cause:'Dust',conf:0.72,sigma:1.3,ward:'South East',suspect:'Phase II road works'},
 {id:'punjabi',place:'Punjabi Bagh',lon:77.131,lat:28.674,pm:279,cause:'Traffic',conf:0.70,sigma:1.2,ward:'West',suspect:'Ring Road flyover queue'}
];
HOTSPOTS.forEach(h=>{const k=km(h.lon,h.lat);h.x=k[0];h.y=k[1];});
const ASSETS=[
 {id:'T-12',kind:'truck',icon:'truck',live:[[77.300,28.622],[77.306,28.636],[77.316,28.647],[77.322,28.655]],usual:[[77.280,28.600],[77.296,28.595],[77.310,28.590]],plan:[[77.300,28.622],[77.316,28.647],[77.300,28.668]]},
 {id:'T-07',kind:'truck',icon:'truck',live:[[77.226,28.618],[77.241,28.628],[77.250,28.640]],usual:[[77.200,28.610],[77.215,28.598],[77.230,28.590]],plan:[[77.226,28.618],[77.241,28.628],[77.252,28.638]]},
 {id:'T-19',kind:'truck',icon:'truck',live:[[77.258,28.518],[77.271,28.530],[77.284,28.548]],usual:[[77.240,28.540],[77.252,28.552],[77.262,28.566]],plan:[[77.258,28.518],[77.271,28.530],[77.284,28.548]]},
 {id:'ASG-07',kind:'gun',icon:'spray-can',live:[[77.160,28.722],[77.171,28.733],[77.180,28.742]],usual:[[77.140,28.720],[77.150,28.740]],plan:[[77.160,28.722],[77.171,28.733]]},
 {id:'SW-03',kind:'sweeper',icon:'brush',live:[[77.276,28.660],[77.289,28.673],[77.302,28.684]],usual:[[77.300,28.700],[77.312,28.690]],plan:[[77.276,28.660],[77.289,28.673],[77.300,28.680]]},
 {id:'I-3',kind:'team',icon:'users',live:[[77.296,28.606],[77.312,28.614],[77.327,28.622]],usual:[[77.296,28.606],[77.300,28.616]],plan:[[77.296,28.606],[77.312,28.614],[77.327,28.622]]}
];
const BUSES=[
 [[77.046,28.592],[77.10,28.575],[77.184,28.563],[77.22,28.60],[77.241,28.628]],
 [[77.031,28.683],[77.131,28.674],[77.165,28.699],[77.171,28.733]],
 [[77.241,28.628],[77.27,28.66],[77.289,28.673],[77.316,28.647]],
 [[77.271,28.530],[77.25,28.58],[77.241,28.628]]
];
const SCHOOLS=[[77.309,28.656],[77.323,28.637],[77.298,28.668],[77.336,28.631],[77.282,28.678]];
const AQI={
 dark:['#3FB871','#9CCB4E','#E8C53A','#F08C35','#E5484D','#C43A6B'],
 light:['#1E8A4C','#5E8F1B','#8A6D00','#B35609','#C02A2A','#7F1D3A']
};
const BANDS=['Good','Satisfactory','Moderate','Poor','Very Poor','Severe'];
const band=v=>v<=30?0:v<=60?1:v<=90?2:v<=120?3:v<=250?4:5;
const THEME={
 dark:{bg:'#0E1417',land:'#121A1E',outline:'#2E3B45',river:'#1A2A33',text:'#E6EDF0',muted:'#8B9AA3',border:'#24303A',panel:'#151D21',teal:'#2DD4BF',trail:'rgba(230,237,240,.22)'},
 light:{bg:'#F2F0EB',land:'#FAF9F6',outline:'#CFCAC0',river:'#D6E2E4',text:'#0B1215',muted:'#5F6B70',border:'#E6E3DC',panel:'#FFFFFF',teal:'#0F766E',trail:'rgba(11,18,21,.25)'}
};
function rng(seed){return function(){seed|=0;seed=seed+0x6D2B79F5|0;let t=Math.imul(seed^seed>>>15,1|seed);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}
const R=rng(42),NG=40,NGRID=[];for(let i=0;i<(NG+1)*(NG+1);i++)NGRID.push(R());
function noise(x,y){const c=v=>Math.min(NG,Math.max(0,v));const xi=Math.floor(x),yi=Math.floor(y),u0=x-xi,v0=y-yi,s=t=>t*t*(3-2*t),u=s(u0),v=s(v0),g=(a,b)=>NGRID[c(b)*(NG+1)+c(a)];return(g(xi,yi)*(1-u)+g(xi+1,yi)*u)*(1-v)+(g(xi,yi+1)*(1-u)+g(xi+1,yi+1)*u)*v;}
const MINI=[];for(let i=0;i<22;i++){MINI.push({x:4+R()*(W_KM-8),y:4+R()*(H_KM-8),a:30+R()*70,s:0.5+R()*0.7});}
function episode(h){return 1+0.14*(Math.cos(2*Math.PI*(h-18)/24)-Math.cos(2*Math.PI*(-18)/24))+0.2*Math.exp(-Math.pow((h-42)/12,2));}
const TREATED={anand:0.72,shahdara:0.8,ito:0.78,ghazipur:0.74,okhla:0.8,jahangirpuri:0.82};
function field(x,y,mode,hour){
 const nx=x/W_KM,ny=y/H_KM,f=episode(hour||0);
 let base=148+60*Math.max(0,(1-nx)*0.6+(1-ny)*0.4-0.3)+44*(noise(nx*9,ny*9)-.5)+22*(noise(nx*26+3,ny*26+5)-.5);
 let hs=0;
 for(const h of HOTSPOTS){const d2=(x-h.x)**2+(y-h.y)**2;let a=(h.pm-160);if(mode==='plan'&&TREATED[h.id])a*=TREATED[h.id];hs+=a*Math.exp(-d2/(2*h.sigma*h.sigma));}
 for(const m of MINI){const d2=(x-m.x)**2+(y-m.y)**2;hs+=m.a*Math.exp(-d2/(2*m.s*m.s));}
 return base*(0.62+0.38*f)+hs*f;
}
function alphaFor(v){const b=band(v);if(b===5)return .5+Math.min(1,(v-250)/210)*.42;if(b===4)return .07+(v-121)/129*.17;if(b===3)return .08;return .07;}
function hexA(hex,a){const n=parseInt(hex.slice(1),16);return `rgba(${n>>16&255},${n>>8&255},${n&255},${a.toFixed(3)})`;}
function polyLen(p){let L=[0];for(let i=1;i<p.length;i++)L.push(L[i-1]+Math.hypot(p[i][0]-p[i-1][0],p[i][1]-p[i-1][1]));return L;}
function along(p,L,t){const d=t*L[L.length-1];for(let i=1;i<p.length;i++){if(d<=L[i]){const r=(d-L[i-1])/((L[i]-L[i-1])||1);return[p[i-1][0]+(p[i][0]-p[i-1][0])*r,p[i-1][1]+(p[i][1]-p[i-1][1])*r];}}return p[p.length-1];}
const CAUSE_ICON={Dust:'wind',Traffic:'car',Burning:'flame','Regional smoke':'cloud-fog'};
const reduced=()=>window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches;

/* ---------- hc-icon ---------- */
const pascal=s=>s.split('-').map(w=>w.charAt(0).toUpperCase()+w.slice(1)).join('');
class HcIcon extends HTMLElement{
 static get observedAttributes(){return['name','size','stroke'];}
 connectedCallback(){this.style.display='inline-flex';this.style.flex='none';this.style.lineHeight='0';this.draw();}
 attributeChangedCallback(){this.draw();}
 draw(){
  if(!this.isConnected)return;
  const L=window.lucide;if(!L||!L.icons){clearTimeout(this._t);this._t=setTimeout(()=>this.draw(),60);return;}
  let node=L.icons[pascal(this.getAttribute('name')||'circle')];if(!node){(this.shadowRoot||this.attachShadow({mode:'open'})).innerHTML='';return;}
  if(node[0]==='svg')node=node[2];
  const sz=this.getAttribute('size')||16,sw=this.getAttribute('stroke')||1.75;
  const ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg');
  Object.entries({width:sz,height:sz,viewBox:'0 0 24 24',fill:'none',stroke:'currentColor','stroke-width':sw,'stroke-linecap':'round','stroke-linejoin':'round','aria-hidden':'true'}).forEach(([k,v])=>svg.setAttribute(k,v));
  node.forEach(([tag,attrs])=>{const el=document.createElementNS(ns,tag);Object.entries(attrs).forEach(([k,v])=>el.setAttribute(k,v));svg.appendChild(el);});
  (this.shadowRoot||this.attachShadow({mode:'open'})).replaceChildren(svg);
 }
}
customElements.define('hc-icon',HcIcon);

/* ---------- hawa-map ---------- */
const MAP_CSS=`:host{display:block;position:relative;overflow:hidden;contain:strict}
canvas{position:absolute;inset:0;width:100%;height:100%}
.ov{position:absolute;inset:0;pointer-events:none;font-family:'Geist',system-ui,sans-serif}
.hs{position:absolute;width:0;height:0;pointer-events:auto;cursor:pointer}
.hs i{position:absolute;left:-5px;top:-5px;width:10px;height:10px;border-radius:50%;box-sizing:border-box}
.hs .core{border:2px solid var(--bg)}
.hs .ring{animation:hp 2.4s cubic-bezier(.2,.6,.3,1) infinite;opacity:0}
.hs.sel .core{outline:2px solid var(--text);outline-offset:3px}
@keyframes hp{0%{transform:scale(1);opacity:.7}100%{transform:scale(4.2);opacity:0}}
.lab{position:absolute;transform:translate(10px,-50%);display:flex;align-items:center;gap:6px;white-space:nowrap;padding:3px 7px 3px 6px;border-radius:6px;background:var(--lbg);border:1px solid var(--border);color:var(--text);font-size:11px;line-height:16px;pointer-events:auto;cursor:pointer;transition:border-color .15s ease-out}
.lab:hover{border-color:var(--muted)}
.lab b{font-weight:500}
.mono{font-family:'Geist Mono',ui-monospace,monospace;font-variant-numeric:tabular-nums}
.u{color:var(--muted)}
.cz{display:inline-flex;align-items:center;gap:3px;color:var(--muted);font-size:10px;padding-left:6px;border-left:1px solid var(--border)}
.pl{position:absolute;transform:translate(-50%,-50%);color:var(--muted);font-size:10.5px;letter-spacing:.02em;white-space:nowrap}
.tk{position:absolute;left:0;top:0;display:flex;align-items:center;gap:4px;will-change:transform}
.tk .b{width:18px;height:18px;margin:-9px 0 0 -9px;border-radius:5px;background:var(--bg);border:1.5px solid var(--teal);color:var(--teal);display:grid;place-items:center;box-sizing:border-box}
.tk.us .b{border-color:var(--muted);color:var(--muted)}
.tk .t{font-family:'Geist Mono',monospace;font-size:10px;color:var(--text);background:var(--lbg);padding:0 4px;border-radius:3px;margin-top:-9px}
.bus{position:absolute;left:0;top:0;width:6px;height:6px;margin:-3px 0 0 -3px;border-radius:50%;background:var(--text);box-shadow:0 0 0 3px var(--halo);will-change:transform}
.sc{position:absolute;width:14px;height:14px;margin:-7px 0 0 -7px;border-radius:3px;background:var(--bg);border:1px solid var(--text);color:var(--text);display:grid;place-items:center;font:600 8px 'Geist',sans-serif}
.sp{position:absolute;width:9px;height:9px;margin:-5px 0 0 -5px;transform:rotate(45deg);background:var(--bg);border:1.5px solid var(--text)}
.spl{position:absolute;transform:translate(10px,-50%);font-size:10.5px;color:var(--text);background:var(--lbg);border:1px dashed var(--muted);padding:1px 6px;border-radius:4px;white-space:nowrap}
.dn{position:absolute;transform:translate(-50%,-150%);font:10px 'Geist Mono',monospace;color:var(--text);background:var(--lbg);padding:0 3px;border-radius:3px}`;
class HawaMap extends HTMLElement{
 static get observedAttributes(){return['theme','mode','hour','layers','selected','center','zoom','labels','cell'];}
 constructor(){super();const r=this.attachShadow({mode:'open'});r.innerHTML=`<style>${MAP_CSS}</style><canvas></canvas><div class="ov"></div>`;this.cv=r.querySelector('canvas');this.ov=r.querySelector('.ov');this._vals={};}
 connectedCallback(){this.ro=new ResizeObserver(()=>this.render());this.ro.observe(this);this.render();this.loop();}
 disconnectedCallback(){this.ro&&this.ro.disconnect();__caf(this._raf);}
 attributeChangedCallback(){__caf(this._rq);this._rq=__raf(()=>this.render());}
 get t(){return THEME[this.getAttribute('theme')||'dark'];}
 cells(){
  if(this._cells&&this._cellKm===this.cellKm)return this._cells;
  const c=this.cellKm,r=c/Math.sqrt(3),out=[];let row=0;
  for(let y=0;y<H_KM;y+=1.5*r,row++){for(let x=(row%2?c/2:0);x<W_KM;x+=c){if(inPoly(x,y,OUTLINE))out.push([x,y]);}}
  this._cellKm=c;this._r=r;this._vals={};return this._cells=out;
 }
 vals(mode,hour){const k=mode+'|'+hour;if(!this._vals[k]){const m=(mode==='plan')?'plan':'live';this._vals[k]=this._cells.map(([x,y])=>field(x,y,m,hour));}return this._vals[k];}
 render(){
  const W=this.clientWidth,H=this.clientHeight;if(!W||!H)return;
  this.cellKm=parseFloat(this.getAttribute('cell')||'0.5');
  const th=this.t,dpr=Math.min(2,window.devicePixelRatio||1),cv=this.cv,ctx=cv.getContext('2d');
  cv.width=W*dpr;cv.height=H*dpr;ctx.setTransform(dpr,0,0,dpr,0,0);
  const mode=this.getAttribute('mode')||'live',hour=parseFloat(this.getAttribute('hour')||'0');
  const layers=(this.getAttribute('layers')||'heat,hotspots,labels,trucks,trails').split(',');
  const has=l=>layers.includes(l);
  const zoom=parseFloat(this.getAttribute('zoom')||'1');
  const cen=(this.getAttribute('center')||'').split(',').map(Number);
  const [cx,cy]=cen.length===2&&!isNaN(cen[0])?km(cen[0],cen[1]):[W_KM/2,H_KM/2];
  const s=Math.min(W/W_KM,H/H_KM)*0.96*zoom;
  const P=(x,y)=>[(x-cx)*s+W/2,(y-cy)*s+H/2];
  this._P=P;this._s=s;
  ctx.fillStyle=th.bg;ctx.fillRect(0,0,W,H);
  ctx.beginPath();OUTLINE.forEach((p,i)=>{const q=P(p[0],p[1]);i?ctx.lineTo(q[0],q[1]):ctx.moveTo(q[0],q[1]);});ctx.closePath();ctx.fillStyle=th.land;ctx.fill();
  const cells=this.cells(),r=this._r*s*0.9;
  if(has('heat')){
   const vals=this.vals(mode,hour),pal=AQI[this.getAttribute('theme')==='light'?'light':'dark'],mono=mode==='donor';
   const hx=[];for(let i=0;i<6;i++){const a=Math.PI/180*(60*i-30);hx.push([Math.cos(a)*r,Math.sin(a)*r]);}
   for(let i=0;i<cells.length;i++){
    const q=P(cells[i][0],cells[i][1]);if(q[0]<-r||q[1]<-r||q[0]>W+r||q[1]>H+r)continue;
    const v=vals[i];let a=alphaFor(v);
    ctx.fillStyle=mono?(this.getAttribute('theme')==='light'?`rgba(11,18,21,${(a*.35).toFixed(3)})`:`rgba(230,237,240,${(a*.28).toFixed(3)})`):hexA(pal[band(v)],a*(this.getAttribute('theme')==='light'?0.85:1));
    if(r<2.2){ctx.fillRect(q[0]-r,q[1]-r,r*2,r*2);continue;}
    ctx.beginPath();ctx.moveTo(q[0]+hx[0][0],q[1]+hx[0][1]);for(let k=1;k<6;k++)ctx.lineTo(q[0]+hx[k][0],q[1]+hx[k][1]);ctx.closePath();ctx.fill();
   }
  }
  ctx.lineJoin='round';ctx.lineCap='round';
  ctx.beginPath();YAMUNA.forEach((p,i)=>{const q=P(p[0],p[1]);i?ctx.lineTo(q[0],q[1]):ctx.moveTo(q[0],q[1]);});ctx.strokeStyle=th.river;ctx.lineWidth=Math.max(2,s*0.35);ctx.stroke();
  ctx.beginPath();OUTLINE.forEach((p,i)=>{const q=P(p[0],p[1]);i?ctx.lineTo(q[0],q[1]):ctx.moveTo(q[0],q[1]);});ctx.closePath();ctx.strokeStyle=th.outline;ctx.lineWidth=1;ctx.stroke();
  const line=(pts,color,w,dash)=>{ctx.beginPath();pts.forEach((p,i)=>{const k=km(p[0],p[1]),q=P(k[0],k[1]);i?ctx.lineTo(q[0],q[1]):ctx.moveTo(q[0],q[1]);});ctx.strokeStyle=color;ctx.lineWidth=w;ctx.setLineDash(dash||[]);ctx.stroke();ctx.setLineDash([]);};
  if(has('trails'))BUSES.forEach(b=>{line(b,th.trail,1.2,[1,4]);});
  const routeKey=mode==='usual'?'usual':mode==='plan'?'plan':'live';
  if(has('trucks'))ASSETS.forEach(a=>line(a[routeKey],mode==='usual'?th.muted:th.teal,1.5,[4,4]));
  if(mode==='donor'){
   const tgt=HOTSPOTS[1],D=[[3.2,-2.1,.31],[-4.1,1.2,.24],[1.4,4.3,.19],[-2.6,-3.8,.14],[5.1,2.6,.12]];
   const hexAt=(x,y,stroke,dash,w)=>{const q=P(x,y);ctx.beginPath();for(let k=0;k<6;k++){const a=Math.PI/180*(60*k-30);const px=q[0]+Math.cos(a)*r*1.9,py=q[1]+Math.sin(a)*r*1.9;k?ctx.lineTo(px,py):ctx.moveTo(px,py);}ctx.closePath();ctx.strokeStyle=stroke;ctx.lineWidth=w;ctx.setLineDash(dash);ctx.stroke();ctx.setLineDash([]);};
   hexAt(tgt.x,tgt.y,th.teal,[],2);D.forEach(d=>hexAt(tgt.x+d[0],tgt.y+d[1],th.text,[3,3],1.2));
   this._donors=D.map(d=>({q:P(tgt.x+d[0],tgt.y+d[1]),w:d[2]}));this._tgt=P(tgt.x,tgt.y);
  }else this._donors=null;
  const sel=this.getAttribute('selected'),sh=HOTSPOTS.find(h=>h.id===sel);
  if(sh&&has('hotspots')){const a=P(sh.x,sh.y),b=P(sh.x-1.5,sh.y-1.3);ctx.beginPath();ctx.moveTo(a[0],a[1]);ctx.lineTo(b[0],b[1]);ctx.strokeStyle=th.text;ctx.setLineDash([3,3]);ctx.lineWidth=1;ctx.stroke();ctx.setLineDash([]);this._sp=b;}else this._sp=null;
  this.overlay(th,has,mode,hour,sh,routeKey);
 }
 overlay(th,has,mode,hour,sh,routeKey){
  const P=this._P,ov=this.ov,f=episode(hour),pal=AQI[this.getAttribute('theme')==='light'?'light':'dark'];
  ov.style.cssText=`--bg:${th.bg};--text:${th.text};--muted:${th.muted};--border:${th.border};--teal:${th.teal};--lbg:${this.getAttribute('theme')==='light'?'rgba(255,255,255,.94)':'rgba(14,20,23,.9)'};--halo:${this.getAttribute('theme')==='light'?'rgba(11,18,21,.12)':'rgba(230,237,240,.14)'}`;
  let h='';const lab=this.getAttribute('labels')||'full';
  if(has('places'))Object.values(PLACES).forEach(p=>{const k=km(p[1],p[2]),q=P(k[0],k[1]);h+=`<div class="pl" style="left:${q[0]}px;top:${q[1]+14}px">${p[0]}</div>`;});
  if(has('schools'))SCHOOLS.forEach(s=>{const k=km(s[0],s[1]),q=P(k[0],k[1]);h+=`<div class="sc" style="left:${q[0]}px;top:${q[1]}px">S</div>`;});
  if(has('hotspots'))HOTSPOTS.forEach(o=>{
   const q=P(o.x,o.y);let v=Math.round(o.pm*f*(mode==='plan'&&TREATED[o.id]?TREATED[o.id]:1));const c=pal[band(v)];
   h+=`<div class="hs${sh===o?' sel':''}" data-id="${o.id}" style="left:${q[0]}px;top:${q[1]}px"><i class="ring" style="display:${lab==='top'&&o.pm<380&&sh!==o?'none':'block'};background:${c};animation-delay:${(o.x%2.4).toFixed(2)}s"></i><i class="core" style="background:${c}"></i></div>`;
   if(lab!=='none'&&(lab==='full'||sh===o||(lab==='top'&&o.pm>=380)))h+=`<div class="lab" data-id="${o.id}" style="left:${q[0]}px;top:${q[1]}px"><b>${o.place}</b><span class="mono">${v}<span class="u"> µg/m³</span></span><span class="cz"><hc-icon name="${CAUSE_ICON[o.cause]}" size="11"></hc-icon>${o.cause}</span></div>`;
  });
  if(this._sp)h+=`<div class="sp" style="left:${this._sp[0]}px;top:${this._sp[1]}px"></div><div class="spl" style="left:${this._sp[0]}px;top:${this._sp[1]}px">Upwind suspect · ${sh.suspect}</div>`;
  if(this._donors){this._donors.forEach(d=>{h+=`<div class="dn" style="left:${d.q[0]}px;top:${d.q[1]}px">w ${d.w.toFixed(2)}</div>`;});h+=`<div class="spl" style="left:${this._tgt[0]+14}px;top:${this._tgt[1]}px;border-style:solid;border-color:${th.teal}">Treated cell · Anand Vihar</div>`;}
  if(has('trails'))BUSES.forEach((b,i)=>{h+=`<div class="bus" data-bus="${i}"></div>`;});
  if(has('trucks'))ASSETS.forEach((a,i)=>{h+=`<div class="tk${mode==='usual'?' us':''}" data-tk="${i}"><div class="b"><hc-icon name="${a.icon}" size="11" stroke="2"></hc-icon></div><span class="t">${a.id}</span></div>`;});
  ov.innerHTML=h;
  ov.querySelectorAll('[data-id]').forEach(el=>el.addEventListener('click',()=>this.dispatchEvent(new CustomEvent('hc-hotspot',{detail:{id:el.dataset.id},bubbles:true,composed:true}))));
  this._tks=[...ov.querySelectorAll('[data-tk]')].map(el=>{const a=ASSETS[+el.dataset.tk],p=a[routeKey].map(pt=>km(pt[0],pt[1]));return{el,p,L:polyLen(p),ph:(+el.dataset.tk*0.37)%1,per:14+(+el.dataset.tk%3)*4};});
  this._bs=[...ov.querySelectorAll('[data-bus]')].map(el=>{const b=BUSES[+el.dataset.bus].map(pt=>km(pt[0],pt[1]));return{el,p:b,L:polyLen(b),ph:+el.dataset.bus*0.23,per:40};});
  this.tick(performance.now());
 }
 tick(now){
  const P=this._P;if(!P)return;const t=reduced()?0:now/1000;
  const pos=(o,pingpong)=>{let u=(t/o.per+o.ph)%1;if(pingpong)u=u<.5?u*2:2-u*2;const k=along(o.p,o.L,u),q=P(k[0],k[1]);o.el.style.transform=`translate(${q[0]}px,${q[1]}px)`;};
  (this._tks||[]).forEach(o=>pos(o,true));(this._bs||[]).forEach(o=>pos(o,false));
 }
 loop(){const f=n=>{this.tick(n);this._raf=__raf(f);};if(!reduced())this._raf=__raf(f);}
}
customElements.define('hawa-map',HawaMap);

/* ---------- hc-chart ---------- */
function fmtH(h){const d=['Tue','Wed','Thu','Fri','Sat'];const abs=14+h;const day=Math.floor(abs/24),hr=((abs%24)+24)%24;return (d[day+ (abs<0?-1:0)]||'Mon')+' '+String(hr).padStart(2,'0')+':00';}
class HcChart extends HTMLElement{
 static get observedAttributes(){return['type','theme','height','value','hour','effect'];}
 connectedCallback(){this.style.display='block';this.ro=new ResizeObserver(()=>this.draw());this.ro.observe(this);this.draw();}
 disconnectedCallback(){this.ro&&this.ro.disconnect();}
 attributeChangedCallback(){this.draw();}
 draw(){
  const W=this.clientWidth;if(!W)return;const H=+(this.getAttribute('height')||220),th=THEME[this.getAttribute('theme')||'dark'],type=this.getAttribute('type')||'impact';
  const light=this.getAttribute('theme')==='light',pal=AQI[light?'light':'dark'];
  const grid=light?'#ECE9E2':'#1E282E',ink=th.text,mut=th.muted,band=light?'rgba(11,18,21,.07)':'rgba(230,237,240,.08)';
  const mono=`font-family:'Geist Mono',monospace;font-size:10.5px;fill:${mut}`;
  let s='';
  if(type==='impact'){
   const pad={l:38,r:12,t:18,b:24},iw=W-pad.l-pad.r,ih=H-pad.t-pad.b,N=49,Rr=rng(7);
   const ctrl=[],obs=[];for(let i=0;i<N;i++){const c=402+i*0.9+14*Math.sin(i/5)+(Rr()-.5)*8;ctrl.push(c);let o=c+(Rr()-.5)*10;if(i>=13&&i<=34){const k=Math.min(1,(i-13)/2)*(i>30?Math.max(0,(34-i)/4):1);o=c*(1-0.18*k)+(Rr()-.5)*8;}obs.push(o);}
   const y0=250,y1=500,X=i=>pad.l+i/(N-1)*iw,Y=v=>pad.t+(1-(v-y0)/(y1-y0))*ih;
   for(let v=250;v<=500;v+=50)s+=`<line x1="${pad.l}" x2="${W-pad.r}" y1="${Y(v)}" y2="${Y(v)}" stroke="${grid}"/><text x="${pad.l-6}" y="${Y(v)+3.5}" text-anchor="end" style="${mono}">${v}</text>`;
   s+=`<rect x="${X(12)}" y="${pad.t}" width="${X(15)-X(12)}" height="${ih}" fill="${th.teal}" opacity="${light?.12:.16}"/><text x="${X(12)+4}" y="${pad.t+11}" style="font:500 10.5px Geist,sans-serif;fill:${th.teal}">Spray · T-12</text>`;
   const top=ctrl.map((c,i)=>[X(i),Y(c*(1.05+i*0.0008))]),bot=ctrl.map((c,i)=>[X(i),Y(c*(0.95-i*0.0008))]).reverse();
   s+=`<path d="M${top.map(p=>p.join(',')).join('L')}L${bot.map(p=>p.join(',')).join('L')}Z" fill="${band}"/>`;
   s+=`<path d="M${ctrl.map((c,i)=>X(i)+','+Y(c)).join('L')}" fill="none" stroke="${mut}" stroke-width="1.25" stroke-dasharray="4 3"/>`;
   s+=`<path d="M${obs.map((c,i)=>X(i)+','+Y(c)).join('L')}" fill="none" stroke="${ink}" stroke-width="1.75" stroke-linejoin="round"/>`;
   const yb=Y(ctrl[24]*0.82)+26;s+=`<path d="M${X(14)},${yb-5}V${yb}H${X(32)}V${yb-5}" fill="none" stroke="${ink}"/><text x="${(X(14)+X(32))/2}" y="${yb+13}" text-anchor="middle" style="font:500 11px 'Geist Mono',monospace;fill:${ink}">PM10 −18% · 90 min</text>`;
   ['05:30','06:30','07:30','08:30','09:30'].forEach((l,i)=>{s+=`<text x="${X(i*12)}" y="${H-6}" text-anchor="${i===0?'start':i===4?'end':'middle'}" style="${mono}">${l}</text>`;});
  }else if(type==='forecast'||type==='mini'){
   const compact=type==='mini',pad=compact?{l:30,r:6,t:8,b:18}:{l:38,r:12,t:14,b:24},iw=W-pad.l-pad.r,ih=H-pad.t-pad.b,v0=+(this.getAttribute('value')||300),Rr=rng(v0);
   const pts=[];for(let h=0;h<=72;h++){const p=v0*episode(h)*(1+(Rr()-.5)*0.04);pts.push([h,p*(0.84-h*0.0012),p,p*(1.14+h*0.003)]);}
   const y0=100,y1=Math.max(500,Math.ceil(Math.max(...pts.map(p=>p[3]))/100)*100),X=h=>pad.l+h/72*iw,Y=v=>pad.t+(1-(v-y0)/(y1-y0))*ih;
   [[100,120,3],[121,250,4],[251,y1,5]].forEach(([a,b,c])=>{s+=`<rect x="${pad.l}" width="${iw}" y="${Y(b)}" height="${Y(a)-Y(b)}" fill="${pal[c]}" opacity="${light?.07:.08}"/>`;});
   for(let v=y0;v<=y1;v+=100)s+=`<line x1="${pad.l}" x2="${W-pad.r}" y1="${Y(v)}" y2="${Y(v)}" stroke="${grid}"/><text x="${pad.l-5}" y="${Y(v)+3.5}" text-anchor="end" style="${mono}">${v}</text>`;
   s+=`<path d="M${pts.map(p=>X(p[0])+','+Y(p[3])).join('L')}L${pts.slice().reverse().map(p=>X(p[0])+','+Y(p[1])).join('L')}Z" fill="${band}"/>`;
   s+=`<path d="M${pts.map(p=>X(p[0])+','+Y(p[2])).join('L')}" fill="none" stroke="${ink}" stroke-width="1.6" stroke-linejoin="round"/>`;
   const hr=this.getAttribute('hour');if(hr!==null){const hx=X(+hr);s+=`<line x1="${hx}" x2="${hx}" y1="${pad.t}" y2="${pad.t+ih}" stroke="${th.teal}" stroke-width="1.25"/><circle cx="${hx}" cy="${Y(pts[Math.round(+hr)][2])}" r="3.5" fill="${th.teal}" stroke="${th.bg}" stroke-width="1.5"/>`;}
   [[0,'Now'],[18,'Wed 08'],[42,'Thu 08'],[66,'Fri 08']].forEach(([h,l],i)=>{s+=`<text x="${X(h)}" y="${H-5}" text-anchor="${i===0?'start':'middle'}" style="${mono}">${l}</text>`;});
  }else if(type==='spark'){
   const Rr=rng(+(this.getAttribute('value')||5)),n=24,a=[];for(let i=0;i<n;i++)a.push(0.5+0.3*Math.sin(i/3+Rr()*2)+(Rr()-.5)*.2);
   s+=`<path d="M${a.map((v,i)=>(i/(n-1)*W).toFixed(1)+','+((1-v)*H).toFixed(1)).join('L')}" fill="none" stroke="${mut}" stroke-width="1.25"/>`;
  }
  (this.shadowRoot||this.attachShadow({mode:'open'})).innerHTML=`<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" style="display:block;overflow:visible">${s}</svg>`;
 }
}
customElements.define('hc-chart',HcChart);

/* ---------- hc-count ---------- */
class HcCount extends HTMLElement{
 static get observedAttributes(){return['to'];}
 connectedCallback(){this.style.fontVariantNumeric='tabular-nums';this.cur=+(this.getAttribute('from')||0);(this.shadowRoot||this.attachShadow({mode:'open'})).textContent=this.fmt(this.cur);this.io=new IntersectionObserver(e=>{if(e[0].isIntersecting){this.seen=true;this.run();this.io.disconnect();}});this.io.observe(this);}
 disconnectedCallback(){this.io&&this.io.disconnect();__caf(this.r);}
 attributeChangedCallback(){if(this.seen)this.run();}
 fmt(v){const d=+(this.getAttribute('decimals')||0);return (this.getAttribute('prefix')||'')+v.toLocaleString('en-IN',{minimumFractionDigits:d,maximumFractionDigits:d})+(this.getAttribute('suffix')||'');}
 run(){const to=+(this.getAttribute('to')||0),from=this.cur,dur=+(this.getAttribute('dur')||900),t0=performance.now();__caf(this.r);if(reduced()){this.cur=to;(this.shadowRoot||this.attachShadow({mode:'open'})).textContent=this.fmt(to);return;}
  const step=n=>{const k=Math.min(1,(n-t0)/dur),e=1-Math.pow(1-k,3);this.cur=from+(to-from)*e;(this.shadowRoot||this.attachShadow({mode:'open'})).textContent=this.fmt(this.cur);if(k<1)this.r=__raf(step);};this.r=__raf(step);}
}
customElements.define('hc-count',HcCount);

/* ---------- hc-iso (hardware line art) ---------- */
const C30=Math.cos(Math.PI/6),S30=0.5;
function isoP(x,y,z,o,k){return[o[0]+(x-y)*C30*k,o[1]+(x+y)*S30*k-z*k];}
function box(x,y,z,w,d,h,o,k,st){const p=(a,b,c)=>isoP(a,b,c,o,k).map(n=>n.toFixed(1)).join(',');
 const top=`${p(x,y,z+h)} ${p(x+w,y,z+h)} ${p(x+w,y+d,z+h)} ${p(x,y+d,z+h)}`,left=`${p(x,y+d,z)} ${p(x+w,y+d,z)} ${p(x+w,y+d,z+h)} ${p(x,y+d,z+h)}`,right=`${p(x+w,y,z)} ${p(x+w,y+d,z)} ${p(x+w,y+d,z+h)} ${p(x+w,y,z+h)}`;
 return `<polygon points="${left}" ${st}/><polygon points="${right}" ${st}/><polygon points="${top}" ${st}/>`;}
function seg(a,b,o,k,st){const p=isoP(...a,o,k),q=isoP(...b,o,k);return `<line x1="${p[0]}" y1="${p[1]}" x2="${q[0]}" y2="${q[1]}" ${st}/>`;}
class HcIso extends HTMLElement{
 static get observedAttributes(){return['kind','theme'];}
 connectedCallback(){this.style.display='block';this.draw();}
 attributeChangedCallback(){this.draw();}
 draw(){
  const kind=this.getAttribute('kind')||'pod-m',th=THEME[this.getAttribute('theme')||'light'],bg=this.getAttribute('theme')==='dark'?th.panel:'#FFFFFF';
  const st=`fill="${bg}" stroke="${th.text}" stroke-width="1.1" stroke-linejoin="round"`,thin=`stroke="${th.text}" stroke-width="1" fill="none"`,acc=`stroke="${th.teal}" stroke-width="1.25" fill="none"`;
  const W=280,H=200,k=9;let s='';
  if(kind==='pod-m'){const o=[128,128];
   s+=box(-2,-2,0,17,12,0.6,o,k,st);s+=box(0,0,0.6,13,8,5,o,k,st);
   for(let i=0;i<5;i++)s+=seg([13,1.5+i*1.2,2],[13,1.5+i*1.2,4.6],o,k,thin);
   s+=box(9,1.8,5.6,2,2,4.4,o,k,st);s+=box(9,-3.4,8.4,2,5.2,1.6,o,k,st);
   s+=seg([2,6,5.6],[2,6,11],o,k,thin);const a=isoP(2,6,11,o,k);s+=`<circle cx="${a[0]}" cy="${a[1]}" r="2.4" ${st}/>`;
   const l=isoP(1.5,8,3,o,k);s+=`<circle cx="${l[0]}" cy="${l[1]}" r="2.2" ${acc}/>`;
  }else if(kind==='pod-s'){const o=[92,120];
   for(let i=0;i<5;i++)s+=box(0,0,i*1.6,7,7,0.9,o,k,st);s+=box(2,2,8,3,3,1.2,o,k,st);s+=seg([3.5,3.5,0],[3.5,3.5,-3],o,k,thin);
   const o2=[196,138];s+=box(0,0,0,8,4,6,o2,k*0.85,st);const sc=[isoP(1,4,1.2,o2,k*.85),isoP(6,4,1.2,o2,k*.85),isoP(6,4,4.6,o2,k*.85),isoP(1,4,4.6,o2,k*.85)];s+=`<polygon points="${sc.map(p=>p.join(',')).join(' ')}" ${acc}/>`;
   s+=box(8,1,1,2.2,2,3,o2,k*.85,st);
  }else{const o=[70,120];
   s+=box(0,0,0,24,3,3,o,k*0.8,st);s+=box(8,-0.6,3,5,4.2,2.6,o,k*0.8,st);
   for(let i=0;i<3;i++)s+=box(17+i*0.9,-0.4,-0.4,0.5,3.8,3.8,o,k*0.8,st);
   s+=box(6,-9,0,9,6,6,o,k*0.8,st);const c1=isoP(10.5,-3,4,o,k*.8),c2=isoP(10.5,-0.6,5,o,k*.8);s+=`<path d="M${c1[0]},${c1[1]} Q${c1[0]+12},${(c1[1]+c2[1])/2} ${c2[0]},${c2[1]}" ${thin}/>`;
   const l=isoP(11,-3,3,o,k*.8);s+=`<circle cx="${l[0]}" cy="${l[1]}" r="2.2" ${acc}/>`;
  }
  let dots='';for(let x=10;x<W;x+=20)for(let y=10;y<H;y+=20)dots+=`<circle cx="${x}" cy="${y}" r=".8" fill="${th.border}"/>`;
  (this.shadowRoot||this.attachShadow({mode:'open'})).innerHTML=`<svg viewBox="0 0 ${W} ${H}" width="100%" style="display:block">${dots}${s}</svg>`;
 }
}
customElements.define('hc-iso',HcIso);

window.Hawa={HOTSPOTS,ASSETS,AQI,BANDS,band,THEME,episode,fmtH,CAUSE_ICON};
})();
