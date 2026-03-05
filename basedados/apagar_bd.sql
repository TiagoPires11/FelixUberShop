-- ============================================================================
-- FelixUberShop - Script de Eliminacao da Base de Dados
-- Autor: Tiago Pires
-- Data: 2025/2026
-- Descricao: Este script elimina todos os objetos (tabelas e base de dados)
--            relacionados com o projeto FelixUberShop. As tabelas sao
--            eliminadas pela ordem inversa da criacao para respeitar as
--            restricoes de chaves estrangeiras (foreign keys).
-- ============================================================================

USE felixubershop;

-- Eliminar tabelas pela ordem inversa (respeitar foreign keys)
DROP TABLE IF EXISTS itens_encomenda;
DROP TABLE IF EXISTS encomendas;
DROP TABLE IF EXISTS operacoes_carteira;
DROP TABLE IF EXISTS carteiras;
DROP TABLE IF EXISTS promocoes;
DROP TABLE IF EXISTS produtos;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS info_mercearia;
DROP TABLE IF EXISTS utilizadores;

-- Eliminar a base de dados
DROP DATABASE IF EXISTS felixubershop;

-- ============================================================================
-- FIM DO SCRIPT DE ELIMINACAO
-- ============================================================================
