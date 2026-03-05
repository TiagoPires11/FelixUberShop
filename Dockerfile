# =========================================================================
#  Dockerfile - FelixUberShop (JSP + MySQL)
#  Autor: Tiago Pires
#  Data: 2025/2026
#  Descricao: Imagem Docker para deploy no Railway.
#             Usa Tomcat 9 (javax.servlet) com JDK 17.
#             Le variaveis de ambiente do Railway para ligacao MySQL.
# =========================================================================

FROM tomcat:9-jdk17

# Remover apps por defeito do Tomcat
RUN rm -rf /usr/local/tomcat/webapps/*

# Criar estrutura do webapp
RUN mkdir -p /usr/local/tomcat/webapps/ROOT/WEB-INF/lib

# Copiar MySQL Connector/J (descarregar no build)
ADD https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar \
    /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/

# Copiar web.xml
COPY paginas/WEB-INF/web.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/

# Copiar basedados.h
COPY basedados/basedados.h /usr/local/tomcat/webapps/ROOT/

# Copiar paginas JSP, CSS, JS
COPY paginas/*.jsp /usr/local/tomcat/webapps/ROOT/
COPY paginas/*.css /usr/local/tomcat/webapps/ROOT/
COPY paginas/*.js  /usr/local/tomcat/webapps/ROOT/

# Copiar script de inicializacao da BD
COPY basedados/criar_bd.sql /docker-entrypoint-initdb.d/

# Railway usa a variavel PORT
ENV PORT=8080

# Expor porta
EXPOSE ${PORT}

# Substituir a porta no arranque e iniciar Tomcat
CMD sed -i "s/port=\"8080\"/port=\"${PORT}\"/" /usr/local/tomcat/conf/server.xml && catalina.sh run
