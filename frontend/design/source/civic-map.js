(function(){
if(customElements.get('civic-map'))return;
const PL=[
 {id:'mundka',name:'Mundka',area:'West Delhi',lon:77.035,lat:28.682,v:437,d:+38,cause:'Regional smoke'},
 {id:'wazirpur',name:'Wazirpur',area:'North West Delhi',lon:77.165,lat:28.700,v:402,d:+51,cause:'Open burning'},
 {id:'ghazipur',name:'Ghazipur',area:'East Delhi',lon:77.329,lat:28.625,v:388,d:+64,cause:'Open burning'},
 {id:'anand',name:'Anand Vihar',area:'East Delhi',lon:77.316,lat:28.647,v:212,d:+22,cause:'Road dust'},
 {id:'shahdara',name:'Shahdara',area:'Shahdara',lon:77.289,lat:28.673,v:186,d:-12,cause:'Traffic'},
 {id:'ito',name:'ITO',area:'Central Delhi',lon:77.241,lat:28.629,v:164,d:-8,cause:'Traffic'},
 {id:'okhla',name:'Okhla Phase 2',area:'South East Delhi',lon:77.271,lat:28.531,v:138,d:+9,cause:'Road dust'},
 {id:'punjabi',name:'Punjabi Bagh',area:'West Delhi',lon:77.131,lat:28.674,v:112,d:-21,cause:'Traffic'},
 {id:'jahangirpuri',name:'Jahangirpuri',area:'North West Delhi',lon:77.171,lat:28.733,v:104,d:-6,cause:'Road dust'},
 {id:'rkpuram',name:'RK Puram',area:'South West Delhi',lon:77.187,lat:28.563,v:94,d:-15,cause:'Traffic'},
 {id:'dwarka',name:'Dwarka',area:'South West Delhi',lon:77.072,lat:28.571,v:78,d:-10,cause:'Road dust'}];
const SCH=[[77.323,28.636],[77.336,28.631],[77.318,28.618],[77.041,28.690],[77.028,28.673],[77.160,28.707],[77.309,28.656]];
const ROUTES={
 'T-12':{plan:[[77.300,28.623],[77.316,28.647],[77.315,28.668]],usual:[[77.300,28.623],[77.294,28.604],[77.306,28.594]]},
 'I-3':{plan:[[77.296,28.606],[77.329,28.625]],usual:[[77.296,28.606],[77.302,28.616]]},
 'ASG-07':{plan:[[77.302,28.651],[77.314,28.646]],usual:[[77.302,28.651],[77.300,28.660]]},
 'SW-03':{plan:[[77.315,28.672],[77.316,28.650]],usual:[[77.300,28.700],[77.312,28.690]]}};
const COL=['#2E7D4F','#7AA83B','#C9A227','#E07A2E','#C8372D','#7E1F3D'];
const band=v=>v<=30?0:v<=60?1:v<=90?2:v<=120?3:v<=250?4:5;
const NAMES=['Good','Satisfactory','Moderate','Poor','Very poor','Severe'];
const RM=()=>window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches;
let LP;const lib=()=>window.maplibregl?Promise.resolve():(LP=LP||new Promise((res,rej)=>{const s=document.createElement('script');s.src='https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js';s.onload=res;s.onerror=rej;document.head.appendChild(s);}));
let BP;const boundary=()=>BP=BP||fetch('./delhi.geojson').then(r=>r.json()).catch(()=>null);
const rc={};function osrm(p){const k=p.map(q=>q.join(',')).join(';');if(rc[k])return rc[k];let c=null;try{c=JSON.parse(localStorage.getItem('civic-r:'+k));}catch(e){}if(c)return rc[k]=Promise.resolve(c);
 const ac=new AbortController();setTimeout(()=>ac.abort(),5000);
 return rc[k]=fetch('https://router.project-osrm.org/route/v1/driving/'+k+'?overview=full&geometries=geojson',{signal:ac.signal}).then(r=>r.json()).then(j=>{const g=j.routes[0].geometry.coordinates;try{localStorage.setItem('civic-r:'+k,JSON.stringify(g));}catch(e){}return g;}).catch(()=>p);}
const CSS=`:host{display:block;position:relative;overflow:hidden;background:#F4F1EA;isolation:isolate;z-index:0}#m{position:absolute;inset:0}
.maplibregl-ctrl-attrib{font:12px 'IBM Plex Sans',sans-serif!important;background:rgba(251,250,246,.85)!important}
.pin{position:relative;width:0;height:0;cursor:pointer}.pin i{position:absolute;left:-6px;top:-6px;width:12px;height:12px;border-radius:50%;border:2px solid #FBFAF6;box-sizing:border-box}
.pin.sel i{outline:2px solid #1F3F9A;outline-offset:3px}
.lab{position:absolute;white-space:nowrap;background:#FBFAF6;border:1px solid #DDD8CC;border-radius:6px;padding:5px 10px;font:500 15px/1.2 'IBM Plex Sans',sans-serif;color:#1B1B1B;display:flex;gap:8px;align-items:baseline;box-shadow:0 1px 2px rgba(27,27,27,.08)}
.lab.sel{border-color:#1F3F9A;box-shadow:0 0 0 1px #1F3F9A}.lab span{font:500 14px 'IBM Plex Mono',monospace;color:#55524C}
.lab.r{left:14px;top:-15px}.lab.l{right:14px;top:-15px}.lab.b{left:-40px;top:14px}.lab.t{left:-40px;bottom:14px}
.sc{width:12px;height:12px;background:#FBFAF6;border:1.5px solid #1B1B1B;border-radius:2px;box-sizing:border-box}
.tk{width:20px;height:20px;border-radius:5px;background:#1F3F9A;color:#fff;display:grid;place-items:center;font:600 9px 'IBM Plex Mono',monospace;box-shadow:0 0 0 2px #FBFAF6}`;
const SIDE={mundka:'r',wazirpur:'t',ghazipur:'r',anand:'r',shahdara:'t',ito:'l',okhla:'r',punjabi:'b',jahangirpuri:'r',rkpuram:'l',dwarka:'b'};
class CivicMap extends HTMLElement{
 static get observedAttributes(){return['selected','mode','layers','center','zoom','top','threshold','hour'];}
 constructor(){super();const r=this.attachShadow({mode:'open'});r.innerHTML=`<link rel="stylesheet" href="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css"><style>${CSS}</style><div id="m"></div>`;this.box=r.getElementById('m');this.mk=[];}
 num(a,d){const v=parseFloat(this.getAttribute(a));return isNaN(v)?d:v;}
 connectedCallback(){if(this.map)return;this.vis=true;this.io=new IntersectionObserver(e=>{this.vis=e[e.length-1].isIntersecting;});this.io.observe(this);
  lib().then(()=>{if(!this.isConnected)return;const c=(this.getAttribute('center')||'77.18,28.64').split(',').map(Number),inter=this.getAttribute('interactive')!=='false';
   this.map=new maplibregl.Map({container:this.box,style:'https://tiles.openfreemap.org/styles/positron',center:c,zoom:this.num('zoom',10.2),interactive:inter,attributionControl:false,fadeDuration:0,dragRotate:false});this.map.addControl(new maplibregl.AttributionControl({compact:true}),'top-left');
   if(inter)this.map.scrollZoom.setWheelZoomRate(1/320);
   this.map.on('load',()=>this.setup());this.ro=new ResizeObserver(()=>this.map&&this.map.resize());this.ro.observe(this);});}
 disconnectedCallback(){cancelAnimationFrame(this.raf);this.io&&this.io.disconnect();this.ro&&this.ro.disconnect();this.map&&this.map.remove();this.map=null;this.ready=false;}
 attributeChangedCallback(n){if(!this.ready)return;if(n==='center'||n==='zoom'){const c=(this.getAttribute('center')||'77.18,28.64').split(',').map(Number);this.map.easeTo({center:c,zoom:this.num('zoom',10.2),duration:RM()?0:900});return;}this.update();}
 mute(){const m=this.map;m.getStyle().layers.forEach(l=>{try{
   if(l.type==='background')m.setPaintProperty(l.id,'background-color','#F4F1EA');
   else if(l.id.includes('water')&&l.type==='fill')m.setPaintProperty(l.id,'fill-color','#CFE0EA');
   else if(l.id.includes('water')&&l.type==='line')m.setPaintProperty(l.id,'line-color','#B9D1DF');
   else if(l.type==='fill'&&/park|wood|grass|landcover/.test(l.id))m.setPaintProperty(l.id,'fill-color','#E6E6DA');
   else if(l.type==='fill'&&/landuse|residential|building/.test(l.id))m.setPaintProperty(l.id,'fill-color','#EDE9DF');
   else if(l.type==='line'&&/highway|road|transportation|bridge|tunnel/.test(l.id))m.setPaintProperty(l.id,'line-color',/motorway|trunk|major|primary/.test(l.id)?'#C9C3B6':'#DDD8CC');
   else if(l.type==='symbol'&&/poi|housenum|transit|rail/.test(l.id))m.setLayoutProperty(l.id,'visibility','none');
   else if(l.type==='symbol'){m.setPaintProperty(l.id,'text-color','#55524C');m.setPaintProperty(l.id,'text-halo-color','#F4F1EA');}
   else if(l.type==='line'&&/boundary|admin/.test(l.id))m.setLayoutProperty(l.id,'visibility','none');}catch(e){}});}
 setup(){const m=this.map;this.mute();const b4=(m.getStyle().layers.find(l=>l.type==='symbol')||{}).id;
  m.addSource('nct',{type:'geojson',data:{type:'FeatureCollection',features:[]}});
  m.addLayer({id:'nct-line',type:'line',source:'nct',paint:{'line-color':'#55524C','line-width':1.4,'line-opacity':.7}},b4);
  boundary().then(g=>{if(g&&this.map)m.getSource('nct').setData(g);});
  m.addSource('pl',{type:'geojson',data:{type:'FeatureCollection',features:[]}});
  const R=(z1,z2)=>['interpolate',['exponential',2],['zoom'],9,['*',['get','r'],z1],14,['*',['get','r'],z2]];
  m.addLayer({id:'blob',type:'circle',source:'pl',paint:{'circle-color':['get','c'],'circle-radius':R(16,420),'circle-blur':1,'circle-opacity':.55}},b4);
  m.addLayer({id:'blob2',type:'circle',source:'pl',paint:{'circle-color':['get','c'],'circle-radius':R(7,170),'circle-blur':.7,'circle-opacity':.55}},b4);
  m.addSource('rt',{type:'geojson',data:{type:'FeatureCollection',features:[]}});
  m.addLayer({id:'rt-u',type:'line',source:'rt',filter:['==',['get','k'],'usual'],layout:{'line-cap':'round'},paint:{'line-color':'#8C877D','line-width':2.5,'line-dasharray':[1.5,1.5]}});
  m.addLayer({id:'rt-p',type:'line',source:'rt',filter:['==',['get','k'],'plan'],layout:{'line-cap':'round','line-join':'round'},paint:{'line-color':'#1F3F9A','line-width':3.5}});
  this.routes={};Promise.all(Object.entries(ROUTES).map(([id,r])=>Promise.all([osrm(r.plan),osrm(r.usual)]).then(([p,u])=>{this.routes[id]={plan:p,usual:u};}))).then(()=>{this.t0=performance.now();this.update();});
  this.ready=true;this.update();this.loop();}
 has(l){return(this.getAttribute('layers')||'').split(',').includes(l);}
 update(){const m=this.map;if(!m)return;const mode=this.getAttribute('mode')||'now',th=this.num('threshold',91),sel=this.getAttribute('selected')||'',hr=this.num('hour',0),F=1+0.14*(Math.cos(2*Math.PI*(hr-18)/24)-Math.cos(2*Math.PI*(-18)/24))+0.2*Math.exp(-Math.pow((hr-42)/12,2)),PLs=PL.map(p=>Object.assign({},p,{v:Math.round(p.v*F)}));
  const shown=PLs.filter(p=>mode==='change'?Math.abs(p.d)>=8:p.v>=th);
  m.getSource('pl').setData({type:'FeatureCollection',features:shown.map(p=>{const c=mode==='change'?(p.d>0?'#B3261E':'#1F3F9A'):COL[band(p.v)],r=mode==='change'?Math.min(1.6,.5+Math.abs(p.d)/45):Math.min(1.6,.45+(p.v-90)/300);return{type:'Feature',properties:{c,r},geometry:{type:'Point',coordinates:[p.lon,p.lat]}};})});
  this.mk.forEach(x=>x.remove());this.mk=[];const add=(el,ll)=>{const k=new maplibregl.Marker({element:el,anchor:'center'}).setLngLat(ll).addTo(m);this.mk.push(k);return k;};
  if(this.has('schools'))SCH.forEach(s=>{const e=document.createElement('div');e.className='sc';e.title='School';add(e,s);});
  const top=this.num('top',3),ranked=PLs.slice().sort((a,b)=>b.v-a.v).slice(0,top).map(p=>p.id);
  shown.forEach(p=>{const e=document.createElement('div');e.className='pin'+(sel===p.id?' sel':'');const col=mode==='change'?(p.d>0?'#B3261E':'#1F3F9A'):COL[band(p.v)];
   let h=`<i style="background:${col}"></i>`;if(sel===p.id||(!sel&&ranked.includes(p.id))||(sel&&ranked.includes(p.id)&&this.hasAttribute('keep-top'))){const val=mode==='change'?(p.d>0?'+':'−')+Math.abs(p.d):p.v;h+=`<div class="lab ${SIDE[p.id]}${sel===p.id?' sel':''}">${p.name}<span>${val}</span></div>`;}
   e.innerHTML=h;e.addEventListener('click',()=>this.dispatchEvent(new CustomEvent('civic-pick',{detail:{id:p.id},bubbles:true,composed:true})));add(e,[p.lon,p.lat]);});
  const rf=[];this.tk=[];if(this.has('routes')&&this.routes)Object.entries(this.routes).forEach(([id,r])=>{if(this.has('usual'))rf.push({type:'Feature',properties:{k:'usual'},geometry:{type:'LineString',coordinates:r.usual}});rf.push({type:'Feature',properties:{k:'plan',id},geometry:{type:'LineString',coordinates:r.plan}});
   if(this.has('trucks')){const e=document.createElement('div');e.className='tk';e.textContent=id.replace('-','');this.tk.push({mk:add(e,r.plan[0]),p:r.plan});}});
  this.rf=rf;m.getSource('rt').setData({type:'FeatureCollection',features:rf});}
 loop(){const f=n=>{this.raf=requestAnimationFrame(f);if(!this.vis||!this.ready||!this.rf||!this.rf.length)return;if(n-(this.l||0)<50)return;this.l=n;
  const draw=this.has('draw'),T=RM()?1:Math.min(1,((n-(this.t0||n))/2600));
  if(draw){const cut=this.rf.map(f=>{if(f.properties.k!=='plan')return f;const c=f.geometry.coordinates,k=Math.max(2,Math.round(c.length*T));return{type:'Feature',properties:f.properties,geometry:{type:'LineString',coordinates:c.slice(0,k)}};});this.map.getSource('rt').setData({type:'FeatureCollection',features:cut});if(T>=1&&!this.done){this.done=true;}}
  const u=RM()?1:((n/1000)/14)%1;this.tk.forEach((t,i)=>{const c=t.p,uu=draw?Math.min(T,1)*.999:((u+i*.23)%1),idx=Math.min(c.length-1,Math.floor(uu*(c.length-1)));t.mk.setLngLat(c[idx]);});};this.raf=requestAnimationFrame(f);}
}
customElements.define('civic-map',CivicMap);
window.Civic={PL,COL,band,NAMES};
})();
