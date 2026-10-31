# Bloco 05 - Limpeza

Objetivo: corrigir a sujeira que você achou nos blocos 03 e 04, **com segurança**.

> **Exceção à ementa:** a trilha só chega nas funções de texto na parte de Data Lake/Lakehouse. Aqui usamos um punhado delas (`TRIM`, `UPPER`, `LOWER`, `REPLACE`) porque limpar esta base só com `UPDATE` + `WHERE` seria artificial.

## Regras do bloco

1. **Cada correção vai dentro de uma transação:** `BEGIN TRAN` -> alteração -> **conferência** -> `COMMIT` (ou `ROLLBACK` se a conferência não bater). Assim, um erro seu não estraga a base.
2. **Rode a transação inteira em uma única execução** (do `BEGIN TRAN` até o `COMMIT`/`ROLLBACK`). **A conferir no Azure:** se o Query editor mantém a transação aberta entre execuções separadas; para não depender disso, não separe.
3. Treino seguro: na primeira vez, termine com `ROLLBACK` só para ver a conferência. Quando bater, troque por `COMMIT` e rode de novo.
4. **Atenção ao SQL Server:** `=` e `IN` **ignoram espaços no fim** e **maiúscula/minúscula** (bloco 03). Por isso não dá para "detectar" cada grafia errada: a regra é **padronizar todas as linhas** (o `UPDATE` reescreve cada valor para a forma correta, e rodar de novo não muda nada). Para espaço sobrando, use `LIKE` com um espaço no começo ou no fim do padrão.
5. Se algo der errado, `01` e `02` recriam a base do zero.

Soluções: [`solucoes/bloco-05-limpeza.sql`](../solucoes/bloco-05-limpeza.sql).

## Exercício 1 - Padronizar `cidade` e `uf` das estações

**O que fazer:** deixe as 5 cidades com a grafia correta (`São Paulo`, `Campinas`, `Rio de Janeiro`, `Belo Horizonte`, `Curitiba`) e as UFs em maiúsculas e sem espaço.

**Por quê:** `GROUP BY cidade` só soma certo se cada cidade tiver **uma** grafia.

**Dica:** `TRIM`, `UPPER`, `LOWER`; para `sao paulo` sem til, `REPLACE(texto, N'ã', N'a')` ajuda a comparar; `CASE` devolve a grafia correta.

**Confira:** `UPDATE` afeta **10** linhas (ele reescreve todas). Depois, a conferência (cidade fora das 5 cidades, ou com espaço sobrando, ou uf com espaço) devolve **0**. Agrupando por `cidade, uf` aparecem **5 linhas**, todas com a grafia correta: São Paulo/SP 3, Campinas/SP 1, Rio de Janeiro/RJ 2, Belo Horizonte/MG 2, Curitiba/PR 2.

## Exercício 2 - Padronizar o `status` dos carregadores

**O que fazer:** deixe só três valores: `Disponivel`, `Em uso`, `Manutencao`. **Não mexa** na `potencia_kw` NULL.

**Por quê:** a potência ausente é desconhecida; inventar um valor seria pior que NULL. Anote como decisão: no tabelão ela segue NULL e as análises tratam "não informada".

**Dica:** `CASE` com `LOWER(TRIM(status))` e `LIKE` com o começo da palavra (cuidado: `disponível` tem acento no `i`, então o começo comum é `dispon`).

**Confira:** a conferência devolve 0 problemas. Ao agrupar por status: `Disponivel` 21, `Em uso` 6, `Manutencao` 3 (total 30). As 4 potências NULL continuam NULL.

## Exercício 3 - Nome e e-mail dos motoristas

**O que fazer:** tire espaços sobrando do `nome` (inclusive dois espaços no meio) e deixe o `email` em minúsculas e sem espaços.

**Por quê:** nome e e-mail são chaves naturais de busca e de deduplicação.

**Dica:** `TRIM`, `LOWER`, `REPLACE(nome, N'  ', N' ')`. Padronize todas as linhas, sem tentar detectar quais estão erradas.

