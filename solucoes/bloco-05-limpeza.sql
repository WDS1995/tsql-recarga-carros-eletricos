-- Soluções do bloco 05 - Limpeza
-- Padrão de cada exercício: BEGIN TRAN -> alteração -> conferência -> COMMIT ou ROLLBACK.
-- Aqui o COMMIT é automático quando a conferência dá zero problema; no seu treino,
-- troque por ROLLBACK na primeira execução para só ver a conferência.
-- Rode cada exercício INTEIRO em uma única execução (A conferir no Azure: o Query editor
-- mantém a transação aberta entre execuções? Por isso tudo vai no mesmo script).

-- Exercício 1
-- Estações: cidade e uf padronizadas.
-- REPLACE tira o til para comparar 'sao paulo' e 'são paulo' do mesmo jeito.
-- Antes: grafias distintas (BIN diferencia maiúscula/minúscula e acento).
SELECT COUNT(DISTINCT cidade COLLATE Latin1_General_BIN) AS cidades_antes,
       COUNT(DISTINCT uf COLLATE Latin1_General_BIN)     AS ufs_antes
FROM estacoes;

BEGIN TRAN;

UPDATE estacoes
SET cidade = CASE LOWER(REPLACE(TRIM(cidade), N'ã', N'a'))
                 WHEN N'sao paulo'      THEN N'São Paulo'
                 WHEN N'campinas'       THEN N'Campinas'
                 WHEN N'rio de janeiro' THEN N'Rio de Janeiro'
                 WHEN N'belo horizonte' THEN N'Belo Horizonte'
                 WHEN N'curitiba'       THEN N'Curitiba'
                 ELSE cidade
             END,
    uf = UPPER(TRIM(uf));

DECLARE @p1 INT = (SELECT COUNT(*) FROM estacoes
                   WHERE cidade COLLATE Latin1_General_BIN NOT IN (N'São Paulo', N'Campinas', N'Rio de Janeiro', N'Belo Horizonte', N'Curitiba')
                      OR DATALENGTH(cidade) <> DATALENGTH(TRIM(cidade))
                      OR uf COLLATE Latin1_General_BIN <> UPPER(TRIM(uf))
                      OR DATALENGTH(uf) <> DATALENGTH(TRIM(uf)));
IF @p1 = 0 COMMIT TRAN ELSE ROLLBACK TRAN;
SELECT @p1 AS problemas_restantes, @@TRANCOUNT AS transacoes_abertas;
-- Depois: grafias distintas
SELECT COUNT(DISTINCT cidade COLLATE Latin1_General_BIN) AS cidades_depois,
       COUNT(DISTINCT uf COLLATE Latin1_General_BIN)     AS ufs_depois
FROM estacoes;

-- Exercício 2
-- Carregadores: status em três valores padrão. A potência NULL NÃO é inventada:
-- não sabemos o valor, então continua NULL.
BEGIN TRAN;

UPDATE carregadores
SET status = CASE
                 WHEN LOWER(TRIM(status)) LIKE N'dispon%' THEN N'Disponivel'
                 WHEN LOWER(TRIM(status)) = N'em uso'      THEN N'Em uso'
                 WHEN LOWER(TRIM(status)) LIKE N'manuten%' THEN N'Manutencao'
                 ELSE status
             END;

DECLARE @p2 INT = (SELECT COUNT(*) FROM carregadores
                   WHERE status COLLATE Latin1_General_BIN NOT IN (N'Disponivel', N'Em uso', N'Manutencao')
                      OR DATALENGTH(status) <> DATALENGTH(TRIM(status)));
IF @p2 = 0 COMMIT TRAN ELSE ROLLBACK TRAN;
-- COLLATE BIN no GROUP BY: sem ele o banco junta 'Disponivel' e 'disponivel' no mesmo grupo.
SELECT status COLLATE Latin1_General_BIN AS status, COUNT(*) AS qtd
FROM carregadores
GROUP BY status COLLATE Latin1_General_BIN
ORDER BY status;
-- As potências NULL continuam NULL:
SELECT COUNT(*) AS potencias_nulas FROM carregadores WHERE potencia_kw IS NULL;

-- Exercício 3
-- Motoristas: nome sem espaços sobrando e e-mail em minúsculas e sem espaços.
BEGIN TRAN;

UPDATE motoristas
SET nome  = REPLACE(TRIM(nome), N'  ', N' '),
    email = LOWER(TRIM(email));

DECLARE @p3 INT = (SELECT COUNT(*) FROM motoristas
                   WHERE DATALENGTH(nome) <> DATALENGTH(TRIM(nome))
                      OR nome LIKE N'%  %'
                      OR email COLLATE Latin1_General_BIN <> LOWER(TRIM(email)));
IF @p3 = 0 COMMIT TRAN ELSE ROLLBACK TRAN;
SELECT @p3 AS problemas_restantes, @@TRANCOUNT AS transacoes_abertas;

-- Exercício 4
-- Veículos: placa sem hífen e em maiúsculas; bateria 0 vira NULL (zero é impossível,
-- NULL diz "não sei").
BEGIN TRAN;

