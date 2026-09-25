import {initializeApp} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-app.js";
import {getFirestore,collection,onSnapshot} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-firestore.js";
import {seedRates} from "./seed-data.js";
const firebaseConfig={apiKey:"AIzaSyD10lAtuJ4dtlvMEq1IWnhqWTdwTwz2ONs",authDomain:"mh-solar-daily-rates.firebaseapp.com",projectId:"mh-solar-daily-rates",storageBucket:"mh-solar-daily-rates.firebasestorage.app",messagingSenderId:"488848209199",appId:"1:488848209199:android:da96ee3b48c10e49111dda"};
const db=getFirestore(initializeApp(firebaseConfig));let rates=[...seedRates],filter="All",query="";
const $=s=>document.querySelector(s),fmt=n=>new Intl.NumberFormat("en-PK").format(Number(n)||0);
const MAIN_BRANDS=["LONGI","JINKO","JA SOLAR","CANADIAN","TRINA"];
function render(){const brands=[...new Set(rates.map(x=>x.brand))];$("#updatedDate").textContent=new Date().toLocaleDateString("en-PK",{day:"2-digit",month:"short",year:"numeric"});
const mainRates=MAIN_BRANDS.map(brand=>{const items=rates.filter(x=>String(x.brand||"").toUpperCase()===brand);if(!items.length)return null;const item=items.reduce((best,x)=>(Number(x.price||0)/Number(x.watt||1))<(Number(best.price||0)/Number(best.watt||1))?x:best,items[0]);return {brand,item,ppw:Math.round((Number(item.price||0)/Number(item.watt||1))*100)/100};}).filter(Boolean);
$("#mainBrandRates").innerHTML=mainRates.length?mainRates.map(({brand,item,ppw})=>`<div class="brand-rate"><div class="brand-name"><b>${esc(brand)}</b><small>${esc(item.watt||"—")}W • ${esc(item.model||"")}</small></div><div class="brand-price"><b>Rs. ${fmt(item.price)}</b><small>Rs. ${ppw}/W</small></div></div>`).join("`):'<div class="rate-loading">No brand rates available.</div>';
const cats=["All",...new Set(rates.map(x=>x.category))];$("#filters").innerHTML=cats.map(c=>`<button class="chip ${c===filter?"active":""}" data-filter="${c}">${c}</button>`).join("");
let list=rates.filter(x=>(filter==="All"||x.category===filter)&&(!query||`${x.brand} ${x.model} ${x.watt}`.toLowerCase().includes(query.toLowerCase())));
$("#ratesGrid").innerHTML=list.length?list.map(x=>`<article class="rate"><div class="rate-top"><span class="badge">${x.status||"In Stock"}</span>${x.isOffer?'<span class="badge">OFFER</span>':""}</div><h3>${esc(x.brand)} • ${esc(x.model)}</h3><p>${esc(x.category)} • ${x.watt||"—"}W</p><div class="price">Rs. ${fmt(x.price)}</div><small>Price can vary by city/supplier</small></article>`).join(""):'<div class="loading">No matching rates found.</div>';
document.querySelectorAll("[data-filter]").forEach(b=>b.onclick=()=>{filter=b.dataset.filter;render()});document.querySelectorAll("[data-cat]").forEach(b=>b.onclick=()=>{filter=b.dataset.cat;document.querySelector("#rates").scrollIntoView();render()})}
function esc(s){return String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]))}
$("#search").oninput=e=>{query=e.target.value;render()};
onSnapshot(collection(db,"solar_rates"),snap=>{if(!snap.empty){rates=snap.docs.map(d=>({id:d.id,...d.data()}));}render()},()=>render());render();