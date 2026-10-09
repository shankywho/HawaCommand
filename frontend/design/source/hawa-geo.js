(function(){
if(customElements.get('hawa-geo'))return;
const KX=97.8,KY=111.2,LON0=76.84,LAT0=28.89;
const toKm=(lon,lat)=>[(lon-LON0)*KX,(LAT0-lat)*KY], toLL=(x,y)=>[LON0+x/KX,LAT0-y/KY];
const OUT=[[77.10,28.885],[77.18,28.87],[77.22,28.845],[77.235,28.79],[77.265,28.735],[77.33,28.705],[77.345,28.66],[77.338,28.60],[77.305,28.555],[77.31,28.50],[77.245,28.43],[77.17,28.405],[77.12,28.465],[77.10,28.52],[77.04,28.515],[76.96,28.55],[76.845,28.565],[76.84,28.64],[76.90,28.705],[76.95,28.765],[77.02,28.81],[77.06,28.86]];
function inPoly(x,y,p){let c=false;for(let i=0,j=p.length-1;i<p.length;j=i++){const[xi,yi]=p[i],[xj,yj]=p[j];if(((yi>y)!=(yj>y))&&(x<(xj-xi)*(y-yi)/(yj-yi)+xi))c=!c;}return c;}
const HOT=[
 {id:'ghazipur',place:'Ghazipur landfill',area:'East Delhi',lon:77.329,lat:28.625,pm:388,cause:'Burning',sig:1.2,tr:.74},
 {id:'anand',place:'Anand Vihar ISBT',area:'East Delhi',lon:77.316,lat:28.647,pm:212,cause:'Dust',sig:1.0,tr:.72},
 {id:'shahdara',place:'Shahdara, GT Road',area:'Shahdara',lon:77.289,lat:28.673,pm:341,cause:'Traffic',sig:1.3,tr:.8},
 {id:'ito',place:'ITO crossing',area:'Central Delhi',lon:77.241,lat:28.629,pm:296,cause:'Traffic',sig:1.1,tr:.78},
 {id:'wazirpur',place:'Wazirpur industrial area',area:'North West',lon:77.165,lat:28.700,pm:402,cause:'Burning',sig:1.2,tr:1},
 {id:'mundka',place:'Mundka',area:'West Delhi',lon:77.035,lat:28.682,pm:437,cause:'Regional smoke',sig:2.2,tr:1},
 {id:'jahangirpuri',place:'Jahangirpuri',area:'North West',lon:77.171,lat:28.733,pm:364,cause:'Dust',sig:1.2,tr:.82},
 {id:'okhla',place:'Okhla Phase-2',area:'South East',lon:77.271,lat:28.531,pm:318,cause:'Dust',sig:1.2,tr:.8},
 {id:'punjabi',place:'Punjabi Bagh',area:'West Delhi',lon:77.131,lat:28.674,pm:279,cause:'Traffic',sig:1.1,tr:1}];
const ST=[['Anand Vihar',28.647,77.316],['ITO',28.629,77.241],['RK Puram',28.563,77.187],['Punjabi Bagh',28.674,77.131],['Okhla Ph-2',28.531,77.271],['Dwarka Sec-8',28.571,77.072],['Jahangirpuri',28.733,77.171],['Mundka',28.682,77.035],['Wazirpur',28.700,77.165],['Bawana',28.776,77.051],['Nehru Nagar',28.568,77.251]];
const SCHOOLS=[[77.309,28.656],[77.323,28.637],[77.298,28.668],[77.336,28.631],[77.282,28.678]];
const ASSETS=[
 {id:'T-12',icon:'truck',plan:[[77.305,28.636],[77.316,28.647],[77.325,28.627]],usual:[[77.293,28.604],[77.306,28.614]]},
 {id:'ASG-07',icon:'spray-can',plan:[[77.303,28.652],[77.315,28.648]],usual:[[77.303,28.652],[77.296,28.660]]},
 {id:'SW-03',icon:'brush',plan:[[77.315,28.672],[77.316,28.649]],usual:[[77.300,28.700],[77.312,28.690]]},
 {id:'I-3',icon:'users',plan:[[77.296,28.628],[77.329,28.625]],usual:[[77.296,28.628],[77.300,28.640]]},
 {id:'T-07',icon:'truck',plan:[[77.241,28.629],[77.268,28.636]],usual:[[77.225,28.615],[77.235,28.600]]},
 {id:'T-19',icon:'truck',plan:[[77.271,28.531],[77.251,28.568]],usual:[[77.245,28.545],[77.262,28.566]]}];
const TRAILS=[[[77.072,28.571],[77.162,28.592],[77.187,28.563],[77.241,28.629]],[[77.035,28.682],[77.131,28.674],[77.165,28.700],[77.171,28.733]],[[77.241,28.629],[77.289,28.673],[77.316,28.647]],[[77.271,28.531],[77.251,28.568],[77.241,28.629]],[[77.051,28.776],[77.171,28.733]]];
const ANCH=[['Ring Road',77.205,28.566],['NH-24',77.300,28.612],['NH-9',77.075,28.676],['Yamuna',77.262,28.664]];
const AQ={dark:['#3FB871','#9CCB4E','#E8C53A','#F08C35','#E5484D','#C43A6B'],light:['#1E8A4C','#5E8F1B','#C9A100','#D9731C','#C02A2A','#7F1D3A']};
const CI={Dust:'wind',Traffic:'car',Burning:'flame','Regional smoke':'cloud-fog'};
const band=v=>v<=30?0:v<=60?1:v<=90?2:v<=120?3:v<=250?4:5;
const ep=h=>1+0.14*(Math.cos(2*Math.PI*(h-18)/24)-Math.cos(2*Math.PI*(-18)/24))+0.2*Math.exp(-Math.pow((h-42)/12,2));
function rng(s){return()=>{s|=0;s=s+0x6D2B79F5|0;let t=Math.imul(s^s>>>15,1|s);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}
const R=rng(42),NG=40,GR=[];for(let i=0;i<(NG+1)**2;i++)GR.push(R());
function noise(x,y){const c=v=>Math.min(NG,Math.max(0,v)),xi=Math.floor(x),yi=Math.floor(y),s=t=>t*t*(3-2*t),u=s(x-xi),v=s(y-yi),g=(a,b)=>GR[c(b)*(NG+1)+c(a)];return(g(xi,yi)*(1-u)+g(xi+1,yi)*u)*(1-v)+(g(xi,yi+1)*(1-u)+g(xi+1,yi+1)*u)*v;}
const WK=(77.36-LON0)*KX,HK=(LAT0-28.40)*KY;
HOT.forEach(h=>{[h.x,h.y]=toKm(h.lon,h.lat);});
const MINI=[];for(let i=0;i<22;i++)MINI.push([4+R()*(WK-8),4+R()*(HK-8),30+R()*70,.5+R()*.7]);
function pmAt(x,y,hour,mix){const nx=x/WK,ny=y/HK,f=ep(hour);let b=148+60*Math.max(0,(1-nx)*.6+(1-ny)*.4-.3)+44*(noise(nx*9,ny*9)-.5)+22*(noise(nx*26+3,ny*26+5)-.5),hs=0;
 for(const h of HOT){const a=(h.pm-160)*(1-(1-h.tr)*mix);hs+=a*Math.exp(-((x-h.x)**2+(y-h.y)**2)/(2*h.sig*h.sig));}
 for(const m of MINI)hs+=m[2]*Math.exp(-((x-m[0])**2+(y-m[1])**2)/(2*m[3]*m[3]));return b*(.62+.38*f)+hs*f;}
const HR=0.29,HEX=[];{const w=Math.sqrt(3)*HR;let row=0;for(let y=0;y<HK;y+=1.5*HR,row++)for(let x=row%2?w/2:0;x<WK;x+=w){const ll=toLL(x,y);if(inPoly(ll[0],ll[1],OUT))HEX.push([x,y]);}}
function hexPoly(x,y,k){const p=[];for(let i=0;i<=6;i++){const a=Math.PI/180*(60*(i%6)-30);p.push(toLL(x+Math.cos(a)*HR*k,y+Math.sin(a)*HR*k));}return p;}
const GEOM=HEX.map(([x,y])=>hexPoly(x,y,.9));
const cache={};function osrm(pts){const key='hc-osrm-'+pts.map(p=>p.join(',')).join(';');if(cache[key])return cache[key];
 cache[key]=new Promise(res=>{try{const s=localStorage.getItem(key);if(s)return res(JSON.parse(s));}catch(e){}
  const ctl=new AbortController();setTimeout(()=>ctl.abort(),5000);
  fetch('https://router.project-osrm.org/route/v1/driving/'+pts.map(p=>p.join(',')).join(';')+'?overview=full&geometries=geojson',{signal:ctl.signal}).then(r=>r.json()).then(j=>{const c=j.routes&&j.routes[0]&&j.routes[0].geometry.coordinates;if(c&&c.length>1){try{localStorage.setItem(key,JSON.stringify(c));}catch(e){}res(c);}else res(pts);}).catch(()=>res(pts));});return cache[key];}
function plen(p){const L=[0];for(let i=1;i<p.length;i++)L.push(L[i-1]+Math.hypot((p[i][0]-p[i-1][0])*KX,(p[i][1]-p[i-1][1])*KY));return L;}
function along(p,L,u){const d=u*L[L.length-1];for(let i=1;i<p.length;i++)if(d<=L[i]){const r=(d-L[i-1])/((L[i]-L[i-1])||1);return[p[i-1][0]+(p[i][0]-p[i-1][0])*r,p[i-1][1]+(p[i][1]-p[i-1][1])*r];}return p[p.length-1];}
const TH={dark:{style:'https://tiles.openfreemap.org/styles/dark',text:'#E6EDF0',muted:'#8B9AA3',bg:'rgba(14,20,23,.9)',border:'#24303A',teal:'#2DD4BF',major:'#4A5A66',bld:'#1C262C',trail:'#C5D0D6',usual:'#8B9AA3'},
 light:{style:'https://tiles.openfreemap.org/styles/positron',text:'#0B1215',muted:'#5F6B70',bg:'rgba(255,255,255,.95)',border:'#E6E3DC',teal:'#0F766E',major:'#B9B2A5',bld:'#E4DFD5',trail:'#3B474D',usual:'#5F6B70'}};
const CSS=`:host{display:block;position:relative;overflow:hidden}.m{position:absolute;inset:0}.maplibregl-ctrl-attrib{font:10px Geist,sans-serif!important}
.hs{position:relative;width:0;height:0;cursor:pointer}.hs i{position:absolute;left:-5px;top:-5px;width:10px;height:10px;border-radius:50%}.hs .c{border:2px solid var(--bgs)}.hs .r{animation:p 2.4s cubic-bezier(.2,.6,.3,1) infinite;opacity:0}.hs.sel .c{outline:2px solid var(--t);outline-offset:3px}
@keyframes p{0%{transform:scale(1);opacity:.7}100%{transform:scale(4.2);opacity:0}}@media (prefers-reduced-motion:reduce){.hs .r{animation:none}}
.lab{position:absolute;left:10px;top:-11px;display:flex;align-items:center;gap:6px;white-space:nowrap;padding:2px 7px 2px 6px;border-radius:6px;background:var(--b);border:1px solid var(--br);color:var(--t);font:11px/16px Geist,sans-serif}.lab b{font-weight:500}.mn{font-family:'Geist Mono',monospace;font-variant-numeric:tabular-nums}.u{color:var(--mu)}.cz{display:inline-flex;align-items:center;gap:3px;color:var(--mu);font-size:10px;padding-left:6px;border-left:1px solid var(--br)}
.st{width:8px;height:8px;background:var(--t);border:2px solid var(--bgs);box-sizing:content-box}.stl{position:absolute;left:8px;top:-4px;font:10px 'Geist Mono',monospace;color:var(--mu);white-space:nowrap;text-shadow:0 0 3px var(--bgs),0 0 3px var(--bgs)}
.tk{display:flex;align-items:center;gap:4px}.tk .b{width:18px;height:18px;border-radius:5px;background:var(--bgs);border:1.5px solid var(--te);color:var(--te);display:grid;place-items:center;box-sizing:border-box}.tk.us .b{border-color:var(--us);color:var(--us)}.tk .t{font:10px 'Geist Mono',monospace;color:var(--t);background:var(--b);padding:0 4px;border-radius:3px}
.bus{width:6px;height:6px;border-radius:50%;background:var(--t);box-shadow:0 0 0 3px rgba(128,128,128,.25)}.sc{width:14px;height:14px;border-radius:3px;background:var(--bgs);border:1px solid var(--t);color:var(--t);display:grid;place-items:center;font:600 8px Geist,sans-serif}
.an{font:italic 11px Geist,sans-serif;color:var(--mu);white-space:nowrap;text-shadow:0 0 3px var(--bgs),0 0 3px var(--bgs);letter-spacing:.02em}.sp{width:9px;height:9px;transform:rotate(45deg);background:var(--bgs);border:1.5px solid var(--t)}.spl{position:absolute;left:10px;top:-10px;font:10.5px Geist,sans-serif;color:var(--t);background:var(--b);border:1px dashed var(--mu);padding:1px 6px;border-radius:4px;white-space:nowrap}
.dn{font:10px 'Geist Mono',monospace;color:var(--t);background:var(--b);padding:0 3px;border-radius:3px}.fb{position:absolute;inset:0;display:grid;place-items:center;font:12px 'Geist Mono',monospace;color:var(--mu)}`;
class HawaGeo extends HTMLElement{
 static get observedAttributes(){return['hour','mode','mix','layers','selected','center','zoom','pitch','bearing','labels'];}
 constructor(){super();const r=this.attachShadow({mode:'open'});r.innerHTML=`<link rel="stylesheet" href="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css"><style>${CSS}</style><div class="m"></div>`;this.box=r.querySelector('.m');this.mk={};}
 get th(){return this.getAttribute('theme')==='light'?'light':'dark';}
 num(a,d){const v=parseFloat(this.getAttribute(a));return isNaN(v)?d:v;}
 cam(){const c=(this.getAttribute('center')||'77.21,28.64').split(',').map(Number);return{center:c,zoom:this.num('zoom',9.6),pitch:this.num('pitch',0),bearing:this.num('bearing',0)};}
 connectedCallback(){this.vis=true;this.io=new IntersectionObserver(e=>{this.vis=e[e.length-1].isIntersecting;},{rootMargin:'200px'});this.io.observe(this);
  const T=TH[this.th];this.style.setProperty('--t',T.text);['--mu',T.muted,'--b',T.bg,'--br',T.border,'--te',T.teal,'--us',T.usual,'--bgs',this.th==='dark'?'#0E1417':'#FFFFFF'].reduce((a,v,i,arr)=>{if(i%2===0)this.style.setProperty(v,arr[i+1]);},0);
  let tries=0;const go=()=>{if(window.maplibregl)return this.init();if(++tries>100){this.shadowRoot.querySelector('.m').innerHTML='<div class="fb">Map unavailable offline</div>';return;}setTimeout(go,100);};go();}
 disconnectedCallback(){this.io&&this.io.disconnect();cancelAnimationFrame(this.raf);this.map&&this.map.remove();this.map=null;}
 attributeChangedCallback(n){if(!this.ready)return;if(['center','zoom','pitch','bearing'].includes(n)){clearTimeout(this._ct);this._ct=setTimeout(()=>this.map.easeTo(Object.assign(this.cam(),{duration:reducedM()?0:1100})),30);return;}
  cancelAnimationFrame(this._uq);this._uq=requestAnimationFrame(()=>this.update());}
 init(){const T=TH[this.th],cam=this.cam();
  this.map=new maplibregl.Map(Object.assign({container:this.box,style:T.style,interactive:this.getAttribute('interactive')!=='false',attributionControl:{compact:true},dragRotate:this.hasAttribute('extrude'),maxPitch:70,fadeDuration:0},cam));
  if(this.getAttribute('interactive')==='false'){}else this.map.scrollZoom.setWheelZoomRate(1/300);
  this.map.on('load',()=>{try{this.setup();}catch(e){console.warn('hawa-geo',e);}});}
 before(){const l=this.map.getStyle().layers.find(l=>l.type==='symbol');return l&&l.id;}
 setup(){const m=this.map,T=TH[this.th],pal=AQ[this.th],b4=this.before(),ext=this.hasAttribute('extrude');
  const vs=Object.entries(m.getStyle().sources).find(([k,s])=>s.type==='vector');const vid=vs&&vs[0];
  if(vid){try{m.addLayer({id:'hc-major',type:'line',source:vid,'source-layer':'transportation',filter:['match',['get','class'],['motorway','trunk'],true,false],paint:{'line-color':T.major,'line-width':['interpolate',['linear'],['zoom'],9,1,13,3.5]}},b4);}catch(e){}}
  m.addSource('hex',{type:'geojson',data:{type:'FeatureCollection',features:[]}});
  const col=['step',['get','pm'],pal[0],31,pal[1],61,pal[2],91,pal[3],121,pal[4],251,pal[5]];
  if(ext){m.addLayer({id:'hc-hex',type:'fill-extrusion',source:'hex',paint:{'fill-extrusion-color':col,'fill-extrusion-height':['*',['max',0,['-',['get','pm'],60]],this.num('extrude-scale',9)],'fill-extrusion-opacity':.88}});}
  else m.addLayer({id:'hc-hex',type:'fill',source:'hex',paint:{'fill-color':col,'fill-opacity':['interpolate',['linear'],['get','pm'],60,this.th==='dark'?.14:.2,121,this.th==='dark'?.26:.34,250,.5,420,.78]}},b4);
  if(vid&&this.hasAttribute('buildings')){try{m.addLayer({id:'hc-bld',type:'fill-extrusion',source:vid,'source-layer':'building',minzoom:12.5,paint:{'fill-extrusion-color':T.bld,'fill-extrusion-height':['coalesce',['get','render_height'],8],'fill-extrusion-opacity':.9}});}catch(e){}}
  m.addSource('trails',{type:'geojson',data:{type:'FeatureCollection',features:[]}});m.addLayer({id:'hc-trails',type:'line',source:'trails',paint:{'line-color':T.trail,'line-opacity':.45,'line-width':1.4,'line-dasharray':[1,2.5]}});
  m.addSource('routes',{type:'geojson',data:{type:'FeatureCollection',features:[]}});m.addLayer({id:'hc-routes',type:'line',source:'routes',layout:{'line-cap':'round'},paint:{'line-color':['match',['get','k'],'usual',T.usual,T.teal],'line-width':2.2,'line-opacity':['get','o'],'line-dasharray':[2,1.5]}});
  m.addSource('aux',{type:'geojson',data:{type:'FeatureCollection',features:[]}});m.addLayer({id:'hc-aux',type:'line',source:'aux',paint:{'line-color':['coalesce',['get','c'],T.text],'line-width':['coalesce',['get','w'],1.2],'line-dasharray':[2,2]}});
  this.routes={};this.trails=TRAILS.map(t=>({p:t}));const jobs=[];
  ASSETS.forEach(a=>{this.routes[a.id]={plan:a.plan,usual:a.usual};jobs.push(osrm(a.plan).then(c=>this.routes[a.id].plan=c),osrm(a.usual).then(c=>this.routes[a.id].usual=c));});
  TRAILS.forEach((t,i)=>jobs.push(osrm(t).then(c=>this.trails[i].p=c)));
  Promise.all(jobs).then(()=>{this.geomDirty=true;this.update();});
  this.ready=true;this.update();this.loop();}
 L(){return(this.getAttribute('layers')||'hex,hotspots,stations,trucks,trails,anchors').split(',');}
 update(){if(!this.ready)return;const m=this.map,has=l=>this.L().includes(l),mode=this.getAttribute('mode')||'live',hour=this.num('hour',0);
  const mix=mode==='plan'?1:mode==='usual'?0:mode==='mix'?this.num('mix',0):0;
  if(has('hex')){const f=HEX.map(([x,y],i)=>({type:'Feature',properties:{pm:Math.round(pmAt(x,y,hour,mix))},geometry:{type:'Polygon',coordinates:[GEOM[i]]}}));m.getSource('hex').setData({type:'FeatureCollection',features:f});}
  m.setLayoutProperty('hc-hex','visibility',has('hex')?'visible':'none');
  m.getSource('trails').setData({type:'FeatureCollection',features:has('trails')?this.trails.map(t=>({type:'Feature',properties:{},geometry:{type:'LineString',coordinates:t.p}})):[]});
  const rf=[];if(has('routes')||has('trucks'))ASSETS.forEach(a=>{const r=this.routes[a.id];if(mode!=='usual')rf.push({type:'Feature',properties:{k:'plan',o:mode==='mix'?.2+.8*mix:1},geometry:{type:'LineString',coordinates:r.plan}});if(mode==='usual'||mode==='mix')rf.push({type:'Feature',properties:{k:'usual',o:mode==='mix'?1-.8*mix:1},geometry:{type:'LineString',coordinates:r.usual}});});
  m.getSource('routes').setData({type:'FeatureCollection',features:rf});
  const aux=[],sel=HOT.find(h=>h.id===this.getAttribute('selected'));
  if(sel)aux.push({type:'Feature',properties:{},geometry:{type:'LineString',coordinates:[[sel.lon,sel.lat],[sel.lon-.014,sel.lat+.011]]}});
  if(mode==='donor'){const t=HOT[1],D=[[3.2,-2.1],[-4.1,1.2],[1.4,4.3],[-2.6,-3.8],[5.1,2.6]];aux.push({type:'Feature',properties:{c:TH[this.th].teal,w:2.4},geometry:{type:'Polygon',coordinates:[hexPoly(t.x,t.y,1.8)]}});D.forEach(d=>aux.push({type:'Feature',properties:{},geometry:{type:'Polygon',coordinates:[hexPoly(t.x+d[0],t.y+d[1],1.8)]}}));}
  m.getSource('aux').setData({type:'FeatureCollection',features:aux});
  this.markers(has,mode,hour,mix,sel);}
 put(key,ll,html,cls,onClick){let e=this.mk[key];if(!e){const el=document.createElement('div');el.className=cls||'';if(onClick)el.addEventListener('click',onClick);e=this.mk[key]={el,mk:new maplibregl.Marker({element:el,anchor:'center'}).setLngLat(ll).addTo(this.map),h:''};}
  e.keep=true;if(e.h!==html){e.el.innerHTML=html;e.h=html;}e.el.className=cls||'';if(ll)e.mk.setLngLat(ll);return e;}
 markers(has,mode,hour,mix,sel){Object.values(this.mk).forEach(e=>e.keep=false);const pal=AQ[this.th],lab=this.getAttribute('labels')||'full',f=ep(hour);
  if(has('anchors'))ANCH.forEach(a=>this.put('a'+a[0],[a[1],a[2]],a[0],'an'));
  if(has('stations'))ST.forEach(s=>this.put('s'+s[0],[s[2],s[1]],`<div class="st"></div>${has('stationlabels')?`<span class="stl">${s[0]} · CAAQMS</span>`:''}`,''));
  if(has('schools'))SCHOOLS.forEach((s,i)=>this.put('sc'+i,s,'S','sc'));
  if(has('hotspots'))HOT.forEach(h=>{const v=Math.round(h.pm*f*(1-(1-h.tr)*mix)),c=pal[band(v)],show=lab==='full'||(lab==='sel'&&sel===h);
   this.put('h'+h.id,[h.lon,h.lat],`<i class="r" style="background:${c}"></i><i class="c" style="background:${c}"></i>${show?`<div class="lab"><b>${h.place}</b><span class="mn">${v}<span class="u"> µg/m³</span></span><span class="cz"><hc-icon name="${CI[h.cause]}" size="11"></hc-icon>${h.cause}</span></div>`:''}`,'hs'+(sel===h?' sel':''),()=>this.dispatchEvent(new CustomEvent('hc-hotspot',{detail:{id:h.id},bubbles:true,composed:true})));});
  if(sel&&has('hotspots'))this.put('sp',[sel.lon-.014,sel.lat+.011],'<div class="sp"></div><span class="spl">Upwind suspect</span>','');
  if(mode==='donor'){const t=HOT[1],D=[[3.2,-2.1,.31],[-4.1,1.2,.24],[1.4,4.3,.19],[-2.6,-3.8,.14],[5.1,2.6,.12]];D.forEach((d,i)=>this.put('dn'+i,toLL(t.x+d[0],t.y+d[1]),'w '+d[2].toFixed(2),'dn'));}
  this.movers=[];if(has('trucks'))ASSETS.forEach((a,i)=>{const sets=mode==='usual'?['usual']:mode==='mix'?['plan','usual']:['plan'];sets.forEach(k=>{const p=this.routes[a.id][k];const e=this.put('t'+a.id+k,null,`<div class="b"><hc-icon name="${a.icon}" size="11" stroke="2"></hc-icon></div><span class="t">${a.id}</span>`,'tk'+(k==='usual'?' us':''));e.mk.setLngLat(p[0]);this.movers.push({e,p,L:plen(p),ph:i*.37%1,per:16+i%3*4,pp:true});});});
  if(has('trails'))this.trails.forEach((t,i)=>{const e=this.put('b'+i,null,'','bus');e.mk.setLngLat(t.p[0]);this.movers.push({e,p:t.p,L:plen(t.p),ph:i*.23,per:60});});
  Object.entries(this.mk).forEach(([k,e])=>{if(!e.keep){e.mk.remove();delete this.mk[k];}});this.tick(performance.now());}
 tick(now){const t=reducedM()?0:now/1000;(this.movers||[]).forEach(o=>{let u=(t/o.per+o.ph)%1;if(o.pp)u=u<.5?u*2:2-u*2;o.e.mk.setLngLat(along(o.p,o.L,u));});}
 loop(){const f=n=>{if(this.vis&&n-(this.lt||0)>50){this.lt=n;this.tick(n);}this.raf=requestAnimationFrame(f);};this.raf=requestAnimationFrame(f);}
}
function reducedM(){return window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches;}
customElements.define('hawa-geo',HawaGeo);
window.HawaGeo={HOT,ST};
})();
