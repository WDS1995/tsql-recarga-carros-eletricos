-- Soluções do bloco 05 - Limpeza
-- Padrão de cada exercício: BEGIN TRAN -> alteração -> conferência -> COMMIT ou ROLLBACK.
-- Aqui o COMMIT é automático quando a conferência dá zero problema; no seu treino,
-- troque por ROLLBACK na primeira execução para só ver a conferência.
-- Rode cada exercício INTEIRO em uma única execução (A conferir no Azure: o Query editor
-- mantém a transação aberta entre execuções? Por isso tudo vai no mesmo script).

-- Exercício 1
-- Estações: cidade e uf padronizadas.
-- O banco ignora caixa e espaço no fim ao comparar, então não dá para "detectar" cada grafia errada.
-- A saída é reescrever TODAS as linhas com o valor canônico (rodar de novo não muda nada).
-- REPLACE tira o til só para comparar 'sao paulo' e 'são paulo' do mesmo jeito.
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
                   WHERE cidade NOT IN (N'São Paulo', N'Campinas', N'Rio de Janeiro', N'Belo Horizonte', N'Curitiba')
                      OR cidade LIKE N'% ' OR cidade LIKE N' %'
                      OR uf LIKE N'% '     OR uf LIKE N' %');
IF @p1 = 0 COMMIT TRAN ELSE ROLLBACK TRAN;
SELECT @p1 AS problemas_restantes, @@TRANCOUNT AS transacoes_abertas;
-- Depois: como todas as linhas foram reescritas, cada grupo mostra a grafia correta.
SELECT cidade, uf, COUNT(*) AS qtd
FROM estacoes
GROUP BY cidade, uf
ORDER BY cidade, uf;

-- Exercício 2
-- Carregadores: status em três valores padrão (todas as linhas reescritas). A potência NULL
-- NÃO é inventada: não sabemos o valor, então continua NULL.
BEGIN TRAN;

UPDATE carregadores
SET status = CASE
                 WHEN LOWER(TRIM(status)) LIKE N'dispon%' THEN N'Disponivel'
                 WHEN LOWER(TRIM(status)) = N'em uso'      THEN N'Em uso'
                 WHEN LOWER(TRIM(status)) LIKE N'manuten%' THEN N'Manutencao'
                 ELSE status
             END;

DECLARE @p2 INT = (SELECT COUNT(*) FROM carregadores
                   WHERE status NOT IN (N'Disponivel', N'Em uso', N'Manutencao')
                      OR status LIKE N'% ' OR status LIKE N' %');
IF @p2 = 0 COMMIT TRAN ELSE ROLLBACK TRAN;
SELECT @p2 AS problemas_restantes, @@TRANCOUNT AS transacoes_abertas;
SELECT status, COUNT(*) AS qtd
FROM carregadores
GROUP BY status
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
                   WHERE nome LIKE N'% ' OR nome LIKE N' %' OR nome LIKE N'%  %'
                      OR email LIKE N'% ' OR email LIKE N' %');
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
-- A subconsulta acha, por e-mail, o id que fica; HAVING COUNT(*) > 1 deixa só os e-mails repetidos.
BEGIN TRAN;

UPDATE v
SET v.id_motorista = k.id_manter
FROM veiculos v
INNER JOIN motoristas m ON m.id_motorista = v.id_motorista
INNER JOIN (SELECT LOWER(TRIM(email)) AS email, MIN(id_motorista) AS id_manter
            FROM motoristas
            GROUP BY LOWER(TRIM(email))
            HAVING COUNT(*) > 1) k ON k.email = LOWER(TRIM(m.email))
WHERE v.id_motorista <> k.id_manter;

DELETE m
FROM motoristas m
INNER JOIN (SELECT LOWER(TRIM(email)) AS email, MIN(id_motorista) AS id_manter
            FROM motoristas
            GROUP BY LOWER(TRIM(email))
            HAVING COUNT(*) > 1) k ON k.email = LOWER(TRIM(m.email))
WHERE m.id_motorista <> k.id_manter;

DECLARE @p5 INT = (SELECT COUNT(*) FROM veiculos v
                   LEFT JOIN motoristas m ON m.id_motorista = v.id_motorista
                   WHERE m.id_motorista IS NULL);
IF @p5 = 0 COMMIT TRAN ELSE ROLLBACK TRAN;
SELECT (SELECT COUNT(*) FROM motoristas) AS motoristas,
       (SELECT COUNT(*) FROM veiculos)   AS veiculos,
       @p5 AS veiculos_sem_dono;

-- Exercício 6
-- Deduplicar recargas: linhas idênticas em todas as colunas, menos o id.
-- Guarda a de menor id de cada grupo e apaga as cópias. (GROUP BY trata NULL como igual a NULL;
-- por isso usamos NOT IN com o MIN(id) em vez de um JOIN por igualdade.)
BEGIN TRAN;

DELETE FROM recargas
WHERE id_recarga NOT IN (SELECT MIN(id_recarga)
                         FROM recargas
                         GROUP BY id_veiculo, id_carregador, inicio, fim,
                                  energia_kwh, preco_kwh_aplicado, valor_total);

DECLARE @p6 INT = (SELECT COUNT(*) FROM recargas)
                - (SELECT COUNT(*) FROM (SELECT 1 AS x
                                         FROM recargas
                                         GROUP BY id_veiculo, id_carregador, inicio, fim,
                                                  energia_kwh, preco_kwh_aplicado, valor_total) g);
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
