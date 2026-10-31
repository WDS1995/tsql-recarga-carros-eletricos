# Bloco 03 - Validação e exploração

Objetivo: **descobrir a sujeira** da base. Nenhum enunciado vai dizer onde está o problema: as perguntas ajudam a olhar, e os números do "Confira" mostram se você achou.

Dica geral: rode **um comando por vez**. Ainda não altere nada nas tabelas neste bloco.

Soluções: [`solucoes/bloco-03-exploracao.sql`](../solucoes/bloco-03-exploracao.sql).

## Exercício 1 - Olhar as primeiras recargas

**O que fazer:** mostre as 10 primeiras recargas, pelo `id_recarga`.

**Por quê:** `TOP` + `ORDER BY` é a forma barata de espiar uma tabela grande sem trazê-la inteira.

**Dica:** `SELECT TOP 10 * ... ORDER BY id_recarga`.

**Confira:** 10 linhas. Olhe a coluna `energia_kwh`: a recarga **9** tem energia **-53.04**. Energia negativa não existe; guarde essa informação.

## Exercício 2 - Contar de três jeitos

**O que fazer:** em `recargas`, devolva numa linha: total de linhas, quantas têm `fim` preenchido, quantos veículos diferentes e quantos carregadores diferentes aparecem.

**Por quê:** `COUNT(*)`, `COUNT(coluna)` e `COUNT(DISTINCT coluna)` respondem perguntas diferentes. `COUNT(coluna)` **ignora NULL**.

**Dica:** `COUNT(*)`, `COUNT(fim)`, `COUNT(DISTINCT id_veiculo)`, `COUNT(DISTINCT id_carregador)`.

**Confira:** 1000 linhas, 988 com `fim`, 92 veículos distintos, 29 carregadores distintos.

*Pergunta para pensar:* a base tem 90 veículos e 30 carregadores. Por que aparecem 92 veículos e 29 carregadores nas recargas?

## Exercício 3 - Período dos dados

**O que fazer:** descubra a data/hora da primeira e da última recarga.

**Por quê:** saber o período coberto evita análises sobre meses que nem existem na base.

**Dica:** `MIN(inicio)` e `MAX(inicio)`.

**Confira:** primeira `2026-07-01 06:21:41`; última `2026-09-30 21:10:46`.

## Exercício 4 - Cidades e UFs das estações

**O que fazer:** liste as combinações distintas de `cidade` e `uf` da tabela `estacoes`, ordenadas.

**Por quê:** `DISTINCT` em coluna de texto é o jeito mais rápido de achar variações de grafia.

**Dica:** `SELECT DISTINCT cidade, uf FROM estacoes ORDER BY ...`.

**Confira:** **6 linhas**. Há 5 cidades de verdade (São Paulo, Campinas, Rio de Janeiro, Belo Horizonte, Curitiba). Qual aparece duas vezes e por quê?

## Exercício 5 - O que o DISTINCT esconde

**O que fazer:** compare, numa linha, quantos valores distintos de `cidade` (e de `uf`) o `COUNT(DISTINCT ...)` normal enxerga com quantos existem de fato gravados.

**Por quê:** por padrão o SQL Server compara texto **sem diferenciar maiúscula de minúscula** e **ignora espaços no fim** (`'SP' = 'SP '` dá verdadeiro). Então `DISTINCT`, `=`, `IN` e `GROUP BY` "juntam" variações que estão gravadas de forma diferente. Para comparar byte a byte use a collation binária.

**Dica:** `COUNT(DISTINCT cidade COLLATE Latin1_General_BIN)`.

**Confira:** cidades: 6 pelo `DISTINCT` normal e **9** gravadas. UFs: 4 pelo `DISTINCT` normal e **6** gravadas.

## Exercício 6 - Status dos carregadores

**O que fazer:** mostre cada grafia de `status` realmente gravada em `carregadores`, com quantos carregadores usam cada uma e o tamanho em bytes (`DATALENGTH`).

**Por quê:** `DATALENGTH` conta os espaços no fim, que `LEN` ignora. É o jeito de enxergar espaço escondido.

**Dica:** `GROUP BY status COLLATE Latin1_General_BIN, DATALENGTH(status)`.

**Confira:** **11 grafias** para só 3 significados (disponível, em uso, manutenção). A grafia mais comum é `Disponivel`, com 17 carregadores (20 bytes). Existem variações com espaço no começo ou no fim (22 bytes) e com acento.

## Exercício 7 - NULLs e valores impossíveis

**O que fazer:** em **uma consulta** (ou duas), conte: carregadores sem `potencia_kw`; recargas sem `fim`, sem `energia_kwh` e sem `valor_total`. Depois conte os valores impossíveis: recargas com `fim` antes de `inicio`; com energia negativa; com `valor_total` acima de 300; veículos com `bateria_kwh = 0`; placas com hífen.

**Por quê:** separar **NULL esperado** de **valor errado** é a habilidade central de qualidade de dados.

**Dica:** subconsultas escalares, `(SELECT COUNT(*) FROM ... WHERE ...)`, lado a lado no `SELECT`; `IS NULL` para NULL e `LIKE N'%-%'` para o hífen.

**Confira:**

| Medida | Resultado |
|---|---|
| carregadores sem potência | 4 |
| recargas sem fim / sem energia / sem valor | 12 / 12 / 12 |
| `fim` antes de `inicio` | 20 |
| energia negativa | 15 |
| `valor_total` acima de 300 | 8 |
| bateria zero | 5 |
| placa com hífen | 9 |

*Pergunta para pensar:* os 12 NULLs de recarga são erro? (Dica: olhe a data delas.)

## Exercício 8 - Motoristas duplicados

**O que fazer:** ache e-mails que aparecem mais de uma vez em `motoristas`, ignorando maiúsculas e espaços. Mostre o e-mail, quantas vezes aparece e o menor e o maior `id_motorista`.

**Por quê:** cadastro duplicado distorce contagens ("quantos motoristas temos?") e divide o histórico de uma pessoa em dois ids.

**Dica:** `GROUP BY LOWER(TRIM(email))` + `HAVING COUNT(*) > 1`.

**Confira:** **3 e-mails** repetidos, cada um 2 vezes. Pares de ids: **5 e 78**, **12 e 79**, **33 e 80**.
