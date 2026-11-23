function b1g3_ozet
% B1-G senaryo 3 (dış bozucu) ayrıntılı özeti; b1g_ozet'ten (B1G_ONEK=b1g3) sonra çalıştırılır, log sonuna ekler.
% 180° hedefleri hariç (net tork sıfırı; 2a'da zaten başarısız). Her koşul x tesis x yöntem için
% (iki başlangıç x 6 hedef-yön x 3 tohum = /36):
%   H7     : son 1 s ölçütü (konum + yüz)
%   çevir  : bozucu penceresinde (3-5 s) gerçek dişli torku iki işareti de aldı (yüz en az bir kez çevrildi)
%   kalıcı : son yüz ilk yüzün tersi (bozucu yüzü kalıcı çevirdi; dB'de beklenen)
%   yakala : kalıcı çevrilen koşularda kestiricinin son yüzü doğru
cd(fileparts(mfilename('fullpath')));
s = load('b1g3_sonuc.mat');  R = s.R;  K = s.K;  M = s.M;
fid = fopen('b1g3_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n--- Senaryo 3 ayrıntı (180° hariç, /36: H7 çevir kalıcı yakala/kalıcı) ---\n');
mS = {'olay', 'olay+yok', 'momentum L100 e0.06', 'lenze 0.03', 'edilgen'};
yaz('%-26s %-11s', 'koşul', 'tesis');
for m = mS, yaz(' | %-21s', m{1}(1:min(9,end))); end
yaz('\n');
for kk = 1:size(K,1)
    for a = {'sürtünmeli', 'sürtünmesiz'}
        yaz('%-26s %-11s', K{kk,1}, a{1});
        for m = mS
            j = strcmp({R.kosul}, K{kk,1}) & strcmp({R.sur}, a{1}) & strcmp({R.yontem}, m{1});
            r = R(j);  c = abs(r(1).hedef - 180) > 1;
            H = vertcat(r.h7);  C = vertcat(r.gercekCevir);  S = vertcat(r.yuzS);  Kk = vertcat(r.yuzK);
            s0 = sign(round(sind(r(1).hedef)*1e9));  s0(s0 == 0) = r(1).Yn(s0 == 0);
            P = S == -s0;  Y = P & Kk == S;
            H = H(:,c);  C = C(:,c);  P = P(:,c);  Y = Y(:,c);
            yaz(' | %2d %2d %2d %2d/%-2d     ', nnz(H), nnz(C), nnz(P), nnz(Y), nnz(P));
        end
        yaz('\n');
    end
end
fclose(fid);
end
