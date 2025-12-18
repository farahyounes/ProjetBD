------Vues------

--V1
CREATE VIEW vue_animaux_dispo AS
SELECT animal_id
FROM animal
WHERE statut_adoption = 'disponible';

--V2
CREATE VIEW vue_adoption AS
SELECT animal_id, adoptant_id, date_depart_refuge, refuge_id
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
    (SELECT COUNT(*) FROM vue_adoption WHERE refuge_id = r.refuge_id) AS nb_adoptions,
    (SELECT COUNT(*) FROM benevole b WHERE b.refuge_id = r.refuge_id) AS nb_benevoles,
    (SELECT COUNT(*) FROM enclos e WHERE e.refuge_id = r.refuge_id AND e.occupation = 0) AS nb_enclos_libres,
    (SELECT COUNT(*) FROM enclos e WHERE e.refuge_id = r.refuge_id AND e.occupation != 0) AS nb_enclos_occupees,
    (SELECT COUNT(*) FROM adoptant) AS nb_total_adoptants_globaux,
    CURRENT_DATE AS date_derniere_mise_a_jour
FROM refuge r;

--V7
CREATE VIEW vue_enclos_libres AS
SELECT e.enclos_id , e.capacite , e.type_enclos , e.refuge_id
FROM enclos e
WHERE NOT EXISTS (
    SELECT 1 
    FROM garde g
    WHERE g.enclos_id = e.enclos_id
      AND g.fin_sejour IS NULL
);