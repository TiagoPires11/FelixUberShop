<%-- =========================================================================
  cliente_encomendas.jsp - Lista de Encomendas do Cliente
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Apresenta a lista de todas as encomendas do cliente com
             estado, valor e data. Permite filtrar por estado e aceder
             aos detalhes de cada encomenda. Inclui opcoes para editar
             ou cancelar encomendas pendentes.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "cliente"; %>
<%@ include file="auth_check.jsp" %>
<%@ include file="header.jsp" %>

<%
    int userId = (Integer) session.getAttribute("user_id");
    String filtroEstado = request.getParameter("estado");
    
    // Verificar se ha mensagem de sucesso na sessao
    String sucesso = null;
    if (session.getAttribute("mensagem_sucesso") != null) {
        sucesso = (String) session.getAttribute("mensagem_sucesso");
        session.removeAttribute("mensagem_sucesso");
    }
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
%>

<h1 class="page-title">&#128230; Minhas Encomendas</h1>

<% if (sucesso != null) { %>
    <div class="alert alert-success"><%= sucesso %></div>
<% } %>

<%-- Filtro por estado --%>
<div class="card">
    <form method="get" action="cliente_encomendas.jsp" class="form-inline">
        <div class="form-group">
            <label for="estado">Filtrar por estado:</label>
            <select id="estado" name="estado">
                <option value="">Todos</option>
                <option value="pendente" <%= "pendente".equals(filtroEstado) ? "selected" : "" %>>Pendente</option>
                <option value="confirmada" <%= "confirmada".equals(filtroEstado) ? "selected" : "" %>>Confirmada</option>
                <option value="em_preparacao" <%= "em_preparacao".equals(filtroEstado) ? "selected" : "" %>>Em Preparação</option>
                <option value="pronta" <%= "pronta".equals(filtroEstado) ? "selected" : "" %>>Pronta</option>
                <option value="entregue" <%= "entregue".equals(filtroEstado) ? "selected" : "" %>>Entregue</option>
                <option value="cancelada" <%= "cancelada".equals(filtroEstado) ? "selected" : "" %>>Cancelada</option>
            </select>
        </div>
        <div class="form-group">
            <button type="submit" class="btn btn-primary">Filtrar</button>
            <a href="cliente_encomendas.jsp" class="btn btn-secondary">Limpar</a>
            <a href="cliente_nova_encomenda.jsp" class="btn btn-info">&#10133; Nova Encomenda</a>
        </div>
    </form>
</div>

<%-- Tabela de encomendas --%>
<div class="card">
<%
        // Construir query com filtro opcional de estado
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT id, codigo_unico, estado, valor_total, observacoes, data_encomenda ");
        sql.append("FROM encomendas WHERE id_cliente = ? ");
        if (filtroEstado != null && !filtroEstado.isEmpty()) {
            sql.append("AND estado = ? ");
        }
        sql.append("ORDER BY data_encomenda DESC");
        
        pstmt = conn.prepareStatement(sql.toString());
        pstmt.setInt(1, userId);
        if (filtroEstado != null && !filtroEstado.isEmpty()) {
            pstmt.setString(2, filtroEstado);
        }
        rs = pstmt.executeQuery();
        
        boolean temEncomendas = false;
%>
    <table>
        <thead>
            <tr>
                <th>Código</th>
                <th>Estado</th>
                <th>Valor Total</th>
                <th>Data</th>
                <th>Ações</th>
            </tr>
        </thead>
        <tbody>
<%
        while (rs.next()) {
            temEncomendas = true;
            String estado = rs.getString("estado");
            int encId = rs.getInt("id");
%>
            <tr>
                <td><strong><%= rs.getString("codigo_unico") %></strong></td>
                <td><span class="badge badge-<%= estado %>"><%= estado %></span></td>
                <td><%= String.format("%.2f", rs.getDouble("valor_total")) %> &euro;</td>
                <td><%= rs.getString("data_encomenda") %></td>
                <td class="acoes">
                    <a href="cliente_encomenda_detalhe.jsp?id=<%= encId %>" class="btn btn-sm btn-info">Ver</a>
                    <% if ("pendente".equals(estado)) { %>
                        <a href="cliente_editar_encomenda.jsp?id=<%= encId %>" class="btn btn-sm btn-warning">Editar</a>
                        <a href="cliente_cancelar_encomenda.jsp?id=<%= encId %>" 
                           class="btn btn-sm btn-danger"
                           onclick="return confirmarAcao('Tem a certeza que deseja cancelar esta encomenda?');">Cancelar</a>
                    <% } %>
                </td>
            </tr>
<%
        }
        
        if (!temEncomendas) {
%>
            <tr><td colspan="5" class="text-center text-muted">Nenhuma encomenda encontrada.</td></tr>
<%
        }
%>
        </tbody>
    </table>
</div>

<%
    } catch (Exception e) {
%>
    <div class="alert alert-error">Erro ao carregar encomendas: <%= e.getMessage() %></div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<script src="scripts.js"></script>
<%@ include file="footer.jsp" %>
