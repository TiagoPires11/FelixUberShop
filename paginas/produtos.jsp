<%-- =========================================================================
  produtos.jsp - Catalogo de Produtos
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Apresenta o catalogo de produtos da mercearia. Permite
             filtrar por categoria e pesquisar por nome. Acessivel a
             todos os perfis de utilizador (incluindo visitantes).
             Mostra nome, preco, categoria e stock de cada produto.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<%@ include file="header.jsp" %>

<%
    // -------------------------------------------------------------------
    // Obter parametro de filtro de categoria (se existir)
    // -------------------------------------------------------------------
    String filtroCategoria = request.getParameter("categoria");
    String filtroPesquisa = request.getParameter("pesquisa");
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
%>

<h1 class="page-title">&#128722; Nossos Produtos</h1>

<%-- Formulario de pesquisa e filtro --%>
<div class="card">
    <form method="get" action="produtos.jsp" class="form-inline">
        <div class="form-group">
            <label for="pesquisa">Pesquisar:</label>
            <input type="text" id="pesquisa" name="pesquisa" 
                   placeholder="Nome do produto..." 
                   value="<%= (filtroPesquisa != null) ? filtroPesquisa : "" %>">
        </div>
        <div class="form-group">
            <label for="categoria">Categoria:</label>
            <select id="categoria" name="categoria">
                <option value="">Todas as Categorias</option>
                <%
                    // Carregar categorias para o filtro
                    pstmt = conn.prepareStatement("SELECT id, nome FROM categorias WHERE ativo = 1 ORDER BY nome");
                    rs = pstmt.executeQuery();
                    while (rs.next()) {
                        String catId = rs.getString("id");
                        String selected = (catId.equals(filtroCategoria)) ? "selected" : "";
                %>
                    <option value="<%= catId %>" <%= selected %>><%= rs.getString("nome") %></option>
                <%
                    }
                    rs.close();
                    pstmt.close();
                %>
            </select>
        </div>
        <div class="form-group">
            <button type="submit" class="btn btn-primary">Filtrar</button>
            <a href="produtos.jsp" class="btn btn-secondary">Limpar</a>
        </div>
    </form>
</div>

<%-- Grid de produtos --%>
<div class="grid-4">
<%
        // -------------------------------------------------------------------
        // Construir query de produtos com filtros opcionais
        // Usa PreparedStatement para prevenir SQL injection
        // -------------------------------------------------------------------
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT p.id, p.nome, p.descricao, p.preco, p.stock, p.imagem, ");
        sql.append("c.nome AS categoria_nome ");
        sql.append("FROM produtos p ");
        sql.append("LEFT JOIN categorias c ON p.id_categoria = c.id ");
        sql.append("WHERE p.ativo = 1 ");
        
        java.util.ArrayList<String> params = new java.util.ArrayList<String>();
        
        // Filtro por categoria
        if (filtroCategoria != null && !filtroCategoria.isEmpty()) {
            sql.append("AND p.id_categoria = ? ");
            params.add(filtroCategoria);
        }
        
        // Filtro por pesquisa de nome
        if (filtroPesquisa != null && !filtroPesquisa.trim().isEmpty()) {
            sql.append("AND p.nome LIKE ? ");
            params.add("%" + filtroPesquisa.trim() + "%");
        }
        
        sql.append("ORDER BY c.nome, p.nome");
        
        pstmt = conn.prepareStatement(sql.toString());
        
        // Definir parametros da query
        for (int i = 0; i < params.size(); i++) {
            pstmt.setString(i + 1, params.get(i));
        }
        
        rs = pstmt.executeQuery();
        
        boolean temProdutos = false;
        while (rs.next()) {
            temProdutos = true;
            double preco = rs.getDouble("preco");
            int stock = rs.getInt("stock");
%>
    <%-- Card individual de produto --%>
    <div class="produto-card">
        <div class="produto-img">
            &#127821;
        </div>
        <div class="produto-info">
            <div class="produto-nome"><%= rs.getString("nome") %></div>
            <div class="produto-categoria"><%= rs.getString("categoria_nome") != null ? rs.getString("categoria_nome") : "Sem categoria" %></div>
            <div class="produto-preco"><%= String.format("%.2f", preco) %> &euro;</div>
            <div class="produto-stock">
                <% if (stock > 0) { %>
                    <span class="text-success">Em stock (<%= stock %>)</span>
                <% } else { %>
                    <span class="text-danger">Esgotado</span>
                <% } %>
            </div>
        </div>
    </div>
<%
        }
        
        if (!temProdutos) {
%>
    </div>
    <div class="card text-center">
        <p class="text-muted">Nenhum produto encontrado com os filtros selecionados.</p>
    </div>
<%
        } else {
%>
</div>
<%
        }
        
        rs.close();
        pstmt.close();
        
    } catch (Exception e) {
%>
    <div class="alert alert-error">
        Erro ao carregar produtos: <%= e.getMessage() %>
    </div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<%@ include file="footer.jsp" %>
