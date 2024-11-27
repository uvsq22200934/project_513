--affichez les 3 langues audio les plus utilisées
SELECT langue_audio, COUNT(*) AS utilisation
FROM VISIONNE
GROUP BY langue_audio
ORDER BY utilisation DESC
LIMIT 3;


--affichez les films qui ont tendance à être visionnée mais pas en entier
SELECT f.titre, AVG(v.temps_visionnage) AS duree_moyenne_visionnage, f.duree AS duree_totale, 
    ROUND((AVG(v.temps_visionnage) / f.duree) * 100, 2) AS pourcentage_moyen
FROM FILMSERIE f, VISIONNE v 
WHERE f.id_film = v.id_film
AND f.type = 'film'
AND v.temps_visionnage < f.duree
GROUP BY f.id_film, f.titre, f.duree 
ORDER BY pourcentage_moyen ASC;


--affichez les 10 films les plus regardés
SELECT f.titre,COUNT(v.id_visionnage) AS nombre_visionnages
FROM FILMSERIE f, VISIONNE v
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
                LEAST(DATEDIFF(CURDATE(), '2023-01-01'), DATEDIFF(a.date_abo + INTERVAL 1 MONTH, '2023-01-01')) 
            ELSE 
                LEAST(DATEDIFF(CURDATE(), a.date_abo), 30)
        END * (a.prix_abo / 30)
    ) AS revenus_totaux
FROM PLATEFORME p, ABONNE a
WHERE p.id_plateforme = a.id_plateforme
AND a.date_abo < CURDATE()
GROUP BY p.id_plateforme, p.nom
ORDER BY revenus_totaux ASC;

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
FROM FILMSERIE f
WHERE NOT EXISTS (
    SELECT 1
    FROM CRITIQUE c
    WHERE c.id_film = f.id_film
    AND c.note >=4) ;
