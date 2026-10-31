# Bloco 01 - Ambiente

Objetivo: criar as 5 tabelas e **ler a estrutura** do banco antes de mexer nos dados. Em Engenharia de Dados, a primeira pergunta diante de uma base nova é: "o que existe aqui e que garantias ela me dá?"

Dica geral: o Query editor mostra só o resultado do último comando. Rode **um comando por vez**.

Soluções: [`solucoes/bloco-01-ambiente.sql`](../solucoes/bloco-01-ambiente.sql) (abra depois de tentar).

## Exercício 1 - Criar as tabelas e listá-las

**O que fazer:** execute `ambiente/01-criar-tabelas.sql`. Depois escreva uma consulta que liste os nomes das tabelas do banco.

**Por quê:** conferir que o ambiente subiu é o primeiro passo de qualquer pipeline.

**Dica:** a view `INFORMATION_SCHEMA.TABLES` tem a coluna `TABLE_TYPE`; as tabelas comuns são `'BASE TABLE'`.

**Confira:** 5 linhas: `carregadores`, `estacoes`, `motoristas`, `recargas`, `veiculos`.

## Exercício 2 - Colunas por tabela

**O que fazer:** mostre quantas colunas cada tabela tem.

**Por quê:** o número de colunas é o primeiro retrato do "tamanho" de cada tabela e vai servir de comparação com o tabelão, mais adiante.

**Dica:** `INFORMATION_SCHEMA.COLUMNS` + `COUNT(*)` + `GROUP BY TABLE_NAME`.

**Confira:** `carregadores` 6, `estacoes` 5, `motoristas` 5, `recargas` 8, `veiculos` 5.

## Exercício 3 - Tipos de dados da tabela `recargas`

**O que fazer:** liste nome da coluna, tipo de dado e se aceita NULL, na ordem em que as colunas foram criadas.

**Por quê:** tipo errado é fonte clássica de bug (data guardada como texto, dinheiro em `float`...). Aqui conferimos o que foi escolhido.

**Dica:** colunas `COLUMN_NAME`, `DATA_TYPE`, `IS_NULLABLE`; ordene por `ORDINAL_POSITION`.

**Confira:** 8 linhas. `id_recarga` é `int` e `NO` (não aceita NULL); `inicio` e `fim` são `datetime2`; `energia_kwh`, `preco_kwh_aplicado` e `valor_total` são `decimal`; todas as outras colunas aceitam NULL (`YES`).

## Exercício 4 - Quem aceita NULL?

**O que fazer:** no banco todo, conte quantas colunas aceitam NULL e quantas não.

**Por quê:** coluna que aceita NULL sem necessidade é porta aberta para dado incompleto.

**Dica:** `GROUP BY IS_NULLABLE` sobre `INFORMATION_SCHEMA.COLUMNS`.

**Confira:** `NO` = 5 e `YES` = 24 (as 5 que não aceitam NULL são as chaves primárias).

## Exercício 5 - Que garantias o banco dá?

**O que fazer:** conte as constraints existentes, por tipo.

**Por quê:** constraints são as regras que o próprio banco impõe. Aqui vamos descobrir que **só existe PRIMARY KEY**: não há `FOREIGN KEY`, `CHECK` nem `UNIQUE`. Por isso a sujeira vai entrar.

**Dica:** `INFORMATION_SCHEMA.TABLE_CONSTRAINTS`, coluna `CONSTRAINT_TYPE`.

**Confira:** uma única linha: `PRIMARY KEY` = 5.

## Exercício 6 - Testar a chave primária

**O que fazer:** tente inserir **duas** estações com o mesmo `id_estacao` (por exemplo 999). Capture o erro para exibi-lo como resultado.

**Por quê:** a PK é a única proteção que existe. Veja como ela reage.

**Dica:** `INSERT INTO estacoes (id_estacao, nome) VALUES (...)` duas vezes dentro de `BEGIN TRY ... END TRY BEGIN CATCH ... END CATCH`; no `CATCH` use `SELECT ERROR_NUMBER(), ERROR_MESSAGE()`.

**Confira:** o número do erro é **2627** (violação de PRIMARY KEY) e a mensagem cita a constraint `pk_estacoes`. A primeira linha (id 999) entra; a segunda não.

## Exercício 7 - O que o banco aceita sem reclamar

**O que fazer:** insira em `recargas` uma linha com `id_recarga = 999999` e `id_veiculo = 123456` (um veículo que não existe). Depois conte as recargas com esse `id_veiculo`.

**Por quê:** sem `FOREIGN KEY`, o banco aceita referência a algo que não existe. É assim que nascem as "órfãs" que vamos caçar no bloco 04.

**Dica:** `INSERT` com só duas colunas; as demais ficam NULL. Depois apague seus testes (`DELETE`) das duas tabelas, ou rode o `02` mais tarde, que esvazia tudo.

**Confira:** a contagem é **1**: o banco aceitou. Apague os testes (`id_recarga = 999999` e `id_estacao = 999`) antes de seguir.
