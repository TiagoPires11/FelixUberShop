#!/bin/bash
# =========================================================================
#  deploy.sh - Script de Deploy para Apache Tomcat
#  Autor: Tiago Pires
#  Data: 2025/2026
#  Descricao: Prepara e faz deploy da aplicacao FelixUberShop no Tomcat.
#             Copia ficheiros JSP, CSS, JS para a estrutura do webapp,
#             coloca o basedados.h junto dos JSPs, e configura o
#             MySQL Connector/J.
#
#  Utilizacao: ./deploy.sh [TOMCAT_WEBAPPS_DIR]
#  Exemplo:    ./deploy.sh /usr/local/opt/tomcat/libexec/webapps
#              ./deploy.sh (usa diretorio por defeito do Homebrew)
# =========================================================================

set -e

# Diretorio base do projeto
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Diretorio Tomcat webapps
if [ -n "$1" ]; then
    TOMCAT_WEBAPPS="$1"
else
    # Tentar encontrar Tomcat instalado via Homebrew
    if [ -d "/usr/local/opt/tomcat/libexec/webapps" ]; then
        TOMCAT_WEBAPPS="/usr/local/opt/tomcat/libexec/webapps"
    elif [ -d "/opt/homebrew/opt/tomcat/libexec/webapps" ]; then
        TOMCAT_WEBAPPS="/opt/homebrew/opt/tomcat/libexec/webapps"
    elif [ -d "$CATALINA_HOME/webapps" ]; then
        TOMCAT_WEBAPPS="$CATALINA_HOME/webapps"
    else
        echo "ERRO: Diretorio do Tomcat nao encontrado!"
        echo "Uso: $0 /caminho/para/tomcat/webapps"
        echo ""
        echo "Instalar Tomcat: brew install tomcat"
        exit 1
    fi
fi

WEBAPP_DIR="$TOMCAT_WEBAPPS/FelixUberShop"

echo "============================================="
echo "  FelixUberShop - Deploy para Tomcat"
echo "============================================="
echo ""
echo "Projeto:  $PROJECT_DIR"
echo "Tomcat:   $TOMCAT_WEBAPPS"
echo "Webapp:   $WEBAPP_DIR"
echo ""

# 1. Criar estrutura do webapp
echo "[1/5] Criar estrutura do webapp..."
rm -rf "$WEBAPP_DIR"
mkdir -p "$WEBAPP_DIR/WEB-INF/lib"

# 2. Copiar ficheiros JSP, CSS, JS
echo "[2/5] Copiar paginas (JSP, CSS, JS)..."
cp "$PROJECT_DIR/paginas/"*.jsp "$WEBAPP_DIR/" 2>/dev/null || true
cp "$PROJECT_DIR/paginas/"*.css "$WEBAPP_DIR/" 2>/dev/null || true
cp "$PROJECT_DIR/paginas/"*.js "$WEBAPP_DIR/" 2>/dev/null || true

# 3. Copiar basedados.h para junto dos JSPs
echo "[3/5] Copiar basedados.h..."
cp "$PROJECT_DIR/basedados/basedados.h" "$WEBAPP_DIR/"

# 4. Copiar web.xml
echo "[4/5] Copiar web.xml..."
if [ -f "$PROJECT_DIR/paginas/WEB-INF/web.xml" ]; then
    cp "$PROJECT_DIR/paginas/WEB-INF/web.xml" "$WEBAPP_DIR/WEB-INF/"
fi

# 5. MySQL Connector/J
echo "[5/5] Verificar MySQL Connector/J..."
CONNECTOR_FOUND=false

# Procurar em locais comuns
for jar in \
    "$PROJECT_DIR/lib/mysql-connector"*.jar \
    "$HOME/.m2/repository/com/mysql/mysql-connector-j/"*"/mysql-connector-j-"*.jar \
    "/usr/local/opt/mysql-connector-java/"*.jar \
    "/opt/homebrew/opt/mysql-connector-java/"*.jar; do
    if [ -f "$jar" ]; then
        cp "$jar" "$WEBAPP_DIR/WEB-INF/lib/"
        echo "  -> Copiado: $(basename "$jar")"
        CONNECTOR_FOUND=true
        break
    fi
done

if [ "$CONNECTOR_FOUND" = false ]; then
    echo ""
    echo "  AVISO: MySQL Connector/J nao encontrado!"
    echo "  Descarregue de: https://dev.mysql.com/downloads/connector/j/"
    echo "  Coloque o ficheiro .jar em: $WEBAPP_DIR/WEB-INF/lib/"
    echo "  Ou em: $PROJECT_DIR/lib/"
    echo ""
fi

echo ""
echo "============================================="
echo "  Deploy concluido!"
echo "============================================="
echo ""
echo "Proximos passos:"
echo "  1. Iniciar MySQL (XAMPP): sudo /Applications/XAMPP/xamppfiles/xampp startmysql"
echo "  2. Criar base de dados:"
echo "     mysql -u root < $PROJECT_DIR/basedados/criar_bd.sql"
echo "  3. Iniciar Tomcat: brew services start tomcat"
echo "     ou: catalina start"
echo "  4. Abrir: http://localhost:8080/FelixUberShop/"
echo ""
echo "Utilizadores de teste:"
echo "  cliente/cliente | funcionario/funcionario | admin/admin"
echo ""
