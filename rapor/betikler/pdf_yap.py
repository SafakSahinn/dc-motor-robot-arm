import sys,os,pymupdf;sys.stdout.reconfigure(encoding='utf-8')
K=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','simulasyon','simulink')
out=sys.argv[1]
d=pymupdf.open(sys.argv[2] if len(sys.argv)>2 else 'ham.pdf')
for f in ('kol_model.slx','sm_kol_model.slx','sm_motor_model.slx','kol_model_kur.m','sm_model_kur.m','blok_tesis.m','blok_sensor.m','blok_kontrolcu.m','blok_ayrik.m','blok_yuk.m','blok_surucu.m','blok_akim.m','sim_param.m','referans_uret.m','dogrula_2.m','dogrula_5a.m','README.md'):
    d.embfile_add(f, open(os.path.join(K,f),'rb').read(), filename=f, desc='Simulink tasarım dosyası')
d.save(out, garbage=3, deflate=True)
d=pymupdf.open(out)
print('sayfa',len(d),'ek',d.embfile_count(), os.path.getsize(out)//1024,'KB')
print('kisa:',[(p.number+1,len(p.get_text())) for p in d if len(p.get_text())<500])
