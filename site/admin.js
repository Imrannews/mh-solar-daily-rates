import {initializeApp} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-app.js";
import {getAuth,signInWithEmailAndPassword,onAuthStateChanged,signOut} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-auth.js";
import {getFirestore,collection,addDoc,updateDoc,deleteDoc,doc,onSnapshot,serverTimestamp,writeBatch} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-firestore.js";
import {seedRates} from "./seed-data.js";
const config={apiKey:"AIzaSyD10lAtuJ4dtlvMEq1IWnhqWTdwTw2ONs",authDomain:"mh-solar-daily-rates.firebaseapp.com",projectId:"mh-solar-daily-rates",storageBucket:"mh-solar-daily-rates.firebasestorage.app",messagingSenderId:"488848209199",appId:"1:488848209199:android:da96ee3b48c10e49111dda"};
// apiKey is read-only client configuration; authorization is enforced by Firebase Auth + Firestore rules.
const app=initializeApp(config),auth=getAuth(app),db=getFirestore(app);let rows=[],editing=null;
const $=s=>document.querySelector(s),fmt=n=>new Intl.NumberFormat("en-PK").format(Number(n)||0);
$("#loginBtn").onclick=async()=>{try{await signInWithEmailAndPassword(auth,$("#email").value.trim(),$("#password").value)}catch(e){$("#loginError").textContent=e.message.replace("Firebase: ","")}};
$("#logoutBtn").onclick=()=>signOut(auth);
onAuthStateChanged(auth,user=>{if(user){$("#loginPanel").hidden=true;$("#adminPanel").hidden=false;listen()}else{$("#loginPanel").hidden=false;$("#adminPanel").hidden=true}});
function listen(){onSnapshot(collection(db,"solar_rates"),snap=>{rows=snap.docs.map(d=>({id:d.id,...d.data()}));renderList()})}
$("#rateForm").onsubmit=async e=>{e.preventDefault();const data={brand:$("#brand").value.trim(),model:$("#model").value.trim(),watt:Number($("#watt").value),price:Number($("#price").value),category:$("#category").value,status:$("#status").value,isOffer:$("#offer").checked,updatedAt:serverTimestamp()};if(!data.brand||!data.model||!data.price)return;if(editing)await updateDoc(doc(db,"solar_rates",editing),data);else await addDoc(collection(db,"solar_rates"),data);reset()};
$("#cancelBtn").onclick=reset;
function reset(){editing=null;$("#rateForm").reset();$("#rateId").value=""}
function edit(r){editing=r.id;$("#brand").value=r.brand||"";$("#model").value=r.model||"";$("#watt").value=r.watt||"";$("#price").value=r.price||"";$("#category").value=r.category||"Solar Panel";$("#status").value=r.status||"In Stock";$("#offer").checked=r.isOffer===true;window.scrollTo({top:0,behavior:"smooth"})}
async function remove(r){if(confirm(`Delete ${r.brand} • ${r.model}?`))await deleteDoc(doc(db,"solar_rates",r.id))}
function renderList(){const q=($("#adminSearch").value||"").toLowerCase();const list=rows.filter(r=>`${r.brand} ${r.model}`.toLowerCase().includes(q));$("#adminList").innerHTML=list.map(r=>`<div class="admin-row"><div><b>${esc(r.brand)}</b><br><small>${esc(r.model)}</small></div><div><b>Rs. ${fmt(r.price)}</b><br><small>${r.category||""} • ${r.watt||""}W</small></div><div><small>${r.status||"In Stock"}</small></div><div class="row-actions"><button data-edit="${r.id}">Edit</button> <button class="danger" data-del="${r.id}">Delete</button></div></div>`).join("")||'<div class="loading">No rates yet.</div>';document.querySelectorAll("[data-edit]").forEach(b=>b.onclick=()=>edit(rows.find(r=>r.id===b.dataset.edit)));document.querySelectorAll("[data-del]").forEach(b=>b.onclick=()=>remove(rows.find(r=>r.id===b.dataset.del)))}
$("#adminSearch").oninput=renderList;
$("#seedBtn").onclick=async()=>{if(!confirm("Import the starter rates into Firestore? Existing records will remain."))return;const batch=writeBatch(db);seedRates.forEach(r=>batch.set(doc(collection(db,"solar_rates")), {...r,updatedAt:serverTimestamp()}));await batch.commit();alert("Starter rates imported.")};
function esc(s){return String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]))}