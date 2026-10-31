window.HELVETIA_SUPABASE_URL = 'https://nbdkuptlytknwqtdijxp.supabase.co';
window.HELVETIA_SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_mKUA0hdLwiO_UMeBbEZ5RA_kfKfLz1y';

(function(){
var url=window.HELVETIA_SUPABASE_URL,key=window.HELVETIA_SUPABASE_PUBLISHABLE_KEY;
if(!window.supabase||!url||!key||url.indexOf('YOUR_')!==-1||key.indexOf('YOUR_')!==-1)return;
window.helvetiaSupabase=window.supabase.createClient(url,key);
})();
