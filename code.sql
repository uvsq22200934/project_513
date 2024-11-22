--CREATION DE TABLE


-- Table FILMSERIE
CREATE TABLE FILMSERIE (
    id_film INT,
    type VARCHAR(50),
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
)
-- Table DISPONIBLE
CREATE TABLE DISPONIBLE (
    id_film INT, -- Film ou série concerné(e)
    langue_audio VARCHAR(10),  -- Code de langue pour l'audio (ex : FR, EN, etc.)
    langue_sous_titre VARCHAR(10), -- Code de langue pour les sous-titres
    PRIMARY KEY (id_film, langue_audio, langue_sous_titre), -- Unicité des langues par film
    FOREIGN KEY (id_film) REFERENCES FILMSERIE(id_film) -- Référence au film
);

-- Table SPECTATEUR
CREATE TABLE SPECTATEUR (
    id_spectateur INT PRIMARY KEY,
    nom VARCHAR(255),
    prenom VARCHAR(255),
    age INT CHECK (age >= 16),
    sexe VARCHAR(50) -- Peut être 'Homme', 'Femme'
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

-- garantir la durée maximale d'un contrat, et la date de début est non null
ALTER TABLE TRAVAILLE
ADD CONSTRAINT duree_maximale CHECK (
    date_contrat_fin <= DATE_ADD(date_contrat_debut, INTERVAL 10 YEAR) -- Vérifie que la fin est dans 10 ans
    AND date_contrat_debut IS NOT NULL -- Vérifie que la date de début n'est pas nulle
);

-- garantir la chronologie des dates de contrats
ALTER TABLE TRAVAILLE
ADD CONSTRAINT date_debut_avant_fin CHECK (date_contrat_debut < date_contrat_fin);

-- garantir qu'un film ne puisse avoir plusieurs restrictions d'âge
ALTER TABLE FILMSERIE
ADD CONSTRAINT pictogramme_combinaison_check
CHECK (
    NOT (
        -- Vérifie qu'on n'a pas à la fois les pictogrammes "-12" et "-18"
        (pictogramme LIKE '%-12%' AND pictogramme LIKE'%-16%' AND pictogramme LIKE '%-18%')
        OR
        -- Vérifie qu'on n'a pas à la fois les pictogrammes "-12" et "contenu explicite"
        (pictogramme LIKE '%-12%' or pictogramme LIKE'%-16%' AND pictogramme LIKE '%contenu explicite%')
    )
);

-- garantir que le spectateur a l'âge requit pour visionner un film
CREATE TRIGGER check_age_restriction
BEFORE INSERT ON VISIONNE
FOR EACH ROW
BEGIN
    DECLARE restriction_age INT;
    DECLARE spectateur_age INT;

    -- Récupérer l'âge du spectateur
    SELECT age INTO spectateur_age
    FROM SPECTATEUR
    WHERE id_spectateur = NEW.id_spectateur;

    -- Récupérer la restriction d'âge du film 
    SELECT pictogramme INTO restriction_age
    FROM FILMSERIE
    WHERE id_film = NEW.id_film;

    -- Vérifier si le pictogramme existe
    IF restriction_age IS NOT NULL THEN
        SET restriction_age = ABS(CAST(restriction_age AS SIGNED));

        -- Vérifier si l'âge du spectateur est inférieur à la restriction d'âge du film
        IF spectateur_age < restriction_age THEN
            SIGNAL SQLSTATE '45000' --message d'erreur personnalisé
            SET MESSAGE_TEXT = 'Vous n''êtes pas autorisé à visionner ce film en raison de sa restriction d''âge.';
        END IF;
    END IF;
END;

-- garantir que le champ de n°épisode et n°saison est remplie pour les séries mais pas pour les films
CREATE TRIGGER check_saison_episode_not_null
BEFORE INSERT ON FILMSERIE
FOR EACH ROW
BEGIN
    -- Si le type est une série
    IF NEW.type = 'série' THEN
        -- Vérifier que num_saison et num_episode ne sont pas NULL
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









