-- Soluções do bloco 03 - Validação e exploração (dados ainda sujos)
-- Rode UM exercício por vez no Query editor.

-- Exercício 1
-- Olhar os dados: as 10 primeiras recargas.
SELECT TOP 10 * FROM recargas ORDER BY id_recarga;

-- Exercício 2
-- COUNT(*) conta linhas; COUNT(coluna) ignora NULL; COUNT(DISTINCT ...) conta valores diferentes.
SELECT COUNT(*)                     AS total_linhas,
       COUNT(fim)                   AS com_fim,
       COUNT(DISTINCT id_veiculo)   AS veiculos_distintos,
       COUNT(DISTINCT id_carregador) AS carregadores_distintos
FROM recargas;

-- Exercício 3
-- Período coberto pelos dados.
SELECT MIN(inicio) AS primeira_recarga, MAX(inicio) AS ultima_recarga
FROM recargas;

-- Exercício 4
-- DISTINCT de cidade e uf nas estações. Atenção: o banco ignora maiúsculas/minúsculas
-- e espaços no fim ao comparar; veja o que o DISTINCT "esconde".
SELECT DISTINCT cidade, uf FROM estacoes ORDER BY cidade, uf;

-- Exercício 5
-- O banco trata 'Curitiba' e 'CURITIBA' como iguais na comparação, mas o texto gravado é diferente.
SELECT id_estacao, '[' + cidade + ']' AS cidade_gravada
FROM estacoes
WHERE cidade = N'curitiba';

-- Espaço sobrando: no LIKE, o espaço do padrão conta (o = ignoraria o espaço no fim).
SELECT id_estacao, '[' + cidade + ']' AS cidade_gravada
FROM estacoes
WHERE cidade LIKE N'% ' OR cidade LIKE N' %';

-- Exercício 6
-- Status dos carregadores: o GROUP BY enxerga quantos grupos?
SELECT COUNT(*) AS grupos_de_status
FROM (SELECT status FROM carregadores GROUP BY status) g;

-- Quais têm espaço sobrando no começo ou no fim?
SELECT id_carregador, '[' + status + ']' AS status_gravado
FROM carregadores
WHERE status LIKE N'% ' OR status LIKE N' %'
ORDER BY id_carregador;

-- Exercício 7 (NULLs)
-- NULLs: quais colunas têm NULL e quantos.
SELECT
    (SELECT COUNT(*) FROM carregadores WHERE potencia_kw IS NULL) AS carregadores_sem_potencia,
    (SELECT COUNT(*) FROM recargas WHERE fim IS NULL)             AS recargas_sem_fim,
    (SELECT COUNT(*) FROM recargas WHERE energia_kwh IS NULL)     AS recargas_sem_energia,
    (SELECT COUNT(*) FROM recargas WHERE valor_total IS NULL)     AS recargas_sem_valor;

-- Exercício 7 (continuação: valores impossíveis)
-- Valores impossíveis.
SELECT
    (SELECT COUNT(*) FROM recargas WHERE fim < inicio)        AS fim_antes_do_inicio,
    (SELECT COUNT(*) FROM recargas WHERE energia_kwh < 0)     AS energia_negativa,
    (SELECT COUNT(*) FROM recargas WHERE valor_total > 300)   AS valor_acima_de_300,
    (SELECT COUNT(*) FROM veiculos WHERE bateria_kwh = 0)     AS bateria_zero,
    (SELECT COUNT(*) FROM veiculos WHERE placa LIKE N'%-%')   AS placa_com_hifen;

-- Exercício 8
-- Cadastros duplicados: e-mails que aparecem mais de uma vez (ignorando caixa e espaços).
SELECT LOWER(TRIM(email)) AS email, COUNT(*) AS qtd, MIN(id_motorista) AS menor_id, MAX(id_motorista) AS maior_id
FROM motoristas
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1
ORDER BY menor_id;
