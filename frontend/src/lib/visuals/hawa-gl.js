// @ts-nocheck
// Vendored from Claude Design export (design/claude-design/source/hawa-gl.js). Registers custom elements; loaded client-side by components/visuals/VisualsLoader.
(function(){
if(customElements.get('hawa-gl'))return;
const V='4.7.1',CSS=`https://unpkg.com/maplibre-gl@${V}/dist/maplibre-gl.css`,JS=`https://unpkg.com/maplibre-gl@${V}/dist/maplibre-gl.js`;
let LP;const lib=()=>window.maplibregl?Promise.resolve(window.maplibregl):(LP=LP||new Promise((res,rej)=>{const s=document.createElement('script');s.src=JS;s.onload=()=>res(window.maplibregl);s.onerror=rej;document.head.appendChild(s);}));
const RM=()=>window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches;
const KX=97.8,KY=111.2;
const OUTLINE=[[77.10,28.885],[77.18,28.87],[77.22,28.845],[77.235,28.79],[77.265,28.735],[77.33,28.705],[77.345,28.66],[77.338,28.60],[77.305,28.555],[77.31,28.50],[77.245,28.43],[77.17,28.405],[77.12,28.465],[77.10,28.52],[77.04,28.515],[76.96,28.55],[76.845,28.565],[76.84,28.64],[76.90,28.705],[76.95,28.765],[77.02,28.81],[77.06,28.86]];
function inPoly(x,y,p){let c=false;for(let i=0,j=p.length-1;i<p.length;j=i++){const[xi,yi]=p[i],[xj,yj]=p[j];if(((yi>y)!=(yj>y))&&(x<(xj-xi)*(y-yi)/(yj-yi)+xi))c=!c;}return c;}
const ST=[
 {id:'anand',name:'Anand Vihar',full:'Anand Vihar ISBT, East Delhi',lon:77.316,lat:28.647,pm:212,cause:'Dust',conf:.82,st:1,side:'r'},
 {id:'ghazipur',name:'Ghazipur',full:'Ghazipur landfill, East Delhi',lon:77.329,lat:28.625,pm:388,cause:'Burning',conf:.74,st:0,side:'b',sigma:1.4},
 {id:'shahdara',name:'Shahdara',full:'GT Road, Shahdara',lon:77.289,lat:28.673,pm:341,cause:'Traffic',conf:.69,st:0,side:'t',sigma:1.4},
 {id:'ito',name:'ITO',full:'ITO junction, Central Delhi',lon:77.241,lat:28.629,pm:296,cause:'Traffic',conf:.77,st:1,side:'l'},
 {id:'nehru',name:'Nehru Nagar',full:'Nehru Nagar, South East Delhi',lon:77.251,lat:28.568,pm:256,cause:'Traffic',conf:.74,st:1,side:'r'},
 {id:'okhla',name:'Okhla Ph-2',full:'Okhla Phase II, South East Delhi',lon:77.271,lat:28.531,pm:318,cause:'Dust',conf:.72,st:1,side:'r'},
 {id:'rkpuram',name:'RK Puram',full:'RK Puram, South West Delhi',lon:77.187,lat:28.563,pm:188,cause:'Traffic',conf:.70,st:1,side:'l'},
 {id:'dwarka',name:'Dwarka Sec-8',full:'Dwarka Sector 8, South West Delhi',lon:77.072,lat:28.571,pm:204,cause:'Dust',conf:.68,st:1,side:'b'},
 {id:'punjabi',name:'Punjabi Bagh',full:'Punjabi Bagh, West Delhi',lon:77.131,lat:28.674,pm:279,cause:'Traffic',conf:.70,st:1,side:'b'},
 {id:'wazirpur',name:'Wazirpur',full:'Wazirpur industrial area, North West Delhi',lon:77.165,lat:28.700,pm:402,cause:'Burning',conf:.63,st:1,side:'r'},
 {id:'jahangirpuri',name:'Jahangirpuri',full:'Jahangirpuri, North West Delhi',lon:77.171,lat:28.733,pm:364,cause:'Dust',conf:.66,st:1,side:'r'},
 {id:'mundka',name:'Mundka',full:'Mundka, West Delhi',lon:77.035,lat:28.682,pm:437,cause:'Regional smoke',conf:.71,st:1,side:'r',sigma:2.2},
 {id:'bawana',name:'Bawana',full:'Bawana, North West Delhi',lon:77.051,lat:28.776,pm:421,cause:'Regional smoke',conf:.69,st:1,side:'r',sigma:2.2}
];
const TREATED={anand:.72,shahdara:.8,ito:.78,ghazipur:.74,okhla:.8,jahangirpuri:.82};
const SCHOOLS=[[77.309,28.656],[77.323,28.637],[77.298,28.668],[77.336,28.631],[77.282,28.680]];
const CAUSE_ICON={Dust:'wind',Traffic:'car',Burning:'flame','Regional smoke':'cloud-fog'};
const AQI={dark:['#3FB871','#9CCB4E','#E8C53A','#F08C35','#E5484D','#C43A6B'],light:['#1E8A4C','#5E8F1B','#B8920A','#D0690E','#C02A2A','#7F1D3A']};
const band=v=>v<=30?0:v<=60?1:v<=90?2:v<=120?3:v<=250?4:5;
function rng(seed){return function(){seed|=0;seed=seed+0x6D2B79F5|0;let t=Math.imul(seed^seed>>>15,1|seed);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}
const R=rng(42),NG=40,NGRID=[];for(let i=0;i<(NG+1)*(NG+1);i++)NGRID.push(R());
function noise(x,y){const c=v=>Math.min(NG,Math.max(0,v));const xi=Math.floor(x),yi=Math.floor(y),s=t=>t*t*(3-2*t),u=s(x-xi),v=s(y-yi),g=(a,b)=>NGRID[c(b)*(NG+1)+c(a)];return(g(xi,yi)*(1-u)+g(xi+1,yi)*u)*(1-v)+(g(xi,yi+1)*(1-u)+g(xi+1,yi+1)*u)*v;}
const MINI=[];for(let i=0;i<24;i++)MINI.push({lon:76.88+R()*.42,lat:28.45+R()*.4,a:30+R()*70,s:.5+R()*.7});
const episode=h=>1+0.14*(Math.cos(2*Math.PI*(h-18)/24)-Math.cos(2*Math.PI*(-18)/24))+0.2*Math.exp(-Math.pow((h-42)/12,2));
function field(lon,lat,hour,mix){const nx=(lon-76.84)/.51,ny=(28.89-lat)/.49,f=episode(hour);
 let base=148+60*Math.max(0,(1-nx)*.6+(1-ny)*.4-.3)+44*(noise(nx*9,ny*9)-.5)+22*(noise(nx*26+3,ny*26+5)-.5),hs=0;
 for(const s of ST){const dx=(lon-s.lon)*KX,dy=(lat-s.lat)*KY,sg=s.sigma||1.2;let a=s.pm-160;if(TREATED[s.id])a*=1-(1-TREATED[s.id])*mix;hs+=a*Math.exp(-(dx*dx+dy*dy)/(2*sg*sg));}
 for(const m of MINI){const dx=(lon-m.lon)*KX,dy=(lat-m.lat)*KY;hs+=m.a*Math.exp(-(dx*dx+dy*dy)/(2*m.s*m.s));}
 return base*(.62+.38*f)+hs*f;}
const stationValue=(s,hour,mix)=>Math.round(s.pm*episode(hour)*(TREATED[s.id]?1-(1-TREATED[s.id])*mix:1));
const liveField=(lon,lat,S,b)=>{let sw=.08,sp=.08*b;for(const s of S){const dx=(lon-s.lon)*KX,dy=(lat-s.lat)*KY,w=Math.exp(-(dx*dx+dy*dy)/(8.4));sw+=w;sp+=w*s.pm;}return sp/sw;};
let HEX=null;function hexes(){if(HEX)return HEX;const c=.5,r=c/Math.sqrt(3),out=[];let row=0;
 for(let yk=0;yk<(28.89-28.40)*KY;yk+=1.5*r,row++){for(let xk=(row%2?c/2:0);xk<(77.36-76.83)*KX;xk+=c){const lon=76.83+xk/KX,lat=28.89-yk/KY;if(!inPoly(lon,lat,OUTLINE))continue;const ring=[];for(let i=0;i<6;i++){const a=Math.PI/180*(60*i-30);ring.push([+(lon+Math.cos(a)*r*.93/KX).toFixed(5),+(lat+Math.sin(a)*r*.93/KY).toFixed(5)]);}ring.push(ring[0]);out.push({lon,lat,ring});}}
 return HEX=out;}
const ROUTES={
 'T-12':{icon:'truck',live:[[77.300,28.623],[77.316,28.647]],usual:[[77.300,28.623],[77.294,28.604],[77.306,28.594]],plan:[[77.300,28.623],[77.316,28.647],[77.315,28.668]]},
 'I-3':{icon:'users',live:[[77.296,28.606],[77.329,28.625]],usual:[[77.296,28.606],[77.302,28.616]],plan:[[77.296,28.606],[77.329,28.625]]},
 'ASG-07':{icon:'spray-can',live:[[77.302,28.651],[77.314,28.646]],usual:[[77.302,28.651],[77.300,28.660]],plan:[[77.302,28.651],[77.314,28.646]]},
 'SW-03':{icon:'brush',live:[[77.315,28.672],[77.316,28.650]],usual:[[77.300,28.700],[77.312,28.690]],plan:[[77.315,28.672],[77.316,28.650]]},
 'T-07':{icon:'truck',live:[[77.241,28.629],[77.265,28.632]],usual:[[77.215,28.610],[77.230,28.590]],plan:[[77.241,28.629],[77.265,28.632]]},
 'T-19':{icon:'truck',live:[[77.271,28.531],[77.285,28.548]],usual:[[77.252,28.552],[77.262,28.566]],plan:[[77.271,28.531],[77.285,28.548]]}
};
const BUSES=[[[77.072,28.571],[77.187,28.563],[77.241,28.629]],[[77.035,28.682],[77.131,28.674],[77.165,28.700],[77.171,28.733]],[[77.241,28.629],[77.289,28.673],[77.316,28.647]],[[77.271,28.531],[77.251,28.568],[77.241,28.629]]];
const ANCHORS=[['Yamuna',77.262,28.668],['Ring Road',77.205,28.583],['NH-9',77.338,28.640],['Outer Ring Road',77.105,28.715]];
const rcache={};function route(pts){const k=pts.map(p=>p.join(',')).join(';');if(rcache[k])return rcache[k];
 let saved=null;try{saved=JSON.parse(sessionStorage.getItem('hawa-route:'+k));}catch(e){}
 if(saved)return rcache[k]=Promise.resolve(saved);
 return rcache[k]=fetch(`https://router.project-osrm.org/route/v1/driving/${k}?overview=full&geometries=geojson`).then(r=>r.json()).then(j=>{const c=j.routes&&j.routes[0]&&j.routes[0].geometry.coordinates;if(!c)throw 0;try{sessionStorage.setItem('hawa-route:'+k,JSON.stringify(c));}catch(e){}return c;}).catch(()=>pts);}
function cum(c){const L=[0];for(let i=1;i<c.length;i++)L.push(L[i-1]+Math.hypot((c[i][0]-c[i-1][0])*KX,(c[i][1]-c[i-1][1])*KY));return L;}
function along(c,L,u){const d=u*L[L.length-1];for(let i=1;i<c.length;i++)if(d<=L[i]){const k=(d-L[i-1])/((L[i]-L[i-1])||1);return[c[i-1][0]+(c[i][0]-c[i-1][0])*k,c[i-1][1]+(c[i][1]-c[i-1][1])*k];}return c[c.length-1];}
const MCSS=`.maplibregl-ctrl-attrib{font:10px 'Geist Mono',monospace!important}
.st{position:relative;width:0;height:0;cursor:pointer}
.st i{position:absolute;left:-5px;top:-5px;width:10px;height:10px;border-radius:50%;box-sizing:border-box}
.st .core{border:2px solid var(--bg)}.st.stn .core{border-radius:2px}
.st .ring{animation:hp 2.4s cubic-bezier(.2,.6,.3,1) infinite;opacity:0}
@keyframes hp{0%{transform:scale(1);opacity:.7}100%{transform:scale(4.2);opacity:0}}
.st.sel .core{outline:2px solid var(--text);outline-offset:3px}
.lab{position:absolute;display:flex;align-items:center;gap:6px;white-space:nowrap;padding:3px 7px;border-radius:6px;background:var(--lbg);border:1px solid var(--border);color:var(--text);font:11px/16px 'Geist',sans-serif;transition:border-color .15s ease-out}
.lab:hover{border-color:var(--muted)}
.lab.r{left:10px;top:-11px}.lab.l{right:10px;top:-11px}.lab.t{left:-20px;bottom:10px}.lab.b{left:-20px;top:10px}
.st.ex .lab.t{left:0;bottom:44px;transform:translateX(-50%)}.st.ex .lab.t:after{content:'';position:absolute;left:50%;top:100%;height:34px;border-left:1px solid var(--muted)}
.lab b{font-weight:500}.mono{font-family:'Geist',sans-serif;font-variant-numeric:tabular-nums}.u{color:var(--muted)}
.tag{font:500 10px 'Geist',sans-serif;color:var(--muted);font-variant-numeric:tabular-nums}
.cz{display:inline-flex;align-items:center;gap:3px;color:var(--muted);font-size:10px;padding-left:6px;border-left:1px solid var(--border)}
.tk{display:flex;align-items:center;gap:4px;pointer-events:none}
.tk .b{width:18px;height:18px;border-radius:5px;background:var(--bg);border:1.5px solid var(--teal);color:var(--teal);display:grid;place-items:center;box-sizing:border-box}
.tk.us .b{border-color:var(--muted);color:var(--muted)}
.cl{font:600 11px 'Geist',sans-serif;color:var(--text);background:var(--lbg);border:1px solid var(--border);border-radius:10px;padding:1px 7px}
.tk .t{font:500 10.5px 'Geist',sans-serif;color:var(--text);background:var(--lbg);padding:0 4px;border-radius:3px}
.bus{width:7px;height:7px;border-radius:50%;background:var(--text);box-shadow:0 0 0 3px var(--halo)}
.sc{width:14px;height:14px;border-radius:3px;background:var(--bg);border:1px solid var(--text);color:var(--text);display:grid;place-items:center;font:600 8px 'Geist',sans-serif}
.sp{display:flex;align-items:center;gap:8px}.sp i{width:10px;height:10px;transform:rotate(45deg);background:var(--bg);border:1.5px solid var(--text)}
.sp span{font:10.5px 'Geist',sans-serif;color:var(--text);background:var(--lbg);border:1px dashed var(--muted);padding:1px 6px;border-radius:4px;white-space:nowrap}
.nb{position:absolute;left:11px;top:-9px;min-width:15px;height:15px;padding:0 4px;border-radius:8px;background:var(--text);color:var(--bg);font:600 9.5px/15px 'Geist',sans-serif;text-align:center;box-sizing:border-box;display:none;pointer-events:none}
.anc{font:italic 500 11px 'Geist',sans-serif;color:var(--muted);white-space:nowrap;text-shadow:0 0 4px var(--bg)}`;

const HB={w:76.80,e:77.40,s:28.36,n:28.93},HN=200,HEAT_COORDS=[[HB.w,HB.n],[HB.e,HB.n],[HB.e,HB.s],[HB.w,HB.s]];
const mercY=lat=>Math.log(Math.tan(Math.PI/4+lat*Math.PI/360)),latOf=y=>(2*Math.atan(Math.exp(y))-Math.PI/2)*180/Math.PI;
const RAMP=[[0,[63,184,113]],[15,[63,184,113]],[45,[156,203,78]],[75,[232,197,58]],[105,[240,140,53]],[185,[229,72,77]],[300,[196,58,107]],[600,[150,40,90]]];
function ramp(v){if(v<=RAMP[0][0])return RAMP[0][1];for(let i=1;i<RAMP.length;i++){if(v<=RAMP[i][0]){const a=RAMP[i-1],b=RAMP[i],t=(v-a[0])/(b[0]-a[0]);return[a[1][0]+(b[1][0]-a[1][0])*t,a[1][1]+(b[1][1]-a[1][1])*t,a[1][2]+(b[1][2]-a[1][2])*t];}}return RAMP[RAMP.length-1][1];}
function boxBlur(a,n,r){const t=new Float32Array(a.length);for(let y=0;y<n;y++){let s=0;for(let x=-r;x<=r;x++)s+=a[y*n+Math.min(n-1,Math.max(0,x))];for(let x=0;x<n;x++){t[y*n+x]=s/(2*r+1);s+=a[y*n+Math.min(n-1,x+r+1)]-a[y*n+Math.max(0,x-r)];}}
 for(let x=0;x<n;x++){let s=0;for(let y=-r;y<=r;y++)s+=t[Math.min(n-1,Math.max(0,y))*n+x];for(let y=0;y<n;y++){a[y*n+x]=s/(2*r+1);s+=t[Math.min(n-1,y+r+1)*n+x]-t[Math.max(0,y-r)*n+x];}}return a;}
let MASK=null;function heatMask(){if(MASK)return MASK;const a=new Float32Array(HN*HN),y0=mercY(HB.n),y1=mercY(HB.s);
 for(let j=0;j<HN;j++){const lat=latOf(y0+(y1-y0)*(j+.5)/HN);for(let i=0;i<HN;i++){a[j*HN+i]=inPoly(HB.w+(HB.e-HB.w)*(i+.5)/HN,lat,OUTLINE)?1:0;}}
 for(let k=0;k<3;k++)boxBlur(a,HN,4);return MASK=a;}
class HawaGL extends HTMLElement{
 static get observedAttributes(){return['theme','hour','mix','mode','layers','selected','center','zoom','pitch','bearing','extrude','hscale','labels','threshold','assets','attrib','attrib-bottom'];}
 constructor(){super();const r=this.attachShadow({mode:'open'});r.innerHTML=`<link rel="stylesheet" href="${CSS}"><style>:host{display:block;position:relative;overflow:hidden}#m{position:absolute;inset:0}${MCSS}</style><div id="m"></div><div id="at">© OpenFreeMap · © OpenMapTiles · © OpenStreetMap</div>`;this.box=r.getElementById('m');this.at=r.getElementById('at');this.mk=[];}
 syncAttrib(){const light=this.th==='light';this.at.style.cssText=`position:absolute;right:8px;bottom:${this.num('attrib-bottom',4)}px;font:10px/1.2 'Geist',sans-serif;color:${light?'#4A555B':'#9AA7AE'};text-shadow:0 0 3px ${light?'#FFFFFF':'#0E1417'},0 0 3px ${light?'#FFFFFF':'#0E1417'};pointer-events:none;white-space:nowrap;display:${this.getAttribute('attrib')==='none'?'none':'block'}`;}
 get th(){return this.getAttribute('theme')==='light'?'light':'dark';}
 has(l){return (this.getAttribute('layers')||'hex,stations,labels,trucks,buses').split(',').includes(l);}
 num(a,d){const v=parseFloat(this.getAttribute(a));return isNaN(v)?d:v;}
 connectedCallback(){this.syncAttrib();if(this.map)return;this._vis=true;try{this.io=new IntersectionObserver(e=>{this._vis=e[e.length-1].isIntersecting;},{rootMargin:'200px'});this.io.observe(this);}catch(e){}
  lib().then(ml=>{if(!this.isConnected)return;const light=this.th==='light';const c=(this.getAttribute('center')||'77.21,28.64').split(',').map(Number);
   const inter=this.getAttribute('interactive')!=='false';
   this.map=new ml.Map({container:this.box,style:`https://tiles.openfreemap.org/styles/${light?'positron':'dark'}`,center:c,zoom:this.num('zoom',10),pitch:this.num('pitch',0),bearing:this.num('bearing',0),interactive:inter,attributionControl:false,maxBounds:[[76.55,28.2],[77.65,29.1]],fadeDuration:0});
   if(inter){this.map.scrollZoom.setWheelZoomRate(1/300);if(this.hasAttribute('cooperative'))this.map.scrollZoom.disable();}
   this.map.on('load',()=>{this.ready=true;this.setup();});
   this.ro=new ResizeObserver(()=>{this.map&&this.map.resize();this.layout();});this.ro.observe(this);});}
 disconnectedCallback(){clearTimeout(this.t);cancelAnimationFrame(this._lr);this._lr=0;this.ro&&this.ro.disconnect();this.io&&this.io.disconnect();if(this.map){this.map.remove();this.map=null;this.ready=false;}}
 attributeChangedCallback(n){if(this.at&&(n==='attrib'||n==='attrib-bottom'||n==='theme'))this.syncAttrib();if(!this.ready)return;if(['center','zoom','pitch','bearing'].includes(n)){const c=(this.getAttribute('center')||'77.21,28.64').split(',').map(Number);this.map.easeTo({center:c,zoom:this.num('zoom',10),pitch:this.num('pitch',0),bearing:this.num('bearing',0),duration:RM()?0:900});return;}
  clearTimeout(this._u);this._u=setTimeout(()=>this.update(),n==='hour'||n==='mix'?60:0);}
 set data(d){this._d=d&&d.length?d:null;if(this._d){const v=this._d.map(s=>s.pm).sort((a,b)=>a-b);this._b=Math.max(40,.55*v[Math.floor(v.length/2)]);}if(this.ready){clearTimeout(this._u);this._u=setTimeout(()=>this.update(),0);}}
 get data(){return this._d;}
 set fleet(a){this._a=a&&a.length?a:null;if(this.ready){clearTimeout(this._u);this._u=setTimeout(()=>this.update(),0);}}
 get fleet(){return this._a;}
 set donors(w){this._w=w&&w.length?w:null;if(this.ready){clearTimeout(this._u);this._u=setTimeout(()=>this.update(),0);}}
 get donors(){return this._w;}
 sts(){return this._d||ST;}
 sv(s,hour,mix){return this._d?Math.round(s.pm):stationValue(s,hour,mix);}
 fld(lon,lat,hour,mix){return this._d?liveField(lon,lat,this._d,this._b):field(lon,lat,hour,mix);}
 heatArm(hs){this._hb=true;clearTimeout(this._ht);this._ht=setTimeout(()=>{this._hb=false;},2500);hs.once('data',()=>{clearTimeout(this._ht);this._hb=false;if(this._hq){this._hq=false;this.heatPush();}});}
 heatPush(){const m=this.map,hs=m&&m.getSource('heat');if(!hs)return;if(this._hb){this._hq=true;return;}this.heatArm(hs);hs.updateImage({url:this.heatUrl(),coordinates:HEAT_COORDS});}
 heatUrl(){const hour=this.num('hour',0),mix=this.mode==='plan'?1:this.mode==='usual'?0:this.num('mix',0),N=HN,c=document.createElement('canvas');c.width=c.height=N;
  const x=c.getContext('2d'),im=x.createImageData(N,N),M=heatMask(),y0=mercY(HB.n),y1=mercY(HB.s),A=this.th==='light'?.6:.68,S=this._d;
  for(let j=0;j<N;j++){const lat=latOf(y0+(y1-y0)*(j+.5)/N);for(let i=0;i<N;i++){const lon=HB.w+(HB.e-HB.w)*(i+.5)/N,k=(j*N+i)*4,col=ramp(this.fld(lon,lat,hour,mix));
   let cov=1;if(S){let d2=1e9;for(const s of S){const dx=(lon-s.lon)*KX,dy=(lat-s.lat)*KY;d2=Math.min(d2,dx*dx+dy*dy);}cov=Math.max(.2,Math.exp(-d2/(2*7*7)));}
   im.data[k]=col[0];im.data[k+1]=col[1];im.data[k+2]=col[2];im.data[k+3]=Math.round(255*A*M[j*N+i]*cov);}}
  x.putImageData(im,0,0);return c.toDataURL();}
 get mode(){return this.getAttribute('mode')||'live';}
 set mode(v){if(v==null)this.removeAttribute('mode');else this.setAttribute('mode',v);}
 setup(){const m=this.map,light=this.th==='light',P=AQI[this.th],firstSym=(m.getStyle().layers.find(l=>l.type==='symbol')||{}).id;
  if(this.getAttribute('basemap')==='clear'&&!light)this.clearBase();
  if(this.mode!=='donor'){m.addSource('heat',{type:'image',url:this.heatUrl(),coordinates:HEAT_COORDS});this.heatArm(m.getSource('heat'));m.addLayer({id:'heat',type:'raster',source:'heat',paint:{'raster-opacity':1,'raster-resampling':'linear','raster-fade-duration':0}},firstSym);}
  if(this.hasAttribute('extrude')){try{m.addLayer({id:'b3d',type:'fill-extrusion',source:'openmaptiles','source-layer':'building',minzoom:12.5,paint:{'fill-extrusion-color':light?'#E2DCD0':'#1E282E','fill-extrusion-height':['coalesce',['get','render_height'],8],'fill-extrusion-base':['coalesce',['get','render_min_height'],0],'fill-extrusion-opacity':.9}},firstSym);}catch(e){}}
  m.addSource('outline',{type:'geojson',data:{type:'Feature',geometry:{type:'LineString',coordinates:OUTLINE.concat([OUTLINE[0]])}}});
  m.addLayer({id:'outline',type:'line',source:'outline',paint:{'line-color':light?'#8A6A45':'#3A4953','line-width':1.2,'line-dasharray':[3,2]}});
  m.addSource('routes',{type:'geojson',data:{type:'FeatureCollection',features:[]}});
  m.addLayer({id:'bus',type:'line',source:'routes',filter:['==',['get','k'],'bus'],paint:{'line-color':light?'rgba(11,18,21,.35)':'rgba(230,237,240,.35)','line-width':1.4,'line-dasharray':[1,2.5]}});
  m.addLayer({id:'rt',type:'line',source:'routes',filter:['!=',['get','k'],'bus'],paint:{'line-color':['case',['==',['get','k'],'usual'],light?'#5F6B70':'#8B9AA3',light?'#0F766E':'#2DD4BF'],'line-width':2.4,'line-opacity':['coalesce',['get','o'],1],'line-dasharray':[2,1.5]}});
  m.addSource('donor',{type:'geojson',data:{type:'FeatureCollection',features:[]}});
  m.addLayer({id:'donor-d',type:'line',source:'donor',filter:['==',['get','t'],0],paint:{'line-color':light?'#0B1215':'#E6EDF0','line-width':1.2,'line-dasharray':[2,2]}});m.addLayer({id:'donor-t',type:'line',source:'donor',filter:['==',['get','t'],1],paint:{'line-color':light?'#0F766E':'#2DD4BF','line-width':2.5}});
  m.on('move',()=>this.layout());
  this.update();this.loadRoutes();this.loop();}
 clearBase(){const m=this.map;m.getStyle().layers.forEach(l=>{const sl=l['source-layer'],P=(k,v)=>{try{m.setPaintProperty(l.id,k,v);}catch(e){}};
   if(l.type==='background')P('background-color','#10171A');
   else if(sl==='water'&&l.type==='fill')P('fill-color','#163240');
   else if(sl==='waterway'&&l.type==='line')P('line-color','#1E4a5C');
   else if(sl==='transportation'&&l.type==='line')P('line-color',/motorway|trunk|primary/.test(JSON.stringify(l.filter||''))?'#4A5B64':'#2E3C44');
   else if(l.type==='symbol'){if(sl==='place'){P('text-color','#B9C5CB');P('text-halo-color','#0E1417');P('text-halo-width',1.4);}else if(sl==='water_name')P('text-color','#74A9BB');else if(sl==='transportation_name')P('text-color','#8B9AA3');}});}
 obstacles(){const out=[],walk=p=>{for(const c of p.children){if(c===this)continue;const cs=getComputedStyle(c);if(cs.display==='none')continue;if(cs.position==='absolute'||cs.position==='fixed'){const r=c.getBoundingClientRect();if(r.width&&r.height)out.push(r);}else if(cs.display==='contents'||c.tagName.includes('-'))walk(c);}};const p=this.parentElement;if(p){walk(p);const g=p.parentElement;if(g)for(const c of g.children){if(c===p)continue;const cs=getComputedStyle(c);if(cs.position==='absolute'&&cs.display!=='none'){const r=c.getBoundingClientRect();if(r.width&&r.height)out.push(r);}}}return out;}
 layout(){if(this._lr)return;this._lr=requestAnimationFrame(()=>{this._lr=0;this._layout();});}
 _layout(){this.cluster(this.scs);const L=this.labs||[];if(!L.length)return;const H=this.getBoundingClientRect(),ob=this.obstacles(),pl=[...this.shadowRoot.querySelectorAll('.st .core')].map(e=>e.getBoundingClientRect()).filter(r=>r.width),M=6,hit=(a,b)=>!(a.right+4<b.left||a.left-4>b.right||a.bottom+4<b.top||a.top-4>b.bottom);
  const ok=r=>r.left>=H.left+M&&r.right<=H.right-M&&r.top>=H.top+M&&r.bottom<=H.bottom-M&&!ob.some(o=>hit(r,o))&&!pl.some(o=>hit(r,o));
  L.forEach(o=>{const sides=o.side?[o.side].concat(['r','l','t','b'].filter(x=>x!==o.side)):[null];let done=false;
   for(const sd of sides){if(sd)o.el.className='lab '+sd;o.el.style.visibility='hidden';const r=o.el.getBoundingClientRect();if(r.width&&ok(r)){o.el.style.visibility='';pl.push(r);done=true;break;}}
   if(!done)o.el.style.visibility='hidden';});}
 css(){const light=this.th==='light';return `--bg:${light?'#FAF9F6':'#0E1417'};--text:${light?'#0B1215':'#E6EDF0'};--muted:${light?'#5F6B70':'#8B9AA3'};--border:${light?'#E6E3DC':'#24303A'};--teal:${light?'#0F766E':'#2DD4BF'};--lbg:${light?'rgba(255,255,255,.95)':'rgba(14,20,23,.92)'};--halo:${light?'rgba(11,18,21,.12)':'rgba(230,237,240,.16)'}`;}
 marker(el,ll,anchor){const ml=window.maplibregl;el.style.cssText+=';'+this.css();const mk=new ml.Marker({element:el,anchor:anchor||'center'}).setLngLat(ll).addTo(this.map);this.mk.push(mk);return mk;}
 cluster(list){const m=this.map;if(!m||!list||!list.length)return;const pts=list.map(o=>m.project(o.mk.getLngLat())),used=list.map(()=>false);
  for(let i=0;i<list.length;i++){if(used[i])continue;used[i]=true;let n=0;for(let j=i+1;j<list.length;j++){if(!used[j]&&Math.hypot(pts[i].x-pts[j].x,pts[i].y-pts[j].y)<24){used[j]=true;n++;list[j].el.style.visibility='hidden';}}
   list[i].el.style.visibility='';if(list[i].bd){list[i].bd.textContent=n?'+'+n:'';list[i].bd.style.display=n?'block':'none';}}}
 update(){const m=this.map;if(!m)return;this.heatPush();
  m.getLayer('heat')&&m.setLayoutProperty('heat','visibility',this.has('hex')?'visible':'none');
  m.getLayer('b3d')&&m.setLayoutProperty('b3d','visibility',this.has('buildings')?'visible':'none');
  m.getLayer('bus')&&m.setLayoutProperty('bus','visibility',this.has('buses')?'visible':'none');
  m.getLayer('rt')&&m.setLayoutProperty('rt','visibility',this.has('trucks')?'visible':'none');
  this.mk.forEach(k=>k.remove());this.mk=[];this.tks=[];this.bs=[];
  const hour=this.num('hour',0),mode=this.mode,mix=mode==='plan'?1:mode==='usual'?0:this.num('mix',0),P=AQI[this.th],sel=this.getAttribute('selected'),lab=this.getAttribute('labels')||'full';
  const maxL=this.num('maxlabels',4),want=s=>lab==='full'||(lab==='sel'&&sel===s.id)||(lab==='major'&&(this.sv(s,hour,mix)>=(isNaN(this.num('threshold',NaN))?340:this.num('threshold',NaN))||sel===s.id));
  const bnd=this.map.getBounds(),pick=this.sts().filter(want).filter(s=>sel===s.id||bnd.contains([s.lon,s.lat])).map(s=>({s,v:this.sv(s,hour,mix)})).sort((a,b)=>(b.s.id===sel)-(a.s.id===sel)||b.v-a.v).slice(0,maxL).map(o=>o.s.id);
  const stL=[],fx=[];this.labs=[];
  if(this.has('anchors'))ANCHORS.forEach(a=>{const e=document.createElement('div');e.className='anc';e.textContent=a[0];this.marker(e,[a[1],a[2]]);fx.push({el:e});});
  this.scs=[];if(this.has('schools'))SCHOOLS.forEach(s=>{const e=document.createElement('div');e.className='scw';e.innerHTML='<div class="sc">S</div><span class="nb"></span>';const mk=this.marker(e,s);this.scs.push({mk,el:e,bd:e.querySelector('.nb')});});
  const thrV=this.num('threshold',NaN),ex=this.hasAttribute('extrude');if(this.has('stations'))this.sts().forEach(s=>{const v=this.sv(s,hour,mix),below=!isNaN(thrV)&&v<thrV,c=below?(this.th==='light'?'#B7B2A8':'#4A5760'):P[band(v)],e=document.createElement('div');e.className='st'+(s.st?' stn':'')+(sel===s.id?' sel':'')+(ex?' ex':'');
   let h=(below?'':`<i class="ring" style="background:${c};animation-delay:${(s.lon*37%2.4).toFixed(2)}s"></i>`)+`<i class="core" style="background:${c}"></i>`;
   if(pick.includes(s.id))h+=`<div class="lab ${ex?'t':s.side}" data-id="${s.id}"><b>${s.name}</b><span class="mono">${v}<span class="u"> µg/m³</span></span>${this.has('causes')?`<span class="cz"><hc-icon name="${CAUSE_ICON[s.cause]||'cloud-fog'}" size="11"></hc-icon>${s.cause}</span>`:''}</div>`;
   e.innerHTML=h;const le=e.querySelector('.lab');if(le)stL.push({el:le,side:ex?'t':s.side,p:pick.indexOf(s.id)});e.addEventListener('click',()=>this.dispatchEvent(new CustomEvent('hc-hotspot',{detail:{id:s.id},bubbles:true,composed:true})));this.marker(e,[s.lon,s.lat]);});
  if(this.has('suspect')||sel==='ghazipur'){const e=document.createElement('div');e.className='sp';e.innerHTML='<i></i><span>Ghazipur landfill · burning suspect</span>';this.marker(e,[77.3335,28.6235],'left');fx.push({el:e.querySelector('span')});}
  if(mode==='donor'){const dc=(this.getAttribute('center')||'77.316,28.647').split(',').map(Number),r=.5/Math.sqrt(3)*1.7,hx=(lon,lat,t)=>{const ring=[];for(let i=0;i<=6;i++){const a=Math.PI/180*(60*i-30);ring.push([lon+Math.cos(a)*r/KX,lat+Math.sin(a)*r/KY]);}return{type:'Feature',properties:{t},geometry:{type:'LineString',coordinates:ring}};};
   const nD=this._w?Math.min(5,this._w.length):5,D=[[.028,-.018],[-.037,.011],[.013,.038],[-.024,-.034],[.046,.024]];m.getSource('donor').setData({type:'FeatureCollection',features:[hx(dc[0],dc[1],1)].concat(D.slice(0,nD).map(d=>hx(dc[0]+d[0],dc[1]+d[1],0)))});
   D.slice(0,nD).forEach((d,i)=>{const e=document.createElement('div');e.className='tag';e.style.cssText='background:var(--lbg);padding:0 4px;border-radius:3px;color:var(--text)';e.textContent=(this._w?Math.round(this._w[i]*100):[31,24,19,14,12][i])+'%';this.marker(e,[dc[0]+d[0],dc[1]+d[1]]);});}
  this.labs=stL.sort((a,b)=>a.p-b.p).concat(fx);
  this.drawRoutes();this.layout();}
 loadRoutes(){const jobs=[];Object.entries(ROUTES).forEach(([id,r])=>['live','usual','plan'].forEach(k=>jobs.push(route(r[k]).then(c=>{r['g_'+k]=c;}))));BUSES.forEach((b,i)=>jobs.push(route(b).then(c=>{BUSES['g'+i]=c;})));
  Promise.all(jobs).then(()=>{if(this.ready)this.drawRoutes();});}
 drawRoutes(){const m=this.map;if(!m||!m.getSource('routes'))return;const mode=this.mode,mix=mode==='plan'?1:mode==='usual'?0:this.num('mix',-1),F=[];
  const sets=mix<0?['live']:mode==='plan'?['plan']:mode==='usual'?['usual']:['usual','plan'];
  const all=Object.entries(ROUTES),aa=this.getAttribute('assets'),want=aa===null?null:aa.split(',').map(x=>x.trim()).filter(Boolean);
  const shown=this._a?[]:(want?all.filter(([id])=>want.includes(id)):all).slice(0,4),rest=this._a?[]:all.filter(e=>!shown.includes(e));
  shown.forEach(([id,r])=>sets.forEach(k=>{const g=r['g_'+k]||r[k];F.push({type:'Feature',properties:{k:k==='usual'?'usual':'plan',o:mix<0?1:k==='usual'?Math.max(.15,1-mix):Math.max(.15,mix)},geometry:{type:'LineString',coordinates:g}});}));
  BUSES.forEach((b,i)=>F.push({type:'Feature',properties:{k:'bus'},geometry:{type:'LineString',coordinates:BUSES['g'+i]||b}}));
  m.getSource('routes').setData({type:'FeatureCollection',features:F});
  (this.tks||[]).forEach(t=>t.mk.remove());(this.bs||[]).forEach(t=>t.mk.remove());(this.fm||[]).forEach(t=>t.remove());this.tks=[];this.bs=[];this.fm=[];
  (this.cls||[]).forEach(c=>c.remove());this.cls=[];
  if(this.has('trucks')&&rest.length){const ps=rest.map(([id,r])=>r[sets[0]][0]),c=[ps.reduce((a,p)=>a+p[0],0)/ps.length,ps.reduce((a,p)=>a+p[1],0)/ps.length],e=document.createElement('div');e.className='cl';e.title=rest.map(x=>x[0]).join(', ');e.textContent='+'+rest.length;this.cls.push(this.marker(e,c));}
  if(this.has('trucks'))shown.forEach(([id,r],i)=>sets.forEach(k=>{if(sets.length>1&&((k==='usual'&&mix>.5)||(k==='plan'&&mix<=.5)))return;const g=r['g_'+k]||r[k],e=document.createElement('div');e.className='tk'+(k==='usual'?' us':'');e.innerHTML=`<div class="b"><hc-icon name="${r.icon}" size="11" stroke="2"></hc-icon></div><span class="t">${id}</span><span class="nb"></span>`;const mk=this.marker(e,g[0],'left');this.tks.push({mk,g,L:cum(g),ph:i*.37%1,per:16+i%3*5,el:e,bd:e.querySelector('.nb')});}));
  if(this.has('buses'))BUSES.forEach((b,i)=>{const g=BUSES['g'+i]||b,e=document.createElement('div');e.className='bus';const mk=this.marker(e,g[0]);this.bs.push({mk,g,L:cum(g),ph:i*.23,per:60});});
  if(this._a&&this.has('trucks'))this._a.forEach(a=>{const e=document.createElement('div');e.className='tk';e.innerHTML=`<div class="b"><hc-icon name="${a.icon||'truck'}" size="11" stroke="2"></hc-icon></div><span class="t">${a.id}</span>`;this.fm.push(this.marker(e,[a.lon,a.lat],'left'));});
  this.step(performance.now());}
 step(now){const t=RM()?0:now/1000;(this.tks||[]).forEach(o=>{let u=(t/o.per+o.ph)%1;u=u<.5?u*2:2-u*2;o.mk.setLngLat(along(o.g,o.L,u));});(this.bs||[]).forEach(o=>{const u=(t/o.per+o.ph)%1;o.mk.setLngLat(along(o.g,o.L,u));});this.cluster(this.tks);
  if(this.hasAttribute('spin')&&this.map&&!RM()){this.map.setBearing(this.num('bearing',0)+Math.sin(t*.05)*18);}}
 loop(){const f=()=>{if(!this.map)return;if(this._vis!==false&&!document.hidden)this.step(performance.now());this.t=setTimeout(f,this.hasAttribute('spin')?40:80);};f();}
}
customElements.define('hawa-gl',HawaGL);
window.HawaGL={ST,episode,stationValue,band,AQI};
})();
