<%-- =========================================================================
  admin_produto_form.jsp - Formulario de Produto (Admin)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Formulario para criar ou editar produtos. Permite definir
             nome, descricao, preco, stock, unidade, categoria e imagem.
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
    
    String idParam = request.getParameter("id");
    boolean modoEdicao = (idParam != null && !idParam.isEmpty());
    int produtoId = modoEdicao ? Integer.parseInt(idParam) : 0;
    
    // Dados do formulario
    String nome = "", descricao = "", imagem_url = "", unidade = "kg";
    double preco = 0;
    int stock = 0, idCategoria = 0;
    int ativo = 1;
    
    // Processar POST
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        nome = request.getParameter("nome");
        descricao = request.getParameter("descricao");
        String precoStr = request.getParameter("preco");
        String stockStr = request.getParameter("stock");
        unidade = request.getParameter("unidade");
        String catStr = request.getParameter("id_categoria");
        imagem_url = request.getParameter("imagem_url");
        String ativoStr = request.getParameter("ativo");
        ativo = "1".equals(ativoStr) ? 1 : 0;
        
        if (nome == null || nome.trim().isEmpty() || precoStr == null || catStr == null) {
            mensagem = "Nome, preço e categoria são obrigatórios.";
            tipoMensagem = "error";
        } else {
            try {
                preco = Double.parseDouble(precoStr);
                stock = Integer.parseInt(stockStr != null ? stockStr : "0");
                idCategoria = Integer.parseInt(catStr);
                
                if (preco < 0) throw new Exception("O preço não pode ser negativo.");
                if (stock < 0) throw new Exception("O stock não pode ser negativo.");
                
                conn = getConnection();
                
                if (modoEdicao) {
                    pstmt = conn.prepareStatement(
                        "UPDATE produtos SET nome=?, descricao=?, preco=?, stock=?, unidade=?, " +
                        "id_categoria=?, imagem_url=?, ativo=? WHERE id=?"
                    );
                    pstmt.setString(1, nome.trim());
                    pstmt.setString(2, descricao != null ? descricao.trim() : null);
                    pstmt.setDouble(3, preco);
                    pstmt.setInt(4, stock);
                    pstmt.setString(5, unidade);
                    pstmt.setInt(6, idCategoria);
                    pstmt.setString(7, imagem_url != null && !imagem_url.trim().isEmpty() ? imagem_url.trim() : null);
                    pstmt.setInt(8, ativo);
                    pstmt.setInt(9, produtoId);
                    pstmt.executeUpdate();
                    mensagem = "Produto atualizado com sucesso!";
                    tipoMensagem = "success";
                } else {
                    pstmt = conn.prepareStatement(
                        "INSERT INTO produtos (nome, descricao, preco, stock, unidade, id_categoria, imagem_url, ativo) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
                    );
                    pstmt.setString(1, nome.trim());
                    pstmt.setString(2, descricao != null ? descricao.trim() : null);
                    pstmt.setDouble(3, preco);
                    pstmt.setInt(4, stock);
                    pstmt.setString(5, unidade);
                    pstmt.setInt(6, idCategoria);
                    pstmt.setString(7, imagem_url != null && !imagem_url.trim().isEmpty() ? imagem_url.trim() : null);
                    pstmt.setInt(8, ativo);
                    pstmt.executeUpdate();
                    mensagem = "Produto criado com sucesso!";
                    tipoMensagem = "success";
                    // Limpar
                    nome = ""; descricao = ""; preco = 0; stock = 0; imagem_url = "";
                    unidade = "kg"; idCategoria = 0; ativo = 1;
                    modoEdicao = false;
                }
                pstmt.close();
                fecharConexao(conn); conn = null;
            } catch (NumberFormatException nfe) {
                mensagem = "Preço ou stock inválido.";
                tipoMensagem = "error";
                if (conn != null) { fecharConexao(conn); conn = null; }
            } catch (Exception e) {
                mensagem = "Erro: " + e.getMessage();
                tipoMensagem = "error";
                if (conn != null) { fecharConexao(conn); conn = null; }
            }
        }
    }
    
    // Carregar dados para edicao
    if (modoEdicao && "GET".equalsIgnoreCase(request.getMethod())) {
        try {
            conn = getConnection();
            pstmt = conn.prepareStatement("SELECT * FROM produtos WHERE id = ?");
            pstmt.setInt(1, produtoId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                nome = rs.getString("nome");
                descricao = rs.getString("descricao") != null ? rs.getString("descricao") : "";
                preco = rs.getDouble("preco");
                stock = rs.getInt("stock");
                unidade = rs.getString("unidade");
                idCategoria = rs.getInt("id_categoria");
                imagem_url = rs.getString("imagem_url") != null ? rs.getString("imagem_url") : "";
                ativo = rs.getInt("ativo");
            }
            fecharRecursos(rs, pstmt, conn); conn = null;
        } catch (Exception e) {
            mensagem = "Erro: " + e.getMessage();
            tipoMensagem = "error";
            if (conn != null) { fecharConexao(conn); conn = null; }
        }
    }
