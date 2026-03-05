<%-- =========================================================================
  admin_promocoes.jsp - Gestao de Promocoes (Admin)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: CRUD completo de promocoes. Lista todas as promocoes com
             indicacao de estado (ativa, futura, expirada). Permite
             criar, editar e eliminar promocoes.
             Acessivel apenas a administradores.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "admin"; %>
<%@ include file="auth_check.jsp" %>

<%
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    String mensagem = null;
    String tipoMensagem = null;
    
    // Processar acoes
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String acao = request.getParameter("acao");
        
        try {
            conn = getConnection();
            
            if ("eliminar".equals(acao)) {
                int pid = Integer.parseInt(request.getParameter("promo_id"));
                pstmt = conn.prepareStatement("DELETE FROM promocoes WHERE id = ?");
                pstmt.setInt(1, pid);
                pstmt.executeUpdate(); pstmt.close();
                mensagem = "Promoção eliminada com sucesso!";
                tipoMensagem = "success";
            }
            
            fecharConexao(conn); conn = null;
        } catch (Exception e) {
            mensagem = "Erro: " + e.getMessage();
            tipoMensagem = "error";
            if (conn != null) { fecharConexao(conn); conn = null; }
        }
    }
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#127873; Gestão de Promoções</h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<div class="card">
    <div class="card-header">
        <h2>Promoções</h2>
        <a href="admin_promocao_form.jsp" class="btn btn-success" style="float:right; margin-top:-35px;">+ Nova Promoção</a>
    </div>
<%
    try {
        conn = getConnection();
        pstmt = conn.prepareStatement(
            "SELECT pr.*, p.nome AS produto_nome " +
            "FROM promocoes pr LEFT JOIN produtos p ON pr.id_produto = p.id " +
            "ORDER BY pr.data_inicio DESC"
        );
        rs = pstmt.executeQuery();
        boolean tem = false;
%>
    <table>
        <thead>
            <tr>
                <th>ID</th><th>Descrição</th><th>Produto</th><th>Desconto</th>
                <th>Início</th><th>Fim</th><th>Estado</th><th>Ações</th>
            </tr>
        </thead>
        <tbody>
<%
        while (rs.next()) {
            tem = true;
            int promoId = rs.getInt("id");
            String dataInicio = rs.getString("data_inicio");
            String dataFim = rs.getString("data_fim");
            String produtoNome = rs.getString("produto_nome");
            
            // Determinar estado
            java.sql.Date hoje = new java.sql.Date(System.currentTimeMillis());
            java.sql.Date inicio = java.sql.Date.valueOf(dataInicio);
            java.sql.Date fim = java.sql.Date.valueOf(dataFim);
            
            String estadoPromo, badgeClass;
            if (hoje.before(inicio)) {
                estadoPromo = "Futura"; badgeClass = "badge-confirmada";
            } else if (hoje.after(fim)) {
                estadoPromo = "Expirada"; badgeClass = "badge-cancelada";
            } else {
                estadoPromo = "Ativa"; badgeClass = "badge-entregue";
            }
%>
            <tr>
                <td><%= promoId %></td>
                <td><strong><%= rs.getString("descricao") %></strong></td>
                <td><%= produtoNome != null ? produtoNome : "<em>Geral</em>" %></td>
                <td><span style="color:#c62828; font-weight:bold;"><%= rs.getInt("percentagem_desconto") %>%</span></td>
                <td><%= dataInicio %></td>
                <td><%= dataFim %></td>
                <td><span class="badge <%= badgeClass %>"><%= estadoPromo %></span></td>
                <td>
                    <a href="admin_promocao_form.jsp?id=<%= promoId %>" class="btn btn-sm btn-info">Editar</a>
                    <form method="post" action="admin_promocoes.jsp" style="display:inline;">
                        <input type="hidden" name="acao" value="eliminar">
                        <input type="hidden" name="promo_id" value="<%= promoId %>">
                        <button type="submit" class="btn btn-sm btn-danger" 
                            onclick="return confirm('Eliminar esta promoção?');">Eliminar</button>
                    </form>
                </td>
            </tr>
<%
        }
        if (!tem) {
%>
            <tr><td colspan="8" class="text-center text-muted">Nenhuma promoção encontrada.</td></tr>
<%
        }
%>
        </tbody>
    </table>
<%
    } catch (Exception e) {
%>
    <div class="alert alert-error">Erro: <%= e.getMessage() %></div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>
</div>

<div class="text-center" style="margin-top:20px;">
    <a href="admin_dashboard.jsp" class="btn btn-secondary">&larr; Voltar ao Painel</a>
</div>

<%@ include file="footer.jsp" %>
