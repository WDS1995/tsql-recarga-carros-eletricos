# Bloco 06 - Tabelão

Objetivo: sair do **normalizado** (5 tabelas ligadas por ids) para o **desnormalizado** (uma tabela larga, com tudo junto), do jeito que analistas e ferramentas de BI preferem.

| | Normalizado (base atual) | Desnormalizado (tabelão) |
|---|---|---|
| Estrutura | 5 tabelas, cada dado em um lugar só | 1 tabela larga, dados repetidos em cada linha |
| Para analisar | vários JOINs a cada consulta | `SELECT` direto, sem JOIN |
| Atualizar um dado | muda em um lugar | precisa recarregar o tabelão |
| Uso típico | sistema que grava (transacional) | análise e relatórios |

No tabelão **entram as regras** que a base crua não tinha: `NOT NULL` e `CHECK`. As recargas inválidas do bloco 05 ficam de fora.

Soluções: [`solucoes/bloco-06-tabelao.sql`](../solucoes/bloco-06-tabelao.sql).

Aviso: `CREATE VIEW` (exercício 8) precisa ser o **primeiro comando do lote**. No Query editor do portal, rode cada trecho entre os `GO` numa execução separada (o `GO` separa lotes). **A conferir no Azure:** se o editor aceita `GO`.

## Exercício 1 - Projetar e criar a tabela

**O que fazer:** crie `tabelao_recargas` (apague a anterior, se existir) com estas 18 colunas, escolhendo tipos iguais aos das tabelas de origem: `id_recarga` (chave primária), `motorista`, `email_motorista`, `placa`, `modelo`, `bateria_kwh`, `id_carregador`, `tipo_conector`, `potencia_kw`, `estacao`, `cidade`, `uf`, `inicio`, `fim`, `duracao_min`, `energia_kwh`, `preco_kwh_aplicado`, `valor_total`.

**Por quê:** cada coluna do tabelão vem de uma das 5 tabelas (o nome do motorista vem de `motoristas`, a cidade de `estacoes` etc.). Decidir `NULL`/`NOT NULL` é decidir o que o dado **precisa** ter. Dica de raciocínio: o que é obrigatório em toda recarga? E o que pode faltar legitimamente (recarga em andamento, potência não informada, bateria desconhecida)?

**Dica:** `DROP TABLE IF EXISTS tabelao_recargas;` e depois `CREATE TABLE`. `NOT NULL` na maioria das colunas; aceitam NULL: `bateria_kwh`, `potencia_kw`, `fim`, `duracao_min`, `energia_kwh`, `valor_total`. `uf` pode ser `CHAR(2)`.

**Confira:** `SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'tabelao_recargas'` devolve **18**.

## Exercício 2 - Constraints

**O que fazer:** adicione (no próprio `CREATE TABLE` ou com `ALTER TABLE`) `CHECK` constraints com nome, para garantir:

1. `fim` é NULL ou `fim >= inicio`;
2. `energia_kwh` é NULL ou `>= 0`;
3. `valor_total` é NULL ou `>= 0`;
4. `preco_kwh_aplicado > 0`;
5. `duracao_min` é NULL ou `>= 0`;
6. coerência de "em andamento": `fim`, `energia_kwh` e `valor_total` são **todos NULL ou todos preenchidos**.

**Por quê:** a constraint é o porteiro da tabela: dado ruim não entra, mesmo que alguém esqueça de filtrar.

**Dica:** um `CHECK` só barra quando a condição dá **falso**. Com NULL a condição dá "desconhecido" e a linha **passa**. Por isso a regra do fim é `fim IS NULL OR fim >= inicio`, e não apenas `fim >= inicio`. Nomeie assim: `CONSTRAINT ck_tabelao_fim CHECK (...)`.

**Confira:** `SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_NAME = 'tabelao_recargas' AND CONSTRAINT_TYPE = 'CHECK'` devolve **6**.

## Exercício 3 - Carregar o tabelão

**O que fazer:** com um único `INSERT ... SELECT`, junte as 5 tabelas e carregue o tabelão **só com recargas válidas**: `fim` NULL ou `>= inicio`; energia NULL ou `>= 0`; valor NULL ou igual a energia x preço aplicado (tolerância de 0,01). Calcule `duracao_min` com `DATEDIFF`.

