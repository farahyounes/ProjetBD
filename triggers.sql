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