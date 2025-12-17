CREATE TABLE refuge (
    refuge_id NUMBER(3) PRIMARY KEY,
    nom VARCHAR(50),
    adresse VARCHAR(100),
    nb_animaux NUMBER(3)
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
    adoptant_id NUMBER(3) PRIMARY KEY,
    nom VARCHAR(30),
    age NUMBER(2),
    espace_ext VARCHAR(3), -- 'oui' ou 'non'
    profil_recherche VARCHAR(30),
    mail VARCHAR(50),
    nb_animaux_possedes NUMBER(2)
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
    caractere VARCHAR(30),
    etat_sante VARCHAR(10), -- 'sain' ou 'malade'
    statut_adoption VARCHAR(20),
    rstr_alim VARCHAR(30),
    traitement VARCHAR(3), -- 'oui' ou 'non'
    refuge_id NUMBER(3),
    enclos_id NUMBER(3),
    adoptant_id NUMBER(3),
    CONSTRAINT fk_refuge_id_animal FOREIGN KEY (refuge_id) REFERENCES refuge(refuge_id),
    CONSTRAINT fk_enclos_id_animal FOREIGN KEY (enclos_id) REFERENCES enclos(enclos_id),
    CONSTRAINT fk_adoptant_id_animal FOREIGN KEY (adoptant_id) REFERENCES adoptant(adoptant_id)
);

CREATE TABLE benevole (
    bnv_id NUMBER(3) PRIMARY KEY,
    nom VARCHAR(20),
    fonction VARCHAR(30),
    age NUMBER(2),
    mail VARCHAR(50),
    date_arrivee DATE,
    refuge_id NUMBER(3),
    CONSTRAINT fk_refuge_id_bnv
    FOREIGN KEY (refuge_id) REFERENCES refuge(refuge_id)
);

CREATE TABLE mission (
    mission_id NUMBER(3) PRIMARY KEY,
    description VARCHAR(50),
    statut VARCHAR(20) -- 'realisee' ou 'non realisee'
);

