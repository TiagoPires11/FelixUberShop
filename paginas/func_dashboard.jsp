<%-- =========================================================================
  func_dashboard.jsp - Painel do Funcionario
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Pagina principal da area de funcionario. Apresenta um resumo
             com estatisticas de encomendas (pendentes, em preparacao, etc.)
             e links rapidos para as funcionalidades do funcionario.
             Acessivel a funcionarios e administradores.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "funcionario"; %>
<%@ include file="auth_check.jsp" %>
<%@ include file="header.jsp" %>

<%
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    int encPendentes = 0, encConfirmadas = 0, encPreparacao = 0, encProntas = 0, totalClientes = 0;
    
    try {
        conn = getConnection();
        
        // Contar encomendas por estado
        pstmt = conn.prepareStatement(
            "SELECT estado, COUNT(*) AS total FROM encomendas " +
            "WHERE estado IN ('pendente','confirmada','em_preparacao','pronta') GROUP BY estado"
        );
        rs = pstmt.executeQuery();
        while (rs.next()) {
            String est = rs.getString("estado");
            int t = rs.getInt("total");
            if ("pendente".equals(est)) encPendentes = t;
            else if ("confirmada".equals(est)) encConfirmadas = t;
            else if ("em_preparacao".equals(est)) encPreparacao = t;
            else if ("pronta".equals(est)) encProntas = t;
        }
        rs.close();
        pstmt.close();
        
        // Contar clientes ativos
        pstmt = conn.prepareStatement("SELECT COUNT(*) AS t FROM utilizadores WHERE perfil = 'cliente' AND ativo = 1");
        rs = pstmt.executeQuery();
        if (rs.next()) totalClientes = rs.getInt("t");
        rs.close();
        pstmt.close();
%>

<h1 class="page-title">&#128188; Painel do Funcionário</h1>
<p class="page-subtitle">Bem-vindo(a), <strong><%= session.getAttribute("nome") %></strong>!</p>

<%-- Estatisticas --%>
<div class="grid-4">
    <div class="card dashboard-stat">
        <div class="stat-value" style="color: #e65100;"><%= encPendentes %></div>
        <div class="stat-label">Pendentes</div>
    </div>
    <div class="card dashboard-stat">
        <div class="stat-value" style="color: #0277bd;"><%= encConfirmadas %></div>
        <div class="stat-label">Confirmadas</div>
    </div>
    <div class="card dashboard-stat">
        <div class="stat-value" style="color: #7b1fa2;"><%= encPreparacao %></div>
        <div class="stat-label">Em Preparação</div>
    </div>
    <div class="card dashboard-stat">
        <div class="stat-value" style="color: #2e7d32;"><%= encProntas %></div>
        <div class="stat-label">Prontas</div>
    </div>
</div>

<%-- Links rapidos --%>
<div class="card">
    <div class="card-header"><h2>Ações Rápidas</h2></div>
    <div class="btn-group">
        <a href="func_encomendas.jsp" class="btn btn-primary">&#128230; Gerir Encomendas</a>
        <a href="func_carteiras.jsp" class="btn btn-info">&#128176; Gerir Carteiras</a>
        <a href="func_perfil.jsp" class="btn btn-secondary">&#128221; Meu Perfil</a>
    </div>
</div>

<%-- Ultimas encomendas pendentes --%>
<div class="card">
    <div class="card-header"><h2>Encomendas Recentes (Pendentes)</h2></div>
<%
        pstmt = conn.prepareStatement(
            "SELECT e.id, e.codigo_unico, e.estado, e.valor_total, e.data_encomenda, u.nome AS cliente_nome " +
            "FROM encomendas e JOIN utilizadores u ON e.id_cliente = u.id " +
            "WHERE e.estado = 'pendente' ORDER BY e.data_encomenda ASC LIMIT 10"
        );
        rs = pstmt.executeQuery();
        boolean tem = false;
%>
    <table>
        <thead>
            <tr><th>Código</th><th>Cliente</th><th>Valor</th><th>Data</th><th>Ações</th></tr>
        </thead>
        <tbody>
<%
        while (rs.next()) {
            tem = true;
%>
            <tr>
                <td><strong><%= rs.getString("codigo_unico") %></strong></td>
                <td><%= rs.getString("cliente_nome") %></td>
                <td><%= String.format("%.2f", rs.getDouble("valor_total")) %> &euro;</td>
                <td><%= rs.getString("data_encomenda") %></td>
                <td><a href="func_encomenda_detalhe.jsp?id=<%= rs.getInt("id") %>" class="btn btn-sm btn-info">Ver</a></td>
            </tr>
<%
        }
        if (!tem) {
%>
            <tr><td colspan="5" class="text-center text-muted">Sem encomendas pendentes.</td></tr>
<%
        }
%>
        </tbody>
    </table>
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
