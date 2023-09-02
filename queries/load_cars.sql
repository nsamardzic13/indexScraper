MERGE INTO `dm.dim_cars` AS target
USING `staging.cars` AS source
ON target.id = source.id
WHEN MATCHED THEN
  UPDATE SET
    target.url = source.url,
    target.zupanija = source.zupanija,
    target.objavljeno = source.objavljeno,
    target.broj_prikaza = source.broj_prikaza,
    target.opis = source.opis,
    target.tip = source.tip,
    target.motor = source.motor,
    target.stanje_vozila = source.stanje_vozila,
    target.prijedeni_kilometri = source.prijedeni_kilometri,
    target.godina_proizvodnje = source.godina_proizvodnje,
    target.snaga_motora_kw = source.snaga_motora_kw,
    target.godina_modela = source.godina_modela,
    target.prodavac = source.prodavac,
    target.boja_vozila = source.boja_vozila,
    target.broj_stupnjeva_na_mjenjacu = source.broj_stupnjeva_na_mjenjacu,
    target.broj_vrata = source.broj_vrata,
    target.oblik_karoserije = source.oblik_karoserije,
    target.ovjes = source.ovjes,
    target.starost = source.starost,
    target.vlasnik = source.vlasnik,
    target.vrsta_pogona = source.vrsta_pogona,
    target.nacini_placanja = source.nacini_placanja,
    target.vrsta_mjenjaca = source.vrsta_mjenjaca,
    target.autoradio = source.autoradio,
    target.klimatizacija_vozila = source.klimatizacija_vozila,
    target.garancija_za_vozilo = source.garancija_za_vozilo,
    target.radni_obujam_cm3 = source.radni_obujam_cm3,
    target.ostali_podaci_o_vozilu = source.ostali_podaci_o_vozilu,
    target.dodatna_oprema_vozila = source.dodatna_oprema_vozila,
    target.oprema_za_udobnost_u_vozilu = source.oprema_za_udobnost_u_vozilu,
    target.sigurnost = source.sigurnost,
    target.sigurnost_protiv_krade = source.sigurnost_protiv_krade,
    target.zracni_jastuci = source.zracni_jastuci,
    target.registriran_do = source.registriran_do,
    target.marka = source.marka,
    target.model = source.model,
    target.prosjecna_potrosnja_goriva_l_100km = source.prosjecna_potrosnja_goriva_l_100km,
    target.razlog_prodaje = source.razlog_prodaje,
    target.godina_prve_registracije = source.godina_prve_registracije,
    target.gorivo = source.gorivo,
    target.ocuvanost_vozila = source.ocuvanost_vozila,
    target.naplata = source.naplata,
    target.radni_obujam_u_cm3 = source.radni_obujam_u_cm3,
    target.mjenjac = source.mjenjac,
    target.model_vozila = source.model_vozila
WHEN NOT MATCHED THEN
  INSERT (id, url, zupanija, objavljeno, broj_prikaza, opis, tip, motor, stanje_vozila, prijedeni_kilometri, godina_proizvodnje, snaga_motora_kw, godina_modela, prodavac, boja_vozila, broj_stupnjeva_na_mjenjacu, broj_vrata, oblik_karoserije, ovjes, starost, vlasnik, vrsta_pogona, nacini_placanja, vrsta_mjenjaca, autoradio, klimatizacija_vozila, garancija_za_vozilo, radni_obujam_cm3, ostali_podaci_o_vozilu, dodatna_oprema_vozila, oprema_za_udobnost_u_vozilu, sigurnost, sigurnost_protiv_krade, zracni_jastuci, registriran_do, marka, model, prosjecna_potrosnja_goriva_l_100km, razlog_prodaje, godina_prve_registracije, gorivo, ocuvanost_vozila, naplata, radni_obujam_u_cm3, mjenjac, model_vozila)
  VALUES (
    source.id, source.url, source.zupanija, source.objavljeno, source.broj_prikaza, source.opis, source.tip, source.motor, source.stanje_vozila, source.prijedeni_kilometri, source.godina_proizvodnje, source.snaga_motora_kw, source.godina_modela, source.prodavac, source.boja_vozila, source.broj_stupnjeva_na_mjenjacu, source.broj_vrata, source.oblik_karoserije, source.ovjes, source.starost, source.vlasnik, source.vrsta_pogona, source.nacini_placanja, source.vrsta_mjenjaca, source.autoradio, source.klimatizacija_vozila, source.garancija_za_vozilo, source.radni_obujam_cm3, source.ostali_podaci_o_vozilu, source.dodatna_oprema_vozila, source.oprema_za_udobnost_u_vozilu, source.sigurnost, source.sigurnost_protiv_krade, source.zracni_jastuci, source.registriran_do, source.marka, source.model, source.prosjecna_potrosnja_goriva_l_100km, source.razlog_prodaje, source.godina_prve_registracije, source.gorivo, source.ocuvanost_vozila, source.naplata, source.radni_obujam_u_cm3, source.mjenjac, source.model_vozila
  );

MERGE INTO `dm.fact_cars` AS target
USING `staging.cars` AS source
ON target.id = source.id
WHEN MATCHED AND target.cijena != source.cijena THEN
  UPDATE SET
    target.valid_to = DATE_ADD(CURRENT_DATE(), INTERVAL -1 DAY), -- Set previous record's valid_to date
    target.is_current = false -- Set previous record as not current
WHEN NOT MATCHED THEN
  INSERT (id, cijena, valid_from, valid_to, is_current)
  VALUES (source.id, source.cijena, CURRENT_DATE(), DATE '9999-12-31', true);