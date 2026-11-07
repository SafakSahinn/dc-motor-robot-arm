function n = esp32_senkron(sp, sira)
% ESP32_SENKRON  PC ile kartın bayt akışını yeniden hizalar; atılan bayt sayısını döndürür.
%   Benzersiz yüklü bir T_YANKI gönderir, kendi yankısını görene dek gelen her şeyi atar.
%   Neden (esp32.md Adım 6): ara sıra bir yanıt PC'ye ancak bir SONRAKİ istek yazılınca ulaşıyor
%   (kart isteği işlemiş, UART'ı boşalmış: takılma USB / Windows yolunda). Zaman aşımından sonra
%   gelen bu eski yanıt bir sonraki isteğin yanıtı sanılır ("bozuk"). Senkron eski baytları atar;
%   yankının kendisi takılırsa yeni yankı onu iter (en çok 5 deneme).
n = 0;
for dn = 1:5
    imza = uint8(randi([0 255], 1, 8));
    esp32_yaz(sp, prot_paketle(1, sira + dn - 1, imza));
    hedef = [uint8([165 90 129]), typecast(uint16(mod(sira + dn - 1, 65536)), 'uint8'), uint8(8), imza];
    al = uint8([]);  t0 = tic;
    while toc(t0) < 1.0
        k = sp.BytesToRead;
        if k > 0
            b = NET.createArray('System.Byte', k);  sp.Read(b, 0, k);  al = [al, uint8(b)]; %#ok<AGROW>
            j = strfind(char(al), char(hedef));
            if ~isempty(j) && numel(al) >= j(1) + 15
                n = n + j(1) - 1;
                kalan = al(j(1) + 16:end);       % yankıdan sonrası (olmamalı)
                n = n + numel(kalan);
                return
            end
        else
            pause(0.005);
        end
    end
    n = n + numel(al);
end
error("esp32:senkron", "senkron kurulamadı (5 yankı)");
end
