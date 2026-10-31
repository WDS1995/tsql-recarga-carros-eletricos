-- Soluções do bloco 04 - JOINs
-- Rode UM exercício por vez no Query editor.

-- Exercício 1
-- INNER JOIN de 2 tabelas: recarga + carregador.
SELECT COUNT(*) AS linhas
FROM recargas r
INNER JOIN carregadores c ON c.id_carregador = r.id_carregador;

-- Exercício 2
-- 3 tabelas: recarga + veículo + motorista. As recargas órfãs somem no INNER JOIN.
SELECT COUNT(*) AS linhas
FROM recargas r
INNER JOIN veiculos v   ON v.id_veiculo = r.id_veiculo
INNER JOIN motoristas m ON m.id_motorista = v.id_motorista;

-- Exercício 3
-- 5 tabelas: o caminho completo, da recarga até a estação e o motorista.
SELECT COUNT(*) AS linhas
FROM recargas r
INNER JOIN veiculos v     ON v.id_veiculo = r.id_veiculo
INNER JOIN motoristas m   ON m.id_motorista = v.id_motorista
INNER JOIN carregadores c ON c.id_carregador = r.id_carregador
INNER JOIN estacoes e     ON e.id_estacao = c.id_estacao;

-- Exercício 4
-- Recargas órfãs: LEFT JOIN e filtro no lado que não casou.
SELECT r.id_recarga, r.id_veiculo, r.inicio
FROM recargas r
LEFT JOIN veiculos v ON v.id_veiculo = r.id_veiculo
WHERE v.id_veiculo IS NULL
ORDER BY r.id_recarga;

-- Exercício 5
-- Motoristas que nunca recarregaram (nem têm veículo com recarga).
SELECT m.id_motorista, m.nome
FROM motoristas m
LEFT JOIN veiculos v ON v.id_motorista = m.id_motorista
LEFT JOIN recargas r ON r.id_veiculo = v.id_veiculo
WHERE r.id_recarga IS NULL
ORDER BY m.id_motorista;

-- Exercício 6
-- Carregador nunca usado.
SELECT c.id_carregador, c.id_estacao, c.tipo_conector
FROM carregadores c
LEFT JOIN recargas r ON r.id_carregador = c.id_carregador
WHERE r.id_recarga IS NULL;

-- Exercício 7
-- Self JOIN: pares de motoristas com o mesmo e-mail (cadastro duplicado).
SELECT a.id_motorista AS id_a, b.id_motorista AS id_b, LOWER(TRIM(a.email)) AS email
FROM motoristas a
INNER JOIN motoristas b
        ON LOWER(TRIM(a.email)) = LOWER(TRIM(b.email))
       AND a.id_motorista < b.id_motorista
ORDER BY a.id_motorista;

-- Exercício 8
-- Motoristas com mais de um veículo (JOIN + GROUP BY + HAVING).
SELECT m.id_motorista, m.nome, COUNT(*) AS veiculos
FROM motoristas m
INNER JOIN veiculos v ON v.id_motorista = m.id_motorista
GROUP BY m.id_motorista, m.nome
HAVING COUNT(*) > 1
ORDER BY m.id_motorista;
