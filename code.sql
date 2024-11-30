-- DROP TABLE
DROP TABLE TRAVAILLE;
DROP TABLE PERSONNE;
DROP TABLE ABONNE;
DROP TABLE VISIONNE;
DROP TABLE DIFFUSE;
DROP TABLE PLATEFORME;
DROP TABLE CRITIQUE;
DROP TABLE SPECTATEUR;
DROP TABLE DISPONIBLE;
DROP TABLE LANGUE;
DROP TABLE PARENT;
DROP TABLE CLASSER;
DROP TABLE CATEGORIE;
DROP TABLE FILMEPISODE;
DROP TABLE SERIE;

--CREATION DE TABLE

CREATE TABLE SERIE (
                       id_serie INT PRIMARY KEY ,
                       nom_serie VARCHAR (25) NOT NULL
);
CREATE TABLE FILMEPISODE (
                           id_film INT,
                           id_serie INT,
                           type VARCHAR(10) CHECK (type IN ('Film', 'Serie')),
                           titre VARCHAR(100) NOT NULL,
                           num_saison INT,
                           num_episode INT,
                           duree INT NOT NULL,
                           date_sortie DATE,
                           pictogramme VARCHAR(25) CHECK (pictogramme IN('mal-voyant', '-12', '-16', '-18', 'contenu explicite', 'violence', 'sexe', 'Tous public')),
                           origine VARCHAR(25) CHECK (origine IN('Histoire vraie', 'Fait divers', 'Adaptation cinématographique')),
                           PRIMARY KEY (id_film)
);
CREATE TABLE CATEGORIE (
                           id_categorie INT PRIMARY KEY,
                           genre VARCHAR(25) NOT NULL
);
CREATE TABLE CLASSER (
                         id_categorie INT,
                         id_film INT,
                         FOREIGN KEY (id_categorie) REFERENCES CATEGORIE(id_categorie),
                         FOREIGN KEY (id_film) REFERENCES FILMEPISODE(id_film)
);
CREATE TABLE PARENT (
                        id_film1 INT, -- Premier film/série dans la relation
                        id_film2 INT, -- Second film/série dans la relation
                        UNIQUE (id_film1, id_film2), -- Contrainte pour éviter les doublons
                        FOREIGN KEY (id_film1) REFERENCES FILMEPISODE(id_film), -- Référence au film/série 1
                        FOREIGN KEY (id_film2) REFERENCES FILMEPISODE(id_film) -- Référence au film/série 2
);
CREATE TABLE LANGUE (
                        id_langue INT PRIMARY KEY,
                        code VARCHAR(10) NOT NULL UNIQUE, -- Ex : FR, EN, ES
                        nom_langue VARCHAR(30) NOT NULL -- Ex : Français, Anglais, Espagnol

);

CREATE TABLE DISPONIBLE (
                            id_langue INT,
                            id_film INT, -- Film ou série concerné(e)
                            langue_audio VARCHAR(10) NOT NULL,  -- Code de langue pour l'audio (ex : FR, EN, etc.)
                            langue_sous_titre VARCHAR(10), -- Code de langue pour les sous-titres
                            UNIQUE (id_film, langue_audio, langue_sous_titre), -- Unicité des langues par film
                            FOREIGN KEY (id_film) REFERENCES FILMEPISODE(id_film) ON DELETE CASCADE, -- Référence au film
                            FOREIGN KEY (langue_audio) REFERENCES LANGUE(code) ON DELETE CASCADE,
                            FOREIGN KEY (langue_sous_titre) REFERENCES LANGUE(code) ON DELETE CASCADE
);

CREATE TABLE SPECTATEUR (
                            id_spectateur INT PRIMARY KEY,
                            nom VARCHAR(30),
                            prenom VARCHAR(30),
                            age INT CHECK (age >= 16),
                            sexe VARCHAR(15) CHECK (sexe IN ('Homme', 'Femme'))
);

CREATE TABLE CRITIQUE (
                          id_critique INT PRIMARY KEY,
                          id_film INT,
                          id_spectateur INT,
                          note INT CHECK (note BETWEEN 0 AND 10),
                          commentaire VARCHAR(255),
                          FOREIGN KEY (id_film) REFERENCES FILMEPISODE(id_film) ON DELETE CASCADE,
                          FOREIGN KEY (id_spectateur) REFERENCES SPECTATEUR(id_spectateur) ON DELETE CASCADE
);

CREATE TABLE PLATEFORME (
                            id_plateforme INT PRIMARY KEY,
                            nom VARCHAR(30) NOT NULL
);

