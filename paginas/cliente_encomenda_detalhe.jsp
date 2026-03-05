<%-- =========================================================================
  cliente_encomenda_detalhe.jsp - Detalhes de uma Encomenda
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Mostra os detalhes completos de uma encomenda especifica
             do cliente, incluindo codigo unico, estado, itens com
             quantidades e precos, valor total e datas.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "cliente"; %>
<%@ include file="auth_check.jsp" %>
<%@ include file="header.jsp" %>

<%
    int userId = (Integer) session.getAttribute("user_id");
    String idParam = request.getParameter("id");
    
    if (idParam == null || idParam.isEmpty()) {
        response.sendRedirect("cliente_encomendas.jsp");
        return;
    }
    
    int encomendaId = Integer.parseInt(idParam);
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
        
        // Carregar dados da encomenda (verificar que pertence ao cliente)
        pstmt = conn.prepareStatement(
            "SELECT id, codigo_unico, estado, valor_total, observacoes, data_encomenda, data_atualizacao " +
            "FROM encomendas WHERE id = ? AND id_cliente = ?"
        );
        pstmt.setInt(1, encomendaId);
        pstmt.setInt(2, userId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
%>
            <div class="alert alert-error">Encomenda não encontrada.</div>
            <a href="cliente_encomendas.jsp" class="btn btn-secondary">Voltar</a>
<%
        } else {
            String codigoUnico = rs.getString("codigo_unico");
            String estado = rs.getString("estado");
            double valorTotal = rs.getDouble("valor_total");
            String observacoes = rs.getString("observacoes");
            String dataEncomenda = rs.getString("data_encomenda");
            String dataAtualizacao = rs.getString("data_atualizacao");
            rs.close();
            pstmt.close();
%>

<h1 class="page-title">&#128230; Encomenda: <%= codigoUnico %></h1>

<%-- Informacoes gerais da encomenda --%>
<div class="grid-2">
    <div class="card">
        <div class="card-header"><h3>Informações</h3></div>
        <p><strong>Código:</strong> <%= codigoUnico %></p>
        <p><strong>Estado:</strong> <span class="badge badge-<%= estado %>"><%= estado %></span></p>
        <p><strong>Data:</strong> <%= dataEncomenda %></p>
        <% if (dataAtualizacao != null) { %>
            <p><strong>Última atualização:</strong> <%= dataAtualizacao %></p>
        <% } %>
        <% if (observacoes != null && !observacoes.isEmpty()) { %>
            <p><strong>Observações:</strong> <%= observacoes %></p>
        <% } %>
    </div>
    <div class="card dashboard-stat">
        <div class="stat-value"><%= String.format("%.2f", valorTotal) %> &euro;</div>
        <div class="stat-label">Valor Total</div>
    </div>
</div>

<%-- Itens da encomenda --%>
<div class="card">
    <div class="card-header"><h2>Itens da Encomenda</h2></div>
    <table>
        <thead>
            <tr>
                <th>Produto</th>
                <th>Preço Unitário</th>
                <th>Quantidade</th>
                <th>Subtotal</th>
            </tr>
        </thead>
        <tbody>
<%
            // Carregar itens da encomenda
            pstmt = conn.prepareStatement(
                "SELECT ie.quantidade, ie.preco_unitario, p.nome " +
                "FROM itens_encomenda ie JOIN produtos p ON ie.id_produto = p.id " +
                "WHERE ie.id_encomenda = ?"
            );
            pstmt.setInt(1, encomendaId);
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                double precoUnit = rs.getDouble("preco_unitario");
                int qtd = rs.getInt("quantidade");
%>
            <tr>
                <td><%= rs.getString("nome") %></td>
                <td><%= String.format("%.2f", precoUnit) %> &euro;</td>
                <td><%= qtd %></td>
                <td><strong><%= String.format("%.2f", precoUnit * qtd) %> &euro;</strong></td>
            </tr>
<%
            }
            rs.close();
            pstmt.close();
%>
        </tbody>
        <tfoot>
            <tr>
                <td colspan="3" class="text-right"><strong>Total:</strong></td>
                <td><strong><%= String.format("%.2f", valorTotal) %> &euro;</strong></td>
            </tr>
        </tfoot>
    </table>
</div>

<%-- Acoes --%>
<div class="btn-group mt-20">
    <a href="cliente_encomendas.jsp" class="btn btn-secondary">&#8592; Voltar às Encomendas</a>
    <% if ("pendente".equals(estado)) { %>
        <a href="cliente_editar_encomenda.jsp?id=<%= encomendaId %>" class="btn btn-warning">Editar Encomenda</a>
        <a href="cliente_cancelar_encomenda.jsp?id=<%= encomendaId %>" class="btn btn-danger"
           onclick="return confirmarAcao('Tem a certeza que deseja cancelar esta encomenda?');">Cancelar Encomenda</a>
    <% } %>
</div>

<%
        }
    } catch (Exception e) {
%>
    <div class="alert alert-error">Erro: <%= e.getMessage() %></div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<script src="scripts.js"></script>
<%@ include file="footer.jsp" %>
