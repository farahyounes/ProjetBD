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
    refuge_id NUMBER(3),
    CONSTRAINT fk_refuge_id_bnv
    FOREIGN KEY (refuge_id) REFERENCES refuge(refuge_id)
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

--R4
SELECT nb_total_animaux, nb_adoptions, nb_adoptions/nb_total_animaux as taux
FROM(
    SELECT
 (SELECT COUNT(*) FROM animal) as nb_total_animaux,
(SELECT COUNT(*)
FROM animal
WHERE statut_adoption='adopte'
AND EXTRACT(YEAR FROM date_depart_refuge)=2023) as nb_adoptions
);


--R5
SELECT a.espece, a.sexe, AVG(a.age) as moy_age
FROM animal a 
GROUP BY a.espece, a.sexe;

--R6
SELECT refuge_id, animal_id
FROM refuge r, animal a, garde g
WHERE a.animal_id = r.animal_id
AND a.animal_id = g.animal_id(+);  -- (+)=LEFT OUTER JOIN

--R7
SELECT r.refuge_id, r.nom
FROM refuge r, animal a, mange m, fournis f
WHERE r.refuge_id=a.refuge_id
AND m.animal_id=a.animal_id
AND f.alim_id=m.alim_id
AND f.date_livraison='2023-09-01';

--R8
SELECT a.race
FROM animal a
WHERE a.statut_adoption='adopte'
AND a.espece='chat'
GROUP BY a.race
HAVING COUNT(*)=(
    SELECT MAX(COUNT(*))
    FROM animal 
    WHERE statut_adoption='adopte'
    AND espece='chat'
    GROUP BY race
);

--R9
SELECT AVG(date_depart_refuge - date_arrivee_refuge) AS durée_moyenne_séjour
FROM animal
WHERE statut_adoption = 'adopté';

--R10
SELECT e.enclos_id
FROM enclos e
WHERE e.occupation .2;

--ou?

SELECT g.enclos_id
FROM garde g
GROUP BY g.enclos_id
HAVING COUNT(g.animal_id) >2;


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

--R13
SELECT b.bnv_id, b.nom
FROM benevole b, realise r, mission m, animal a
WHERE b.bnv_id=r.bnv_id
AND m.mission_id=r.mission_id
AND m.description='nourris' 
AND a.animal_id=r.animal_id
AND a.nom='Twixie'
AND r.deb_mission='2023-05-20';

--R14 (A MODIFIER AVEC LA VUE)
SELECT b.nom, v.animal_id
FROM Vue_adoption v, benevole b, adoptant ad
WHERE b.nom = ad.nom
AND v.adoptant_id = ad.adoptant_id
AND v.date_depart_refuge IS NOT NULL;

--R15
SELECT a.animal_id, a.nom, MAX(r.fin_mission) as dernier_soin, (a.date_depart_refuge-MAX(r.fin_mission)) as delai --le max recup last soin
FROM animal a, realise r, mission m
WHERE a.animal_id=r.animal_id
AND r.mission_id=m.mission_id 
AND a.traitement='oui'
AND m.description='soin'
GROUP By a.animal_id, a.nom, a.date_depart_refuge;

--R16
SELECT adoptant_id, nom, nb_animaux_possedes
FROM adoptant
WHERE nb_animaux_possedes > 1;

--R17
SELECT A.animal_id, A.nom
FROM animal A 
WHERE NOT EXISTS (
    SELECT *
    FROM realise R, mission M
    WHERE R.mission_id = M.mission_id
    AND R.animal_id = A.animal_id
    AND M.description LIKE '%soin%'
);

--R18
SELECT AP.adoptant_id, AP.nom
FROM adoption AD, adoptant AP, animal A 
WHERE AD.adoptant_id = AP.adoptant_id
AND AD.animal_id = A.animal_id
AND A.etat_sante = 'fragile';

--R19
SELECT b.refuge_id, b.bnv_id, COUNT(r.mission_id) as nb_missions
FROM benevole b, realise r
WHERE b.bnv_id = r.bnv_id
GROUP BY b.refuge_id, b.bnv_id
HAVING COUNT(r.mission_id) = 
            (SELECT MAX(COUNT(r2.mission_id))
            FROM benevole b2, realise r2
            WHERE b2.bnv_id = r2.bnv_id
            AND b2.refuge_id = b.refuge_id
            GROUP BY b2.bnv_id);

--R20
SELECT G.animal_id, A.nom, COUNT(DISTINCT G.enclos_ID) AS nb_enclos
FROM garde G, animal A
WHERE A.animal_id = G.animal_id
GROUP BY G.animal_id, A.nom
HAVING COUNT(DISTINCT G.enclos_id) > 2;

--R21
SELECT F.frs_id, FR.nom, F.refuge_id, R.nom, COUNT(DISTINCT FR.type_fourniture) AS nb_types_fournitures
FROM fournis F, fournisseur FR, refuge R
WHERE F.frs_id = FR.frs_id
AND F.refuge_id = R.refuge_id
GROUP BY F.frs_id, FR.nom, F.refuge_id, R.nom
HAVING COUNT(DISTINCT FR.type_fourniture) >= 3;

