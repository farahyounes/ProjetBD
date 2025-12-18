------Triggers------

--T1
ALTER TABLE adoptant
ADD CONSTRAINT chk_espace_ext
CHECK (espace_ext IN('oui', 'non'));

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
CREATE OR REPLACE TRIGGER trg_age_min_animal
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

--T10 change d'apres chat?
CREATE OR REPLACE TRIGGER maj_statut_animal_adoption
BEFORE UPDATE OF adoptant_id ON animal
FOR EACH ROW
BEGIN
    -- Si un adoptant est renseigné et l'animal n'était pas encore adopté
    IF :NEW.adoptant_id IS NOT NULL AND :OLD.statut_adoption <> 'adopte' THEN
        :NEW.statut_adoption := 'adopte';
        :NEW.date_depart_refuge := SYSDATE;  -- facultatif : date d'adoption
    END IF;
END;
/