CREATE TABLE fournisseur (
    frs_id NUMBER(3) PRIMARY KEY,
    nom VARCHAR(20),
    type_fourniture VARCHAR(50)
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
    refuge_id NUMBER(3),
    date_livraison DATE,
    PRIMARY KEY (frs_id, alim_id),
    CONSTRAINT fk_frs_id_fournis FOREIGN KEY (frs_id) REFERENCES fournisseur(frs_id),
    CONSTRAINT fk_alim_id_fournis FOREIGN KEY (alim_id) REFERENCES alimentation(alim_id),
    CONSTRAINT fk_refuge_id_fournis FOREIGN KEY (refuge_id) REFERENCES refuge(refuge_id)
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
AND caractere = 'chat calme'
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
WHERE statut_adoption = 'adopte'
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
WHERE statut_adoption = 'adopte';

--R10
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
AND m.description LIKE '%nourri%' 
AND a.animal_id=r.animal_id
AND a.nom='Twixie'
AND r.deb_mission='2023-05-20';

--R14
SELECT b.nom, v.animal_id
FROM vue_adoption v, benevole b, adoptant ad
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
SELECT A.animal_id, A.nom, A.etat_sante, AL.type_alim
FROM mange M, animal A, alimentation AL
WHERE M.animal_id = A.animal_id
AND M.alim_id = AL.alim_id
AND AL.type_alim = 'croquette boeuf'  
AND A.etat_sante = 'malade';


------Vues------

--V1
CREATE VIEW vue_animaux_dispo AS
SELECT animal_id
FROM animal
WHERE statut_adoption = 'disponible';

--V2
CREATE VIEW vue_adoption AS
SELECT animal_id, adoptant_id, date_depart_refuge
FROM animal
WHERE statut_adoption = 'adopte';

--V3
CREATE VIEW vue_animaux_benevoles AS
SELECT a.animal_id, a.etat_sante, a.statut_adoption, a.caractere, a.rstr_alim, g.enclos_id
FROM animal a, garde g
WHERE a.animal_ID=g.animal_ID;

--V4
CREATE VIEW vue_enclos_benevoles AS
SELECT e.enclos_id, e.capacite, COUNT(g.animal_id) AS nbr_animaux_presents
FROM enclos e, garde g 
WHERE e.enclos_id=g.enclos_id
GROUP BY e.enclos_id, e.capacite;

--V5
CREATE VIEW vue_missions_benevoles AS 
SELECT r.mission_id, r.bnv_id, r.animal_id, r.deb_mission, r.fin_mission, m.description
FROM realise r, mission m
WHERE r.mission_id=m.mission_id;

-- Comment benevole l’utilise:
SELECT *
FROM Vue_missions_benevoles
WHERE bnv_id = 2
  AND statut IN ('assignee');

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
FOR EACH ROW
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

    IF v_restriction IS NOT NULL AND v_restriction <> v_type_alim THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cet aliment est incompatible avec la restriction alimentaire de l’animal');
    END IF;
END;
/

--T4
CREATE OR REPLACE TRIGGER trg_espace_enclos
BEFORE INSERT OR UPDATE ON garde
FOR EACH ROW
DECLARE
    espece_nouvelle VARCHAR2(30);
    espece_existante VARCHAR2(30);
    nombre_animaux NUMBER;
    capacite_max NUMBER;
    espece_incompatible EXCEPTION;
    capacite_depassee EXCEPTION;
    PRAGMA EXCEPTION_INIT(espece_incompatible, -20001);
    PRAGMA EXCEPTION_INIT(capacite_depassee, -20002);
BEGIN
    -- Récupère l'espèce de l'animal à ajouter
    SELECT espece
    INTO espece_nouvelle
    FROM animal
    WHERE animal_id = :NEW.animal_id;
    -- Vérifie si l'enclos contient déjà des animaux
    SELECT COUNT(*)
    INTO nombre_animaux
    FROM garde
    WHERE enclos_id = :NEW.enclos_id;
    -- Récupère la capacité maximale de l'enclos
    SELECT capacite
    INTO capacite_max
    FROM enclos
    WHERE enclos_id = :NEW.enclos_id;
    -- Vérifie si la capacité maximale est dépassée
    IF nombre_animaux >= capacite_max THEN
        RAISE capacite_depassee;
    END IF;
    -- Si l'enclos n'est pas vide, vérifie que les espèces sont compatibles
    IF nombre_animaux > 0 THEN
        SELECT a.espece
        INTO espece_existante
        FROM animal a, garde g
        WHERE g.animal_id = a.animal_id
          AND g.enclos_id = :NEW.enclos_id
          AND ROWNUM = 1;  -- On suppose que toutes les espèces dans l'enclos sont identiques
-- Vérifie si l'espèce de l'animal à ajouter est différente
        IF espece_existante != espece_nouvelle THEN
            RAISE espece_incompatible;
        END IF;
    END IF;
EXCEPTION
    WHEN espece_incompatible THEN
        RAISE_APPLICATION_ERROR(-20001, 'On ne peut pas mélanger différentes espèces dans un même enclos.');
    WHEN capacite_depassee THEN
        RAISE_APPLICATION_ERROR(-20002, 'La capacité maximale de l''enclos est atteinte.');
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
      AND :NEW.age < 3 THEN

    RAISE_APPLICATION_ERROR(-20001, 'Un animal peut être adopté à partir de 3 mois');
   END IF;

END;
/

--T6
ALTER TABLE benevole
ADD CONSTRAINT chk_benevole_age
CHECK(age>=18);

--T7
CREATE OR REPLACE TRIGGER benev_mission
BEFORE INSERT OR UPDATE OF deb_mission, fin_mission, bnv_id ON realise
FOR EACH ROW
DECLARE
    nb_mission NUMBER;
BEGIN
    IF :NEW.bnv_id IS NOT NULL THEN
        SELECT COUNT(*)
        INTO nb_mission
        FROM realise r
        WHERE r.bnv_id = :NEW.bnv_id
          AND (r.mission_id != :NEW.mission_id)
          AND :NEW.deb_mission <= NVL(r.fin_mission, TIMESTAMP '9999-12-31 23:59:59')
          AND NVL(:NEW.fin_mission, TIMESTAMP '9999-12-31 23:59:59') >= r.deb_mission;

        IF nb_mission > 0 THEN
            RAISE_APPLICATION_ERROR(-20001,'Impossible d''assigner cette mission : le bénévole a déjà une mission en cours pendant cette période.');
        END IF;
    END IF;
END;
/

--T8
CREATE OR REPLACE TRIGGER soins_veterinaires
BEFORE INSERT OR UPDATE OF bnv_id, animal_id ON realise
FOR EACH ROW
DECLARE
    fonction_benev  benevole.fonction%TYPE;
    sante_animal   animal.etat_sante%TYPE;
    type_mission   mission.description%TYPE;
BEGIN
    -- Récupérer l'état de santé de l'animal
    SELECT etat_sante
    INTO sante_animal
    FROM animal
    WHERE animal_id = :NEW.animal_id;
    -- Récupérer la fonction du bénévole
    SELECT fonction
    INTO fonction_benev
    FROM benevole
    WHERE bnv_id = :NEW.bnv_id;
    -- Récupérer le type de mission
    SELECT description
    INTO type_mission
    FROM mission
    WHERE mission_id = :NEW.mission_id;
    -- Vérifier que seul un vétérinaire peut un soigner un animal malade
    IF sante_animal = 'malade'
       AND type_mission = 'soins vétérinaires'
       AND fonction_benev <> 'vétérinaire'
    THEN
        RAISE_APPLICATION_ERROR(-20002,'Seul un bénévole vétérinaire peut effectuer des soins sur un animal malade.');
    END IF;
END;
/

--T9
CREATE OR REPLACE TRIGGER animal_adopte_enclos
BEFORE INSERT OR UPDATE OF animal_id ON garde
FOR EACH ROW
DECLARE
    statut animal.statut_adoption%TYPE;
BEGIN
    SELECT statut_adoption
    INTO statut
    FROM animal
    WHERE animal_id = :NEW.animal_id;

    IF statut = 'adopte' THEN
        RAISE_APPLICATION_ERROR(-20010,'Un animal adopté ne peut pas être affecté à un enclos.');
    END IF;
END;
/

--T10
CREATE OR REPLACE TRIGGER maj_statut_animal_adoption
AFTER INSERT ON adoption
FOR EACH ROW
BEGIN
    UPDATE animal
    SET statut_adoption = 'adopté'
    WHERE animal_id = :NEW.animal_id
      AND statut_adoption <> 'adopté';
END;
/

--jeu de données

--refuge
INSERT INTO refuge VALUES (101, 'SPA de Gennevilliers', 'Gennevilliers', 180);
INSERT INTO refuge VALUES (102, 'SPA de Lyon Sud', 'Brignais', 140);
INSERT INTO refuge VALUES (103, 'SPA de Marseille Provence', 'Marseille', 165);
INSERT INTO refuge VALUES (104, 'SPA de Nantes', 'Carquefou', 95);
INSERT INTO refuge VALUES (105, 'SPA de Strasbourg', 'Strasbourg', 120);

INSERT INTO refuge VALUES (106, 'SPA de Lille', 'Lille', 110);
INSERT INTO refuge VALUES (107, 'SPA de Toulouse', 'Toulouse', 150);
INSERT INTO refuge VALUES (108, 'SPA de Bordeaux', 'Mérignac', 130);
INSERT INTO refuge VALUES (109, 'SPA de Rennes', 'Rennes', 90);
INSERT INTO refuge VALUES (110, 'SPA de Nice Côte d Azur', 'Nice', 160);

INSERT INTO refuge VALUES (111, 'SPA de Roubaix', 'Roubaix', 200);
INSERT INTO refuge VALUES (112, 'SPA de Tours', 'Tours', 85);
INSERT INTO refuge VALUES (113, 'SPA Avignon', 'Avignon', 125);
INSERT INTO refuge VALUES (114, 'SPA de Montpellier', 'Montpellier', 145);
INSERT INTO refuge VALUES (115, 'SPA Orleans', 'Orléans', 100);

INSERT INTO refuge VALUES (116, 'Refuge Arche de Noe', 'Versailles', 70);
INSERT INTO refuge VALUES (117, 'Refuge Seconde Chance', 'Paris', 60);
INSERT INTO refuge VALUES (118, 'Refuge Les Amis des Bêtes', 'Toulouse', 55);
INSERT INTO refuge VALUES (119, 'Refuge Assistance Animale', 'Paris', 40);
INSERT INTO refuge VALUES (120, 'Refuge Chats Sans Toit', 'Lyon', 75);

INSERT INTO refuge VALUES (121, 'Fondation 30 Millions dAmis', 'Marseille', 90);
INSERT INTO refuge VALUES (122, 'Refuge Ligue Protectrice', 'Lyon', 65);
INSERT INTO refuge VALUES (123, 'Refuge Animaux en Detresse', 'Bordeaux', 105);
INSERT INTO refuge VALUES (124, 'Refuge Vallée des Loups', 'Lille', 50);
INSERT INTO refuge VALUES (125, 'Refuge Espoir Animal', 'Versailles', 80);

INSERT INTO refuge VALUES (126, 'SPA de Perpignan', 'Perpignan', 115);
INSERT INTO refuge VALUES (127, 'SPA de Clermont-Ferrand', 'Clermont-Ferrand', 98);
INSERT INTO refuge VALUES (128, 'SPA de Limoges', 'Limoges', 72);
INSERT INTO refuge VALUES (129, 'SPA de Besancon', 'Besançon', 68);
INSERT INTO refuge VALUES (130, 'SPA de Mulhouse', 'Mulhouse', 130);

-- adoptant 
INSERT INTO adoptant VALUES (1, 'Farah YOUNES', 20, 'oui', 'chat calme', 'farahyounes@spa.com', 0);
INSERT INTO adoptant VALUES (2, 'Alyssa Morellon', 20, 'oui', 'chat joueur', 'alyssamorellon@spa.com', 4);
INSERT INTO adoptant VALUES (3, 'Mouna Guehairia', 20, 'non', 'chien calme', 'mounaguehairia@spa.com', 2);
INSERT INTO adoptant VALUES (4, 'Mathis Renou', 21, 'oui', 'chat calme', 'mathisrenou@spa.com', 1);
INSERT INTO adoptant VALUES (5, 'Alex Costa', 20, 'oui', 'chien joueur', 'alexcosta@spa.com', 4);
INSERT INTO adoptant VALUES (6, 'Julien Konstantinov', 20, 'non', 'chien energique', 'julienkonstantinov@spa.com', 0);
INSERT INTO adoptant VALUES (7, 'Hugo Atlan', 23, 'oui', 'chat calme', 'hugoatlan@spa.com', 3);
INSERT INTO adoptant VALUES (8, 'Emerson Kan', 21, 'non', 'chat affectueux', 'emersonkan@spa.com', 0);
INSERT INTO adoptant VALUES (9, 'Samy Achaibou', 20, 'non', 'chat sociable', 'samyachaibou@spa.com', 1);
INSERT INTO adoptant VALUES (10, 'Béatrice Finance', 30, 'oui', 'chien calme', 'beatricefinance@spa.com', 0);
INSERT INTO adoptant VALUES (11, 'Sandrine Vial', 15, 'oui', 'chat affectueux', 'sandrinevial@spa.com', 2);
INSERT INTO adoptant VALUES (12, 'Ider Tseveendorj', 50, 'oui', 'chat calme', 'idertseveendorj@spa.com', 0);
INSERT INTO adoptant VALUES (13, 'Franck Quessette', 22, 'non', 'chien joueur', 'franckquessette@spa.com', 1);
INSERT INTO adoptant VALUES (14, 'Thierry Mautor', 19, 'oui', 'chien affectueux', 'thierrymautor@spa.com', 2);
INSERT INTO adoptant VALUES (15, 'Aurore Rincheval', 45, 'non', 'chat calme', 'aurorerincheval@spa.com', 0);
INSERT INTO adoptant VALUES (16, 'Charles-Henry Gattoliat', 23, 'oui', 'chat calme', 'charleshenrygattoliat@spa.com', 2);
INSERT INTO adoptant VALUES (17, 'Sébastien Gaumer', 14, 'oui', 'chat energique', 'sebastiengaumer@spa.com', 3);
INSERT INTO adoptant VALUES (18, 'Santiago Vargas Triana', 21, 'oui', 'chien affectueux', 'santiagovargastriana@spa.com', 0);
INSERT INTO adoptant VALUES (19, 'Alexandre Mesbah', 33, 'oui', 'chien energique', 'alexandremesbah@spa.com', 2);
INSERT INTO adoptant VALUES (20, 'Yohan Deray', 22, 'oui', 'chien affectueux', 'yohanderay@spa.com', 0);
INSERT INTO adoptant VALUES (21, 'Theo Larouco', 21, 'oui', 'chat independant', 'theolarouco@spa.com', 1);
INSERT INTO adoptant VALUES (22, 'Julien Bignoles', 20, 'non', 'chien independant', 'julienbignoles@spa.com', 2);
INSERT INTO adoptant VALUES (23, 'Frédérick Cremazy', 55, 'oui', 'chat independant', 'frederickcremazy@spa.com', 0);
INSERT INTO adoptant VALUES (24, 'Lina Belkhir', 21, 'oui', 'chat calme', 'linabelkhir@spa.com', 4);
INSERT INTO adoptant VALUES (25, 'Jessica Karega', 21, 'non', 'chat sociable', 'jessicakarega@spa.com', 0);
INSERT INTO adoptant VALUES (26, 'Hassan Moudani', 25, 'oui', 'chat joueur', 'hassanmoudani@spa.com', 1);
INSERT INTO adoptant VALUES (27, 'Ines Scholler', 20, 'non', 'chat joueur', 'inesscholler@spa.com', 0);
INSERT INTO adoptant VALUES (28, 'Laurine Cantrel', 17, 'oui', 'chat calme', 'laurinecantrel@spa.com', 3);
INSERT INTO adoptant VALUES (29, 'Lysa Percevault', 22, 'non', 'chat sociable', 'lysapercevault@spa.com', 2);
INSERT INTO adoptant VALUES (30, 'Elouan Cossec', 20, 'non', 'chat calme', 'elouancossec@spa.com', 2);
INSERT INTO adoptant VALUES (31, 'Sophie Netter', 43, 'oui', 'chien sociable', 'sophienetter@spa.com', 1);

--Bénévole
INSERT INTO benevole VALUES (401,'Laurent','soigneur animalier',27,'laurent@spa.fr',DATE '2023-09-12',101);
INSERT INTO benevole VALUES (402,'Morel','vétérinaire',34,'morel@spa.fr',DATE '2022-05-18',101);
INSERT INTO benevole VALUES (403,'Lefevre','accueil du public',22,'lefevre@spa.fr',DATE '2024-02-03',102);
INSERT INTO benevole VALUES (404,'Rousseau','responsable refuge',51,'rousseau@spa.fr',DATE '2016-11-10',102);
INSERT INTO benevole VALUES (405,'Garcia','promeneur canin',25,'garcia@spa.fr',DATE '2023-07-01',103);
INSERT INTO benevole VALUES (406,'Vidal','assistant veterinaire',39,'vidal@spa.fr',DATE '2020-03-22',103);
INSERT INTO benevole VALUES (407,'Blanchard','gestion adoptions',31,'blanchard@spa.fr',DATE '2021-10-05',104);
INSERT INTO benevole VALUES (408,'Faivre','accueil animaux',28,'faivre@spa.fr',DATE '2022-06-14',104);
INSERT INTO benevole VALUES (409,'Chevalier','responsable quarantaine',46,'chevalier@spa.fr',DATE '2018-01-09',105);
INSERT INTO benevole VALUES (410,'Mercier','soigneur animalier',24,'mercier@spa.fr',DATE '2024-01-17',105);
INSERT INTO benevole VALUES (411,'Benoit','promeneur canin',19,'benoit@spa.fr',DATE '2024-03-11',106);
INSERT INTO benevole VALUES (412,'Collet','gestion stocks',44,'collet@spa.fr',DATE '2019-08-27',106);
INSERT INTO benevole VALUES (413,'Renault','soins animaux',29,'renault@spa.fr',DATE '2023-02-15',107);
INSERT INTO benevole VALUES (414,'Julien','accueil adoptants',33,'julien@spa.fr',DATE '2021-09-06',107);
INSERT INTO benevole VALUES (415,'Marchal','agent technique',48,'marchal@spa.fr',DATE '2017-04-20',108);
INSERT INTO benevole VALUES (416,'Lemoine','coordinateur benevoles',41,'lemoine@spa.fr',DATE '2019-12-02',108);
INSERT INTO benevole VALUES (417,'Picard','promeneur canin',26,'picard@spa.fr',DATE '2023-06-08',109);
INSERT INTO benevole VALUES (418,'Gauthier','suivi post adoption',37,'gauthier@spa.fr',DATE '2020-10-19',109);
INSERT INTO benevole VALUES (419,'Leroy','soins animaux',32,'leroy@spa.fr',DATE '2022-01-14',110);
INSERT INTO benevole VALUES (420,'Caron','agent de nettoyage enclos',55,'caron@spa.fr',DATE '2015-05-30',110);
INSERT INTO benevole VALUES (421,'Lopez','vétérinaire',43,'lopez@spa.fr',DATE '2020-02-11',111);
INSERT INTO benevole VALUES (422,'Martin','accueil animaux',21,'martin@spa.fr',DATE '2024-02-01',111);
INSERT INTO benevole VALUES (423,'Robin','vétérinaire',36,'robin@spa.fr',DATE '2021-06-23',112);
INSERT INTO benevole VALUES (424,'Texier','administration',50,'texier@spa.fr',DATE '2016-09-15',112);
INSERT INTO benevole VALUES (425,'Pelletier','gestion stocks',30,'pelletier@spa.fr',DATE '2022-11-07',113);
INSERT INTO benevole VALUES (426,'Herve','agent de nettoyage enclos',27,'herve@spa.fr',DATE '2023-08-19',113);
INSERT INTO benevole VALUES (427,'Fernandez','sensibilisation publique',46,'ferdandez@spa.fr',DATE '2018-03-12',114);
INSERT INTO benevole VALUES (428,'Mallet','accueil du public',23,'mallet@spa.fr',DATE '2024-01-10',114);
INSERT INTO benevole VALUES (429,'Prevost','transport animaux',38,'prevost@spa.fr',DATE '2021-07-29',115);
INSERT INTO benevole VALUES (430,'Alex','responsable site',57,'alex@spa.fr',DATE '2014-10-04',115);

--Animal
INSERT INTO animal VALUES (201,'Rex','chien','Labrador',5,'M',DATE '2022-01-10',NULL,'chien calme','sain','disponible','croquettes boeuf chien','non',101,10,NULL);
INSERT INTO animal VALUES (202,'Olafe','chat','Persan',7,'F',DATE '2020-03-05',DATE '2025-05-10','chat joueur','sain','adopte','croquettes boeuf chat','non',NULL,2,NULL);
INSERT INTO animal VALUES (203,'Max','chien','Berger allemand',7,'M',DATE '2023-11-12',NULL,'chien craintif','malade','disponible','croquettes boeuf chien','oui',101,10,NULL);
INSERT INTO animal VALUES (204,'Mia','chat','Siamois',4,'F',DATE '2023-12-01',NULL,'chat sociable','sain','disponible','croquettes boeuf chat','non',104,20,NULL);
INSERT INTO animal VALUES (205,'Rocky','chien','American staff',6,'M',DATE '2021-10-18',NULL,'chien energique','sain','reserve','croquettes boeuf chien','non',108,11,5);
INSERT INTO animal VALUES (206,'Dior','chat','Maine coon',3,'F',DATE '2024-02-20',DATE '2025-10-06','chat affectueux','sain','adopte','croquettes boeuf chat','non',NULL,8,NULL);
INSERT INTO animal VALUES (207,'Jasmin','chat','Chartreux',5,'F',DATE '2023-10-02',NULL,'chat independant','sain','disponible','croquettes poulet chat','non',115,22,NULL);
INSERT INTO animal VALUES (208,'Ange','chat','Persan',8,'F',DATE '2018-08-14',NULL,'chat calme','malade','disponible','croquettes poulet chat','oui',112,26,NULL);
INSERT INTO animal VALUES (209,'Oscar','chien','Beagle',4,'M',DATE '2023-09-05',NULL,'chien joueur','sain','disponible','croquettes boeuf chien','non',112,12,NULL);
INSERT INTO animal VALUES (210,'Buddy','chien','Golden retriever',3,'M',DATE '2024-01-25',NULL,'chien sociable','sain','reserve','patée chien','non',115,15,10);
INSERT INTO animal VALUES (211,'Lily','chat','Chartreux',5,'F',DATE '2024-10-02',NULL,'chat independant','sain','reserve','croquettes saumon chat','non',115,22,11);
INSERT INTO animal VALUES (212,'Thor','chien','Malinois',6,'M',DATE '2023-07-19',NULL,'chien joueur','sain','disponible','croquettes poulet chien','non',123,13,NULL);
INSERT INTO animal VALUES (213,'Cleo','chat','Bengal',2,'F',DATE '2024-04-01',NULL,'chat sociable','sain','disponible','croquettes saumon chat','non',123,23,NULL);
INSERT INTO animal VALUES (214,'Diesel','chien','Rottweiler',9,'M',DATE '2018-06-11',NULL,'chien calme','malade','disponible','patée chien','oui',120,14,NULL);
INSERT INTO animal VALUES (215,'Perle','chat','Sacré de Birmanie',7,'F',DATE '2019-09-29',DATE '2025-11-12','chat calme','sain','adopte','croquettes saumon chat','non',NULL,12,NULL);
INSERT INTO animal VALUES (216,'Simba','chien','Malinois',3,'M',DATE '2024-02-08',NULL,'chien energique','sain','reserve','croquettes poulet chien','non',102,11,16);
INSERT INTO animal VALUES (217,'Noisette','chat','Europeen',1,'F',DATE '2025-05-12',NULL,'chat joueur','sain','disponible','croquettes saumon chat','non',102,21,NULL);
INSERT INTO animal VALUES (218,'Shadow','chien','Dobermann',5,'M',DATE '2025-11-30',NULL,'chien craintif','sain','disponible','croquettes poulet chien','non',104,20,NULL);
INSERT INTO animal VALUES (219,'Molly','chat','Siamois',4,'F',DATE '2023-12-18',NULL,'chat affectueux','sain','disponible','patée chat','non',104,11,NULL);
INSERT INTO animal VALUES (220,'Baxter','chien','Cocker',10,'M',DATE '2017-05-07',NULL,'chien calme','malade','disponible','patée chien','oui',105,28,NULL);
INSERT INTO animal VALUES (221,'Iris','chat','Europeen',6,'F',DATE '2025-10-21',NULL,'chat calme','sain','disponible','patée chat','non',105,18,NULL);
INSERT INTO animal VALUES (222,'Kira','chien','Border collie',4,'F',DATE '2024-10-12',NULL,'chien joueur','sain','disponible','croquettes boeuf chien','non',123,13,NULL);
INSERT INTO animal VALUES (223,'Plume','chat','Europeen',3,'F',DATE '2024-01-18',NULL,'chat affectueux','sain','disponible','patée chat','non',106,20,NULL);
INSERT INTO animal VALUES (224,'Apollo','chien','Cocker',6,'M',DATE '2023-09-03',NULL,'chien affectueux','sain','reserve','croquettes poulet chien','non',107,12,18);
INSERT INTO animal VALUES (225,'Neige','chat','Angora',5,'F',DATE '2022-11-27',NULL,'chat calme','sain','disponible','patée chat','non',125,22,NULL);
INSERT INTO animal VALUES (226,'Rambo','chien','Teckel',8,'M',DATE '2020-06-22',NULL,'chien sociable','malade','disponible','croquettes boeuf chien','oui',108,14,NULL);
INSERT INTO animal VALUES (227,'Pacha','chat','Persan',2,'F',DATE '2024-03-14',NULL,'chat affectueux','sain','disponible','patée chat','non',125,22,NULL);
INSERT INTO animal VALUES (228,'Leo','chien','Teckel',7,'M',DATE '2020-08-09',NULL,'chien sociable','sain','disponible','croquettes boeuf chien','non',130,13,NULL);
INSERT INTO animal VALUES (229,'Pote','chat','Maine coon',4,'F',DATE '2021-12-05',NULL,'chat independant','sain','reserve','patée chat','non',109,21,22);
INSERT INTO animal VALUES (230,'Atlas','chien','Berger australien',5,'M',DATE '2021-10-30',NULL,'chien calme','sain','reserve','croquettes boeuf chien','non',111,14,23);

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
INSERT INTO mission VALUES (10, 'soins vétérinaires', 'realisee');

INSERT INTO mission VALUES (11, 'Administration soins medicaux', 'realisee');
INSERT INTO mission VALUES (12, 'Transport animal veterinaire', 'realisee');
INSERT INTO mission VALUES (13, 'soins vétérinaires', 'assignée');
INSERT INTO mission VALUES (14, 'Installation nouveaux arrivants', 'realisee');
INSERT INTO mission VALUES (15, 'Suivi quarantaine animaux', 'realisee');

INSERT INTO mission VALUES (16, 'Controle etat enclos', 'realisee');
INSERT INTO mission VALUES (17, 'Reparation materiel enclos', 'non realisee');
INSERT INTO mission VALUES (18, 'Nettoyage zone soins', 'realisee');
INSERT INTO mission VALUES (19, 'Gestion stocks alimentaires', 'assignée');
INSERT INTO mission VALUES (20, 'soins vétérinaires', 'non realisee');

INSERT INTO mission VALUES (21, 'Preparation dossiers adoption', 'realisee');
INSERT INTO mission VALUES (22, 'Mise a jour fiches animaux', 'realisee');
INSERT INTO mission VALUES (23, 'Contact familles adoptantes', 'assignée');
INSERT INTO mission VALUES (24, 'Suivi post adoption', 'non realisee');
INSERT INTO mission VALUES (25, 'Organisation planning benevoles', 'realisee');

INSERT INTO mission VALUES (26, 'Aider a former les nouveaux benevoles', 'non realisee');
INSERT INTO mission VALUES (27, 'Accueil public refuge', 'realisee');
INSERT INTO mission VALUES (28, 'Sensibilisation à la protection animale', 'assignée');
INSERT INTO mission VALUES (29, 'soins vétérinaires', 'realisee');
INSERT INTO mission VALUES (30, 'Preparation evenements du refuge', 'non realisee');

--fournisseurs
INSERT INTO fournisseur VALUES (201, 'Royal Canin', 'Croquettes chiens adultes');
INSERT INTO fournisseur VALUES (202, 'Royal Canin', 'Croquettes chats stérilisés');
INSERT INTO fournisseur VALUES (203, 'Royal Canin', 'Croquettes chiots');

INSERT INTO fournisseur VALUES (204, 'Purina', 'Croquettes chats seniors');
INSERT INTO fournisseur VALUES (205, 'Purina', 'Croquettes chiens sensibles');

INSERT INTO fournisseur VALUES (206, 'Hills Vet', 'Médicaments');
INSERT INTO fournisseur VALUES (207, 'Hills Vet', 'Régime rénal animaux');

INSERT INTO fournisseur VALUES (208, 'Virbac', 'Médicaments');
INSERT INTO fournisseur VALUES (209, 'Virbac', 'Produits antiparasitaires');

INSERT INTO fournisseur VALUES (210, 'Beaphar', 'Antipuces et vermifuges');
INSERT INTO fournisseur VALUES (211, 'Beaphar', 'Compléments nutritionnels');

INSERT INTO fournisseur VALUES (212, 'Trixie', 'Jouets chiens');
INSERT INTO fournisseur VALUES (213, 'Trixie', 'Jouets chats');
INSERT INTO fournisseur VALUES (230, 'Trixie', 'Brosses et peignes');

INSERT INTO fournisseur VALUES (214, 'Hunter', 'Colliers pour chiens');
INSERT INTO fournisseur VALUES (215, 'Hunter', 'Laisses');

INSERT INTO fournisseur VALUES (216, 'Ferplast', 'Cages');
INSERT INTO fournisseur VALUES (217, 'Ferplast', 'Caisses de transport');

INSERT INTO fournisseur VALUES (218, 'Cat Best', 'Litiere');
INSERT INTO fournisseur VALUES (219, 'Cat Best', 'Litiere');

INSERT INTO fournisseur VALUES (220, 'Saniterpen', 'Produits desinfection');
INSERT INTO fournisseur VALUES (221, 'Saniterpen', 'Nettoyants bactericides');

INSERT INTO fournisseur VALUES (222, 'Kerbl', 'Lampes chauffantes');
INSERT INTO fournisseur VALUES (223, 'Kerbl', 'Cages');

INSERT INTO fournisseur VALUES (224, 'Zooplus', 'Gamelles');
INSERT INTO fournisseur VALUES (225, 'Zooplus', 'Paniers');

INSERT INTO fournisseur VALUES (226, 'MPS Italia', 'Caisses transport chats');
INSERT INTO fournisseur VALUES (227, 'MPS Italia', 'Caisses transport chiens');

INSERT INTO fournisseur VALUES (228, 'Animed', 'Soins oculaires');
INSERT INTO fournisseur VALUES (229, 'Animed', 'Soins dentaires');


-- alimentation
CREATE SEQUENCE seq_alim START WITH 1;

INSERT INTO alimentation (alim_id, type_alim, qte_dispo)
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
    SELECT 'croquette saumon chat' FROM dual
    UNION ALL
    SELECT 'patée chat' FROM dual
    UNION ALL
    SELECT 'patée chien' FROM dual
) aliment
CROSS JOIN (
    SELECT LEVEL AS n FROM dual CONNECT BY LEVEL <= 5
);