--R22 
SELECT a.espece, r.refuge_id, r.nom, COUNT(a.animal_ID) as nbr_animaux
FROM animal a, refuge r 
WHERE a.refuge_id=r.refuge_id
GROUP BY a.espece, r.refuge_id, r.nom
HAVING COUNT(*)=(
    SELECT MAX(COUNT(*))
    FROM animal a2
    WHERE a2.espece=a.espece
    GROUP BY a2.refuge_id
);

--R23
SELECT A.animal_id, A.nom, AP.adoptant_id, AP.nom, (A.date_depart_refuge - A.date_arrivee_refuge) AS duree_sejour
FROM adoption AD, animal A, adoptant AP
WHERE AD.animal_id = A.animal_id
AND AD.adoptant_id = AP.adoptant_id
AND (A.date_depart_refuge - A.date_arrivee_refuge) > 180;

--R24
SELECT A.animal_id, A.nom, A.etat_sante, AL.type
FROM mange M, animal A, alimentation AL
WHERE M.animal_id = A.animal_id
AND M.aliment_id = AL.aliment_id
AND AL.type = 'croquette boeuf'  
AND A.etat_sante = 'fragile';


------Vues------

--V1
CREATE VIEW vue_animaux_dispo
SELECT animal_id
FROM animal
WHERE statut_adoption = 'disponible';

--V2
CREATE VIEW vue_adoption
SELECT animal_id, adoptant_id, date_depart_refuge
FROM animal
WHERE statut_adoption = 'adopté';

--V3
CREATE VIEW vue_animaux_benevoles 
SELECT a.animal_id, a.etat_sante, a.statut_adoption, a.caractere, a.rstr_alim, g.enclos_id
FROM animal a, garde g
WHERE a.animal_ID=g.animal_ID;

--V4
CREATE VIEW vue_enclos_benevoles 
SELECT e.enclos_id, e.capacite, COUNT(g.animal_id) AS nbr_animaux_presents
FROM enclos e, garde g 
WHERE e.enclos_id=g.enclos_id
GROUP BY e.enclos_id, e.capacite;

--V5
CREATE VIEW vue_missions_benevoles 
SELECT r.mission_id, r.bnv_id, r.animal_id, r.deb_mission, r.fin_mission, m.description
FROM realise r, mission m
WHERE r.mission_id=m.mission_id;


------Triggers------

--T1
ALTER TABLE adoptant
ADD CONSTRAINT chk_espace_ext
CHECK (espace_ext = 'oui');

--T2
ALTER TABLE adoptant
ADD CONSTRAINT chk_nb_animaux_max
CHECK (nb_animaux_possedes <= 4);

--T3
CREATE OR REPLACE TRIGGER trg_rstr_alim
BEFORE INSERT OR UPDATE ON mange
DECLARE
    v_restriction VARCHAR2(30);
    v_type_alim  VARCHAR2(30);
BEGIN

    SELECT rstr_alim
    INTO v_restriction
    FROM animal
    WHERE animal_id = :NEW.animal_id;

    SELECT type_alim
    INTO v_type_alim
    FROM alimentation
    WHERE alim_id = :NEW.alim_id;

    IF v_restriction IS NOT NULL AND v_restriction = v_type_alim THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cet aliment est incompatible avec la restriction alimentaire de l’animal');
    END IF;
END;
/

--T4
CREATE OR REPLACE TRIGGER trg_espace_enclos
BEFORE INSERT OR UPDATE ON garde

FOR EACH ROW
DECLARE
    v_especes_existantes VARCHAR(30);
    v_especes_nouvelles VARCHAR(30);
BEGIN
   SELECT espece
   INTO v_especes_nouvelles
   FROM animal a 
   WHERE a.animal_id=:NEW.animal_id;

   SELECT a.espece 
   INTO v_especes_existantes
   FROM animal a, garde g 
   WHERE g.animal_id=a.animal_id
   AND g.enclos_id= :NEW.enclos_id
   AND ROWNUM=1;

   IF v_especes_existantes <> v_especes_nouvelles THEN --Le <> pr verif si diff
      RAISE_APPLICATION_ERROR(-20001, 'On ne peut pas mélanger différentes espèces dans un même enclos.');
   END IF;

 EXCEPTION
 WHEN NO_DATA_FOUND THEN
   NULL;
END;
/
   
--T5
CREATE trg_age_min_animal
BEFORE UPDATE OF statut_adoption ON animal

FOR EACH ROW
BEGIN 
   IF :NEW.statut_adoption='adopte' 
      AND :NEW.age <0.25 THEN

    RAISE_APPLICATION_ERROR(-20001, 'Un animal peut être adopté à partir de 3 mois');
   END IF;

END;
/

--T6
ALTER TABLE benevole
ADD CONSTRAINT chk_benevole_age
CHECK(age>=18);

