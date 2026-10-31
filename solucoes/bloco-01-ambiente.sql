-- Soluções do bloco 01 - Ambiente
-- Pré-requisito: ambiente/01-criar-tabelas.sql já executado.
-- No Query editor do portal, rode UM exercício por vez (o painel de resultados
-- mostra só o resultado do último comando).

-- Exercício 1
-- Lista as tabelas criadas no banco.
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Exercício 2
-- Quantidade de colunas por tabela.
SELECT TABLE_NAME, COUNT(*) AS qtd_colunas
FROM INFORMATION_SCHEMA.COLUMNS
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- Exercício 3
-- Tipos de dados da tabela recargas, na ordem das colunas.
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'recargas'
ORDER BY ORDINAL_POSITION;

-- Exercício 4
-- Quais colunas aceitam NULL? Só as chaves primárias não aceitam.
SELECT IS_NULLABLE, COUNT(*) AS qtd_colunas
FROM INFORMATION_SCHEMA.COLUMNS
GROUP BY IS_NULLABLE;

-- Exercício 5
-- Constraints existentes, por tipo: só PRIMARY KEY (nada de FOREIGN KEY, CHECK, UNIQUE).
SELECT CONSTRAINT_TYPE, COUNT(*) AS qtd
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
GROUP BY CONSTRAINT_TYPE;

-- Exercício 6
-- Teste da PK: o segundo INSERT repete o id e falha (erro 2627).
-- O TRY/CATCH mostra o erro como resultado, sem interromper o script.
BEGIN TRY
    INSERT INTO estacoes (id_estacao, nome) VALUES (999, N'Teste');
    INSERT INTO estacoes (id_estacao, nome) VALUES (999, N'Teste repetido');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS numero_erro, ERROR_MESSAGE() AS mensagem;
END CATCH;

-- Exercício 7
-- Sem FOREIGN KEY, o banco aceita uma recarga de veículo que não existe.
INSERT INTO recargas (id_recarga, id_veiculo) VALUES (999999, 123456);
SELECT COUNT(*) AS recargas_com_veiculo_inexistente
FROM recargas
WHERE id_veiculo = 123456;

-- Limpeza dos testes (o 02-carga-dados.sql também apaga tudo ao rodar).
DELETE FROM recargas WHERE id_recarga = 999999;
DELETE FROM estacoes WHERE id_estacao = 999;
