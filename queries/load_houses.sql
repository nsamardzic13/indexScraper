MERGE INTO `dm.dim_houses` AS target
USING `staging.houses` AS source
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
    target.stambena_povrsina_u_m2 = source.stambena_povrsina_u_m2,
    target.broj_soba = source.broj_soba,
    target.godina_izgradnje = source.godina_izgradnje,
    target.godina_zadnje_adaptacije = source.godina_zadnje_adaptacije,
    target.namjestenost = source.namjestenost,
    target.zamjena = source.zamjena,
    target.tip_oglasa = source.tip_oglasa,
    target.prodavac = source.prodavac,
    target.povrsina_okucnice_u_m2 = source.povrsina_okucnice_u_m2,
    target.detaljnije_o_kuci = source.detaljnije_o_kuci,
    target.tip_kuce = source.tip_kuce,
    target.broj_etaza_kuce = source.broj_etaza_kuce,
    target.grijanje = source.grijanje,
    target.tel_ili_mobitel = source.tel_ili_mobitel,
    target.vlastita_sifra_objekta = source.vlastita_sifra_objekta,
    target.energetski_certifikat = source.energetski_certifikat,
    target.orijentacija = source.orijentacija,
    target.dodatna_oprema_prostora = source.dodatna_oprema_prostora,
    target.rezerviranih_parking_mjesta = source.rezerviranih_parking_mjesta,
    target.email = source.email,
    target.kat = source.kat,
    target.o_stanu = source.o_stanu,
    target.drzava = source.drzava,
    target.grad = source.grad,
    target.povrsina_vrta_u_m2 = source.povrsina_vrta_u_m2,
    target.dostupno_od = source.dostupno_od,
    target.broj_etaza_stana = source.broj_etaza_stana,
    target.povrsina_terase_u_m2 = source.povrsina_terase_u_m2,
    target.tip_stana = source.tip_stana,
    target.o_zemljistu = source.o_zemljistu,
    target.motor = source.motor,
    target.povrsina_u_m2 = source.povrsina_u_m2,
    target.pozicija_poslovnog_prostora = source.pozicija_poslovnog_prostora,
    target.tip_nekretnine_za_odmor = source.tip_nekretnine_za_odmor,
    target.namjena_poslovnog_prostora = source.namjena_poslovnog_prostora,
    target.povrsina_balkona_u_m2 = source.povrsina_balkona_u_m2,
    target.o_poslovnom_prostoru = source.o_poslovnom_prostoru,
    target.tip_zemljista = source.tip_zemljista
WHEN NOT MATCHED THEN
  INSERT (id, url, zupanija, objavljeno, broj_prikaza, opis, grad_opcina, naselje, stambena_povrsina_u_m2, broj_soba, godina_izgradnje, godina_zadnje_adaptacije, namjestenost, zamjena, tip_oglasa, prodavac, povrsina_okucnice_u_m2, detaljnije_o_kuci, tip_kuce, broj_etaza_kuce, grijanje, tel_ili_mobitel, vlastita_sifra_objekta, energetski_certifikat, orijentacija, dodatna_oprema_prostora, rezerviranih_parking_mjesta, email, kat, o_stanu, drzava, grad, povrsina_vrta_u_m2, dostupno_od, broj_etaza_stana, povrsina_terase_u_m2, tip_stana, o_zemljistu, motor, povrsina_u_m2, pozicija_poslovnog_prostora, tip_nekretnine_za_odmor, namjena_poslovnog_prostora, povrsina_balkona_u_m2, o_poslovnom_prostoru, tip_zemljista)
  VALUES (
    source.id, source.url, source.zupanija, source.objavljeno, source.broj_prikaza, source.opis, source.grad_opcina, source.naselje, source.stambena_povrsina_u_m2, source.broj_soba, source.godina_izgradnje, source.godina_zadnje_adaptacije, source.namjestenost, source.zamjena, source.tip_oglasa, source.prodavac, source.povrsina_okucnice_u_m2, source.detaljnije_o_kuci, source.tip_kuce, source.broj_etaza_kuce, source.grijanje, source.tel_ili_mobitel, source.vlastita_sifra_objekta, source.energetski_certifikat, source.orijentacija, source.dodatna_oprema_prostora, source.rezerviranih_parking_mjesta, source.email, source.kat, source.o_stanu, source.drzava, source.grad, source.povrsina_vrta_u_m2, source.dostupno_od, source.broj_etaza_stana, source.povrsina_terase_u_m2, source.tip_stana, source.o_zemljistu, source.motor, source.povrsina_u_m2, source.pozicija_poslovnog_prostora, source.tip_nekretnine_za_odmor, source.namjena_poslovnog_prostora, source.povrsina_balkona_u_m2, source.o_poslovnom_prostoru, source.tip_zemljista
  );

MERGE INTO `dm.fact_houses` AS target
USING `staging.houses` AS source
ON target.id = source.id
WHEN MATCHED AND target.cijena != source.cijena THEN
  UPDATE SET
    target.valid_to = DATE_ADD(CURRENT_DATE(), INTERVAL -1 DAY), -- Set previous record's valid_to date
    target.is_current = false -- Set previous record as not current
WHEN NOT MATCHED THEN
  INSERT (id, cijena, valid_from, valid_to, is_current)
  VALUES (source.id, source.cijena, CURRENT_DATE(), DATE '9999-12-31', true);