**Confira:** `UPDATE` afeta **80** linhas (o `UPDATE` toca todas; o que importa é o resultado). Conferência: 0 nomes com espaço sobrando (começo, fim ou duplo) e 0 e-mails com espaço sobrando.

## Exercício 4 - Placa e bateria dos veículos

**O que fazer:** deixe a placa em maiúsculas e **sem hífen**. Troque `bateria_kwh = 0` por NULL.

**Por quê:** zero é um valor impossível para a capacidade da bateria; NULL diz "não sei" e não distorce médias.

**Dica:** `UPPER`, `REPLACE(placa, N'-', N'')`, `CASE`.

**Confira:** conferência: 0 placas com hífen, 0 placas com tamanho diferente de 7, 0 baterias iguais a zero. **5** veículos ficam com `bateria_kwh` NULL.

## Exercício 5 - Deduplicar motoristas

**O que fazer:** para cada e-mail repetido, **mantenha o menor `id_motorista`**. Primeiro **reaponte** os veículos dos duplicados para o id mantido; **só depois** apague os motoristas duplicados.

**Por quê:** se apagar antes, os veículos ficam sem dono. A ordem importa. Isto é o que uma `FOREIGN KEY` obrigaria a fazer.

**Dica:** estratégia em passos: (1) para cada e-mail, escolher o id que fica (`MIN` com `GROUP BY`; `HAVING COUNT(*) > 1` separa os e-mails repetidos); (2) reapontar os veículos dos outros ids para ele (`UPDATE` com `JOIN`); (3) apagar o excedente. Faça o exercício 3 antes (e-mail já em minúsculas).

**Confira:** o reapontamento afeta **3** veículos e o `DELETE` afeta **3** motoristas. Resultado: `motoristas` = **77**, `veiculos` = **90** (nenhum apagado) e **0** veículos sem dono.

## Exercício 6 - Apagar recargas duplicadas

**O que fazer:** apague as cópias de recargas idênticas em todas as colunas (menos o id), mantendo a de menor id.

**Por quê:** recarga duplicada conta o faturamento em dobro.

**Dica:** agrupe por todas as colunas menos o id e pegue o `MIN(id_recarga)` de cada grupo (o `GROUP BY` trata NULL como igual a NULL); apague as linhas cujo id não está nessa lista.

**Confira:** o `DELETE` afeta **15** linhas. Depois `COUNT(*)` de `recargas` = **985**.

## Exercício 7 - Quantas recargas são inválidas? (não corrigir)

**O que fazer:** **não corrija nem apague** as recargas inválidas. Apenas meça, numa consulta: total, órfãs (veículo inexistente), `fim` antes de `inicio`, energia negativa, valor incoerente (diferente de energia x preço aplicado, com tolerância de 0,01), total de inválidas e total de válidas.

**Por quê (decisão didática):** não temos como saber o valor "certo" de uma energia negativa, e apagar destrói a evidência. O correto é registrar o problema, devolver à origem para correção e **deixar essas linhas fora do tabelão** (bloco 06). A base crua continua sendo o retrato fiel do que chegou.

**Dica:** `LEFT JOIN veiculos`; `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` para cada condição; `ABS(valor_total - ROUND(energia_kwh * preco_kwh_aplicado, 2)) > 0.01`.

**Confira:** total **985**; órfãs **10**; `fim` antes de `inicio` **20**; energia negativa **15**; valor incoerente **8**; inválidas **53**; válidas **932**.

## Exercício 8 - Nem todo NULL é erro

**O que fazer:** entre as recargas com `fim` NULL, confirme que são todas "em andamento": `energia_kwh` e `valor_total` também NULL. Mostre quantas são e em quantas os três campos estão NULL juntos.

**Por quê:** essas linhas **ficam** na base e no tabelão. Tratar todo NULL como erro apagaria dado legítimo.

**Dica:** `WHERE fim IS NULL` e `SUM(CASE WHEN energia_kwh IS NULL AND valor_total IS NULL THEN 1 ELSE 0 END)`.

**Confira:** **12** recargas em andamento, **12** com energia e valor também NULL.
