-- ============================================================================
-- FelixUberShop - Script de Criacao da Base de Dados
-- Autor: Tiago Pires
-- Data: 2025/2026
-- Descricao: Este script cria a base de dados 'felixubershop', todas as
--            tabelas necessarias e insere os dados iniciais (utilizadores
--            por defeito, carteira da loja, produtos de exemplo, etc.)
-- ============================================================================

-- Criar a base de dados (se nao existir) com charset UTF-8
CREATE DATABASE IF NOT EXISTS felixubershop
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_general_ci;

USE felixubershop;

-- ============================================================================
-- TABELA: utilizadores
-- Descricao: Armazena todos os utilizadores do sistema (clientes, funcionarios
--            e administradores). O campo 'perfil' define o tipo de acesso.
--            O campo 'ativo' permite inativar utilizadores sem os apagar.
-- ============================================================================
CREATE TABLE IF NOT EXISTS utilizadores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(64) NOT NULL COMMENT 'SHA-256 hash da password',
    morada VARCHAR(255) DEFAULT NULL,
    telefone VARCHAR(20) DEFAULT NULL,
    perfil ENUM('cliente', 'funcionario', 'admin') NOT NULL DEFAULT 'cliente',
    ativo TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1=ativo, 0=inativo',
    data_registo DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================================
