
USE clicsalud_ips;


-- CONSULTA 1 — Promedio de resultados por departamento

SELECT
    d.nombre_departamento,
    ROUND(AVG(r.valor), 2)      AS promedio_indicador
FROM resultado r
JOIN ips          i  ON r.id_ips          = i.id_ips
JOIN municipio    m  ON i.id_municipio    = m.id_municipio
JOIN departamento d  ON m.id_departamento = d.id_departamento
GROUP BY d.nombre_departamento
ORDER BY promedio_indicador DESC;


-- CONSULTA 2 — Top IPS con mejores resultados

SELECT
    i.nombre_ips,
    ROUND(AVG(r.valor), 2)      AS promedio
FROM resultado r
JOIN ips i ON r.id_ips = i.id_ips
GROUP BY i.nombre_ips
ORDER BY promedio DESC
LIMIT 20;

-- CONSULTA 3 — Total de registros por servicio

SELECT
    s.nombre_servicio           AS servicio,
    COUNT(*)                    AS total_registros
FROM resultado r
JOIN indicador ind ON r.id_indicador = ind.id_indicador
JOIN servicio  s   ON r.id_servicio  = s.id_servicio
GROUP BY s.nombre_servicio
ORDER BY total_registros DESC;


-- CONSULTA 4 — Promedio de resultados por municipio

SELECT
    d.nombre_departamento           AS departamento,
    m.nombre_municipio              AS municipio,
    COUNT(DISTINCT i.id_ips)        AS total_ips,
    ROUND(AVG(r.valor), 2)          AS promedio_indicador
FROM resultado r
JOIN ips          i  ON r.id_ips          = i.id_ips
JOIN municipio    m  ON i.id_municipio    = m.id_municipio
JOIN departamento d  ON m.id_departamento = d.id_departamento
GROUP BY
    d.nombre_departamento,
    m.nombre_municipio
ORDER BY promedio_indicador DESC;


-- CONSULTA 5 — Total de registros por indicador y servicio

SELECT
    s.nombre_servicio               AS servicio,
    ind.nombre_indicador            AS indicador,
    ind.unidad,
    COUNT(*)                        AS total_registros,
    ROUND(AVG(r.valor), 2)          AS promedio_resultado
FROM resultado r
JOIN indicador ind ON r.id_indicador = ind.id_indicador
JOIN servicio  s   ON r.id_servicio  = s.id_servicio
GROUP BY
    s.nombre_servicio,
    ind.nombre_indicador,
    ind.unidad
ORDER BY
    s.nombre_servicio,
    total_registros DESC;