CREATE TABLE DIFFUSE (
                         id_film INT,
                         id_plateforme INT,
                         date_dispo DATE,
                         duree_dispo INT CHECK (duree_dispo > 0), -- durée en jours
                         PRIMARY KEY (id_film, id_plateforme),
                         FOREIGN KEY (id_film) REFERENCES FILMEPISODE(id_film) ON DELETE CASCADE,
                         FOREIGN KEY (id_plateforme) REFERENCES PLATEFORME(id_plateforme) ON DELETE CASCADE
);
CREATE TABLE VISIONNE (
                          id_visionnage INT PRIMARY KEY,
                          id_film INT,
                          id_plateforme INT,
                          id_spectateur
                          date_visionnage DATE,
                          temps_visionnage INT, -- temps en minutes
                          langue_audio VARCHAR (15),
                          langue_sous_titre VARCHAR(15),
                          FOREIGN KEY (id_film) REFERENCES FILMEPISODE(id_film) ON DELETE CASCADE,
                          FOREIGN KEY (id_plateforme) REFERENCES PLATEFORME(id_plateforme) ON DELETE CASCADE,
                          FOREIGN KEY (id_spectateur) REFERENCES SPECTATEUR(id_spectateur) ON DELETE CASCADE,
                          FOREIGN KEY (langue_audio) REFERENCES LANGUE(code) ON DELETE CASCADE,
                          FOREIGN KEY (langue_sous_titre) REFERENCES LANGUE(code) ON DELETE CASCADE
);

CREATE TABLE ABONNE (
                        id_plateforme INT,
                        id_spectateur INT,
                        date_abo DATE,
                        prix_abo DECIMAL(5, 2) CHECK (prix_abo >= 0),
                        duree_abo INT CHECK( duree_abo > 0), --temps en mois
                        PRIMARY KEY (id_plateforme, id_spectateur),
                        FOREIGN KEY (id_plateforme) REFERENCES PLATEFORME(id_plateforme) ON DELETE CASCADE ,
                        FOREIGN KEY (id_spectateur) REFERENCES SPECTATEUR(id_spectateur) ON DELETE CASCADE
);

CREATE TABLE PERSONNE (
                          nom VARCHAR(25),
                          prenom VARCHAR(25),
                          sexe VARCHAR(15),
                          age INT,
                          metier VARCHAR(30),
                          PRIMARY KEY (nom, prenom)
);

CREATE TABLE TRAVAILLE (
                           id_travaille INT PRIMARY KEY,
                           nom VARCHAR(255),
                           prenom VARCHAR(255),
                           id_film INT,
                           date_contrat_debut DATE,
                           date_contrat_fin DATE,
                           salaire DECIMAL(10, 2),
                           FOREIGN KEY (nom, prenom) REFERENCES PERSONNE(nom, prenom),
                           FOREIGN KEY (id_film) REFERENCES FILMEPISODE(id_film)
);


--CONTRAINTES / TRIGGERS


-- TRAVAIL

--garantir la durée maximale d'un contrat, et la date de début est non null
ALTER TABLE TRAVAILLE
ADD CONSTRAINT duree_maximale CHECK (
    date_contrat_fin <= ADD_MONTHS(date_contrat_debut, INTERVAL 10 YEAR) --Vérifie que la fin est dans 10 ans
    AND date_contrat_debut IS NOT NULL --Vérifie que la date de début n'est pas nulle
);

--garantir la chronologie des dates de contrats
ALTER TABLE TRAVAILLE
ADD CONSTRAINT date_debut_avant_fin CHECK (date_contrat_debut < date_contrat_fin);


-- PLATEFORME

--garantir que la date d'abonnement est antérieure à la date actuelle
ALTER TABLE ABONNE
ADD CONSTRAINT check_date_abo
CHECK (date_abo <= CURRENT_DATE);

--garantir que la date de diffusion d'un film est postérieure à sa date de sortie
ALTER TABLE DIFFUSE
ADD CONSTRAINT check_date_diffusion
CHECK (date_dispo >= date_sortie);


-- FILMS

--garantir qu'un film ne puisse avoir plusieurs restrictions d'âge
ALTER TABLE FILMEPISODE
ADD CONSTRAINT pictogramme_combinaison_check
CHECK (
    NOT (
        --Vérifie qu'on n'a pas à la fois les pictogrammes "-12" et "-18"
        (pictogramme LIKE '%-12%' AND pictogramme LIKE'%-16%' AND pictogramme LIKE '%-18%')
        OR
        --Vérifie qu'on n'a pas à la fois les pictogrammes "-12" et "contenu explicite"
        (pictogramme LIKE '%-12%' AND pictogramme LIKE '%contenu explicite%')
    )
);

