-- Soluções do bloco 08 - Fecho (procedure, trigger, permissões)
-- CREATE PROCEDURE e CREATE TRIGGER precisam ser o PRIMEIRO comando do lote.
-- Neste arquivo os lotes são separados por GO (vale para sqlcmd/SSMS).
-- No Query editor do portal, rode cada trecho entre os GO numa execução separada (o GO separa lotes; CREATE PROCEDURE/TRIGGER precisa ser o primeiro comando do lote) — A conferir no Azure se o editor aceita GO.

-- Exercício 1
-- Procedure que apaga e recarrega o tabelão em uma transação.
-- Se qualquer passo falhar, ROLLBACK devolve o tabelão como estava.
-- No Query editor do portal, rode cada trecho entre os GO numa execução separada (o GO separa lotes; CREATE PROCEDURE/TRIGGER precisa ser o primeiro comando do lote) — A conferir no Azure se o editor aceita GO.
GO
CREATE OR ALTER PROCEDURE atualizar_tabelao
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRAN;

        DELETE FROM tabelao_recargas;

        INSERT INTO tabelao_recargas
            (id_recarga, motorista, email_motorista, placa, modelo, bateria_kwh,
             id_carregador, tipo_conector, potencia_kw, estacao, cidade, uf,
             inicio, fim, duracao_min, energia_kwh, preco_kwh_aplicado, valor_total)
        SELECT r.id_recarga, m.nome, m.email, v.placa, v.modelo, v.bateria_kwh,
               c.id_carregador, c.tipo_conector, c.potencia_kw, e.nome, e.cidade, e.uf,
               r.inicio, r.fim, DATEDIFF(MINUTE, r.inicio, r.fim), r.energia_kwh,
               r.preco_kwh_aplicado, r.valor_total
        FROM recargas r
        INNER JOIN veiculos v     ON v.id_veiculo = r.id_veiculo
        INNER JOIN motoristas m   ON m.id_motorista = v.id_motorista
        INNER JOIN carregadores c ON c.id_carregador = r.id_carregador
        INNER JOIN estacoes e     ON e.id_estacao = c.id_estacao
        WHERE (r.fim IS NULL OR r.fim >= r.inicio)
          AND (r.energia_kwh IS NULL OR r.energia_kwh >= 0)
          AND (r.valor_total IS NULL
               OR ABS(r.valor_total - ROUND(r.energia_kwh * r.preco_kwh_aplicado, 2)) <= 0.01);

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

-- Exercício 2
-- Teste do caminho feliz: apaga parte do tabelão e deixa a procedure refazer.
DELETE FROM tabelao_recargas WHERE id_recarga <= 300;
SELECT COUNT(*) AS linhas_antes FROM tabelao_recargas;

EXEC atualizar_tabelao;
SELECT COUNT(*) AS linhas_depois FROM tabelao_recargas;

-- Exercício 3
-- Teste do ROLLBACK: uma recarga com preço aplicado 0 passa pelo filtro, mas o CHECK
-- do tabelão (preço > 0) barra. O DELETE já tinha rodado; o ROLLBACK devolve as linhas.
INSERT INTO recargas (id_recarga, id_veiculo, id_carregador, inicio, fim, energia_kwh, preco_kwh_aplicado, valor_total)
VALUES (2001, 1, 1, '2026-09-30 22:00:00', '2026-09-30 22:30:00', 10.00, 0.00, 0.00);

BEGIN TRY
    EXEC atualizar_tabelao;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS numero_erro, ERROR_MESSAGE() AS mensagem;
END CATCH;

SELECT COUNT(*) AS linhas_apos_o_erro, @@TRANCOUNT AS transacoes_abertas FROM tabelao_recargas;

-- Desfaz o dado ruim e confirma que a procedure volta a funcionar.
DELETE FROM recargas WHERE id_recarga = 2001;
EXEC atualizar_tabelao;
SELECT COUNT(*) AS linhas_final FROM tabelao_recargas;

-- Exercício 4
-- Tabela de histórico de status.
DROP TABLE IF EXISTS historico_status;

