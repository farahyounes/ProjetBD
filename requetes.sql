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
SELECT A.animal_id, A.nom, A.etat_sante, AL.type
FROM mange M, animal A, alimentation AL
WHERE M.animal_id = A.animal_id
AND M.aliment_id = AL.aliment_id
AND AL.type = 'croquette boeuf'  
AND A.etat_sante = 'fragile';