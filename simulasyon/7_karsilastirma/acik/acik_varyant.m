function V = acik_varyant(p0)
% ACIK_VARYANT  Karşılaştırılan yoklama bölgesi seçenekleri (acik_karsilastir, acik_birlestir).
mgl = p0.mgl;
V = struct('ad', {'180 (eski)', '180+360', 'tork 1°', 'tork 2°', 'tork 3°'}, ...
           'bolge', {'180', '180+360', 'tork', 'tork', 'tork'}, ...
           'esik', {NaN, NaN, mgl*sind(1), mgl*sind(2), mgl*sind(3)});
end
