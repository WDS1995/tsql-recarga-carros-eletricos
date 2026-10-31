# Bloco 04 - JOINs

Objetivo: juntar as tabelas, de 2 até 5, e usar `LEFT JOIN` para achar o que **falta** (quem não casa). Sem `FOREIGN KEY`, o JOIN é o único jeito de descobrir se as relações estão íntegras.

Dica geral: rode **um comando por vez**. Dê apelidos às tabelas (`r`, `v`, `m`, `c`, `e`).

Soluções: [`solucoes/bloco-04-joins.sql`](../solucoes/bloco-04-joins.sql).

Mapa das ligações:

```
recargas.id_veiculo    -> veiculos.id_veiculo
veiculos.id_motorista  -> motoristas.id_motorista
recargas.id_carregador -> carregadores.id_carregador
carregadores.id_estacao -> estacoes.id_estacao
```

## Exercício 1 - Dois JOINs de 2 tabelas

**O que fazer:** junte `recargas` com `carregadores` e conte as linhas do resultado.

**Por quê:** o `INNER JOIN` só devolve linhas que casam dos dois lados. Comparar a contagem com a tabela original mostra se algo ficou de fora.

**Dica:** `FROM recargas r INNER JOIN carregadores c ON c.id_carregador = r.id_carregador`.

**Confira:** **1000** linhas: toda recarga aponta para um carregador que existe.

## Exercício 2 - Três tabelas

**O que fazer:** junte `recargas`, `veiculos` e `motoristas` e conte.

**Por quê:** é o caminho "quem fez a recarga".

**Dica:** dois `INNER JOIN` em sequência.

**Confira:** **990** linhas. Sumiram 10 recargas: elas não casaram com nenhum veículo (o exercício 4 mostra quais).

## Exercício 3 - Cinco tabelas

**O que fazer:** junte as 5 tabelas, do motorista até a estação, e conte as linhas.

**Por quê:** é a junção que vai alimentar o tabelão no bloco 06.

**Dica:** além das 3 anteriores, `carregadores` (por `id_carregador`) e `estacoes` (por `c.id_estacao`).

**Confira:** **990** linhas.

## Exercício 4 - Recargas órfãs

**O que fazer:** liste as recargas cujo `id_veiculo` não existe em `veiculos`: id da recarga, id do veículo e início, ordenado pelo id da recarga.

**Por quê:** "órfã" é registro filho sem pai, o que uma `FOREIGN KEY` teria impedido.

**Dica:** `LEFT JOIN` de `recargas` para `veiculos` e filtro `WHERE v.id_veiculo IS NULL` (a coluna do lado que **não casou**).

**Confira:** **10 recargas**: ids 151, 188, 202, 226, 228, 333, 349, 525, 604 e 996. Os veículos citados são números altos (903 a 991), que não existem.

## Exercício 5 - Motoristas que nunca recarregaram

**O que fazer:** liste os motoristas que não têm nenhuma recarga (via seus veículos).

**Por quê:** é um caso **legítimo** (cadastrou, mas não usou), não um erro. Mas é o tipo de pergunta de negócio que só o `LEFT JOIN` responde.

**Dica:** `motoristas LEFT JOIN veiculos LEFT JOIN recargas`, e filtre `recargas.id_recarga IS NULL`.

**Confira:** **6 motoristas**: ids 41, 48, 52, 59, 63 e 70.

## Exercício 6 - Carregador nunca usado

**O que fazer:** ache o carregador que nunca aparece em `recargas`.

**Por quê:** equipamento parado é informação valiosa para a operação.

**Dica:** mesma ideia do exercício anterior, agora a partir de `carregadores`.

**Confira:** **1 carregador**: `id_carregador = 30` (estação 10, conector `Type 2`).

## Exercício 7 - Self JOIN: o mesmo e-mail em dois ids

**O que fazer:** liste os pares de motoristas com o mesmo e-mail (ignorando maiúsculas e espaços), mostrando os dois ids, **sem repetir o par invertido**.

**Por quê:** juntar a tabela com ela mesma é a forma clássica de comparar linhas entre si.

**Dica:** self join: junte a tabela com ela mesma comparando os e-mails normalizados (caixa e espaços); uma condição de ordem entre os dois ids evita contar o par duas vezes e o par consigo mesmo.

**Confira:** **3 pares**: (5, 78), (12, 79), (33, 80).

## Exercício 8 - Motoristas com mais de um veículo

**O que fazer:** liste os motoristas que têm 2 ou mais veículos, com a quantidade.

**Por quê:** relação 1 para N (um motorista, vários carros). Combina JOIN com `GROUP BY` e `HAVING`.

**Dica:** `GROUP BY` o motorista e `HAVING COUNT(*) > 1`.

**Confira:** **10 motoristas**, todos com 2 veículos: ids 16, 27, 31, 36, 39, 45, 51, 56, 60 e 69.
