-- Soluções do bloco 06 - Tabelão (normalizado -> desnormalizado)
-- Pré-requisito: bloco 05 concluído (base limpa).
-- No Query editor do portal, rode cada trecho entre os GO numa execução separada (o GO separa lotes; CREATE VIEW precisa ser o primeiro comando do lote) — A conferir no Azure se o editor aceita GO.

-- Exercício 1
-- Tabelão com colunas desnormalizadas e constraints (o Exercício 2 está logo abaixo, no mesmo CREATE).
-- Atenção: um CHECK só barra quando a condição dá FALSO. Com NULL a condição dá
-- "desconhecido" e a linha PASSA. Por isso os CHECKs de fim/energia/valor têm "IS NULL OR ...".
DROP TABLE IF EXISTS tabelao_recargas;

CREATE TABLE tabelao_recargas (
    id_recarga         INT           NOT NULL PRIMARY KEY,
    motorista          NVARCHAR(100) NOT NULL,
    email_motorista    NVARCHAR(150) NOT NULL,
    placa              NVARCHAR(10)  NOT NULL,
    modelo             NVARCHAR(60)  NOT NULL,
    bateria_kwh        DECIMAL(5,1)  NULL,
    id_carregador      INT           NOT NULL,
    tipo_conector      NVARCHAR(20)  NOT NULL,
    potencia_kw        DECIMAL(6,1)  NULL,
    estacao            NVARCHAR(100) NOT NULL,
    cidade             NVARCHAR(60)  NOT NULL,
    uf                 CHAR(2)       NOT NULL,
    inicio             DATETIME2(0)  NOT NULL,
    fim                DATETIME2(0)  NULL,
    duracao_min        INT           NULL,
    energia_kwh        DECIMAL(7,2)  NULL,
    preco_kwh_aplicado DECIMAL(6,2)  NOT NULL,
    valor_total        DECIMAL(9,2)  NULL,
    CONSTRAINT ck_tabelao_fim      CHECK (fim IS NULL OR fim >= inicio),
    CONSTRAINT ck_tabelao_energia  CHECK (energia_kwh IS NULL OR energia_kwh >= 0),
    CONSTRAINT ck_tabelao_valor    CHECK (valor_total IS NULL OR valor_total >= 0),
    CONSTRAINT ck_tabelao_preco    CHECK (preco_kwh_aplicado > 0),
    CONSTRAINT ck_tabelao_duracao  CHECK (duracao_min IS NULL OR duracao_min >= 0),
    CONSTRAINT ck_tabelao_andamento CHECK (
        (fim IS NULL AND energia_kwh IS NULL AND valor_total IS NULL)
     OR (fim IS NOT NULL AND energia_kwh IS NOT NULL AND valor_total IS NOT NULL))
);

SELECT COUNT(*) AS colunas FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'tabelao_recargas';

-- Exercício 2
-- Os CHECKs foram criados no CREATE TABLE do Exercício 1; aqui só conferimos quantos existem.
SELECT COUNT(*) AS checks FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'tabelao_recargas' AND CONSTRAINT_TYPE = 'CHECK';

-- Exercício 3
-- Carga do tabelão: junta as 5 tabelas e deixa de fora as recargas inválidas.
-- INNER JOIN em veiculos já elimina as órfãs.
INSERT INTO tabelao_recargas
    (id_recarga, motorista, email_motorista, placa, modelo, bateria_kwh,
     id_carregador, tipo_conector, potencia_kw, estacao, cidade, uf,
     inicio, fim, duracao_min, energia_kwh, preco_kwh_aplicado, valor_total)
SELECT r.id_recarga, m.nome, m.email, v.placa, v.modelo, v.bateria_kwh,
       c.id_carregador, c.tipo_conector, c.potencia_kw, e.nome, e.cidade, e.uf,
       r.inicio, r.fim, DATEDIFF(MINUTE, r.inicio, r.fim), r.energia_kwh, r.preco_kwh_aplicado, r.valor_total
FROM recargas r
INNER JOIN veiculos v     ON v.id_veiculo = r.id_veiculo
INNER JOIN motoristas m   ON m.id_motorista = v.id_motorista
INNER JOIN carregadores c ON c.id_carregador = r.id_carregador
INNER JOIN estacoes e     ON e.id_estacao = c.id_estacao
WHERE (r.fim IS NULL OR r.fim >= r.inicio)
  AND (r.energia_kwh IS NULL OR r.energia_kwh >= 0)
  AND (r.valor_total IS NULL
       OR ABS(r.valor_total - ROUND(r.energia_kwh * r.preco_kwh_aplicado, 2)) <= 0.01);

