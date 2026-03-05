<%-- =========================================================================
  admin_dashboard.jsp - Painel do Administrador
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Pagina principal da area de administracao. Apresenta
             estatisticas gerais do sistema (utilizadores, produtos,
             encomendas, carteiras) e links rapidos para todas as
             funcionalidades administrativas.
             Acessivel apenas a administradores.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "admin"; %>
<%@ include file="auth_check.jsp" %>
<%@ include file="header.jsp" %>

<%
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    int totalUtilizadores = 0, totalClientes = 0, totalFuncionarios = 0;
    int totalProdutos = 0, produtosSemStock = 0;
    int totalEncomendas = 0, encPendentes = 0, encEntregues = 0;
    double totalVendas = 0, saldoLoja = 0;
    int totalPromocoes = 0;
    
    try {
        conn = getConnection();
        
        // Utilizadores
        pstmt = conn.prepareStatement(
            "SELECT perfil, COUNT(*) AS t FROM utilizadores GROUP BY perfil"
        );
        rs = pstmt.executeQuery();
        while (rs.next()) {
            int t = rs.getInt("t");
            totalUtilizadores += t;
            if ("cliente".equals(rs.getString("perfil"))) totalClientes = t;
            else if ("funcionario".equals(rs.getString("perfil"))) totalFuncionarios = t;
        }
        rs.close(); pstmt.close();
        
        // Produtos
        pstmt = conn.prepareStatement("SELECT COUNT(*) AS t FROM produtos WHERE ativo = 1");
        rs = pstmt.executeQuery();
        if (rs.next()) totalProdutos = rs.getInt("t");
        rs.close(); pstmt.close();
        
        pstmt = conn.prepareStatement("SELECT COUNT(*) AS t FROM produtos WHERE ativo = 1 AND stock = 0");
        rs = pstmt.executeQuery();
        if (rs.next()) produtosSemStock = rs.getInt("t");
        rs.close(); pstmt.close();
        
        // Encomendas
        pstmt = conn.prepareStatement(
            "SELECT estado, COUNT(*) AS t, SUM(valor_total) AS soma FROM encomendas GROUP BY estado"
        );
        rs = pstmt.executeQuery();
        while (rs.next()) {
            int t = rs.getInt("t");
            totalEncomendas += t;
            String est = rs.getString("estado");
            if ("pendente".equals(est)) encPendentes = t;
            else if ("entregue".equals(est)) { encEntregues = t; totalVendas = rs.getDouble("soma"); }
        }
        rs.close(); pstmt.close();
        
        // Saldo da loja
        pstmt = conn.prepareStatement("SELECT saldo FROM carteiras WHERE tipo = 'loja'");
        rs = pstmt.executeQuery();
        if (rs.next()) saldoLoja = rs.getDouble("saldo");
        rs.close(); pstmt.close();
        
        // Promocoes ativas
        pstmt = conn.prepareStatement(
            "SELECT COUNT(*) AS t FROM promocoes WHERE CURDATE() BETWEEN data_inicio AND data_fim"
        );
        rs = pstmt.executeQuery();
        if (rs.next()) totalPromocoes = rs.getInt("t");
        rs.close(); pstmt.close();
%>

<h1 class="page-title">&#128736; Painel de Administração</h1>
<p class="page-subtitle">Bem-vindo(a), <strong><%= session.getAttribute("nome") %></strong>!</p>

<%-- Estatisticas --%>
<div class="grid-4">
    <div class="card dashboard-stat">
        <div class="stat-value"><%= totalUtilizadores %></div>
        <div class="stat-label">Utilizadores</div>
        <small class="text-muted"><%= totalClientes %> clientes, <%= totalFuncionarios %> func.</small>
    </div>
    <div class="card dashboard-stat">
        <div class="stat-value"><%= totalProdutos %></div>
        <div class="stat-label">Produtos Ativos</div>
        <% if (produtosSemStock > 0) { %>
        <small style="color:#c62828;"><%= produtosSemStock %> sem stock!</small>
        <% } %>
    </div>
    <div class="card dashboard-stat">
        <div class="stat-value"><%= totalEncomendas %></div>
        <div class="stat-label">Encomendas</div>
        <small class="text-muted"><%= encPendentes %> pendentes</small>
    </div>
    <div class="card dashboard-stat">
        <div class="stat-value" style="color:#2e7d32;"><%= String.format("%.2f", saldoLoja) %>&euro;</div>
        <div class="stat-label">Saldo Loja</div>
        <small class="text-muted"><%= encEntregues %> vendas concluídas</small>
    </div>
</div>

<%-- Links rapidos --%>
<div class="grid-3">
    <div class="card">
        <div class="card-header"><h2>&#128101; Utilizadores</h2></div>
        <p>Gerir contas de clientes, funcionários e administradores.</p>
        <a href="admin_utilizadores.jsp" class="btn btn-primary" style="width:100%;">Gerir Utilizadores</a>
    </div>
    <div class="card">
        <div class="card-header"><h2>&#128230; Produtos</h2></div>
        <p>Adicionar, editar e remover produtos do catálogo.</p>
        <a href="admin_produtos.jsp" class="btn btn-primary" style="width:100%;">Gerir Produtos</a>
    </div>
    <div class="card">
        <div class="card-header"><h2>&#127873; Promoções</h2></div>
        <p>Criar e gerir promoções e descontos (<%= totalPromocoes %> ativas).</p>
        <a href="admin_promocoes.jsp" class="btn btn-primary" style="width:100%;">Gerir Promoções</a>
    </div>
</div>

<div class="grid-3">
    <div class="card">
        <div class="card-header"><h2>&#128230; Encomendas</h2></div>
        <p>Visualizar e gerir todas as encomendas do sistema.</p>
        <a href="func_encomendas.jsp" class="btn btn-info" style="width:100%;">Gerir Encomendas</a>
    </div>
    <div class="card">
        <div class="card-header"><h2>&#128176; Carteiras</h2></div>
        <p>Gerir carteiras de clientes e da loja.</p>
        <a href="admin_carteiras.jsp" class="btn btn-info" style="width:100%;">Gerir Carteiras</a>
    </div>
    <div class="card">
        <div class="card-header"><h2>&#9881; Info Mercearia</h2></div>
        <p>Editar informações, horários e contactos da loja.</p>
        <a href="admin_info.jsp" class="btn btn-info" style="width:100%;">Editar Informações</a>
    </div>
</div>

<%
    } catch (Exception e) {
%>
<div class="alert alert-error">Erro: <%= e.getMessage() %></div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<%@ include file="footer.jsp" %>
