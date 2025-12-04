CREATE TABLE refuge (
    refuge_id NUMBER(3) PRIMARY KEY,
    nom VARCHAR(50),
    adresse VARCHAR(100),
    nb_animaux NUMBER(3)
);

CREATE TABLE animal (
    animal_id NUMBER(3) PRIMARY KEY,
    nom VARCHAR(20),
    espece VARCHAR(30),
    race VARCHAR(30),
    age NUMBER(2),
    sexe CHAR(1), -- mettre que 'F' ou 'M'
    date_arrivee_refuge DATE,
    date_depart_refuge DATE,
    taille NUMBER(3),
    caractere VARCHAR(30),
    etat_sante VARCHAR(10), -- 'sain' ou 'malade'
    statut_adoption VARCHAR(20),
    rstr_alim VARCHAR(20),
    traitement CHAR(3), -- 'oui' ou 'non'
    refuge_id NUMBER(3),
    CONSTRAINT fk_refuge_id_animal
    FOREIGN KEY (refuge_id) REFERENCES refuge(refuge_id)
);

CREATE TABLE enclos (
    enclos_id NUMBER(3) PRIMARY KEY,
    capacite NUMBER(2),
    type_enclos VARCHAR(20),
    occupation NUMBER(2),
    refuge_id NUMBER(3),
    CONSTRAINT fk_refuge_id_enclos
    FOREIGN KEY (refuge_id) REFERENCES refuge(refuge_id)
);

CREATE TABLE adoptant (
    adoptant_id NUMBER(4) PRIMARY KEY,
    nom VARCHAR(20),
    age NUMBER(2),
    espace_ext CHAR(3), -- 'oui' ou 'non'
    profil_cherche VARCHAR(30),
    mail VARCHAR(50),
    nb_animaux_possedes NUMBER(2)
);

CREATE TABLE benevole (
    bnv_id NUMBER(3) PRIMARY KEY,
    nom VARCHAR(20),
    fonction VARCHAR(30),
    age NUMBER(2),
    mail VARCHAR(50),
    date_arrivee DATE
);

CREATE TABLE mission (
    mission_id NUMBER(3) PRIMARY KEY,
    description VARCHAR(30),
    statut VARCHAR(20) -- 'realisee' ou 'non realisee'
);

CREATE TABLE fournisseur (
    frs_id NUMBER(3) PRIMARY KEY,
    nom VARCHAR(20),
    type_fourniture VARCHAR(30)
);

CREATE TABLE alimentation (
    alim_id NUMBER(3) PRIMARY KEY,
    type_alim VARCHAR(30),
    qte_dispo NUMBER(3)
);

CREATE TABLE realise (
    mission_id NUMBER(3),
    bnv_id NUMBER(3),
    animal_id NUMBER(3),
    deb_mission TIMESTAMP,
    fin_mission TIMESTAMP,
    PRIMARY KEY (mission_id, bnv_id, animal_id),
    CONSTRAINT fk_mission_id_realise FOREIGN KEY (mission_id) REFERENCES mission(mission_id),
    CONSTRAINT fk_bnv_id_realise FOREIGN KEY (bnv_id) REFERENCES benevole(bnv_id),
    CONSTRAINT fk_animal_id_realise FOREIGN KEY (animal_id) REFERENCES animal(animal_id)
);

CREATE TABLE fournis (
    frs_id NUMBER(3),
    alim_id NUMBER(3),
    qte_fourniture NUMBER(3),
    prix_fourniture NUMBER(7,2),
    date_livraison DATE,
    PRIMARY KEY (frs_id, alim_id),
    CONSTRAINT fk_frs_id_fournis FOREIGN KEY (frs_id) REFERENCES fournisseur(frs_id),
    CONSTRAINT fk_alim_id_fournis FOREIGN KEY (alim_id) REFERENCES alimentation(alim_id)
);

CREATE TABLE mange (
    animal_id NUMBER(3),
    alim_id NUMBER(3),
    qte_conso NUMBER(2),
    PRIMARY KEY (animal_id, alim_id),
    CONSTRAINT fk_animal_id_mange FOREIGN KEY (animal_id) REFERENCES animal(animal_id),
    CONSTRAINT fk_alim_id_mange FOREIGN KEY (alim_id) REFERENCES alimentation(alim_id)
);

CREATE TABLE garde (
    enclos_id NUMBER(3),
    animal_id NUMBER(3),
    deb_sejour DATE,
    fin_sejour DATE,
    PRIMARY KEY (enclos_id, animal_id),
    CONSTRAINT fk_enclos_id_garde FOREIGN KEY (enclos_id) REFERENCES enclos(enclos_id),
    CONSTRAINT fk_animal_id_garde FOREIGN KEY (animal_id) REFERENCES animal(animal_id)
);


-------Requètes-------

--R1
SELECT animal_id
FROM animal
WHERE espece = 'chat'
AND caractere = 'calme'
AND statut_adoption = 'disponible';

--R2
SELECT bnv_id
FROM benevole b
WHERE b.bnv_id NOT IN (SELECT r.bnv_id
                        FROM realise r, mission m
                        WHERE r.mission_id = m.mission_id
                        AND description = 'nourrissage des chats');

--R3
SELECT animal_id
FROM animal
WHERE statut_adoption = 'adopté'
AND EXTRACT(MONTH FROM date_depart_refuge) = 1; -- 1=janvier

--R6
SELECT refuge_id, animal_id
FROM refuge r, animal a, garde g
WHERE a.animal_id = r.animal_id
AND a.animal_id = g.animal_id(+);  -- (+)=LEFT OUTER JOIN

--R9
SELECT AVG(date_depart_refuge - date_arrivee_refuge) AS durée_moyenne_séjour
FROM animal
WHERE statut_adoption = 'adopté';

--R11
SELECT count(r.mission_id) as nb_missions_juin, b.bnv_id
FROM realise r, benevole b
WHERE r.bnv_id = b.bnv_id
AND EXTRACT(MONTH FROM r.deb_mission) = 6
GROUP BY b.bnv_id;

--R12
SELECT *
FROM (SELECT bnv_id
        FROM benevole
        ORDER BY date_arrivee ASC)
WHERE ROWNUM <= 5;

--R14 (A MODIFIER AVEC LA VUE)
SELECT b.nom, animal_id
FROM animal a, benevole b, adoptant ad
WHERE b.nom = ad.nom
AND a.adoptant_id = ad.adoptant_id
AND a.statut_adoption = 'adopté'
AND a.date_depart_refuge IS NOT NULL;