**Por quê:** é a etapa de transformação de um ETL/ELT: juntar, calcular, filtrar. `INNER JOIN` com `veiculos` já elimina as órfãs. As recargas em andamento **entram**.

**Dica:** `DATEDIFF(MINUTE, r.inicio, r.fim)` (devolve NULL quando `fim` é NULL). Liste as colunas na ordem do `INSERT` e do `SELECT`.

**Confira:** **932** linhas inseridas (as mesmas 932 válidas do bloco 05).

## Exercício 4 - Conferir a carga

**O que fazer:** numa consulta, mostre: total de linhas, quantas em andamento, primeira e última data de início, soma de `valor_total` e soma de `energia_kwh`.

**Por quê:** reconciliar o destino com o que se esperava é parte da carga.

**Dica:** `COUNT(*)`, `SUM(CASE WHEN fim IS NULL THEN 1 ELSE 0 END)`, `MIN`, `MAX`, `SUM`.

**Confira:** **932** linhas; **12** em andamento; primeira `2026-07-01 06:21:41`; última `2026-09-30 21:10:46`; faturamento **66858.76**; energia **28523.95** kWh.

## Exercício 5 - A constraint barrando linhas ruins

**O que fazer:** tente inserir no tabelão (a) uma linha com `fim` **anterior** a `inicio` (e `duracao_min` NULL, para só essa regra falhar) e (b) uma linha com `motorista` NULL. Capture cada erro com `TRY/CATCH`. Depois confira se o total continua o mesmo.

**Por quê:** é a prova de que o tabelão se protege sozinho.

**Dica:** `INSERT ... VALUES` completo para (a) (inclua `energia_kwh` e `valor_total`, por causa da regra de coerência); para (b), só as colunas obrigatórias. `SELECT ERROR_NUMBER(), ERROR_MESSAGE()` no `CATCH`.

**Confira:** (a) erro **547**, citando `ck_tabelao_fim`; (b) erro **515** (não aceita NULL na coluna `motorista`); depois do teste o tabelão continua com **932** linhas.

## Exercício 6 - Duração das recargas

**O que fazer:** mostre a menor, a média e a maior `duracao_min` e quantas recargas têm duração NULL.

**Por quê:** `DATEDIFF(MINUTE, ...)` conta minutos entre os dois instantes. A duração fica NULL de propósito nas recargas em andamento.

**Dica:** `MIN`, `AVG`, `MAX` ignoram NULL.

**Confira:** menor **9**, média **127**, maior **812**, e **12** sem duração. (`AVG` de coluna inteira devolve inteiro.)

## Exercício 7 - A mesma pergunta nos dois modelos

**O que fazer:** calcule o faturamento e o número de recargas **por cidade** de duas formas: (a) no tabelão, sem JOIN; (b) na base normalizada, com os JOINs e **as mesmas regras de validade** do exercício 3.

**Por quê:** o resultado tem que ser igual. A diferença é o custo de escrever e de executar a consulta.

**Dica:** (a) `GROUP BY cidade`. (b) `recargas` + `veiculos` + `carregadores` + `estacoes`.

**Confira:** as duas consultas devolvem o mesmo resultado: Belo Horizonte 221 / 16663.07; Campinas 65 / 3718.58; Curitiba 215 / 14701.61; Rio de Janeiro 208 / 14692.22; São Paulo 223 / 17083.28.

## Exercício 8 - VIEW como contraste

**O que fazer:** crie a view `vw_recargas_detalhe` com a mesma junção e os mesmos filtros (colunas à sua escolha) e conte as linhas dela.

**Por quê:** a view **guarda só a consulta**, não os dados, e não tem constraints: cada `SELECT` refaz os JOINs. O tabelão guarda os dados prontos e as regras. Cada um tem seu uso.

**Dica:** `CREATE OR ALTER VIEW ... AS SELECT ...` sozinho em seu lote.

**Confira:** a view devolve **932** linhas (as mesmas do tabelão).
