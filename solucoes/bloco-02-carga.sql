-- Soluções do bloco 02 - Carga
-- Pré-requisito: ambiente/02-carga-dados.sql já executado.

-- Exercício 1
-- Contagem de linhas por tabela, em um único resultado.
SELECT 'estacoes' AS tabela, COUNT(*) AS linhas FROM estacoes
UNION ALL SELECT 'carregadores', COUNT(*) FROM carregadores
UNION ALL SELECT 'motoristas', COUNT(*) FROM motoristas
UNION ALL SELECT 'veiculos', COUNT(*) FROM veiculos
UNION ALL SELECT 'recargas', COUNT(*) FROM recargas;

-- Exercício 2
-- Total de linhas do banco inteiro.
SELECT SUM(linhas) AS total_linhas
FROM (
    SELECT COUNT(*) AS linhas FROM estacoes
    UNION ALL SELECT COUNT(*) FROM carregadores
    UNION ALL SELECT COUNT(*) FROM motoristas
    UNION ALL SELECT COUNT(*) FROM veiculos
    UNION ALL SELECT COUNT(*) FROM recargas
) t;

-- Exercício 3
-- Primeiras linhas de cada tabela (uma consulta por vez no Query editor).
SELECT TOP 5 * FROM estacoes ORDER BY id_estacao;
SELECT TOP 5 * FROM carregadores ORDER BY id_carregador;
SELECT TOP 5 * FROM motoristas ORDER BY id_motorista;
SELECT TOP 5 * FROM veiculos ORDER BY id_veiculo;
SELECT TOP 5 * FROM recargas ORDER BY id_recarga;

-- Exercício 4
-- A carga é repetível? Rodar o 02 de novo não deve dobrar as linhas.
-- (Depois de rodar o 02 uma segunda vez, repita o exercício 1.)
SELECT COUNT(*) AS recargas FROM recargas;

-- Exercício 5
-- Menor e maior id de cada tabela: confirma que os ids começam em 1 e não têm buracos.
SELECT MIN(id_recarga) AS menor_id, MAX(id_recarga) AS maior_id,
       COUNT(*) AS linhas, MAX(id_recarga) - MIN(id_recarga) + 1 AS esperado_sem_buracos
FROM recargas;
