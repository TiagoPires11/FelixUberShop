# FelixUberShop - Mercearia Online
## Trabalho de Avaliação - LPI 2025/2026
### Grupo: TiagoPires

---

## Descrição
Aplicação web JSP + MySQL para gestão de encomendas de uma mercearia online.
Implementa sistema de carteiras virtuais com auditoria, gestão de encomendas,
promoções dinâmicas e 4 perfis de utilizador.

## Estrutura do Projeto
```
TiagoPires/
├── basedados/
│   ├── basedados.h          # Módulo de ligação ao MySQL (ÚNICO)
│   ├── criar_bd.sql         # Script de criação da base de dados
│   └── apagar_bd.sql        # Script de eliminação da base de dados
├── paginas/
│   ├── WEB-INF/web.xml      # Configuração Tomcat
│   ├── estilos.css           # Folha de estilos
│   ├── scripts.js            # JavaScript (validações)
│   ├── header.jsp            # Cabeçalho dinâmico
│   ├── footer.jsp            # Rodapé
│   ├── auth_check.jsp        # Controlo de acesso
│   ├── erro.jsp              # Página de erro
│   ├── index.jsp             # Página inicial
│   ├── produtos.jsp          # Catálogo de produtos
│   ├── promocoes.jsp         # Promoções
│   ├── login.jsp             # Login
│   ├── registo.jsp           # Registo
│   ├── logout.jsp            # Logout
│   ├── cliente_*.jsp         # Área do cliente (8 páginas)
│   ├── func_*.jsp            # Área do funcionário (5 páginas)
│   └── admin_*.jsp           # Área do administrador (9 páginas)
├── relatorio/                # Relatório PDF
├── deploy.sh                 # Script de deploy
└── README.md                 # Este ficheiro
```

## Requisitos
- **Apache Tomcat** 9+ (para JSP)
- **MySQL** 5.7+ (via XAMPP ou standalone)
- **MySQL Connector/J** 8.x (driver JDBC)

## Instalação

### 1. Instalar Tomcat (macOS)
```bash
brew install tomcat
```

### 2. Descarregar MySQL Connector/J
Descarregar de: https://dev.mysql.com/downloads/connector/j/
Colocar o ficheiro `mysql-connector-j-8.x.x.jar` na pasta `lib/` ou diretamente
em `TOMCAT/webapps/FelixUberShop/WEB-INF/lib/`

### 3. Criar a Base de Dados
```bash
# Iniciar MySQL via XAMPP
sudo /Applications/XAMPP/xamppfiles/xampp startmysql

# Criar base de dados
mysql -u root < basedados/criar_bd.sql
```

### 4. Deploy no Tomcat
```bash
# Opção A: Script automático
./deploy.sh

# Opção B: Manual
# Copiar paginas/* para TOMCAT/webapps/FelixUberShop/
# Copiar basedados/basedados.h para TOMCAT/webapps/FelixUberShop/
# Copiar mysql-connector-j-*.jar para TOMCAT/webapps/FelixUberShop/WEB-INF/lib/
```

### 5. Iniciar Tomcat
```bash
brew services start tomcat
# ou
catalina start
```

### 6. Aceder à Aplicação
Abrir no browser: **http://localhost:8080/FelixUberShop/**

## Utilizadores de Teste
| Username     | Password     | Perfil       |
|-------------|-------------|-------------|
| cliente     | cliente     | Cliente      |
| funcionario | funcionario | Funcionário  |
| admin       | admin       | Administrador|

## Funcionalidades

### Visitante (sem login)
- Ver página inicial com informações da mercearia
- Consultar catálogo de produtos
- Ver promoções ativas
- Registar-se como cliente

### Cliente
- Dashboard com resumo pessoal
- Gerir perfil e alterar password
- Carteira virtual (depósitos, levantamentos, auditoria)
- Criar encomendas (pagamento via carteira)
- Consultar, editar e cancelar encomendas pendentes

### Funcionário
- Dashboard com estatísticas de encomendas
- Gerir encomendas (alterar estados: pendente → confirmada → em preparação → pronta → entregue)
- Validar encomendas por código único
- Gerir carteiras dos clientes
- Editar perfil pessoal

### Administrador
- Dashboard com estatísticas globais
- CRUD completo de utilizadores
- CRUD completo de produtos
- CRUD completo de promoções
- Gestão de todas as carteiras (incluindo loja)
- Gestão de encomendas (herda funcionalidades do funcionário)
- Editar informações da mercearia
- Editar perfil pessoal

## Notas Técnicas
- Passwords armazenadas com hash **SHA-256**
- Todas as transações financeiras usam **transações SQL** (ACID)
- Sistema de **auditoria** completo na tabela `operacoes_carteira`
- Código único de encomenda gerado com **UUID**
- Sem frameworks CSS/JS externos (CSS e JavaScript próprio)
- Ficheiro `basedados.h` é o **ÚNICO** ponto de acesso à base de dados

## Para Apagar a Base de Dados
```bash
mysql -u root < basedados/apagar_bd.sql
```
