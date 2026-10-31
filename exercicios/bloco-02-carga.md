# Bloco 02 - Carga

Objetivo: carregar os dados e **conferir que chegou tudo**. Contar linhas depois de uma carga é a validação mais básica de um pipeline (reconciliação de volume).

Dica geral: rode **um comando por vez** no Query editor.

Soluções: [`solucoes/bloco-02-carga.sql`](../solucoes/bloco-02-carga.sql).

## Exercício 1 - Contar linhas por tabela

**O que fazer:** execute `ambiente/02-carga-dados.sql`. Depois escreva **uma única consulta** que devolva duas colunas, `tabela` e `linhas`, com uma linha por tabela.

**Por quê:** um relatório de volumes por tabela é o primeiro item de qualquer checklist de carga.

**Dica:** um `SELECT 'nome' AS tabela, COUNT(*) AS linhas FROM ...` por tabela, unidos com `UNION ALL`.

**Confira:** `estacoes` 10, `carregadores` 30, `motoristas` 80, `veiculos` 90, `recargas` 1000.

## Exercício 2 - Total do banco

**O que fazer:** some as linhas de todas as tabelas em um só número.

**Por quê:** praticar consulta sobre consulta (subconsulta no `FROM`).

**Dica:** use o `UNION ALL` do exercício 1 dentro de parênteses e aplique `SUM` por fora. A subconsulta precisa de um apelido.

**Confira:** **1210** linhas.

## Exercício 3 - Olhar os dados de cada tabela

**O que fazer:** para cada uma das 5 tabelas, mostre as 5 primeiras linhas, ordenadas pelo id.

**Por quê:** olhar uns poucos registros revela o formato real dos dados antes de qualquer análise.

**Dica:** `SELECT TOP 5 * FROM tabela ORDER BY ...`. Lembre: um comando por vez.

**Confira:** a primeira estação é a `Estacao Paulista` (São Paulo, SP); a segunda tem a cidade escrita `sao paulo` e uf `sp`. A primeira recarga é a de `id_recarga = 1`, início em `2026-07-01 06:21:41`, 32.92 kWh, valor 75.39. Repare nas diferenças de escrita: você vai voltar a elas.

## Exercício 4 - A carga é repetível?

**O que fazer:** execute o `02-carga-dados.sql` **uma segunda vez**. Depois conte as linhas de `recargas`.

**Por quê:** carga que dobra os dados quando roda de novo é um erro clássico. O script limpa cada tabela (`DELETE`) antes de inserir. Isso se chama carga **idempotente**.

**Dica:** `SELECT COUNT(*) FROM recargas`.

**Confira:** continua **1000**, e não 2000.

## Exercício 5 - Os ids têm buracos?

**O que fazer:** em `recargas`, mostre em uma linha: menor id, maior id, número de linhas e o número de linhas que deveria haver se os ids fossem seguidos (`maior - menor + 1`).

**Por quê:** buracos em ids sequenciais podem indicar linhas perdidas na carga.

**Dica:** `MIN`, `MAX` e `COUNT(*)` na mesma consulta.

**Confira:** menor 1, maior 1000, linhas 1000, esperado 1000: não há buracos.
