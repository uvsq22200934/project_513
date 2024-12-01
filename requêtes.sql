--affichez les 3 langues audio les plus utilisées
SELECT langue_audio, COUNT(*) AS utilisation
FROM VISIONNE
GROUP BY langue_audio
ORDER BY utilisation DESC
LIMIT 3;


--affichez les films qui ont tendance à être visionnée mais pas en entier
SELECT f.titre, AVG(v.temps_visionnage) AS duree_moyenne_visionnage, f.duree AS duree_totale, 
    ROUND((AVG(v.temps_visionnage) / f.duree) * 100, 2) AS pourcentage_moyen
FROM FILMEPISODE f, VISIONNE v 
WHERE f.id_film = v.id_film
AND f.type = 'film'
AND v.temps_visionnage < f.duree
GROUP BY f.id_film, f.titre, f.duree 
ORDER BY pourcentage_moyen ASC;


--affichez les 10 films les plus regardés
SELECT f.titre,COUNT(v.id_visionnage) AS nombre_visionnages
FROM FILMEPISODE f, VISIONNE v
WHERE f.id_film = v.id_film
AND f.type = 'film'
GROUP BY f.id_film, f.titre
ORDER BY nombre_visionnages DESC
LIMIT 10;

--affichez les revenus totaux générés par les abonnements des plateformes
SELECT 
    p.nom AS nom_plateforme,
    SUM(
        CASE
            WHEN a.date_abo < '2023-01-01' THEN
                GREATEST(0, LEAST(TIMESTAMPDIFF(MONTH, '2023-01-01', '2024-01-01'),
                                  TIMESTAMPDIFF(MONTH, '2023-01-01', a.date_abo + INTERVAL a.duree_abo MONTH)))
            ELSE
                GREATEST(0, LEAST(TIMESTAMPDIFF(MONTH, a.date_abo, '2024-01-01'),
                                  TIMESTAMPDIFF(MONTH, a.date_abo, a.date_abo + INTERVAL a.duree_abo MONTH)))
        END * a.prix_abo
    ) AS revenus_totaux
FROM PLATEFORME p
JOIN ABONNE a ON p.id_plateforme = a.id_plateforme
WHERE a.date_abo < '2024-01-01' 
  AND a.date_abo + INTERVAL a.duree_abo MONTH > '2023-01-01'
GROUP BY p.nom
ORDER BY revenus_totaux DESC;



--Quelle plateforme offre le plus grand nombre de films/séries ?
SELECT p.nom AS plateforme, COUNT(d.id_film) AS nombre_de_films
FROM PLATEFORME p, DIFFUSE d 
WHERE p.id_plateforme = d.id_plateforme
GROUP BY p.id_plateforme
ORDER BY nombre_de_films DESC
LIMIT 1;

--Pour chaque catégorie, donner le nombre total de films.
SELECT c.genre AS categorie, COUNT(cl.id_film) AS nombre_de_films
FROM CATEGORIE c, CLASSER cl
WHERE c.id_categorie = cl.id_categorie
GROUP BY c.id_categorie
ORDER BY nombre_de_films DESC;

--Quels sont les films dont les notes sont exclusivement inférieures à 4?
SELECT f.titre
FROM FILMEPISODE f
WHERE NOT EXISTS (
    SELECT 1à
    FROM CRITIQUE c
    WHERE c.id_film = f.id_film
    AND c.note >=4) ;

--Obtenir les films qui ont reçu une note supérieure à la moyenne globale de tous les films.
Select f.titre
FROM CRITIQUE c, FILMEPISODE f
WHERE c.id_film = f.id_film
AND c.note > (SELECT AVG(c.note ) FROM CRITIQUE) ;

--Donner le nombre de langues audio disponibles pour chaque film, en ordre décroissant.
SELECT f.titre, count(DISTINCT v.langue_audio) as calcul
FROM VISIONNE v, FILMEPISODE f
WHERE v.id_film = f.id_film
group by f.titre
order by calcul DESC ;


--Quels spectateurs ont regardé un film sans regarder la suite ?


--Quel est le salaire moyen des personnes en fonction de leur sexe et de leur métier ?
SElECT avg(tr.salaire) as calcul_salaire
FROM TRAVAILLE tr, PERSONNE p
WHERE p.nom = tr.nom and p.prenom=tr.prenom
group by p.sexe,
         p.metier ;

--Donner le nombre de films qui n'ont pas de critique.
SELECT COUNT(f.id_film)
FROM FILMEPISODE f
WHERE f.id_film NOT in (SELECT c.id_film FROM CRITIQUE ) ;

--Trouver pour le film Vaiana 1 , la plateforme de visionnage sur laquelle il est disponible dans le plus de langues.
SELECT v.id_plateforme, count(DISTINCT v.langue_audio) + count(DISTINCT v.langue_sous_titre) as total_langues_dispo
FROM VISIONNE v, FILMEPISODE f, PLATEFORME p
WHERE v.id_film = f.id_film
  and p.id_plateforme = v.id_plateforme
  and f.titre = 'Titanic'
group by p.id_plateforme
order by total_langues_dispo DESC
FETCH FIRST ROW ONLY;

--Trouver pour l’utilisateur Jean Dupond, la catégorie de films dans laquelle il a laissé les meilleures notes.
SELECT avg(cr.note) as calcul_moyenne
FROM SPECTATEUR s, CRITIQUE cr, FILMEPISODE f, CLASSER cl, CATEGORIE ca
WHERE s.id_spectateur = cr.id_spectateur and cr.id_film = f.id_film and cl.id_categorie = ca.id_categorie and cl.id_film = f.id_film
  and s.nom = 'Dupond' and s.prenom = 'Jean'
group by ca.genre
order by calcul_moyenne DESC
FETCH FIRST ROW ONLY;