-- TABELA: carteiras
-- Descricao: Cada cliente tem uma carteira com saldo. Existe tambem uma
--            carteira especial da FelixUberShop (id_utilizador=NULL, tipo='loja').
--            Todas as transacoes de pagamento passam por este sistema.
-- ============================================================================
CREATE TABLE IF NOT EXISTS carteiras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_utilizador INT DEFAULT NULL COMMENT 'NULL para a carteira da loja',
    saldo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    tipo ENUM('cliente', 'loja') NOT NULL DEFAULT 'cliente',
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_utilizador) REFERENCES utilizadores(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================================
-- TABELA: operacoes_carteira
-- Descricao: Regista TODAS as operacoes realizadas sobre carteiras para
--            efeitos de auditoria. Inclui depositos, levantamentos e
--            pagamentos de encomendas. Guarda carteiras de origem/destino,
--            tipo de operacao, valor e data.
-- ============================================================================
CREATE TABLE IF NOT EXISTS operacoes_carteira (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_carteira_origem INT DEFAULT NULL COMMENT 'NULL em depositos',
    id_carteira_destino INT DEFAULT NULL COMMENT 'NULL em levantamentos',
    tipo_operacao ENUM('deposito', 'levantamento', 'pagamento', 'reembolso') NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    descricao VARCHAR(255) DEFAULT NULL,
    data_operacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_carteira_origem) REFERENCES carteiras(id) ON DELETE SET NULL,
    FOREIGN KEY (id_carteira_destino) REFERENCES carteiras(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================================
-- TABELA: categorias
-- Descricao: Categorias de produtos da mercearia (ex: Frutas, Laticinios,
--            Bebidas, etc.). Permite organizar os produtos por tipo.
-- ============================================================================
CREATE TABLE IF NOT EXISTS categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao VARCHAR(255) DEFAULT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- ============================================================================
-- TABELA: produtos
-- Descricao: Catalogo de produtos da mercearia. Cada produto tem nome, preco,
--            categoria, stock e estado ativo/inativo. O campo 'imagem' guarda
--            o nome do ficheiro de imagem do produto.
-- ============================================================================
CREATE TABLE IF NOT EXISTS produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT DEFAULT NULL,
    preco DECIMAL(10,2) NOT NULL,
    id_categoria INT DEFAULT NULL,
    imagem VARCHAR(255) DEFAULT NULL COMMENT 'Nome do ficheiro de imagem',
    stock INT NOT NULL DEFAULT 0,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================================
-- TABELA: encomendas
-- Descricao: Regista as encomendas dos clientes. Cada encomenda tem um codigo
--            unico (para validacao pelo funcionario), estado, valor total e
--            data. O estado acompanha o ciclo de vida da encomenda.
-- ============================================================================
CREATE TABLE IF NOT EXISTS encomendas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    codigo_unico VARCHAR(20) NOT NULL UNIQUE COMMENT 'Codigo para validacao pelo funcionario',
    estado ENUM('pendente', 'confirmada', 'em_preparacao', 'pronta', 'entregue', 'cancelada') NOT NULL DEFAULT 'pendente',
    valor_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    observacoes TEXT DEFAULT NULL,
    data_encomenda DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES utilizadores(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- TABELA: itens_encomenda
-- Descricao: Detalhe de cada encomenda - lista os produtos encomendados,
--            as quantidades e o preco unitario no momento da encomenda
--            (para manter historico mesmo que o preco mude).
-- ============================================================================
CREATE TABLE IF NOT EXISTS itens_encomenda (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_encomenda INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    preco_unitario DECIMAL(10,2) NOT NULL COMMENT 'Preco no momento da encomenda',
    FOREIGN KEY (id_encomenda) REFERENCES encomendas(id) ON DELETE CASCADE,
    FOREIGN KEY (id_produto) REFERENCES produtos(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- TABELA: promocoes
-- Descricao: Informacoes e promocoes dinamicas definidas pelos administradores.
--            Apresentadas na homepage e pagina de promocoes. Cada promocao
--            tem datas de inicio/fim para controlo de visibilidade.
-- ============================================================================
CREATE TABLE IF NOT EXISTS promocoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT DEFAULT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    id_admin_criador INT DEFAULT NULL,
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_admin_criador) REFERENCES utilizadores(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================================
-- TABELA: info_mercearia
-- Descricao: Tabela chave-valor para guardar informacoes gerais da mercearia
--            (localizacao, contactos, horarios, etc.). Permite ao admin
--            alterar estas informacoes sem modificar o codigo.
-- ============================================================================
CREATE TABLE IF NOT EXISTS info_mercearia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    chave VARCHAR(100) NOT NULL UNIQUE,
    valor TEXT NOT NULL,
    descricao VARCHAR(255) DEFAULT NULL COMMENT 'Descricao da informacao'
) ENGINE=InnoDB;

-- ============================================================================
-- DADOS INICIAIS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Utilizadores por defeito (passwords em SHA-256)
-- cliente/cliente | funcionario/funcionario | admin/admin
-- ----------------------------------------------------------------------------
INSERT INTO utilizadores (nome, email, username, password, morada, telefone, perfil, ativo) VALUES
('Cliente Teste', 'cliente@felixubershop.pt', 'cliente', 'a60b85d409a01d46023f90741e01b79543a3cb1ba048eaefbe5d7a63638043bf', 'Rua do Cliente 1, Castelo Branco', '912345678', 'cliente', 1),
('Funcionario Teste', 'funcionario@felixubershop.pt', 'funcionario', '24d96a103e8552cb162117e5b94b1ead596b9c0a94f73bc47f7d244d279cacf2', 'Rua do Funcionario 2, Castelo Branco', '923456789', 'funcionario', 1),
('Administrador', 'admin@felixubershop.pt', 'admin', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 'Rua do Admin 3, Castelo Branco', '934567890', 'admin', 1);

-- ----------------------------------------------------------------------------
-- Carteiras: uma para cada utilizador + carteira especial da loja
-- ----------------------------------------------------------------------------
INSERT INTO carteiras (id_utilizador, saldo, tipo) VALUES
(1, 50.00, 'cliente'),   -- Carteira do cliente teste (com 50 euros iniciais)
(2, 0.00, 'cliente'),    -- Carteira do funcionario (todos os utilizadores tem carteira)
(3, 0.00, 'cliente'),    -- Carteira do admin
(NULL, 0.00, 'loja');    -- Carteira especial da FelixUberShop

-- ----------------------------------------------------------------------------
-- Categorias de produtos
-- ----------------------------------------------------------------------------
INSERT INTO categorias (nome, descricao) VALUES
('Frutas e Legumes', 'Frutas frescas e legumes da epoca'),
('Laticinios', 'Leite, queijo, iogurtes e derivados'),
('Padaria', 'Pao, bolos e produtos de padaria'),
('Bebidas', 'Agua, sumos, refrigerantes e bebidas alcoolicas'),
('Mercearia', 'Produtos de mercearia geral'),
('Congelados', 'Produtos congelados'),
('Higiene', 'Produtos de higiene pessoal e do lar'),
('Snacks', 'Snacks, bolachas e aperitivos');

-- ----------------------------------------------------------------------------
-- Produtos de exemplo
-- ----------------------------------------------------------------------------
INSERT INTO produtos (nome, descricao, preco, id_categoria, stock, ativo) VALUES
('Maca Royal Gala (kg)', 'Macas Royal Gala frescas, preco por quilograma', 1.99, 1, 100, 1),
('Banana (kg)', 'Bananas da Madeira, preco por quilograma', 1.49, 1, 80, 1),
('Laranja (kg)', 'Laranjas do Algarve, preco por quilograma', 1.29, 1, 120, 1),
('Tomate (kg)', 'Tomate maduro, preco por quilograma', 2.19, 1, 60, 1),
('Alface Unidade', 'Alface fresca', 0.89, 1, 40, 1),
('Leite Meio Gordo 1L', 'Leite UHT meio gordo, 1 litro', 0.79, 2, 200, 1),
('Queijo Flamengo (kg)', 'Queijo flamengo fatiado, preco por quilograma', 7.99, 2, 30, 1),
('Iogurte Natural Pack 4', 'Pack de 4 iogurtes naturais', 1.59, 2, 50, 1),
('Manteiga 250g', 'Manteiga com sal, 250 gramas', 2.49, 2, 40, 1),
('Pao de Forma', 'Pao de forma integral, 500g', 1.39, 3, 60, 1),
('Croissant Unidade', 'Croissant simples', 0.59, 3, 80, 1),
('Bolo de Arroz', 'Bolo de arroz tradicional', 0.45, 3, 100, 1),
('Agua 1.5L', 'Garrafa de agua mineral, 1.5 litros', 0.39, 4, 300, 1),
('Sumo de Laranja 1L', 'Sumo de laranja natural, 1 litro', 2.29, 4, 50, 1),
('Coca-Cola 1.5L', 'Refrigerante Coca-Cola, 1.5 litros', 1.89, 4, 80, 1),
('Arroz Agulha 1kg', 'Arroz agulha, pacote de 1 quilograma', 1.19, 5, 150, 1),
('Massa Esparguete 500g', 'Massa esparguete, 500 gramas', 0.89, 5, 120, 1),
('Azeite Extra Virgem 750ml', 'Azeite extra virgem portugues, 750ml', 4.99, 5, 40, 1),
('Atum em Lata', 'Atum em conserva, lata de 120g', 1.29, 5, 100, 1),
('Pizza Margherita Congelada', 'Pizza margherita congelada, 350g', 2.99, 6, 30, 1),
('Gelado Baunilha 1L', 'Gelado de baunilha, 1 litro', 3.49, 6, 25, 1),
('Sabonete Pack 3', 'Pack de 3 sabonetes', 1.99, 7, 60, 1),
('Detergente Roupa 1.5L', 'Detergente para maquina de roupa, 1.5 litros', 4.49, 7, 35, 1),
('Batatas Fritas 150g', 'Batatas fritas classicas, 150g', 1.69, 8, 70, 1),
('Bolachas Maria 200g', 'Bolachas Maria tradicionais, 200g', 0.99, 8, 90, 1);

-- ----------------------------------------------------------------------------
-- Informacoes da mercearia (chave-valor)
-- ----------------------------------------------------------------------------
INSERT INTO info_mercearia (chave, valor, descricao) VALUES
('nome', 'FelixUberShop', 'Nome da mercearia'),
('morada', 'Rua da Mercearia 42, 6000-001 Castelo Branco', 'Morada completa'),
('telefone', '+351 272 123 456', 'Telefone de contacto'),
('email', 'geral@felixubershop.pt', 'Email de contacto'),
('horario_semana', 'Segunda a Sexta: 08:00 - 20:00', 'Horario dias uteis'),
('horario_sabado', 'Sabado: 09:00 - 18:00', 'Horario ao sabado'),
('horario_domingo', 'Domingo: 10:00 - 13:00', 'Horario ao domingo'),
('descricao', 'A FelixUberShop e a sua mercearia de confianca em Castelo Branco. Oferecemos produtos frescos e de qualidade, com servico de encomendas online para a sua comodidade.', 'Descricao da mercearia'),
('sobre', 'Fundada em 2025, a FelixUberShop nasceu com o objetivo de trazer a tradicao da mercearia de bairro para o mundo digital. Mantemos o atendimento personalizado com a conveniencia das encomendas online.', 'Sobre nos');

-- ----------------------------------------------------------------------------
-- Promocoes de exemplo
-- ----------------------------------------------------------------------------
INSERT INTO promocoes (titulo, descricao, data_inicio, data_fim, ativo, id_admin_criador) VALUES
('Desconto em Frutas!', 'Esta semana todas as frutas com 10% de desconto. Aproveite os produtos frescos da epoca!', '2026-03-01', '2026-03-31', 1, 3),
('Pack Pequeno-Almoco', 'Compre pao de forma + manteiga + leite e ganhe um desconto especial no seu pequeno-almoco!', '2026-03-01', '2026-04-15', 1, 3),
('Novos Produtos Congelados', 'Conheca a nossa nova gama de produtos congelados. Praticos e deliciosos para o seu dia-a-dia.', '2026-03-01', '2026-03-15', 1, 3);

-- ============================================================================
-- FIM DO SCRIPT DE CRIACAO
-- ============================================================================
