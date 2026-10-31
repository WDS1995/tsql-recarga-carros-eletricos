-- =====================================================================
-- Rede de recarga de carros elétricos - criação das tabelas (DDL)
-- Dados e estrutura FICTÍCIOS, feitos para prática de T-SQL.
--
-- ATENÇÃO: a base é CRUA DE PROPÓSITO. Cada tabela tem só a chave
-- primária. Não há FOREIGN KEY, NOT NULL, CHECK, UNIQUE nem DEFAULT.
-- Por isso a carga (02-carga-dados.sql) traz dados sujos, e você vai
-- encontrar e resolver esses problemas durante a prática.
--
-- Pode rodar de novo quando quiser: as tabelas são recriadas do zero.
-- =====================================================================

DROP TABLE IF EXISTS recargas;
DROP TABLE IF EXISTS veiculos;
DROP TABLE IF EXISTS motoristas;
DROP TABLE IF EXISTS carregadores;
DROP TABLE IF EXISTS estacoes;

CREATE TABLE estacoes (
    id_estacao   INT CONSTRAINT pk_estacoes PRIMARY KEY,
    nome         NVARCHAR(100),
    cidade       NVARCHAR(60),
    uf           NVARCHAR(5),
    inaugurada_em DATE
);

CREATE TABLE carregadores (
    id_carregador INT CONSTRAINT pk_carregadores PRIMARY KEY,
    id_estacao    INT,
    tipo_conector NVARCHAR(20),
    potencia_kw   DECIMAL(6,1),
    preco_kwh     DECIMAL(6,2),
    status        NVARCHAR(20)
);

CREATE TABLE motoristas (
    id_motorista  INT CONSTRAINT pk_motoristas PRIMARY KEY,
    nome          NVARCHAR(100),
    email         NVARCHAR(150),
    cidade        NVARCHAR(60),
    cadastrado_em DATE
);

CREATE TABLE veiculos (
    id_veiculo   INT CONSTRAINT pk_veiculos PRIMARY KEY,
    id_motorista INT,
    placa        NVARCHAR(10),
    modelo       NVARCHAR(60),
    bateria_kwh  DECIMAL(5,1)
);

CREATE TABLE recargas (
    id_recarga         INT CONSTRAINT pk_recargas PRIMARY KEY,
    id_veiculo         INT,
    id_carregador      INT,
    inicio             DATETIME2(0),
    fim                DATETIME2(0),
    energia_kwh        DECIMAL(7,2),
    preco_kwh_aplicado DECIMAL(6,2),
    valor_total        DECIMAL(9,2)
);