UPDATE veiculos
SET placa = UPPER(REPLACE(TRIM(placa), N'-', N'')),
    bateria_kwh = CASE WHEN bateria_kwh = 0 THEN NULL ELSE bateria_kwh END;

DECLARE @p4 INT = (SELECT COUNT(*) FROM veiculos
                   WHERE placa LIKE N'%-%' OR LEN(placa) <> 7 OR bateria_kwh = 0);
IF @p4 = 0 COMMIT TRAN ELSE ROLLBACK TRAN;
SELECT COUNT(*) AS veiculos_sem_bateria_informada FROM veiculos WHERE bateria_kwh IS NULL;

-- Exercício 5
-- Deduplicar motoristas: mantém o MENOR id de cada e-mail.
-- Ordem importa: 1) reapontar os veículos; 2) só então apagar os duplicados.
BEGIN TRAN;

UPDATE v
SET v.id_motorista = k.id_manter
FROM veiculos v
INNER JOIN (SELECT id_motorista,
                   MIN(id_motorista) OVER (PARTITION BY LOWER(TRIM(email))) AS id_manter
            FROM motoristas) k ON k.id_motorista = v.id_motorista
WHERE k.id_motorista <> k.id_manter;

DELETE FROM motoristas
WHERE id_motorista IN (SELECT id_motorista
                       FROM (SELECT id_motorista,
                                    MIN(id_motorista) OVER (PARTITION BY LOWER(TRIM(email))) AS id_manter
                             FROM motoristas) k
                       WHERE id_motorista <> id_manter);

DECLARE @p5 INT = (SELECT COUNT(*) FROM veiculos v
                   LEFT JOIN motoristas m ON m.id_motorista = v.id_motorista
                   WHERE m.id_motorista IS NULL);
IF @p5 = 0 COMMIT TRAN ELSE ROLLBACK TRAN;
SELECT (SELECT COUNT(*) FROM motoristas) AS motoristas,
       (SELECT COUNT(*) FROM veiculos)   AS veiculos,
       @p5 AS veiculos_sem_dono;

-- Exercício 6
-- Deduplicar recargas: linhas idênticas em todas as colunas, menos o id.
-- Guarda a de menor id e apaga as cópias.
BEGIN TRAN;

WITH d AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY id_veiculo, id_carregador, inicio, fim,
                                           energia_kwh, preco_kwh_aplicado, valor_total
                              ORDER BY id_recarga) AS rn
    FROM recargas
)
DELETE FROM d WHERE rn > 1;

DECLARE @p6 INT = (SELECT COUNT(*) FROM (
                       SELECT ROW_NUMBER() OVER (PARTITION BY id_veiculo, id_carregador, inicio, fim,
                                                              energia_kwh, preco_kwh_aplicado, valor_total
                                                 ORDER BY id_recarga) AS rn
                       FROM recargas) x WHERE rn > 1);
IF @p6 = 0 COMMIT TRAN ELSE ROLLBACK TRAN;
SELECT COUNT(*) AS recargas FROM recargas;

-- Exercício 7
-- Recargas inválidas: NÃO são corrigidas nem apagadas. Aqui só medimos quantas ficarão
-- de fora do tabelão.
SELECT COUNT(*) AS total,
       SUM(CASE WHEN v.id_veiculo IS NULL THEN 1 ELSE 0 END)                       AS orfas,
       SUM(CASE WHEN r.fim < r.inicio THEN 1 ELSE 0 END)                           AS fim_antes_inicio,
       SUM(CASE WHEN r.energia_kwh < 0 THEN 1 ELSE 0 END)                          AS energia_negativa,
       SUM(CASE WHEN ABS(r.valor_total - ROUND(r.energia_kwh * r.preco_kwh_aplicado, 2)) > 0.01
                THEN 1 ELSE 0 END)                                                 AS valor_incoerente,
       SUM(CASE WHEN v.id_veiculo IS NULL
                  OR r.fim < r.inicio
                  OR r.energia_kwh < 0
                  OR ABS(r.valor_total - ROUND(r.energia_kwh * r.preco_kwh_aplicado, 2)) > 0.01
                THEN 1 ELSE 0 END)                                                 AS invalidas,
       SUM(CASE WHEN v.id_veiculo IS NOT NULL
                 AND (r.fim IS NULL OR r.fim >= r.inicio)
                 AND (r.energia_kwh IS NULL OR r.energia_kwh >= 0)
                 AND (r.valor_total IS NULL
                      OR ABS(r.valor_total - ROUND(r.energia_kwh * r.preco_kwh_aplicado, 2)) <= 0.01)
                THEN 1 ELSE 0 END)                                                 AS validas
FROM recargas r
LEFT JOIN veiculos v ON v.id_veiculo = r.id_veiculo;

-- Exercício 8
-- Nem todo NULL é erro: recarga em andamento tem fim, energia e valor NULL ao mesmo tempo.
SELECT COUNT(*) AS em_andamento,
       SUM(CASE WHEN energia_kwh IS NULL AND valor_total IS NULL THEN 1 ELSE 0 END) AS com_energia_e_valor_nulos
FROM recargas
WHERE fim IS NULL;