-- Exercício 4
-- Conferência do tabelão.
SELECT COUNT(*)                                            AS linhas,
       SUM(CASE WHEN fim IS NULL THEN 1 ELSE 0 END)        AS em_andamento,
       MIN(inicio)                                         AS primeira,
       MAX(inicio)                                         AS ultima,
       SUM(valor_total)                                    AS faturamento_total,
       SUM(energia_kwh)                                    AS kwh_total
FROM tabelao_recargas;

-- Exercício 5
-- A constraint barrando linhas ruins (erro 547 = CHECK; erro 515 = NOT NULL).
BEGIN TRY
    INSERT INTO tabelao_recargas
        (id_recarga, motorista, email_motorista, placa, modelo, id_carregador, tipo_conector,
         estacao, cidade, uf, inicio, fim, duracao_min, energia_kwh, preco_kwh_aplicado, valor_total)
    VALUES (900001, N'Teste', N'teste@exemplo.com.br', N'AAA0A00', N'Teste', 1, N'CCS2',
            N'Estacao Teste', N'São Paulo', 'SP', '2026-09-01 10:00:00', '2026-09-01 09:00:00',
            NULL, 10, 2.50, 25);
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS numero_erro, ERROR_MESSAGE() AS mensagem;
END CATCH;

BEGIN TRY
    INSERT INTO tabelao_recargas
        (id_recarga, motorista, email_motorista, placa, modelo, id_carregador, tipo_conector,
         estacao, cidade, uf, inicio, preco_kwh_aplicado)
    VALUES (900002, NULL, N'teste@exemplo.com.br', N'AAA0A00', N'Teste', 1, N'CCS2',
            N'Estacao Teste', N'São Paulo', 'SP', '2026-09-01 10:00:00', 2.50);
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS numero_erro, ERROR_MESSAGE() AS mensagem;
END CATCH;

SELECT COUNT(*) AS linhas_depois_dos_testes FROM tabelao_recargas;

-- Exercício 6
-- Duração: DATEDIFF(MINUTE, inicio, fim). Recarga em andamento fica NULL.
SELECT MIN(duracao_min) AS menor, AVG(duracao_min) AS media, MAX(duracao_min) AS maior,
       SUM(CASE WHEN duracao_min IS NULL THEN 1 ELSE 0 END) AS sem_duracao
FROM tabelao_recargas;

-- Exercício 7
-- Mesma pergunta nos dois modelos: faturamento por cidade.
-- No tabelão: nenhum JOIN.
SELECT cidade, COUNT(*) AS recargas, SUM(valor_total) AS faturamento
FROM tabelao_recargas
GROUP BY cidade
ORDER BY cidade;

-- Na base normalizada: 4 JOINs e as mesmas regras de validade.
SELECT e.cidade, COUNT(*) AS recargas, SUM(r.valor_total) AS faturamento
FROM recargas r
INNER JOIN veiculos v     ON v.id_veiculo = r.id_veiculo
INNER JOIN carregadores c ON c.id_carregador = r.id_carregador
INNER JOIN estacoes e     ON e.id_estacao = c.id_estacao
WHERE (r.fim IS NULL OR r.fim >= r.inicio)
  AND (r.energia_kwh IS NULL OR r.energia_kwh >= 0)
  AND (r.valor_total IS NULL
       OR ABS(r.valor_total - ROUND(r.energia_kwh * r.preco_kwh_aplicado, 2)) <= 0.01)
GROUP BY e.cidade
ORDER BY e.cidade;

-- Exercício 8
-- VIEW como contraste: guarda só a consulta, não os dados e não tem constraints.
-- CREATE VIEW precisa ser o primeiro comando do lote.
-- No Query editor do portal, rode cada trecho entre os GO numa execução separada (o GO separa lotes; CREATE VIEW precisa ser o primeiro comando do lote) — A conferir no Azure se o editor aceita GO.
GO
CREATE OR ALTER VIEW vw_recargas_detalhe AS
SELECT r.id_recarga, m.nome AS motorista, v.placa, e.nome AS estacao, e.cidade,
       r.inicio, r.fim, r.energia_kwh, r.valor_total
FROM recargas r
INNER JOIN veiculos v     ON v.id_veiculo = r.id_veiculo
INNER JOIN motoristas m   ON m.id_motorista = v.id_motorista
INNER JOIN carregadores c ON c.id_carregador = r.id_carregador
INNER JOIN estacoes e     ON e.id_estacao = c.id_estacao
WHERE (r.fim IS NULL OR r.fim >= r.inicio)
  AND (r.energia_kwh IS NULL OR r.energia_kwh >= 0)
  AND (r.valor_total IS NULL
       OR ABS(r.valor_total - ROUND(r.energia_kwh * r.preco_kwh_aplicado, 2)) <= 0.01);
GO

SELECT COUNT(*) AS linhas_da_view FROM vw_recargas_detalhe;