-- enclos
CREATE SEQUENCE seq_enclos START WITH 1;
INSERT INTO enclos (enclos_id, capacite, type_enclos, occupation, refuge_id)
SELECT seq_enclos.NEXTVAL, FLOOR(DBMS_RANDOM.VALUE(1, 5)), type_enclos, FLOOR(DBMS_RANDOM.VALUE(0, 5)), (SELECT refuge_id FROM refuge ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROWS ONLY)  
FROM (
    SELECT 'chien' AS type_enclos FROM dual
    UNION ALL
    SELECT 'chat' FROM dual
);

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
INSERT INTO realise VALUES (1, 1, 100, TIMESTAMP '2025-12-16 09:00:00', TIMESTAMP '2025-12-16 11:00:00');
INSERT INTO realise VALUES (2, 2, 101, TIMESTAMP '2025-12-16 10:00:00', TIMESTAMP '2025-12-16 12:00:00');
INSERT INTO realise VALUES (3, 3, 102, TIMESTAMP '2025-12-16 11:00:00', TIMESTAMP '2025-12-16 13:00:00');
INSERT INTO realise VALUES (4, 4, 103, TIMESTAMP '2025-12-16 13:00:00', TIMESTAMP '2025-12-16 15:00:00');
INSERT INTO realise VALUES (5, 5, 104, TIMESTAMP '2025-12-16 14:00:00', TIMESTAMP '2025-12-16 16:00:00');
INSERT INTO realise VALUES (6, 6, 105, TIMESTAMP '2025-12-17 09:00:00', TIMESTAMP '2025-12-17 11:00:00');
INSERT INTO realise VALUES (7, 1, 106, TIMESTAMP '2025-12-17 11:00:00', TIMESTAMP '2025-12-17 13:00:00');
INSERT INTO realise VALUES (8, 2, 107, TIMESTAMP '2025-12-17 13:00:00', TIMESTAMP '2025-12-17 15:00:00');
INSERT INTO realise VALUES (9, 3, 108, TIMESTAMP '2025-12-17 15:00:00', TIMESTAMP '2025-12-17 17:00:00');
INSERT INTO realise VALUES (10, 4, 109, TIMESTAMP '2025-12-18 09:00:00', TIMESTAMP '2025-12-18 11:00:00');
INSERT INTO realise VALUES (11, 5, 110, TIMESTAMP '2025-12-18 11:00:00', TIMESTAMP '2025-12-18 13:00:00');
INSERT INTO realise VALUES (12, 6, 111, TIMESTAMP '2025-12-18 13:00:00', TIMESTAMP '2025-12-18 15:00:00');
INSERT INTO realise VALUES (13, 1, 112, TIMESTAMP '2025-12-19 09:00:00', TIMESTAMP '2025-12-19 11:00:00');
INSERT INTO realise VALUES (14, 2, 113, TIMESTAMP '2025-12-19 11:00:00', TIMESTAMP '2025-12-19 13:00:00');
INSERT INTO realise VALUES (15, 3, 114, TIMESTAMP '2025-12-19 13:00:00', TIMESTAMP '2025-12-19 15:00:00');

