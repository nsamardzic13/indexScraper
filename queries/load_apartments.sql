MERGE INTO `dm.dim_apartments` AS target
USING `staging.apartments` AS source
ON target.id = source.id
WHEN MATCHED THEN
  UPDATE SET
    target.url = source.url,
    target.zupanija = source.zupanija,
    target.objavljeno = source.objavljeno,
    target.broj_prikaza = source.broj_prikaza,
    target.opis = source.opis,
    target.grad_opcina = source.grad_opcina,
    target.naselje = source.naselje,
    target.broj_soba = source.broj_soba,
    target.godina_izgradnje = source.godina_izgradnje,
    target.godina_zadnje_adaptacije = source.godina_zadnje_adaptacije,
    target.stambena_povrsina_u_m2 = source.stambena_povrsina_u_m2,
    target.energetski_certifikat = source.energetski_certifikat,
    target.namjestenost = source.namjestenost,
    target.kat = source.kat,
    target.zamjena = source.zamjena,
    target.tip_oglasa = source.tip_oglasa,
    target.prodavac = source.prodavac,
    target.broj_etaza_stana = source.broj_etaza_stana,
    target.o_stanu = source.o_stanu,
    target.orijentacija = source.orijentacija,
    target.tip_stana = source.tip_stana,
    target.ulaz = source.ulaz,
    target.grijanje = source.grijanje,
    target.dodatna_oprema_prostora = source.dodatna_oprema_prostora,
    target.tel_ili_mobitel = source.tel_ili_mobitel,
    target.email = source.email,
    target.rezerviranih_parking_mjesta = source.rezerviranih_parking_mjesta,
    target.povrsina_balkona_u_m2 = source.povrsina_balkona_u_m2,
    target.vlastita_sifra_objekta = source.vlastita_sifra_objekta,
    target.povrsina_terase_u_m2 = source.povrsina_terase_u_m2,
    target.povrsina_vrta_u_m2 = source.povrsina_vrta_u_m2,
    target.dostupno_od = source.dostupno_od,
    target.drzava = source.drzava,
    target.grad = source.grad,
    target.povrsina_okucnice_u_m2 = source.povrsina_okucnice_u_m2,
    target.tip_nekretnine_za_odmor = source.tip_nekretnine_za_odmor,
    target.broj_etaza_kuce = source.broj_etaza_kuce,
    target.tip_kuce = source.tip_kuce,
    target.detaljnije_o_kuci = source.detaljnije_o_kuci,
    target.pozicija_poslovnog_prostora = source.pozicija_poslovnog_prostora,
    target.motor = source.motor,
    target.povrsina_u_m2 = source.povrsina_u_m2,
    target.o_zemljistu = source.o_zemljistu,
    target.namjena_poslovnog_prostora = source.namjena_poslovnog_prostora,
    target.tip_zemljista = source.tip_zemljista,
    target.o_poslovnom_prostoru = source.o_poslovnom_prostoru
WHEN NOT MATCHED THEN
  INSERT (id, url, zupanija, objavljeno, broj_prikaza, opis, grad_opcina, naselje, broj_soba, godina_izgradnje, godina_zadnje_adaptacije, stambena_povrsina_u_m2, energetski_certifikat, namjestenost, kat, zamjena, tip_oglasa, prodavac, broj_etaza_stana, o_stanu, orijentacija, tip_stana, ulaz, grijanje, dodatna_oprema_prostora, tel_ili_mobitel, email, rezerviranih_parking_mjesta, povrsina_balkona_u_m2, vlastita_sifra_objekta, povrsina_terase_u_m2, povrsina_vrta_u_m2, dostupno_od, drzava, grad, povrsina_okucnice_u_m2, tip_nekretnine_za_odmor, broj_etaza_kuce, tip_kuce, detaljnije_o_kuci, pozicija_poslovnog_prostora, motor, povrsina_u_m2, o_zemljistu, namjena_poslovnog_prostora, tip_zemljista, o_poslovnom_prostoru)
  VALUES (
    source.id, source.url, source.zupanija, source.objavljeno, source.broj_prikaza, source.opis, source.grad_opcina, source.naselje, source.broj_soba, source.godina_izgradnje, source.godina_zadnje_adaptacije, source.stambena_povrsina_u_m2, source.energetski_certifikat, source.namjestenost, source.kat, source.zamjena, source.tip_oglasa, source.prodavac, source.broj_etaza_stana, source.o_stanu, source.orijentacija, source.tip_stana, source.ulaz, source.grijanje, source.dodatna_oprema_prostora, source.tel_ili_mobitel, source.email, source.rezerviranih_parking_mjesta, source.povrsina_balkona_u_m2, source.vlastita_sifra_objekta, source.povrsina_terase_u_m2, source.povrsina_vrta_u_m2, source.dostupno_od, source.drzava, source.grad, source.povrsina_okucnice_u_m2, source.tip_nekretnine_za_odmor, source.broj_etaza_kuce, source.tip_kuce, source.detaljnije_o_kuci, source.pozicija_poslovnog_prostora, source.motor, source.povrsina_u_m2, source.o_zemljistu, source.namjena_poslovnog_prostora, source.tip_zemljista, source.o_poslovnom_prostoru
  );

MERGE INTO `dm.fact_apartments` AS target
USING `staging.apartments` AS source
ON target.id = source.id
WHEN MATCHED AND target.cijena != source.cijena THEN
  UPDATE SET
    target.valid_to = DATE_ADD(CURRENT_DATE(), INTERVAL -1 DAY), -- Set previous record's valid_to date
    target.is_current = false -- Set previous record as not current
WHEN NOT MATCHED BY SOURCE THEN 
  UPDATE SET
    target.valid_to = DATE_ADD(CURRENT_DATE(), INTERVAL -1 DAY), -- Set previous record's valid_to date
    target.is_current = false -- Set previous record as not current
WHEN NOT MATCHED BY TARGET THEN
  INSERT (id, cijena, valid_from, valid_to, is_current)
  VALUES (source.id, source.cijena, CURRENT_DATE(), DATE '9999-12-31', true);