# Bloco 08 - Fecho: automatizar e proteger

Objetivo: transformar o que você fez à mão em rotina repetível (procedure), registrar mudanças importantes sozinho (trigger) e controlar quem pode ler o quê (permissões).

Pré-requisito: blocos 05 e 06 concluídos (base limpa e `tabelao_recargas` com 932 linhas).

Soluções: [`solucoes/bloco-08-fecho.sql`](../solucoes/bloco-08-fecho.sql).

## Aviso sobre `CREATE PROCEDURE` e `CREATE TRIGGER`

Esses comandos precisam ser o **primeiro comando do lote**. No Query editor, no Query editor do portal, rode cada trecho entre os `GO` numa execução separada (o `GO` separa lotes; `CREATE PROCEDURE`/`TRIGGER` precisa ser o primeiro comando do lote). Nos scripts de solução os lotes são separados por `GO`. **A conferir no Azure:** se o Query editor aceita `GO`; se não aceitar, cole só o `CREATE ...` em cada execução.

Fontes (Microsoft Learn): `CREATE USER ... WITHOUT LOGIN` e usuário de banco contido com senha constam na sintaxe do Azure SQL Database (página "CREATE USER (Transact-SQL)"). O Query editor mostra só o último resultado de um script e tem limite de 5 minutos por execução (página "Azure Portal Query Editor").

## Exercício 1 - Procedure `atualizar_tabelao`

**O que fazer:** crie a procedure `atualizar_tabelao`, sem parâmetros, que **apaga e recarrega** o tabelão (mesmo `INSERT ... SELECT` do bloco 06) dentro de uma transação com `TRY/CATCH`. Se algo falhar, a transação deve ser desfeita e o erro repassado.

**Por quê:** na vida real o tabelão é recarregado todo dia. Se a recarga falhar no meio, ninguém pode ficar com um tabelão vazio ou pela metade: o `ROLLBACK` mantém o tabelão antigo.

**Dica:** `CREATE OR ALTER PROCEDURE`, `SET XACT_ABORT ON`, `BEGIN TRAN`/`COMMIT`, bloco `TRY/CATCH`, `@@TRANCOUNT`, `ROLLBACK` e `THROW` para repassar o erro. Pense em onde cada peça entra.

**Confira:** o comando termina sem erro. `SELECT name FROM sys.procedures` mostra `atualizar_tabelao`.

## Exercício 2 - Testar o caminho feliz

**O que fazer:** apague parte do tabelão (`DELETE ... WHERE id_recarga <= 300`), confira a contagem, rode `EXEC atualizar_tabelao;` e conte de novo.

**Por quê:** só se confia em uma rotina depois de vê-la funcionar.

**Dica:** um comando por vez.

**Confira:** depois do `DELETE` restam **653** linhas (279 foram apagadas); depois do `EXEC`, **932**.

## Exercício 3 - Testar o ROLLBACK

**O que fazer:** insira em `recargas` uma linha de teste que **passe pelo filtro**, mas **viole uma constraint do tabelão** (sugestão: `id_recarga = 2001`, veículo 1, carregador 1, `preco_kwh_aplicado = 0`, `valor_total = 0`, energia 10, datas de `2026-09-30 22:00:00` a `22:30:00`). Rode a procedure dentro de um `TRY/CATCH` que mostre o erro. Confira o tabelão. Depois apague a linha de teste e rode a procedure de novo.

**Por quê:** é a prova de que o `ROLLBACK` devolve o tabelão como estava, mesmo depois do `DELETE` já executado dentro da procedure.

**Dica:** `TRY/CATCH` em volta do `EXEC`; as funções `ERROR_NUMBER()` e `ERROR_MESSAGE()` mostram o que houve.

**Confira:** erro **547**, citando a constraint `ck_tabelao_preco`. Logo depois, o tabelão ainda tem **932** linhas e `@@TRANCOUNT` = **0**. Depois de apagar a linha de teste e rodar a procedure, o tabelão tem **932** linhas.

## Exercício 4 - Tabela `historico_status`

**O que fazer:** crie `historico_status` com: `id_historico` (inteiro com `IDENTITY`, chave primária), `id_carregador`, `status_anterior`, `status_novo` e `alterado_em` (data/hora, preenchida sozinha com a hora atual).

**Por quê:** é o log de auditoria que o trigger vai alimentar.

**Dica:** `INT IDENTITY(1,1) PRIMARY KEY`; `DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()`.

**Confira:** `SELECT COUNT(*) FROM historico_status` devolve **0**.

## Exercício 5 - Trigger de manutenção

