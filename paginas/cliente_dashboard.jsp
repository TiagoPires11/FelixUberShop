<%-- =========================================================================
  cliente_dashboard.jsp - Painel do Cliente
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Pagina principal da area de cliente. Apresenta um resumo
             com saldo da carteira, numero de encomendas recentes e
             links rapidos para as funcionalidades do cliente.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "cliente"; %>
<%@ include file="auth_check.jsp" %>
<%@ include file="header.jsp" %>

<%
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    double saldo = 0;
    int totalEncomendas = 0;
    int encomendasPendentes = 0;
    
    try {
        conn = getConnection();
        int userId = (Integer) session.getAttribute("user_id");
        
        // -------------------------------------------------------------------
        // Obter saldo da carteira do cliente
        // -------------------------------------------------------------------
        pstmt = conn.prepareStatement("SELECT saldo FROM carteiras WHERE id_utilizador = ? AND tipo = 'cliente'");
        pstmt.setInt(1, userId);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            saldo = rs.getDouble("saldo");
        }
        rs.close();
        pstmt.close();
        
        // -------------------------------------------------------------------
        // Contar total de encomendas do cliente
        // -------------------------------------------------------------------
        pstmt = conn.prepareStatement("SELECT COUNT(*) AS total FROM encomendas WHERE id_cliente = ?");
        pstmt.setInt(1, userId);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            totalEncomendas = rs.getInt("total");
        }
        rs.close();
        pstmt.close();
        
        // -------------------------------------------------------------------
        // Contar encomendas pendentes
        // -------------------------------------------------------------------
        pstmt = conn.prepareStatement(
            "SELECT COUNT(*) AS total FROM encomendas WHERE id_cliente = ? AND estado IN ('pendente', 'confirmada', 'em_preparacao', 'pronta')"
        );
        pstmt.setInt(1, userId);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            encomendasPendentes = rs.getInt("total");
        }
        rs.close();
        pstmt.close();
%>

<h1 class="page-title">&#128100; Minha Conta</h1>
<p class="page-subtitle">Bem-vindo(a), <strong><%= session.getAttribute("nome") %></strong>!</p>

<%-- Estatisticas rapidas --%>
<div class="grid-3">
    <div class="card dashboard-stat">
        <div class="stat-value"><%= String.format("%.2f", saldo) %> &euro;</div>
        <div class="stat-label">Saldo da Carteira</div>
        <br>
        <a href="cliente_carteira.jsp" class="btn btn-primary btn-sm">Gerir Carteira</a>
    </div>
    <div class="card dashboard-stat">
        <div class="stat-value"><%= totalEncomendas %></div>
        <div class="stat-label">Total de Encomendas</div>
        <br>
        <a href="cliente_encomendas.jsp" class="btn btn-primary btn-sm">Ver Encomendas</a>
    </div>
    <div class="card dashboard-stat">
        <div class="stat-value"><%= encomendasPendentes %></div>
        <div class="stat-label">Encomendas em Curso</div>
        <br>
        <a href="cliente_nova_encomenda.jsp" class="btn btn-primary btn-sm">Nova Encomenda</a>
    </div>
</div>

<%-- Links rapidos --%>
<div class="card" style="margin-top: 20px;">
    <div class="card-header">
        <h2>Ações Rápidas</h2>
    </div>
    <div class="btn-group">
        <a href="cliente_nova_encomenda.jsp" class="btn btn-primary">&#128722; Nova Encomenda</a>
        <a href="cliente_carteira.jsp" class="btn btn-info">&#128176; Carteira</a>
        <a href="cliente_perfil.jsp" class="btn btn-secondary">&#128221; Editar Perfil</a>
        <a href="produtos.jsp" class="btn btn-warning">&#127821; Ver Produtos</a>
    </div>
</div>

<%-- Ultimas encomendas --%>
<div class="card" style="margin-top: 20px;">
    <div class="card-header">
        <h2>Últimas Encomendas</h2>
    </div>
    
<%
        // Carregar ultimas 5 encomendas do cliente
        pstmt = conn.prepareStatement(
            "SELECT id, codigo_unico, estado, valor_total, data_encomenda " +
            "FROM encomendas WHERE id_cliente = ? ORDER BY data_encomenda DESC LIMIT 5"
        );
        pstmt.setInt(1, userId);
        rs = pstmt.executeQuery();
        
        boolean temEncomendas = false;
%>
    <table>
        <thead>
            <tr>
                <th>Código</th>
                <th>Estado</th>
                <th>Valor</th>
                <th>Data</th>
            </tr>
        </thead>
        <tbody>
<%
        while (rs.next()) {
            temEncomendas = true;
%>
            <tr>
                <td><strong><%= rs.getString("codigo_unico") %></strong></td>
                <td><span class="badge badge-<%= rs.getString("estado") %>"><%= rs.getString("estado") %></span></td>
                <td><%= String.format("%.2f", rs.getDouble("valor_total")) %> &euro;</td>
                <td><%= rs.getString("data_encomenda") %></td>
            </tr>
<%
        }
        
        if (!temEncomendas) {
%>
            <tr><td colspan="4" class="text-center text-muted">Ainda não fez nenhuma encomenda.</td></tr>
<%
        }
%>
        </tbody>
    </table>
</div>

<%
    } catch (Exception e) {
%>
    <div class="alert alert-error">Erro ao carregar dashboard: <%= e.getMessage() %></div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<%@ include file="footer.jsp" %>