--garantir que les champs pour séries sont remplis uniquement pour les séries et vides pour les films
TRIGGER VERIFIE
CREATE OR REPLACE TRIGGER check_saison_episode_not_null
BEFORE INSERT OR UPDATE ON FILMEPISODE
FOR EACH ROW
BEGIN
    -- Si le type est une série
    IF :NEW.type = 'série' THEN
        IF :NEW.num_episode IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Le champ num_episode ne peut pas être NULL pour une série.');
        END IF;
        IF :NEW.num_saison IS NULL THEN
            RAISE_APPLICATION_ERROR(-20002, 'Le champ num_saison ne peut pas être NULL pour une série.');
        END IF;
        IF :NEW.id_serie IS NULL THEN
            RAISE_APPLICATION_ERROR(-20003, 'Le champ id_serie ne peut pas être NULL pour une série.');
        END IF;

    -- Sinon, si le type est un film
    ELSIF :NEW.type = 'film' THEN
        IF :NEW.num_episode IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20004, 'Le champ num_episode doit être NULL pour un film.');
        END IF;
        IF :NEW.num_saison IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20005, 'Le champ num_saison doit être NULL pour un film.');
        END IF;
        IF :NEW.id_serie IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20006, 'Le champ id_serie doit être NULL pour un film.');
        END IF;
    END IF;
END;
/


--garantir la cohérence entre le genre et la durée d'un film
TRIGGER VERIFIE
CREATE OR REPLACE TRIGGER check_duree_court_metrage
BEFORE INSERT OR UPDATE ON FILMEPISODE
FOR EACH ROW
DECLARE
    genre_film VARCHAR2(255);
BEGIN
    -- Récupérer le genre du film depuis les tables CLASSER et CATEGORIE
    BEGIN
        SELECT c.genre
        INTO genre_film
        FROM CLASSER cl
        JOIN CATEGORIE c ON cl.id_categorie = c.id_categorie
        WHERE cl.id_film = :NEW.id_film;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si aucune correspondance n'est trouvée, lever une erreur
            RAISE_APPLICATION_ERROR(-20003, 'Le genre du film est introuvable.');
    END;

    -- Vérifier si le genre est "court-métrage" et que la durée est supérieure ou égale à 40 minutes
    IF genre_film = 'court-métrage' AND :NEW.duree >= 40 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Un court-métrage doit avoir une durée inférieure à 40 minutes.');
    END IF;

    -- Vérifier si le genre n'est pas "court-métrage" et que la durée est inférieure à 40 minutes
    IF genre_film != 'court-métrage' AND :NEW.duree < 40 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Un long-métrage doit avoir une durée d''au moins 40 minutes.');
    END IF;
END;
/


--Vérifier qu'un film ait une date de sortie antérieure ou égale à la date actuelle
TRIGGER VERIFIE
CREATE OR REPLACE TRIGGER check_date_sortie
BEFORE INSERT OR UPDATE ON FILMEPISODE
FOR EACH ROW
BEGIN
    -- Vérifier si la date de sortie est postérieure à la date actuelle
    IF :NEW.date_sortie > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20002, 'La date de sortie ne peut pas être dans le futur.');
    END IF;
END;
/


-- VISIONNAGE

--garantir que le spectateur a l'âge requis pour visionner un film
CREATE OR REPLACE TRIGGER check_age_restriction
BEFORE INSERT OR UPDATE ON VISIONNE
FOR EACH ROW
DECLARE
    restriction_age INT;
    spectateur_age INT;
BEGIN
    -- Récupérer l'âge du spectateur
    SELECT age
    INTO spectateur_age
    FROM SPECTATEUR
    WHERE id_spectateur = :NEW.id_spectateur;

    -- Récupérer la restriction d'âge du film
    SELECT
        CASE
            WHEN pictogramme = '-10' THEN 10
            WHEN pictogramme = '-12' THEN 12
            WHEN pictogramme = '-16' THEN 16
            WHEN pictogramme = '-18' THEN 18
            ELSE NULL
        END
    INTO restriction_age
    FROM FILMEPISODE
    WHERE id_film = :NEW.id_film;

    -- Vérifier si le pictogramme impose une restriction d'âge
    IF restriction_age IS NOT NULL THEN
        -- Vérifier si l'âge du spectateur est inférieur à la restriction d'âge du film
        IF spectateur_age < restriction_age THEN
            RAISE_APPLICATION_ERROR(-20001, 'Vous n''êtes pas autorisé à visionner ce film en raison de sa restriction d''âge.');
        END IF;
    END IF;
END;


--vérifier que le film était disponible sur une plateforme du spectateur au moment du visionnage
CREATE OR REPLACE TRIGGER check_filme_visionnage_disponibilite
BEFORE INSERT OR UPDATE ON VISIONNE
FOR EACH ROW
DECLARE
    film_disponible INT;
    abonnement_valide INT;
    date_abo DATE;
    date_dispo DATE;
    duree_dispo INT;
