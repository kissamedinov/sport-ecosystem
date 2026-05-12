SELECT t.name, d.name as division_name, d.birth_year 
FROM tournaments t 
JOIN tournament_divisions d ON t.id = d.tournament_edition_id 
WHERE t.name ILIKE '%Kuzbayev%';