-- Gardé
INSERT INTO garde (enclos_id, animal_id, deb_sejour, fin_sejour)
SELECT enclos_id, animal_id, 
    SYSDATE + DBMS_RANDOM.VALUE(0, 3),
    SYSDATE + DBMS_RANDOM.VALUE(0, 3) + DBMS_RANDOM.VALUE(7, 120)
FROM enclos e
JOIN animal a ON e.enclos_id = a.enclos_id
WHERE ROWNUM <=30;

-- Mange 
INSERT INTO mange (animal_id, alim_id, qte_conso)
SELECT a.animal_id, al.alim_id, TRUNC(DBMS_RANDOM.VALUE(100, 400))
FROM animal a
JOIN alimentation al
    ON (a.espece = 'chat' AND al.type_alim LIKE '%chat%')
    OR (a.espece = 'chien' AND al.type_alim LIKE '%chien%')
WHERE ROWNUM <= 30;

-- fournis
INSERT INTO fournis VALUES (201,1,50,120,101,DATE '2018-02-15');
INSERT INTO fournis VALUES (201,2,30,80,102,DATE '2018-06-20');
INSERT INTO fournis VALUES (202,3,40,90,103,DATE '2019-03-05');
INSERT INTO fournis VALUES (202,4,25,70,104,DATE '2019-08-12');
INSERT INTO fournis VALUES (203,5,35,100,105,DATE '2020-01-25');
INSERT INTO fournis VALUES (203,6,20,60,106,DATE '2020-07-18');
INSERT INTO fournis VALUES (204,7,45,110,107,DATE '2020-11-03');
INSERT INTO fournis VALUES (204,1,15,40,108,DATE '2021-02-14');
INSERT INTO fournis VALUES (205,2,50,130,109,DATE '2021-05-22');
INSERT INTO fournis VALUES (205,3,30,85,110,DATE '2021-09-01');
INSERT INTO fournis VALUES (206,4,25,70,111,DATE '2022-01-17');
INSERT INTO fournis VALUES (206,5,35,95,112,DATE '2022-04-29');
INSERT INTO fournis VALUES (207,6,40,100,113,DATE '2022-08-12');
INSERT INTO fournis VALUES (207,7,20,50,114,DATE '2022-11-23');
INSERT INTO fournis VALUES (208,1,30,80,115,DATE '2023-02-08');
INSERT INTO fournis VALUES (208,2,25,65,116,DATE '2023-05-19');
INSERT INTO fournis VALUES (209,3,45,120,117,DATE '2023-09-04');
INSERT INTO fournis VALUES (209,4,15,40,118,DATE '2023-12-15');
INSERT INTO fournis VALUES (210,5,50,130,119,DATE '2024-03-10');
INSERT INTO fournis VALUES (210,6,30,85,120,DATE '2024-06-20');
INSERT INTO fournis VALUES (211,7,25,60,121,DATE '2024-09-30');
INSERT INTO fournis VALUES (211,1,35,95,122,DATE '2024-12-11');
INSERT INTO fournis VALUES (212,2,40,110,123,DATE '2025-01-22');
INSERT INTO fournis VALUES (212,3,20,55,124,DATE '2025-04-05');
INSERT INTO fournis VALUES (213,4,30,80,125,DATE '2025-06-16');
INSERT INTO fournis VALUES (213,5,25,65,126,DATE '2025-09-27');
INSERT INTO fournis VALUES (214,6,45,120,127,DATE '2025-11-08');
INSERT INTO fournis VALUES (214,7,15,40,128,DATE '2025-12-20');
INSERT INTO fournis VALUES (201,1,50,120,129,DATE '2019-03-14');
INSERT INTO fournis VALUES (202,2,30,80,130,DATE '2020-06-01');