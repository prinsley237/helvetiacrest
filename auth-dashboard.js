(function(){
var $=function(s,c){return (c||document).querySelector(s)},$$=function(s,c){return Array.prototype.slice.call((c||document).querySelectorAll(s))};
function toast(m){var t=$('#ts');t.textContent=m;t.classList.add('s');clearTimeout(t.h);t.h=setTimeout(function(){t.classList.remove('s')},2600)}
function show(v){if(['login','register','dashboard'].indexOf(v)<0)v='login';$$('.view').forEach(function(e){e.classList.remove('on')});$('#v-'+v).classList.add('on');scrollTo(0,0);if(v==='dashboard')enter()}
addEventListener('hashchange',function(){show(location.hash.slice(1))});
document.addEventListener('click',function(e){var a=e.target.closest('[data-v],[data-t]');if(!a)return;if(a.dataset.v){e.preventDefault();location.hash=a.dataset.v}else if(a.dataset.t){e.preventDefault();toast(a.dataset.t+' (static preview)')}});
// password eye
$$('.eye').forEach(function(b){b.onclick=function(){var i=b.parentNode.querySelector('input'),s=i.type==='password';i.type=s?'text':'password';b.textContent=s?'Hide':'Show'}});
// strength
var rp=$('#rp');rp.addEventListener('input',function(){var v=rp.value,s=0;if(v.length>=8)s++;if(/[A-Z]/.test(v)&&/[a-z]/.test(v))s++;if(/\d/.test(v))s++;if(/[^A-Za-z0-9]/.test(v))s++;var m=$('#mt');m.style.width=(s*25)+'%';m.style.background=['#DC2626','#EA580C','#D4A83A','#16A34A','#16A34A'][s]});
// forms
function bad(f,on){f.classList.toggle('bad',on)}
$$('form').forEach(function(F){F.addEventListener('submit',function(e){e.preventDefault();var ok=true;
$$('.fld',F).forEach(function(f){var i=f.querySelector('input'),v=i.value.trim(),b=false;
if(i.type==='email')b=!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);else if(i.id==='rp')b=v.length<8;else if(i.id==='rc')b=v!==rp.value||!v;else b=!v;
bad(f,b);if(b)ok=false});
var ag=$('#ag',F);if(ag&&!ag.checked){ok=false;toast('Please accept the terms to continue.')}
if(!ok)return;var btn=$('.btn',F);btn.classList.add('loading');
var n=($('#rn',F)||{}).value,em=($('input[type=email]',F)||{}).value||'';window.__nm=(n||em.split('@')[0]||'Guest');
setTimeout(function(){btn.classList.remove('loading');location.hash='dashboard'},900)})});
// dashboard entrance
function money(v,s){return s+v.toLocaleString('en-US',{minimumFractionDigits:2,maximumFractionDigits:2})}
function enter(){var nm=(window.__nm||'there').split(' ')[0];nm=nm.charAt(0).toUpperCase()+nm.slice(1);$('#hi').textContent='Welcome, '+nm;$('#ini').textContent=nm.charAt(0);
var els=$$('.wc .a'),tot=$('#tot'),t0=performance.now();
(function f(t){var p=Math.min((t-t0)/1800,1),k=1-Math.pow(1-p,4);els.forEach(function(e){e.textContent=money(+e.dataset.to*k,e.dataset.s)});tot.textContent=money(26336.25*k,'$');if(p<1)requestAnimationFrame(f)})(t0);
$$('.bar i').forEach(function(i){i.style.width='0';setTimeout(function(){i.style.width=i.dataset.w+'%'},200)})}
// particles
$$('canvas.fx').forEach(function(c){var x=c.getContext('2d'),W,H,P=[];function r(){W=c.width=c.offsetWidth;H=c.height=c.offsetHeight}r();addEventListener('resize',r);
for(var i=0;i<40;i++)P.push({x:Math.random()*1200,y:Math.random()*1200,r:Math.random()*1.6+.4,v:Math.random()*.3+.1,a:Math.random()*6});
(function d(){if(c.offsetWidth){x.clearRect(0,0,W,H);P.forEach(function(p){p.y-=p.v;p.a+=.02;if(p.y<-5){p.y=H+5;p.x=Math.random()*W}x.beginPath();x.arc(p.x%W+Math.sin(p.a)*7,p.y,p.r,0,6.28);x.fillStyle='rgba(232,194,90,'+(.2+.35*Math.abs(Math.sin(p.a)))+')';x.fill()})}
if(!matchMedia('(prefers-reduced-motion:reduce)').matches)requestAnimationFrame(d)})()});
show(location.hash.slice(1)||'login');
})();