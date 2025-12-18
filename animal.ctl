LOAD DATA
INFILE '/media/sf_IN513/ProjetBD/animal.csv'
APPEND
INTO TABLE animal
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' 
TRAILING NULLCOLS
(
    animal_id,
    nom,
    espece,
    race,
    age,
    sexe,
    date_arrivee_refuge DATE "YYYY-MM-DD",
    date_depart_refuge DATE "YYYY-MM-DD",
    caractere,
    etat_sante,
    statut_adoption,
    rstr_alim,
    traitement,
    refuge_id,
    enclos_id,
    adoptant_id
)