--affichez les 3 langues audio les plus utilisées
SELECT langue_audio, COUNT(*) AS utilisation
FROM VISIONNE
GROUP BY langue_audio
ORDER BY utilisation DESC
LIMIT 3;


--affichez les films qui ont tendance à être visionnée mais pas en entier
SELECT f.titre, AVG(v.temps_visionnage) AS duree_moyenne_visionnage, f.duree AS duree_totale, 
    ROUND((AVG(v.temps_visionnage) / f.duree) * 100, 2) AS pourcentage_moyen
FROM FILMSERIE f
JOIN VISIONNE v ON f.id_film = v.id_film
WHERE f.type = 'film'
AND v.temps_visionnage < f.duree
GROUP BY f.id_film, f.titre, f.duree 
ORDER BY pourcentage_moyen ASC;


--affichez les 10 films les plus regardés
SELECT f.titre,COUNT(v.id_visionnage) AS nombre_visionnages
FROM FILMSERIE f
JOIN VISIONNE v ON f.id_film = v.id_film
WHERE f.type = 'film'
GROUP BY f.id_film, f.titre
ORDER BY nombre_visionnages DESC
LIMIT 10;
