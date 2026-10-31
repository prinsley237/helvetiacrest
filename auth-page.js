(function(){
var $=function(s,c){return (c||document).querySelector(s)},$$=function(s,c){return Array.prototype.slice.call((c||document).querySelectorAll(s))};
function toast(message){var element=$('#ts');if(!element)return;element.textContent=message;element.classList.add('s');clearTimeout(element.h);element.h=setTimeout(function(){element.classList.remove('s')},2600)}

document.addEventListener('click',function(event){var link=event.target.closest('[data-t]');if(!link)return;event.preventDefault();toast(link.dataset.t+' (static preview)')});
$$('.eye').forEach(function(button){button.onclick=function(){var input=button.parentNode.querySelector('input'),show=input.type==='password';input.type=show?'text':'password';button.textContent=show?'Hide':'Show'}});

var password=$('#rp');
if(password)password.addEventListener('input',function(){var value=password.value,score=0;if(value.length>=8)score++;if(/[A-Z]/.test(value)&&/[a-z]/.test(value))score++;if(/\d/.test(value))score++;if(/[^A-Za-z0-9]/.test(value))score++;var meter=$('#mt');meter.style.width=(score*25)+'%';meter.style.background=['#DC2626','#EA580C','#D4A83A','#16A34A','#16A34A'][score]});

$$('form').forEach(function(form){form.addEventListener('submit',async function(event){event.preventDefault();var registering=!!form.closest('#v-register'),valid=true;
$$('.fld',form).forEach(function(field){var input=field.querySelector('input'),value=input.value.trim(),invalid=false;
if(input.type==='email')invalid=!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);else if(input.id==='rp')invalid=value.length<8;else if(input.id==='rc')invalid=value!==password.value||!value;else invalid=!value;
field.classList.toggle('bad',invalid);if(invalid)valid=false});
if(!valid)return;
var client=window.helvetiaSupabase;if(!client){toast('Supabase is not configured. Add the project URL and public key to supabase-config.js.');return}
var button=$('.btn',form),email,passwordValue;button.classList.add('loading');
try{
if(registering){email=$('#re',form).value.trim();passwordValue=$('#rp',form).value;var signUp=await client.auth.signUp({email:email,password:passwordValue,options:{data:{full_name:$('#rn',form).value.trim()},emailRedirectTo:new URL('dashboard.html',window.location.href).toString()}});if(signUp.error)throw signUp.error;if(signUp.data.session){window.location.href='dashboard.html';return}toast('Check your email to confirm your account, then sign in.');return}
email=$('#le',form).value.trim();passwordValue=$('#lp',form).value;var signIn=await client.auth.signInWithPassword({email:email,password:passwordValue});if(signIn.error)throw signIn.error;window.location.href='dashboard.html'
}catch(error){toast(error.message||'Unable to connect. Please try again.')}finally{button.classList.remove('loading')}
})});

$$('canvas.fx').forEach(function(canvas){var context=canvas.getContext('2d'),width,height,particles=[];function resize(){width=canvas.width=canvas.offsetWidth;height=canvas.height=canvas.offsetHeight}resize();addEventListener('resize',resize);
for(var i=0;i<40;i++)particles.push({x:Math.random()*1200,y:Math.random()*1200,r:Math.random()*1.6+.4,v:Math.random()*.3+.1,a:Math.random()*6});
(function draw(){if(canvas.offsetWidth){context.clearRect(0,0,width,height);particles.forEach(function(particle){particle.y-=particle.v;particle.a+=.02;if(particle.y<-5){particle.y=height+5;particle.x=Math.random()*width}context.beginPath();context.arc(particle.x%width+Math.sin(particle.a)*7,particle.y,particle.r,0,6.28);context.fillStyle='rgba(232,194,90,'+(.2+.35*Math.abs(Math.sin(particle.a)))+')';context.fill()})}if(!matchMedia('(prefers-reduced-motion:reduce)').matches)requestAnimationFrame(draw)})()});
})();