%>

<%@ include file="header.jsp" %>

<h1 class="page-title"><%= modoEdicao ? "&#9999; Editar Produto" : "&#10133; Novo Produto" %></h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<div class="card" style="max-width: 700px; margin: 0 auto;">
    <div class="card-header"><h2><%= modoEdicao ? "Editar Dados" : "Criar Produto" %></h2></div>
    <form method="post" action="admin_produto_form.jsp<%= modoEdicao ? "?id=" + produtoId : "" %>">
        <div class="form-group">
            <label for="nome">Nome do Produto: *</label>
            <input type="text" id="nome" name="nome" value="<%= nome %>" required class="form-control">
        </div>
        <div class="form-group">
            <label for="descricao">Descrição:</label>
            <textarea id="descricao" name="descricao" rows="3" class="form-control"><%= descricao %></textarea>
        </div>
        <div class="grid-3">
            <div class="form-group">
                <label for="preco">Preço (&euro;): *</label>
                <input type="number" id="preco" name="preco" value="<%= String.format("%.2f", preco) %>" 
                    step="0.01" min="0" required class="form-control">
            </div>
            <div class="form-group">
                <label for="stock">Stock: *</label>
                <input type="number" id="stock" name="stock" value="<%= stock %>" min="0" required class="form-control">
            </div>
            <div class="form-group">
                <label for="unidade">Unidade: *</label>
                <select id="unidade" name="unidade" class="form-control" required>
                    <option value="kg" <%= "kg".equals(unidade) ? "selected" : "" %>>kg</option>
                    <option value="unidade" <%= "unidade".equals(unidade) ? "selected" : "" %>>unidade</option>
                    <option value="litro" <%= "litro".equals(unidade) ? "selected" : "" %>>litro</option>
                    <option value="pack" <%= "pack".equals(unidade) ? "selected" : "" %>>pack</option>
                    <option value="dúzia" <%= "dúzia".equals(unidade) ? "selected" : "" %>>dúzia</option>
                </select>
            </div>
        </div>
        <div class="grid-2">
            <div class="form-group">
                <label for="id_categoria">Categoria: *</label>
                <select id="id_categoria" name="id_categoria" class="form-control" required>
                    <option value="">-- Selecionar --</option>
<%
    try {
        if (conn == null) conn = getConnection();
        pstmt = conn.prepareStatement("SELECT id, nome FROM categorias ORDER BY nome");
        rs = pstmt.executeQuery();
        while (rs.next()) {
%>
                    <option value="<%= rs.getInt("id") %>" <%= rs.getInt("id") == idCategoria ? "selected" : "" %>>
                        <%= rs.getString("nome") %>
                    </option>
<%
        }
        fecharRecursos(rs, pstmt, conn); conn = null;
    } catch (Exception e) { /* ignore */ }
%>
                </select>
            </div>
            <div class="form-group">
                <label for="ativo">Estado:</label>
                <select id="ativo" name="ativo" class="form-control">
                    <option value="1" <%= ativo == 1 ? "selected" : "" %>>Ativo</option>
                    <option value="0" <%= ativo == 0 ? "selected" : "" %>>Inativo</option>
                </select>
            </div>
        </div>
        <div class="form-group">
            <label for="imagem_url">URL da Imagem:</label>
            <input type="text" id="imagem_url" name="imagem_url" value="<%= imagem_url %>" 
                placeholder="https://..." class="form-control">
        </div>
        <div class="btn-group">
            <button type="submit" class="btn btn-primary"><%= modoEdicao ? "Guardar Alterações" : "Criar Produto" %></button>
            <a href="admin_produtos.jsp" class="btn btn-secondary">Cancelar</a>
        </div>
    </form>
</div>

<%@ include file="footer.jsp" %>
