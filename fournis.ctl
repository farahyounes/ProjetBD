LOAD DATA
INFILE 'fournis.csv'
APPEND
INTO TABLE fournis
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
(
    fournisseur_id,
    alim_id,
    qte_livree,
    qte_dispo,
    date_livraison DATE "YYYY-MM-DD"
)
