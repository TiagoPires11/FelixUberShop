<%-- =========================================================================
  index.jsp - Pagina Principal (Homepage)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Pagina inicial da FelixUberShop. Apresenta informacoes gerais
             da mercearia (localizacao, contactos, horarios), promocoes
             ativas e destaques de produtos. Acessivel a todos os perfis.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<%@ include file="header.jsp" %>

<%
    // -------------------------------------------------------------------
    // Carregar informacoes da mercearia da base de dados
    // Estas informacoes sao guardadas na tabela info_mercearia (chave-valor)
    // -------------------------------------------------------------------
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Mapa para guardar as informacoes da mercearia
    java.util.HashMap<String, String> info = new java.util.HashMap<String, String>();
    
    try {
        conn = getConnection();
        
        // Carregar todas as informacoes da mercearia
        pstmt = conn.prepareStatement("SELECT chave, valor FROM info_mercearia");
        rs = pstmt.executeQuery();
        while (rs.next()) {
            info.put(rs.getString("chave"), rs.getString("valor"));
        }
        rs.close();
        pstmt.close();
%>

<%-- Seccao Hero - Destaque principal da mercearia --%>
<div class="hero">
    <h1>&#127819; <%= info.getOrDefault("nome", "FelixUberShop") %></h1>
    <p><%= info.getOrDefault("descricao", "A sua mercearia de confiança online") %></p>
    <br>
    <a href="produtos.jsp" class="btn btn-lg" style="background-color: white; color: #2e7d32;">Ver Produtos</a>
    <% if (!estaLogado) { %>
        <a href="registo.jsp" class="btn btn-lg" style="background-color: #43a047; color: white; border: 2px solid white;">Registar-se</a>
    <% } %>
</div>

<%-- Informacoes da mercearia (localizacao, contactos, horarios) --%>
<div class="grid-3">
    
    <%-- Bloco: Localizacao --%>
    <div class="card info-block">
        <h3>&#128205; Localização</h3>
        <p><%= info.getOrDefault("morada", "Castelo Branco") %></p>
    </div>
    
    <%-- Bloco: Contactos --%>
    <div class="card info-block">
        <h3>&#128222; Contactos</h3>
        <p>Tel: <%= info.getOrDefault("telefone", "") %></p>
        <p>Email: <%= info.getOrDefault("email", "") %></p>
    </div>
    
    <%-- Bloco: Horarios de Funcionamento --%>
    <div class="card info-block">
        <h3>&#128336; Horários</h3>
        <p><%= info.getOrDefault("horario_semana", "") %></p>
        <p><%= info.getOrDefault("horario_sabado", "") %></p>
        <p><%= info.getOrDefault("horario_domingo", "") %></p>
    </div>
    
</div>

<%-- Seccao: Promocoes Ativas --%>
<%
        // Carregar promocoes ativas (data atual entre data_inicio e data_fim)
        pstmt = conn.prepareStatement(
            "SELECT titulo, descricao, data_inicio, data_fim FROM promocoes " +
            "WHERE ativo = 1 AND data_inicio <= CURDATE() AND data_fim >= CURDATE() " +
            "ORDER BY data_fim ASC"
        );
        rs = pstmt.executeQuery();
        
        boolean temPromocoes = false;
%>

<h2 class="page-title" style="margin-top: 30px;">&#127873; Promoções em Destaque</h2>

<%
        while (rs.next()) {
            temPromocoes = true;
%>
            <div class="promo-card">
                <h3><%= rs.getString("titulo") %></h3>
                <p><%= rs.getString("descricao") %></p>
                <p class="promo-data">
                    Válido de <%= rs.getString("data_inicio") %> até <%= rs.getString("data_fim") %>
                </p>
            </div>
<%
        }
        
        if (!temPromocoes) {
%>
            <div class="card">
                <p class="text-center text-muted">Não existem promoções ativas de momento.</p>
            </div>
<%
        }
        rs.close();
        pstmt.close();
%>

<%-- Seccao: Sobre Nos --%>
<div class="card" style="margin-top: 20px;">
    <div class="card-header">
        <h2>Sobre Nós</h2>
    </div>
    <p><%= info.getOrDefault("sobre", "Bem-vindo à FelixUberShop!") %></p>
</div>

<%
    } catch (Exception e) {
        // Erro ao carregar dados - mostrar mensagem generica
%>
        <div class="alert alert-error">
            Erro ao carregar informações da mercearia. Por favor, tente novamente mais tarde.
            <br><small><%= e.getMessage() %></small>
        </div>
<%
    } finally {
        // Fechar todos os recursos da base de dados
        fecharRecursos(rs, pstmt, conn);
    }
%>

<%@ include file="footer.jsp" %>
