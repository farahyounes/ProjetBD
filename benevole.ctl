LOAD DATA
INFILE 'benevole.csv'
APPEND
INTO TABLE benevole
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
(
    benevole_id,
    nom,
    fonction,
    age,
    mail,
    date_embauche DATE "YYYY-MM-DD",
    refuge_id
)