CREATE TABLE historico_status (
    id_historico    INT IDENTITY(1,1) PRIMARY KEY,
    id_carregador   INT          NOT NULL,
    status_anterior NVARCHAR(20) NULL,
    status_novo     NVARCHAR(20) NOT NULL,
    alterado_em     DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);

-- Exercício 5
-- Trigger AFTER UPDATE: grava no histórico quando o status VIRA manutenção.
-- Usa as tabelas especiais inserted (depois) e deleted (antes); funciona para várias
-- linhas atualizadas de uma vez.
-- No Query editor do portal, rode cada trecho entre os GO numa execução separada (o GO separa lotes; CREATE PROCEDURE/TRIGGER precisa ser o primeiro comando do lote) — A conferir no Azure se o editor aceita GO.
GO
CREATE OR ALTER TRIGGER trg_carregadores_manutencao
ON carregadores
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(status)
        INSERT INTO historico_status (id_carregador, status_anterior, status_novo)
        SELECT i.id_carregador, d.status, i.status
        FROM inserted i
        INNER JOIN deleted d ON d.id_carregador = i.id_carregador
        WHERE i.status = N'Manutencao'
          AND d.status <> i.status;
END;
GO

-- Exercício 6
-- Teste do trigger.
UPDATE carregadores SET status = N'Manutencao' WHERE id_carregador = 1;
SELECT COUNT(*) AS historico_apos_1_manutencao FROM historico_status;

UPDATE carregadores SET status = N'Em uso' WHERE id_carregador = 2;
SELECT COUNT(*) AS historico_apos_em_uso FROM historico_status;

UPDATE carregadores SET status = N'Manutencao' WHERE id_carregador IN (3, 4, 5);
SELECT COUNT(*) AS historico_apos_3_de_uma_vez FROM historico_status;

UPDATE carregadores SET status = N'Manutencao' WHERE id_carregador = 7;
SELECT COUNT(*) AS historico_carregador_ja_em_manutencao FROM historico_status;

SELECT id_carregador, status_anterior, status_novo FROM historico_status ORDER BY id_historico;

-- Volta os carregadores ao estado normal (voltar para Disponivel não grava no histórico).
UPDATE carregadores SET status = N'Disponivel' WHERE id_carregador IN (1, 2, 3, 4, 5);
SELECT status, COUNT(*) AS qtd
FROM carregadores
GROUP BY status
ORDER BY status;

-- Exercício 7
-- Papel (role) + usuário sem login + GRANT só no tabelão.
-- CREATE USER ... WITHOUT LOGIN consta na sintaxe do Azure SQL Database (Microsoft Learn).
DROP USER IF EXISTS analista_demo;
DROP ROLE IF EXISTS analista_leitura;

CREATE ROLE analista_leitura;
CREATE USER analista_demo WITHOUT LOGIN;
ALTER ROLE analista_leitura ADD MEMBER analista_demo;
GRANT SELECT ON dbo.tabelao_recargas TO analista_leitura;

-- Exercício 8
-- Testando as permissões como o analista.
EXECUTE AS USER = 'analista_demo';
SELECT USER_NAME() AS quem_sou;
SELECT COUNT(*) AS linhas_do_tabelao FROM tabelao_recargas;
REVERT;

EXECUTE AS USER = 'analista_demo';
BEGIN TRY
    SELECT COUNT(*) FROM recargas;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS numero_erro, ERROR_MESSAGE() AS mensagem;
END CATCH;
REVERT;

EXECUTE AS USER = 'analista_demo';
BEGIN TRY
    DELETE FROM tabelao_recargas;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS numero_erro, ERROR_MESSAGE() AS mensagem;
END CATCH;
REVERT;

-- REVOKE: o analista perde o acesso ao tabelão.
REVOKE SELECT ON dbo.tabelao_recargas FROM analista_leitura;

EXECUTE AS USER = 'analista_demo';
BEGIN TRY
    SELECT COUNT(*) FROM tabelao_recargas;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS numero_erro, ERROR_MESSAGE() AS mensagem;
END CATCH;
REVERT;

SELECT USER_NAME() AS voltei_para;