**O que fazer:** crie um trigger `AFTER UPDATE` na tabela `carregadores` que, quando o `status` **passar a ser** `Manutencao`, grave uma linha em `historico_status` com o status anterior e o novo. Deve funcionar quando várias linhas são atualizadas de uma vez e **não** deve gravar se o status já era `Manutencao`.

**Por quê:** o banco registra o evento sozinho, sem depender de quem alterou lembrar de avisar.

**Dica:** o trigger enxerga as linhas como ficaram e como eram antes da alteração, nas tabelas especiais `inserted` e `deleted`. Compare as duas para descobrir a mudança. `UPDATE(coluna)` evita trabalho à toa. Pense em conjunto de linhas, não em uma linha.

**Confira:** o `CREATE TRIGGER` termina sem erro. `SELECT name FROM sys.triggers` mostra o trigger.

## Exercício 6 - Testar o trigger

**O que fazer:**

1. Coloque o carregador 1 em `Manutencao` e conte o histórico.
2. Coloque o carregador 2 em `Em uso` e conte o histórico.
3. Coloque os carregadores 3, 4 e 5 em `Manutencao` **num único `UPDATE`** e conte.
4. Atualize o carregador 7 (que já estava em manutenção) para `Manutencao` e conte.
5. Liste o histórico. Depois volte os carregadores 1 a 5 para `Disponivel`.

**Por quê:** testar o caso comum e os casos de borda (vários de uma vez, sem mudança real, mudança para outro status).

**Dica:** `UPDATE carregadores SET status = N'...' WHERE ...`; um comando por vez.

**Confira:** contagem do histórico após cada passo: **1**, **1**, **4**, **4**. A listagem tem **4 linhas** (carregadores 1, 3, 4 e 5), todas com `status_anterior = Disponivel` e `status_novo = Manutencao` (a ordem das linhas pode variar). Depois de voltar tudo: `Disponivel` 21, `Em uso` 6, `Manutencao` 3. Voltar para `Disponivel` não grava histórico.

## Exercício 7 - Papel, usuário e GRANT

**O que fazer:** crie o papel (role) `analista_leitura`, o usuário `analista_demo` **sem login** e coloque o usuário no papel. Dê ao papel permissão de **leitura somente** na tabela `tabelao_recargas`.

**Por quê:** princípio do menor privilégio: o analista precisa ler o tabelão, não alterar nem ver as tabelas cruas. Dar permissão ao **papel**, e não à pessoa, facilita a manutenção.

**Dica:** `CREATE ROLE`, `CREATE USER ... WITHOUT LOGIN`, `ALTER ROLE ... ADD MEMBER ...`, `GRANT SELECT ON ... TO ...`.

**Confira:** os quatro comandos terminam sem erro. (Usuário `WITHOUT LOGIN` existe para testes; não consegue conectar. Em produção você criaria o usuário a partir de uma identidade real: usuário de banco contido com senha ou usuário do Microsoft Entra ID, `CREATE USER [nome] FROM EXTERNAL PROVIDER`. **A conferir no Azure** o passo a passo exato na sua assinatura e o que seu usuário administrador tem permissão de criar.)

## Exercício 8 - Testar como o analista, e REVOKE

**O que fazer:** assuma a identidade do usuário de teste e verifique que ele: (a) consegue contar as linhas do tabelão; (b) **não** consegue ler `recargas`; (c) **não** consegue apagar linhas do tabelão. Volte à sua identidade em cada teste. Depois retire o `SELECT` do papel (`REVOKE`) e confirme que o analista perdeu o acesso.

**Por quê:** permissão só vale depois de testada. O `REVOKE` fecha o acesso sem apagar nada.

**Dica:** `EXECUTE AS USER = 'analista_demo'; ... REVERT;`. Para mostrar o erro em vez de interromper o script, coloque o comando proibido em `BEGIN TRY ... END TRY BEGIN CATCH ... END CATCH` e dê `REVERT` depois. `SELECT USER_NAME()` mostra quem você é naquele momento. **A conferir no Azure:** `EXECUTE AS USER` no Query editor (testado aqui em SQL Server 2022).

**Confira:** (a) `USER_NAME()` devolve `analista_demo` e a contagem é **932**; (b) erro **229**, "The SELECT permission was denied on the object 'recargas'"; (c) erro **229**, "The DELETE permission was denied on the object 'tabelao_recargas'"; depois do `REVOKE`, o `SELECT` do analista no tabelão também dá erro **229**; ao final `USER_NAME()` volta a ser `dbo` (ou o seu usuário, no Azure).
