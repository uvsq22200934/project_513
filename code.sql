--CREATION DE TABLE

-- Table FILMSERIE
CREATE TABLE FILMSERIE (
    id_film INT,
    type VARCHAR(50) CHECK (type IN ('film', 'série')),
    titre VARCHAR(255) NOT NULL,
    num_saison INT,
    num_episode INT,
    duree INT NOT NULL, -- durée en minutes
    date_sortie DATE,
    pictogramme VARCHAR(255), -- chemin ou description du pictogramme
    origine VARCHAR(255),
    PRIMARY KEY (id_film)
);

-- Table CATEGORIE
CREATE TABLE CATEGORIE (
    id_categorie INT PRIMARY KEY,
    genre VARCHAR(255) NOT NULL
);

-- Table CLASSER
CREATE TABLE CLASSER (
    id_categorie INT,
    id_film INT,
    FOREIGN KEY (id_categorie) REFERENCES CATEGORIE(id_categorie),
    FOREIGN KEY (id_film) REFERENCES FILMSERIE(id_film)
);

-- Table PARENT
CREATE TABLE PARENT (
    id_film1 INT, -- Premier film/série dans la relation
    id_film2 INT, -- Second film/série dans la relation
    UNIQUE (id_film1, id_film2), -- Contrainte pour éviter les doublons
    FOREIGN KEY (id_film1) REFERENCES FILMSERIE(id_film), -- Référence au film/série 1
    FOREIGN KEY (id_film2) REFERENCES FILMSERIE(id_film) -- Référence au film/série 2
);


-- Table LANGUE
CREATE TABLE LANGUE (
    id_langue INT PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE, -- Ex : FR, EN, ES
    nom_langue VARCHAR(255) NOT NULL -- Ex : Français, Anglais, Espagnol
);
-- Table DISPONIBLE
CREATE TABLE DISPONIBLE (
    id_film INT, -- Film ou série concerné(e)
    langue_audio VARCHAR(10) NOT NULL,  -- Code de langue pour l'audio (ex : FR, EN, etc.)
    langue_sous_titre VARCHAR(10), -- Code de langue pour les sous-titres
    PRIMARY KEY (id_film, langue_audio, langue_sous_titre), -- Unicité des langues par film
    FOREIGN KEY (id_film) REFERENCES FILMSERIE(id_film) -- Référence au film
);

-- Table SPECTATEUR
CREATE TABLE SPECTATEUR (
    id_spectateur INT PRIMARY KEY,
    nom VARCHAR(255),
    prenom VARCHAR(255),
    age INT CHECK (age >= 16)
    sexe VARCHAR(50) CHECK (sexe IN ('Homme', 'Femme')),
);

-- Table CRITIQUE
CREATE TABLE CRITIQUE (
    id_critique INT PRIMARY KEY,
    id_film INT,
    id_spectateur INT,
    note INT CHECK (note BETWEEN 0 AND 10),
    commentaire TEXT,
    FOREIGN KEY (id_film) REFERENCES FILMSERIE(id_film),
    FOREIGN KEY (id_spectateur) REFERENCES SPECTATEUR(id_spectateur)
);

-- Table PLATEFORME
CREATE TABLE PLATEFORME (
    id_plateforme INT PRIMARY KEY,
    nom VARCHAR(255) NOT NULL
);

-- Table DIFFUSE
CREATE TABLE DIFFUSE (
    id_film INT,
    id_plateforme INT,
    date_dispo DATE,
    duree_dispo INT CHECK (duree_dispo > 0), -- durée en jours
    PRIMARY KEY (id_film, id_plateforme),
    FOREIGN KEY (id_film) REFERENCES FILMSERIE(id_film),
    FOREIGN KEY (id_plateforme) REFERENCES PLATEFORME(id_plateforme)
);

-- Table VISIONNE
CREATE TABLE VISIONNE (
    id_visionnage INT PRIMARY KEY,
    id_film INT,
    id_plateforme INT,
    date_visionnage DATE,
    temps_visionnage INT, -- temps en minutes
    temps_pause INT, -- temps de pause en minutes
    FOREIGN KEY (id_film) REFERENCES FILMSERIE(id_film),
    FOREIGN KEY (id_plateforme) REFERENCES PLATEFORME(id_plateforme)
);

-- Table ABONNE
CREATE TABLE ABONNE (
    id_plateforme INT,
    id_spectateur INT,
    date_abo DATE,
    prix_abo DECIMAL(5, 2) CHECK (prix_abo >= 0),
    PRIMARY KEY (id_plateforme, id_spectateur),
    FOREIGN KEY (id_plateforme) REFERENCES PLATEFORME(id_plateforme),
    FOREIGN KEY (id_spectateur) REFERENCES SPECTATEUR(id_spectateur)
);

