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

-- Comment benevole l’utilise:
SELECT *
FROM Vue_missions_benevoles
WHERE benevole_ID = 2
  AND statut IN ('assignée’);

--V6
CREATE VIEW vue_admin AS
SELECT 
    r.refuge_id,
    r.nom AS nom_refuge,
    (SELECT COUNT(*) FROM animal a WHERE a.refuge_id = r.refuge_id) AS nb_animaux,
    (SELECT COUNT(*) FROM adoption ad WHERE ad.refuge_id = r.refuge_id) AS nb_adoptions,
    (SELECT COUNT(*) FROM benevole b WHERE b.refuge_id = r.refuge_id) AS nb_benevoles,
    (SELECT COUNT(*) FROM enclos e WHERE e.refuge_id = r.refuge_id AND e.occupation = 0) AS nb_enclos_libres,
    (SELECT COUNT(*) FROM enclos e WHERE e.refuge_id = r.refuge_id AND e.occupation != 0) AS nb_enclos_occupees,
    (SELECT COUNT(*) FROM Adoptant) AS nb_total_adoptants_globaux,
    CURRENT_DATE AS date_derniere_mise_a_jour
FROM refuge r;


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

--jeu de données

--refuge

INSERT INTO refuge VALUES (101, 'SPA de Gennevilliers', 'Gennevilliers (Hauts-de-Seine)', 180);
INSERT INTO refuge VALUES (104, 'SPA de Lyon Sud', 'Brignais (Rhône)', 140);
INSERT INTO refuge VALUES (108, 'SPA de Marseille Provence', 'Marseille (Bouches-du-Rhône)', 165);
INSERT INTO refuge VALUES (112, 'SPA de Nantes', 'Carquefou (Loire-Atlantique)', 95);
INSERT INTO refuge VALUES (115, 'SPA de Strasbourg', 'Strasbourg (Bas-Rhin)', 120);

INSERT INTO refuge VALUES (120, 'SPA de Lille', 'Lille (Nord)', 110);
INSERT INTO refuge VALUES (123, 'SPA de Toulouse', 'Toulouse (Haute-Garonne)', 150);
INSERT INTO refuge VALUES (127, 'SPA de Bordeaux', 'Mérignac (Gironde)', 130);
INSERT INTO refuge VALUES (131, 'SPA de Rennes', 'Rennes (Ille-et-Vilaine)', 90);
INSERT INTO refuge VALUES (135, 'SPA de Nice Côte d Azur', 'Nice (Alpes-Maritimes)', 160);

INSERT INTO refuge VALUES (140, 'Refuge de la SPA de Roubaix', 'Roubaix (Nord)', 200);
INSERT INTO refuge VALUES (144, 'SPA de Tours', 'Tours (Indre-et-Loire)', 85);
INSERT INTO refuge VALUES (148, 'SPA d Avignon', 'Avignon (Vaucluse)', 125);
INSERT INTO refuge VALUES (152, 'SPA de Montpellier', 'Montpellier (Hérault)', 145);
INSERT INTO refuge VALUES (156, 'SPA d Orleans', 'Orléans (Loiret)', 100);

INSERT INTO refuge VALUES (160, 'Refuge de l Arche de Noe', 'Île-de-France', 70);
INSERT INTO refuge VALUES (165, 'Refuge Seconde Chance', 'Essonne', 60);
INSERT INTO refuge VALUES (169, 'Refuge Les Amis des Bêtes', 'Loiret', 55);
INSERT INTO refuge VALUES (173, 'Refuge Assistance Animale', 'Paris', 40);
INSERT INTO refuge VALUES (178, 'Refuge Chats Sans Toit', 'Île-de-France', 75);

INSERT INTO refuge VALUES (182, 'Fondation 30 Millions d Amis', 'France', 90);
INSERT INTO refuge VALUES (186, 'Refuge de la Ligue Protectrice', 'Lyon (Rhône)', 65);
INSERT INTO refuge VALUES (190, 'Refuge Animaux en Detresse', 'Hauts-de-France', 105);
INSERT INTO refuge VALUES (195, 'Refuge de la Vallée des Loups', 'Aisne', 50);
INSERT INTO refuge VALUES (201, 'Refuge de l Espoir Animal', 'Normandie', 80);

INSERT INTO refuge VALUES (205, 'SPA de Perpignan', 'Perpignan (Pyrénées-Orientales)', 115);
INSERT INTO refuge VALUES (210, 'SPA de Clermont-Ferrand', 'Clermont-Ferrand (Puy-de-Dôme)', 98);
INSERT INTO refuge VALUES (215, 'SPA de Limoges', 'Limoges (Haute-Vienne)', 72);
INSERT INTO refuge VALUES (220, 'SPA de Besancon', 'Besançon (Doubs)', 68);
INSERT INTO refuge VALUES (225, 'SPA de Mulhouse', 'Mulhouse (Haut-Rhin)', 130);


--mission
INSERT INTO mission VALUES (1, 'Nettoyage quotidien des enclos des chiens', 'realisee');
INSERT INTO mission VALUES (2, 'Nettoyage quotidien des enclos des chats', 'realisee');
INSERT INTO mission VALUES (3, 'Désinfecter la zone de quarantaine', 'assignée');
INSERT INTO mission VALUES (4, 'Mise a jour des dossiers des animaux', 'non realisee');
INSERT INTO mission VALUES (5, 'Distribution matinale des repas chiens', 'assignée');

INSERT INTO mission VALUES (6, 'Activite stimulation chiens ', 'realisee');
INSERT INTO mission VALUES (7, 'Validation finale du dossier adoption ', 'assignée');
INSERT INTO mission VALUES (8, 'Promenade des chiens, matin', 'realisee');
INSERT INTO mission VALUES (9, 'Promenade chiens, apres-midi', 'non realisee');
INSERT INTO mission VALUES (10, 'Surveillance des animaux en soins', 'realisee');

INSERT INTO mission VALUES (11, 'Administration soins medicaux', 'realisee');
INSERT INTO mission VALUES (12, 'Transport animal veterinaire', 'realisee');
INSERT INTO mission VALUES (13, 'Accueil nouveaux animaux refuge', 'assignée');
INSERT INTO mission VALUES (14, 'Installation nouveaux arrivants', 'realisee');
INSERT INTO mission VALUES (15, 'Suivi quarantaine animaux', 'realisee');

INSERT INTO mission VALUES (16, 'Controle etat enclos', 'realisee');
INSERT INTO mission VALUES (17, 'Reparation materiel enclos', 'non realisee');
INSERT INTO mission VALUES (18, 'Nettoyage zone soins', 'realisee');
INSERT INTO mission VALUES (19, 'Gestion stocks alimentaires', 'assignée');
INSERT INTO mission VALUES (20, 'Gestion stocks medicaux', 'non realisee');

INSERT INTO mission VALUES (21, 'Preparation dossiers adoption', 'realisee');
INSERT INTO mission VALUES (22, 'Mise a jour fiches animaux', 'realisee');
INSERT INTO mission VALUES (23, 'Contact familles adoptantes', 'assignée');
INSERT INTO mission VALUES (24, 'Suivi post adoption', 'non realisee');
INSERT INTO mission VALUES (25, 'Organisation planning benevoles', 'realisee');

INSERT INTO mission VALUES (26, 'Aider a former les nouveaux benevoles', 'non realisee');
INSERT INTO mission VALUES (27, 'Accueil public refuge', 'realisee');
INSERT INTO mission VALUES (28, 'Sensibilisation à la protection animale', 'assignée');
INSERT INTO mission VALUES (29, 'Archivage documents refuge', 'realisee');
INSERT INTO mission VALUES (30, 'Preparation evenements du refuge', 'non realisee');


--fournisseurs
INSERT INTO fournisseur VALUES (201, 'Royal Canin', 'Croquettes chiens adultes');
INSERT INTO fournisseur VALUES (202, 'Royal Canin', 'Croquettes chats stérilisés');
INSERT INTO fournisseur VALUES (203, 'Royal Canin', 'Croquettes chiots');

INSERT INTO fournisseur VALUES (204, 'Purina', 'Croquettes chats seniors');
INSERT INTO fournisseur VALUES (205, 'Purina', 'Croquettes chiens sensibles');

INSERT INTO fournisseur VALUES (206, 'Hill s Vet', 'Médicaments');
INSERT INTO fournisseur VALUES (207, 'Hill s Vet', 'Régime rénal animaux');

INSERT INTO fournisseur VALUES (208, 'Virbac', 'Médicaments');
INSERT INTO fournisseur VALUES (209, 'Virbac', 'Produits antiparasitaires');

INSERT INTO fournisseur VALUES (210, 'Beaphar', 'Antipuces et vermifuges');
INSERT INTO fournisseur VALUES (211, 'Beaphar', 'Compléments nutritionnels');

INSERT INTO fournisseur VALUES (212, 'Trixie', 'Jouets chiens');
INSERT INTO fournisseur VALUES (213, 'Trixie', 'Jouets chats');
INSERT INTO fournisseur VALUES (214, 'Trixie', 'Brosses et peignes');

INSERT INTO fournisseur VALUES (215, 'Hunter', 'Colliers pour chiens');
INSERT INTO fournisseur VALUES (216, 'Hunter', 'Laisses');

INSERT INTO fournisseur VALUES (217, 'Ferplast', 'Cages');
INSERT INTO fournisseur VALUES (218, 'Ferplast', 'Caisses de transport');

INSERT INTO fournisseur VALUES (219, 'Cat Best', 'Litiere');
INSERT INTO fournisseur VALUES (220, 'Cat Best', 'Litiere');

INSERT INTO fournisseur VALUES (221, 'Saniterpen', 'Produits desinfection');
INSERT INTO fournisseur VALUES (222, 'Saniterpen', 'Nettoyants bactericides');

INSERT INTO fournisseur VALUES (223, 'Kerbl', 'Lampes chauffantes');
INSERT INTO fournisseur VALUES (224, 'Kerbl', 'Cages');

INSERT INTO fournisseur VALUES (225, 'Zooplus', 'Gamelles');
INSERT INTO fournisseur VALUES (226, 'Zooplus', 'Paniers');

INSERT INTO fournisseur VALUES (227, 'MPS Italia', 'Caisses transport chats');
INSERT INTO fournisseur VALUES (228, 'MPS Italia', 'Caisses transport chiens');

INSERT INTO fournisseur VALUES (229, 'Animed', 'Soins oculaires');
INSERT INTO fournisseur VALUES (230, 'Animed', 'Soins dentaires');

-- alimentation
CREATE SEQUENCE seq_alim START WITH 1;

INSERT INTO alimentation (aliment_ID, type_alim, qte_dispo)
SELECT seq_alim.NEXTVAL, aliment.type_alim, FLOOR(DBMS_RANDOM.VALUE(10, 90))
FROM (
    SELECT 'croquette boeuf chien' AS type_alim FROM dual
    UNION ALL
    SELECT 'croquette poulet chien' FROM dual
    UNION ALL
    SELECT 'croquette boeuf chat' FROM dual
    UNION ALL
    SELECT 'croquette poulet chat' FROM dual
    UNION ALL
    SELECT 'patée chat' FROM dual
    UNION ALL
    SELECT 'patée chien' FROM dual
) aliment
CROSS JOIN (
    SELECT LEVEL AS n FROM dual CONNECT BY LEVEL <= 5
);

-- enclos

INSERT INTO enclos (enclos_id, capacite, type_enclos, occupation, refuge_id)
SELECT seq_enclos.NEXTVAL, FLOOR(DBMS_RANDOM.VALUE(1, 5)), type_enclos, FLOOR(DBMS_RANDOM.VALUE(0, 5)), (SELECT refuge_id FROM refuge ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROWS ONLY)  
FROM (
    SELECT 'chien' AS type_enclos FROM dual
    UNION ALL
    SELECT 'chat' FROM dual
);

-- adoptant 

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (1, 'Farah YOUNES', 20, 'oui', 'chat calme', 'farahyounes@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (2, 'Alyssa Morellon', 20, 'oui', 'chat agité', 'alyssamorellon@spa.com', '4')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (3, 'Mouna Guehairia', 20, 'non', 'chien calme', 'mounaguehairia@spa.com', '2')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (4, 'Mathis Renou', 21, 'oui', 'chat calme', 'mathisrenou@spa.com', '1')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (5, 'Alex Costa', 20, 'oui', 'chien agité', 'alexcosta@spa.com', '6')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (6, 'Julien konstantinov', 20, 'non', 'chien agité', 'julienkonstantinov@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (7, 'Hugo atlan', 23, 'oui', 'chat calme', 'hugoatlan@spa.com', '3')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (8, 'Emerson Kan', 21, 'non', 'chat calme', 'emersonkan@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (9, 'Samy Achaibou', 20, 'non', 'chat agité', 'samyachaibou@spa.com', '1')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (10, 'Béatrice Finance', 30, 'oui', 'chien calme', 'beatricefinance@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (11, 'Sandrine Vial', 15, 'oui', 'chat calme', 'sandrinevial@spa.com', '2')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (12, 'Ider Tseveendorj', 50, 'oui', 'chat calme', 'idertseveendorj@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (13, 'Franck Quessette', 22, 'non', 'chien agité', 'franckquessette@spa.com', '1')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (14, 'Thierry Mautor', 19, 'oui', 'chien calme', 'thierrymautor@spa.com', '2')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (15, 'Aurore Rincheval', 45, 'non', 'chat calme', 'aurorerincheval@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (16, 'Charles-henry Gattoliat', 23, 'oui', 'chat calme', 'charleshenrygattoliat@spa.com', '2')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (17, 'Sébastien Gaumer', 14, 'oui', 'chat agité', 'sébastiengaumer@spa.com', '3')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (18, 'Santiago Vargas Triana', 21, 'oui', 'chien calme', 'santiagovargastriana@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (19, 'Alexandre Mesbah', 33, 'oui', 'chien agité', 'alexandremesbah@spa.com', '2')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (20, 'Yohan Deray', 22, 'oui', 'chien calme', 'yohanderay@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (21, 'Theo larouco', 21, 'oui', 'chat calme', 'theolarouco@spa.com', '1')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (22, 'Julien Bignoles', 20, 'non', 'chien agité', 'julienbignoles@spa.com', '10')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (23, 'Frédérick Cremazy', 55, 'oui', 'chat agité', 'frederickcremazy@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (24, 'Lina Belkhir', 21, 'oui', 'chat calme', 'linabelkhir@spa.com', '4')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (25, 'Jessica karega', 21, 'non', 'chat calme', 'jessicakarega@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (26, 'Hassan Moudani', 25, 'oui', 'chat calme', 'hassanmoudani@spa.com', '1')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (27, 'Ines Scholler', 20, 'non', 'chat calme', 'inesscholler@spa.com', '0')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (28, 'Laurine Cantrel', 17, 'oui', 'chat calme', 'laurinecantrel@spa.com', '3')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (29, 'Lysa Percevault', 22, 'non', 'chat calme', 'lysapercevault@spa.com', '2')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (30, 'Elouan Cossec', 20, 'non', 'chat calme', 'elouancossec@spa.com', '6')

INSERT INTO adoptant (adoptant_id, nom, age, espace_ext, profil_recherche, mail, nb_animaux_possedes)
VALUES (31, 'Sophie Netter', 43, 'oui', 'chien calme', 'sophienetter@spa.com', '1')

-- Réalise
-- pour les soins faisables que par des vétérinaires

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission)
SELECT m.mission_id, b.bnv_id, a.animal_id,
       SYSTIMESTAMP + DBMS_RANDOM.VALUE(0,5),  -- débute entre maintenant et +5 jours
       SYSTIMESTAMP + DBMS_RANDOM.VALUE(5,10)   -- finit entre +5 et +10 jours
FROM mission m
JOIN benevole b ON b.fonction = 'veterinaire'       
JOIN animal a ON a.etat_sante = 'malade'           
WHERE ROWNUM <= 15;

-- pour les missions basiques

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (1, 1, 100, TIMESTAMP '2025-12-16 09:00:00', TIMESTAMP '2025-12-16 11:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (2, 2, 101, TIMESTAMP '2025-12-16 10:00:00', TIMESTAMP '2025-12-16 12:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (3, 3, 102, TIMESTAMP '2025-12-16 11:00:00', TIMESTAMP '2025-12-16 13:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (4, 4, 103, TIMESTAMP '2025-12-16 13:00:00', TIMESTAMP '2025-12-16 15:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (5, 5, 104, TIMESTAMP '2025-12-16 14:00:00', TIMESTAMP '2025-12-16 16:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (6, 6, 105, TIMESTAMP '2025-12-17 09:00:00', TIMESTAMP '2025-12-17 11:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (7, 1, 106, TIMESTAMP '2025-12-17 11:00:00', TIMESTAMP '2025-12-17 13:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (8, 2, 107, TIMESTAMP '2025-12-17 13:00:00', TIMESTAMP '2025-12-17 15:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (9, 3, 108, TIMESTAMP '2025-12-17 15:00:00', TIMESTAMP '2025-12-17 17:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (10, 4, 109, TIMESTAMP '2025-12-18 09:00:00', TIMESTAMP '2025-12-18 11:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (11, 5, 110, TIMESTAMP '2025-12-18 11:00:00', TIMESTAMP '2025-12-18 13:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (12, 6, 111, TIMESTAMP '2025-12-18 13:00:00', TIMESTAMP '2025-12-18 15:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (13, 1, 112, TIMESTAMP '2025-12-19 09:00:00', TIMESTAMP '2025-12-19 11:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (14, 2, 113, TIMESTAMP '2025-12-19 11:00:00', TIMESTAMP '2025-12-19 13:00:00');

INSERT INTO realise (mission_id, bnv_id, animal_id, deb_mission, fin_mission) 
VALUES (15, 3, 114, TIMESTAMP '2025-12-19 13:00:00', TIMESTAMP '2025-12-19 15:00:00');


-- Gardé

INSERT INTO garde (enclos_id, animal_id, deb_sejour, fin_sejour)
SELECT enclos_id, animal_id, 
    SYSDATE + DBMS_RANDOM.VALUE(0, 3),
    SYSDATE + DBMS_RANDOM.VALUE(0, 3) + DBMS_RANDOM.VALUE(7, 120)
FROM enclos e
JOIN animal a ON e.enclos_id = a.enclos_id;
WHERE ROWNUM <=30;

-- Mange 

INSERT INTO mange (animal_id, alim_id, qte_conso)
SELECT a.animal_id, al.alim_id, TRUNC(DBMS_RANDOM.VALUE(100, 400))
FROM animal a
JOIN alimentation al
    ON (a.espece = 'chat' AND al.type_alim LIKE '%chat%')
    OR (a.espece = 'chien' AND al.type_alim LIKE '%chien%')
WHERE ROWNUM <= 30;