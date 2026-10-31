# Bloco 07 - Análise

Objetivo: usar o tabelão para responder perguntas de negócio. **Nenhum JOIN**: é o ganho da desnormalização. Use sempre `tabelao_recargas`.

Dica geral: rode **um comando por vez**.

Lembrete de ordem de execução de uma consulta: `FROM` -> `WHERE` -> `GROUP BY` -> `HAVING` -> `SELECT` -> `ORDER BY` -> `TOP`.

Soluções: [`solucoes/bloco-07-analise.sql`](../solucoes/bloco-07-analise.sql).

## Exercício 1 - As recargas mais caras

**O que fazer:** liste as 10 recargas de maior valor: id, motorista, estação e valor.

**Por quê:** olhar os extremos é a forma rápida de achar o que merece atenção.

**Dica:** `TOP 10` + `ORDER BY valor_total DESC`. Acrescente `id_recarga` ao `ORDER BY` para desempates.

**Confira:** a maior é a recarga **167**, de Renata Cardoso na Estacao Batel, **222.42**. A 10ª é a recarga 475, **174.42**.

## Exercício 2 - Resumo geral

**O que fazer:** numa linha, mostre: número de recargas, número de recargas concluídas (com valor), faturamento total, ticket médio, menor valor, maior valor e energia total.

**Por quê:** `COUNT(*)` conta todas as linhas; `COUNT(valor_total)` e `AVG(valor_total)` ignoram NULL, ou seja, só enxergam as concluídas. **Ticket médio** é o valor médio por recarga.

**Dica:** `COUNT(*)`, `COUNT(valor_total)`, `SUM`, `AVG`, `MIN`, `MAX`.

**Confira:** 932 recargas; 920 concluídas; faturamento **66858.76**; ticket médio **72.67** (a coluna mostra mais casas decimais); menor **9.47**; maior **222.42**; energia **28523.95** kWh.

## Exercício 3 - Por cidade

**O que fazer:** por cidade, mostre recargas, kWh, faturamento e ticket médio, da cidade que mais fatura para a que menos fatura.

**Por quê:** `GROUP BY` transforma muitas linhas em uma por grupo.

**Dica:** `GROUP BY cidade` e `ORDER BY` pelo apelido da soma.

**Confira:** São Paulo 223 recargas / 17083.28; Belo Horizonte 221 / 16663.07; Curitiba 215 / 14701.61; Rio de Janeiro 208 / 14692.22; Campinas 65 / 3718.58 (Campinas tem só 1 estação). Ticket médio de São Paulo: ~77.65.

## Exercício 4 - Estações com faturamento alto (HAVING)

**O que fazer:** liste as estações (com a cidade) cujo faturamento passa de **6000**, da maior para a menor.

**Por quê:** `WHERE` filtra linhas **antes** de agrupar; `HAVING` filtra grupos **depois** de calcular o `SUM`.

**Dica:** `GROUP BY estacao, cidade HAVING SUM(valor_total) > 6000`.

**Confira:** **6 estações**, na ordem: Pampulha (11025.62), Paulista (10043.30), Barra (8058.22), Portao (7495.96), Batel (7205.65) e Copacabana (6634.00).

## Exercício 5 - Por mês

**O que fazer:** mostre, por mês de início, o número de recargas, os kWh e o faturamento.

**Por quê:** análise temporal é a mais comum em dados de operação.

**Dica:** `DATEPART(MONTH, inicio)` no `SELECT`, no `GROUP BY` e no `ORDER BY`.

**Confira:** mês 7: 297 recargas / 8899.87 kWh / 20886.12; mês 8: 332 / 10290.51 / 24235.22; mês 9: 303 / 9333.57 / 21737.42.

## Exercício 6 - Horário de pico

**O que fazer:** descubra as 3 horas do dia (0 a 23) em que mais recargas começam.

**Por quê:** o pico define a capacidade que a rede precisa ter.

**Dica:** `DATEPART(HOUR, inicio)`, `COUNT(*)`, `ORDER BY` a contagem decrescente e `TOP 3`.

**Confira:** 18h com **103** recargas; 19h com **84**; 17h com **77**.

## Exercício 7 - Regra de negócio com CASE: faixa de potência

**O que fazer:** classifique cada recarga pela potência do carregador em: `Lenta (até 11 kW)`, `Intermediária (até 22 kW)`, `Rápida (acima de 22 kW)` e `Não informada` (potência NULL). Mostre, por faixa, o número de recargas e o faturamento.

**Por quê:** `CASE` é como a regra de negócio vira dado. E o ramo `IS NULL` evita que potência desconhecida caia sem querer em outra faixa.

**Dica:** o `CASE` deve ficar numa subconsulta (ou CTE) para você agrupar pelo resultado dele; teste `IS NULL` **primeiro**.

**Confira:** Rápida 438 recargas / 36226.53; Intermediária 251 / 17102.75; Lenta 168 / 9319.22; Não informada 75 / 4210.26. Somam 932.

## Exercício 8 - Melhores motoristas

**O que fazer:** liste os 5 motoristas que mais gastaram: nome, número de recargas, gasto total e ticket médio.

**Por quê:** é a base de uma ação de fidelização.

**Dica:** agrupe por `email_motorista` e `motorista` (o e-mail é o que identifica a pessoa; dois motoristas diferentes podem ter o mesmo nome).

**Confira:** 1) Tatiana Zanetti, 29 recargas, **2602.55**; 2) Karina Cardoso, 31, **2549.76**; 3) Elisa Esteves, 25, **2489.36**; 4) Mariana Queiroz, 28, **2468.92**; 5) Paulo Dias, 23, **2354.05**.