-- Table PERSONNE
CREATE TABLE PERSONNE (
    nom VARCHAR(255),
    prenom VARCHAR(255),
    sexe VARCHAR(50),
    age INT,
    metier VARCHAR(255),
    PRIMARY KEY (nom, prenom)
);

-- Table TRAVAILLE
CREATE TABLE TRAVAILLE (
    id_travaille INT PRIMARY KEY,
    nom VARCHAR(255),
    prenom VARCHAR(255),
    id_film INT,
    date_contrat_debut DATE,
    date_contrat_fin DATE,
    salaire DECIMAL(10, 2),
    FOREIGN KEY (nom, prenom) REFERENCES PERSONNE(nom, prenom),
    FOREIGN KEY (id_film) REFERENCES FILMSERIE(id_film)
);

--CONTRAINTE

ALTER TABLE VISIONNE 
    ADD langue_audio VARCHAR(10) NOT NULL, 
    ADD langue_sous_titre VARCHAR(10) DEFAULT NULL;

--création d'dune ligne en update pour la date de la critique
ALTER TABLE CRITIQUE ADD COLUMN date_critique DATETIME DEFAULT CURRENT_TIMESTAMP;

--garantir la durée maximale d'un contrat, et la date de début est non null
ALTER TABLE TRAVAILLE
ADD CONSTRAINT duree_maximale CHECK (
    date_contrat_fin <= DATE_ADD(date_contrat_debut, INTERVAL 10 YEAR) --Vérifie que la fin est dans 10 ans
    AND date_contrat_debut IS NOT NULL --Vérifie que la date de début n'est pas nulle
);

--garantir la chronologie des dates de contrats
ALTER TABLE TRAVAILLE
ADD CONSTRAINT date_debut_avant_fin CHECK (date_contrat_debut < date_contrat_fin);

--garantir que la date d'abonnement est antérieure à la date actuelle
ALTER TABLE ABONNE
ADD CONSTRAINT check_date_abo
CHECK (date_abo <= CURRENT_DATE);

--garantir qu'un film ne puisse avoir plusieurs restrictions d'âge
ALTER TABLE FILMSERIE
ADD CONSTRAINT pictogramme_combinaison_check
CHECK (
    NOT (
        --Vérifie qu'on n'a pas à la fois les pictogrammes "-12" et "-18"
        (pictogramme LIKE '%-12%' AND pictogramme LIKE'%-16%' AND pictogramme LIKE '%-18%')
        OR
        --Vérifie qu'on n'a pas à la fois les pictogrammes "-12" et "contenu explicite"
        (pictogramme LIKE '%-12%' or pictogramme LIKE'%-16%' AND pictogramme LIKE '%contenu explicite%')
    )
);

--garantir que le spectateur a l'âge requit pour visionner un film
CREATE TRIGGER check_age_restriction
BEFORE INSERT ON VISIONNE
FOR EACH ROW
BEGIN
    DECLARE restriction_age INT;
    DECLARE spectateur_age INT;

    --Récupérer l'âge du spectateur
    SELECT age INTO spectateur_age
    FROM SPECTATEUR
    WHERE id_spectateur = NEW.id_spectateur;

    --Récupérer la restriction d'âge du film 
    SELECT pictogramme INTO restriction_age
    FROM FILMSERIE
    WHERE id_film = NEW.id_film;

    --Vérifier si le pictogramme existe
    IF restriction_age IS NOT NULL THEN
        SET restriction_age = ABS(CAST(restriction_age AS SIGNED));

        --Vérifier si l'âge du spectateur est inférieur à la restriction d'âge du film
        IF spectateur_age < restriction_age THEN
            SIGNAL SQLSTATE '45000' --message d'erreur personnalisé
            SET MESSAGE_TEXT = "Vous n'êtes pas autorisé à visionner ce film en raison de sa restriction d'âge.";
        END IF;
    END IF;
END;

--garantir que le champ de n°épisode et n°saison est remplie pour les séries mais pas pour les films
CREATE TRIGGER check_saison_episode_not_null
BEFORE INSERT ON FILMSERIE
FOR EACH ROW
BEGIN
    --Si le type est une série
    IF NEW.type = 'série' THEN
        --Vérifier que num_saison et num_episode ne sont pas NULL
        IF NEW.num_saison IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le champ num_saison ne peut pas être NULL pour une série.';
        END IF;
        
        IF NEW.num_episode IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le champ num_episode ne peut pas être NULL pour une série.';
        END IF;
    END IF;
END;

