function sonum_tarama
% SONUM_TARAMA  Şekil 7 (makale ~10,3 Hz, thd ~1,05 der) hangi sönümle tutuyor?
% Viskoz sürtünme (döner tabla değerleri ya da sıfır) x temas sönümü xi.
fid = fopen('sonum_tarama_log.txt','w');
fprintf(fid, '%-10s %6s %8s %9s\n', 'viskoz', 'xi', 'f [Hz]', 'A [der]');
for visk = [1 0]
    for xi = [0 0.0025 0.005 0.01]
        p = ghaffari_param('sekil7');
        if ~visk, p.cm = 0; p.cle = 0; p.cl = 0; end
        p.xis = xi; p.cs = 2*xi*p.ks/p.wa;
        o = ghaffari2013(p, 11.67, 20);
        s = 'cm, cle'; if ~visk, s = 'yok'; end
        fprintf(fid, '%-10s %6.4f %8.2f %9.3f\n', s, xi, o.f_Hz, o.A_deg);
        fprintf('%-10s %6.4f %8.2f %9.3f\n', s, xi, o.f_Hz, o.A_deg);
    end
end
fclose(fid);
end