BEGIN
    -- Vérifier si le film était disponible sur la plateforme au moment du visionnage
    SELECT COUNT(*)
    INTO film_disponible
    FROM DIFFUSE
    WHERE id_film = :NEW.id_film
    AND id_plateforme = :NEW.id_plateforme
    AND :NEW.date_visionnage BETWEEN date_dispo AND (date_dispo + INTERVAL duree_dispo DAY);

    -- Si le film n'était pas disponible au moment du visionnage, lever une erreur
    IF film_disponible = 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Le film n''était pas disponible sur cette plateforme au moment du visionnage.');
    END IF;

    -- Vérifier que le spectateur était abonné à la plateforme au moment du visionnage
    SELECT date_abo
    INTO date_abo
    FROM ABONNE
    WHERE id_spectateur = :NEW.id_spectateur
    AND id_plateforme = :NEW.id_plateforme;

    -- Vérifier si la date d'abonnement est antérieure ou égale à la date de visionnage
    IF date_abo > :NEW.date_visionnage THEN
        RAISE_APPLICATION_ERROR(-20009, 'Vous devez être abonné à la plateforme avant de pouvoir visionner ce film.');
    END IF;

END;
/

--Vérifier que la date de visionnage est antérieure ou égale à la date actuelle
CREATE OR REPLACE TRIGGER check_date_visionnage
BEFORE INSERT OR UPDATE ON VISIONNE
FOR EACH ROW
BEGIN
    -- Vérifier si la date de visionnage est antérieure ou égale à la date actuelle
    IF :NEW.date_visionnage > CURRENT_DATE THEN
        RAISE_APPLICATION_ERROR(-20010, 'La date de visionnage ne peut pas être supérieure à la date actuelle.');
    END IF;
END;
/



-- CRITIQUES

--supprimer les critiques associés à un film ou une série qui est retiré de la plateforme
ALTER TABLE CRITIQUE
ADD CONSTRAINT fk_film_critique
FOREIGN KEY (id_film) REFERENCES FILMEPISODE(id_film)
ON DELETE CASCADE;

--création d'dune ligne en update pour la date de la critique
ALTER TABLE CRITIQUE ADD COLUMN date_critique DATETIME DEFAULT CURRENT_TIMESTAMP;

--garantir une critique par spectateur par jour
CREATE OR REPLACE TRIGGER check_critique_one_per_day
BEFORE INSERT ON CRITIQUE
FOR EACH ROW
DECLARE
    visionnage_existe INT;
    critique_existe INT;
BEGIN
    -- Vérifier si le spectateur a visionné le film
    SELECT COUNT(*)
    INTO visionnage_existe
    FROM VISIONNE v
    WHERE v.id_film = :NEW.id_film
      AND v.id_spectateur = :NEW.id_spectateur;

    -- Si aucun visionnage trouvé, empêcher l'insertion
    IF visionnage_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Vous ne pouvez soumettre une critique que si vous avez visionné le film.');
    END IF;

    -- Vérifier si une critique existe déjà pour ce film par ce spectateur à la date du jour
    SELECT COUNT(*)
    INTO critique_existe
    FROM CRITIQUE c
    WHERE c.id_film = :NEW.id_film
      AND c.id_spectateur = :NEW.id_spectateur
      AND TRUNC(c.date_critique) = TRUNC(SYSDATE);

    -- Si une critique existe déjà pour aujourd'hui, empêcher l'insertion
    IF critique_existe > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Vous ne pouvez soumettre qu''une critique par jour pour ce film.');
    END IF;
END;
/


-- LANGUE

--garantir la disponibilité de la langue
CREATE OR REPLACE TRIGGER check_langues_disponibles
BEFORE INSERT OR UPDATE ON VISIONNE
FOR EACH ROW
DECLARE
    langue_audio_disponible INT := 0;
    langue_sous_titre_disponible INT := 0;
BEGIN
    -- Vérifier si la langue audio est disponible
    SELECT COUNT(*)
    INTO langue_audio_disponible
    FROM DISPONIBLE
    WHERE id_film = :NEW.id_film
      AND langue_audio = :NEW.langue_audio;

    IF langue_audio_disponible = 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'La langue audio spécifiée n''est pas disponible pour ce film.');
    END IF;

    -- Vérifier si la langue des sous-titres est spécifiée et disponible
    IF :NEW.langue_sous_titre IS NOT NULL THEN
        SELECT COUNT(*)
        INTO langue_sous_titre_disponible
        FROM DISPONIBLE
        WHERE id_film = :NEW.id_film
          AND langue_sous_titre = :NEW.langue_sous_titre;

        IF langue_sous_titre_disponible = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'La langue des sous-titres spécifiée n''est pas disponible pour ce film.');
        END IF;
    END IF;
END;
/