--garantir une critique par spectateur par jour
CREATE TRIGGER check_critique_one_per_day
BEFORE INSERT ON CRITIQUE
FOR EACH ROW
BEGIN
    DECLARE visionnage_existe INT;
    DECLARE critique_existe INT;

    --Vérifier si le spectateur a visionné le film
    SELECT COUNT(*)
    INTO visionnage_existe
    FROM VISIONNE v
    WHERE v.id_film = NEW.id_film
      AND v.id_spectateur = NEW.id_spectateur;

    --Si aucun visionnage trouvé, empêcher l'insertion
    IF visionnage_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Vous ne pouvez soumettre une critique que si vous avez visionné le film.';
    END IF;

    --Vérifier si une critique existe déjà pour ce film par ce spectateur à la date du jour
    SELECT COUNT(*)
    INTO critique_existe
    FROM CRITIQUE c
    WHERE c.id_film = NEW.id_film
      AND c.id_spectateur = NEW.id_spectateur
      AND DATE(c.date_critique) = CURRENT_DATE;

    --Si une critique existe déjà pour aujourd'hui, empêcher l'insertion
    IF critique_existe > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "Vous ne pouvez soumettre qu'une critique par jour pour ce film.";
    END IF;
END;

--garantir la cohérence entre le genre et la durée d'un film
CREATE TRIGGER check_duree_court_metrage
BEFORE INSERT ON FILMSERIE
FOR EACH ROW
BEGIN
    DECLARE genre_film VARCHAR(255);

    -- Récupérer le genre du film depuis la table CLASSER et CATEGORIE
    SELECT c.genre
    INTO genre_film
    FROM CLASSER cl
    JOIN CATEGORIE c ON cl.id_categorie = c.id_categorie
    WHERE cl.id_film = NEW.id_film;

    -- Vérifier si le genre est "court-métrage" et que la durée est supérieure ou égale à 40 minutes
    IF genre_film = 'court-métrage' AND NEW.duree >= 40 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un court-métrage doit avoir une durée inférieure à 40 minutes.';
    END IF;

    -- Vérifier si le genre n'est pas "court-métrage" et que la durée est inférieure à 40 minutes
    IF genre_film != 'court-métrage' AND NEW.duree < 40 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "Un long-métrage doit avoir une durée d'au moins 40 minutes.";
    END IF;
END;

--garantir la disponibilité de la langue
CREATE TRIGGER check_langues_disponibles
BEFORE INSERT ON VISIONNE
FOR EACH ROW
BEGIN
    DECLARE langue_disponible INT;
    
    -- Vérifier si la langue audio est disponible pour le film dans la table DISPONIBLE
    SELECT COUNT(*)
    INTO langue_disponible
    FROM DISPONIBLE
    WHERE id_film = NEW.id_film
      AND langue_audio = NEW.langue_audio;
    
    -- Si la langue audio n'est pas disponible, générer une erreur
    IF langue_disponible = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "La langue audio spécifiée n'est pas disponible pour ce film.";
    END IF;

    -- Vérifier si la langue des sous-titres est spécifiée et si elle est disponible
    IF NEW.langue_sous_titre IS NOT NULL THEN
        SELECT COUNT(*)
        INTO langue_disponible
        FROM DISPONIBLE
        WHERE id_film = NEW.id_film
          AND langue_sous_titre = NEW.langue_sous_titre;
        
        -- Si la langue des sous-titres n'est pas disponible, générer une erreur
        IF langue_disponible = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = "La langue des sous-titres spécifiée n'est pas disponible pour ce film.";
        END IF;
    END IF;
END;

--verifie que la version visionnée(audio et sous-titre) est disponible
CREATE TRIGGER check_langues_disponibles
BEFORE INSERT ON VISIONNE
FOR EACH ROW
BEGIN
    DECLARE langue_audio_disponible INT;
    DECLARE langue_sous_titre_disponible INT;

    --vérifier si la langue audio est disponible pour le film
    SELECT COUNT(*)
    INTO langue_audio_disponible
    FROM DISPONIBLE
    WHERE id_film = NEW.id_film
      AND langue_audio = NEW.langue_audio;

    IF langue_audio_disponible = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "La langue audio spécifiée n'est pas disponible pour ce film.";
    END IF;

    --vérifier si la langue des sous-titres est spécifiée et si elle est disponible
    IF NEW.langue_sous_titre IS NOT NULL THEN
        SELECT COUNT(*)
        INTO langue_sous_titre_disponible
        FROM DISPONIBLE
        WHERE id_film = NEW.id_film
          AND langue_sous_titre = NEW.langue_sous_titre;

        IF langue_sous_titre_disponible = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = "La langue des sous-titres spécifiée n'est pas disponible pour ce film.";
        END IF;
    END IF;
END;
