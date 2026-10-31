-- Soluções do bloco 07 - Análise (tudo sobre tabelao_recargas, sem JOIN)
-- Rode UM exercício por vez no Query editor.

-- Exercício 1
-- As 10 recargas mais caras.
SELECT TOP 10 id_recarga, motorista, estacao, valor_total
FROM tabelao_recargas
ORDER BY valor_total DESC, id_recarga;

-- Exercício 2
-- Resumo geral. COUNT(valor_total) ignora as recargas em andamento (NULL).
-- AVG também ignora NULL: o ticket médio é só das recargas concluídas.
SELECT COUNT(*)           AS recargas,
       COUNT(valor_total) AS concluidas,
       SUM(valor_total)   AS faturamento,
       AVG(valor_total)   AS ticket_medio,
       MIN(valor_total)   AS menor_valor,
       MAX(valor_total)   AS maior_valor,
       SUM(energia_kwh)   AS kwh_total
FROM tabelao_recargas;

-- Exercício 3
-- Por cidade: recargas, kWh, faturamento e ticket médio.
SELECT cidade,
       COUNT(*)         AS recargas,
       SUM(energia_kwh) AS kwh,
       SUM(valor_total) AS faturamento,
       AVG(valor_total) AS ticket_medio
FROM tabelao_recargas
GROUP BY cidade
ORDER BY faturamento DESC;

-- Exercício 4
-- Estações com faturamento acima de 6000 (HAVING filtra DEPOIS de agrupar; WHERE filtra antes).
SELECT estacao, cidade, SUM(valor_total) AS faturamento
FROM tabelao_recargas
GROUP BY estacao, cidade
HAVING SUM(valor_total) > 6000
ORDER BY faturamento DESC;

-- Exercício 5
-- Faturamento e kWh por mês.
SELECT DATEPART(MONTH, inicio) AS mes,
       COUNT(*)                AS recargas,
       SUM(energia_kwh)        AS kwh,
       SUM(valor_total)        AS faturamento
FROM tabelao_recargas
GROUP BY DATEPART(MONTH, inicio)
ORDER BY mes;

-- Exercício 6
-- Horário de pico: as 3 horas do dia com mais recargas iniciadas.
SELECT TOP 3 DATEPART(HOUR, inicio) AS hora, COUNT(*) AS recargas
FROM tabelao_recargas
GROUP BY DATEPART(HOUR, inicio)
ORDER BY recargas DESC, hora;

-- Exercício 7
-- Regra de negócio com CASE: faixa de potência do carregador.
-- Potência NULL (não informada) não cai em nenhuma faixa por engano: vira "Não informada".
SELECT faixa, COUNT(*) AS recargas, SUM(valor_total) AS faturamento
FROM (
    SELECT valor_total,
           CASE
               WHEN potencia_kw IS NULL THEN N'Não informada'
               WHEN potencia_kw <= 11   THEN N'Lenta (até 11 kW)'
               WHEN potencia_kw <= 22   THEN N'Intermediária (até 22 kW)'
               ELSE N'Rápida (acima de 22 kW)'
           END AS faixa
    FROM tabelao_recargas
) t
GROUP BY faixa
ORDER BY faturamento DESC;

-- Exercício 8
-- Os 5 motoristas que mais gastaram, com número de recargas e ticket médio.
SELECT TOP 5 motorista, COUNT(*) AS recargas, SUM(valor_total) AS gasto, AVG(valor_total) AS ticket_medio
FROM tabelao_recargas
GROUP BY email_motorista, motorista
ORDER BY gasto DESC, motorista;
