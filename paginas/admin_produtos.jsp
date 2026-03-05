<%-- =========================================================================
  admin_produtos.jsp - Gestao de Produtos (Admin)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: CRUD completo de produtos. Lista todos os produtos com
             filtros por categoria e pesquisa por nome. Permite criar,
             editar, ativar/desativar e eliminar produtos.
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
            
            if ("toggle_ativo".equals(acao)) {
                int pid = Integer.parseInt(request.getParameter("produto_id"));
                int ativo = Integer.parseInt(request.getParameter("ativo"));
                pstmt = conn.prepareStatement("UPDATE produtos SET ativo = ? WHERE id = ?");
                pstmt.setInt(1, ativo == 1 ? 0 : 1);
                pstmt.setInt(2, pid);
                pstmt.executeUpdate(); pstmt.close();
                mensagem = "Estado do produto alterado!";
                tipoMensagem = "success";
                
            } else if ("eliminar".equals(acao)) {
                int pid = Integer.parseInt(request.getParameter("produto_id"));
                // Verificar se esta em encomendas
                pstmt = conn.prepareStatement("SELECT COUNT(*) AS t FROM itens_encomenda WHERE id_produto = ?");
                pstmt.setInt(1, pid);
                rs = pstmt.executeQuery(); rs.next();
                if (rs.getInt("t") > 0) {
                    rs.close(); pstmt.close();
                    pstmt = conn.prepareStatement("UPDATE produtos SET ativo = 0 WHERE id = ?");
                    pstmt.setInt(1, pid);
                    pstmt.executeUpdate(); pstmt.close();
                    mensagem = "Produto desativado (tem itens de encomenda associados).";
                    tipoMensagem = "warning";
                } else {
                    rs.close(); pstmt.close();
                    pstmt = conn.prepareStatement("DELETE FROM produtos WHERE id = ?");
                    pstmt.setInt(1, pid);
                    pstmt.executeUpdate(); pstmt.close();
                    mensagem = "Produto eliminado com sucesso!";
                    tipoMensagem = "success";
                }
            }
            
            fecharConexao(conn); conn = null;
        } catch (Exception e) {
            mensagem = "Erro: " + e.getMessage();
            tipoMensagem = "error";
            if (conn != null) { fecharConexao(conn); conn = null; }
        }
    }
    
    String filtroCategoria = request.getParameter("categoria");
    if (filtroCategoria == null) filtroCategoria = "";
    String pesquisa = request.getParameter("pesquisa");
    if (pesquisa == null) pesquisa = "";
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#128230; Gestão de Produtos</h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<%-- Filtros + botao criar --%>
<div class="card">
    <div class="card-header">
        <h2>Filtrar</h2>
        <a href="admin_produto_form.jsp" class="btn btn-success" style="float:right; margin-top:-35px;">+ Novo Produto</a>
    </div>
    <form method="get" action="admin_produtos.jsp" class="form-inline">
        <div class="grid-3">
            <div class="form-group">
                <label for="categoria">Categoria:</label>
                <select name="categoria" id="categoria" class="form-control">
                    <option value="">-- Todas --</option>
<%
    try {
        conn = getConnection();
        pstmt = conn.prepareStatement("SELECT id, nome FROM categorias ORDER BY nome");
        rs = pstmt.executeQuery();
        while (rs.next()) {
%>
                    <option value="<%= rs.getInt("id") %>" <%= String.valueOf(rs.getInt("id")).equals(filtroCategoria) ? "selected" : "" %>>
                        <%= rs.getString("nome") %>
                    </option>
<%
        }
        rs.close(); pstmt.close();
    } catch (Exception e) { /* ignore */ }
%>
                </select>
            </div>
            <div class="form-group">
                <label for="pesquisa">Nome:</label>
                <input type="text" name="pesquisa" id="pesquisa" value="<%= pesquisa %>" class="form-control">
            </div>
            <div class="form-group" style="display:flex; align-items:flex-end;">
                <button type="submit" class="btn btn-primary">&#128269; Filtrar</button>
                &nbsp;<a href="admin_produtos.jsp" class="btn btn-secondary">Limpar</a>
            </div>
        </div>
    </form>
</div>

<%-- Lista de produtos --%>
<div class="card">
    <div class="card-header"><h2>Produtos</h2></div>
<%
    try {
        if (conn == null) conn = getConnection();
        StringBuilder sql = new StringBuilder(
            "SELECT p.id, p.nome, p.preco, p.stock, p.unidade, p.ativo, c.nome AS categoria " +
            "FROM produtos p JOIN categorias c ON p.id_categoria = c.id WHERE 1=1 "
        );
        java.util.List<String> params = new java.util.ArrayList<>();
        if (!filtroCategoria.isEmpty()) { sql.append("AND p.id_categoria = ? "); params.add(filtroCategoria); }
        if (!pesquisa.trim().isEmpty()) { sql.append("AND p.nome LIKE ? "); params.add("%" + pesquisa.trim() + "%"); }
        sql.append("ORDER BY p.nome");
        
        pstmt = conn.prepareStatement(sql.toString());
        for (int i = 0; i < params.size(); i++) pstmt.setString(i + 1, params.get(i));
        rs = pstmt.executeQuery();
        boolean tem = false;
%>
    <table>
        <thead>
            <tr><th>ID</th><th>Nome</th><th>Categoria</th><th>Preço</th><th>Stock</th><th>Unidade</th><th>Estado</th><th>Ações</th></tr>
        </thead>
        <tbody>
<%
        while (rs.next()) {
            tem = true;
            int pid = rs.getInt("id");
            int ativo = rs.getInt("ativo");
            int stock = rs.getInt("stock");
%>
            <tr<%= ativo == 0 ? " style=\"opacity:0.5;\"" : "" %>>
                <td><%= pid %></td>
                <td><strong><%= rs.getString("nome") %></strong></td>
                <td><%= rs.getString("categoria") %></td>
                <td><%= String.format("%.2f", rs.getDouble("preco")) %> &euro;</td>
                <td><span style="color: <%= stock == 0 ? "#c62828" : stock < 10 ? "#e65100" : "#2e7d32" %>;"><%= stock %></span></td>
                <td><%= rs.getString("unidade") %></td>
                <td><%= ativo == 1 ? "<span class='badge badge-entregue'>Ativo</span>" : "<span class='badge badge-cancelada'>Inativo</span>" %></td>
                <td>
                    <a href="admin_produto_form.jsp?id=<%= pid %>" class="btn btn-sm btn-info">Editar</a>
                    <form method="post" action="admin_produtos.jsp" style="display:inline;">
                        <input type="hidden" name="acao" value="toggle_ativo">
                        <input type="hidden" name="produto_id" value="<%= pid %>">
                        <input type="hidden" name="ativo" value="<%= ativo %>">
                        <button type="submit" class="btn btn-sm <%= ativo == 1 ? "btn-warning" : "btn-success" %>"><%= ativo == 1 ? "Desativar" : "Ativar" %></button>
                    </form>
                    <form method="post" action="admin_produtos.jsp" style="display:inline;">
                        <input type="hidden" name="acao" value="eliminar">
                        <input type="hidden" name="produto_id" value="<%= pid %>">
                        <button type="submit" class="btn btn-sm btn-danger" onclick="return confirm('Eliminar este produto?');">Eliminar</button>
                    </form>
                </td>
            </tr>
<%
        }
        if (!tem) {
%>
            <tr><td colspan="8" class="text-center text-muted">Nenhum produto encontrado.</td></tr>
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
