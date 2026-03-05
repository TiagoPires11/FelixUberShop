<%-- =========================================================================
  admin_promocao_form.jsp - Formulario de Promocao (Admin)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Formulario para criar ou editar promocoes. Permite definir
             descricao, produto associado (opcional), percentagem de
             desconto e datas de inicio/fim.
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
    int promoId = modoEdicao ? Integer.parseInt(idParam) : 0;
    
    String descricaoPromo = "";
    int idProduto = 0, percentagem = 10;
    String dataInicio = "", dataFim = "";
    
    // Processar POST
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        descricaoPromo = request.getParameter("descricao");
        String produtoStr = request.getParameter("id_produto");
        String percStr = request.getParameter("percentagem_desconto");
        dataInicio = request.getParameter("data_inicio");
        dataFim = request.getParameter("data_fim");
        
        if (descricaoPromo == null || descricaoPromo.trim().isEmpty() ||
            percStr == null || dataInicio == null || dataFim == null ||
            dataInicio.isEmpty() || dataFim.isEmpty()) {
            mensagem = "Descrição, percentagem e datas são obrigatórios.";
            tipoMensagem = "error";
        } else {
            try {
                percentagem = Integer.parseInt(percStr);
                idProduto = (produtoStr != null && !produtoStr.isEmpty()) ? Integer.parseInt(produtoStr) : 0;
                
                if (percentagem < 1 || percentagem > 100) throw new Exception("Percentagem deve ser entre 1 e 100.");
                if (dataFim.compareTo(dataInicio) < 0) throw new Exception("Data de fim deve ser posterior à data de início.");
                
                conn = getConnection();
                
                if (modoEdicao) {
                    pstmt = conn.prepareStatement(
                        "UPDATE promocoes SET descricao=?, id_produto=?, percentagem_desconto=?, " +
                        "data_inicio=?, data_fim=? WHERE id=?"
                    );
                    pstmt.setString(1, descricaoPromo.trim());
                    if (idProduto > 0) pstmt.setInt(2, idProduto);
                    else pstmt.setNull(2, java.sql.Types.INTEGER);
                    pstmt.setInt(3, percentagem);
                    pstmt.setString(4, dataInicio);
                    pstmt.setString(5, dataFim);
                    pstmt.setInt(6, promoId);
                    pstmt.executeUpdate();
                    mensagem = "Promoção atualizada com sucesso!";
                    tipoMensagem = "success";
                } else {
                    pstmt = conn.prepareStatement(
                        "INSERT INTO promocoes (descricao, id_produto, percentagem_desconto, data_inicio, data_fim) " +
                        "VALUES (?, ?, ?, ?, ?)"
                    );
                    pstmt.setString(1, descricaoPromo.trim());
                    if (idProduto > 0) pstmt.setInt(2, idProduto);
                    else pstmt.setNull(2, java.sql.Types.INTEGER);
                    pstmt.setInt(3, percentagem);
                    pstmt.setString(4, dataInicio);
                    pstmt.setString(5, dataFim);
                    pstmt.executeUpdate();
                    mensagem = "Promoção criada com sucesso!";
                    tipoMensagem = "success";
                    descricaoPromo = ""; idProduto = 0; percentagem = 10;
                    dataInicio = ""; dataFim = "";
                    modoEdicao = false;
                }
                pstmt.close();
                fecharConexao(conn); conn = null;
            } catch (NumberFormatException nfe) {
                mensagem = "Valores numéricos inválidos.";
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
            pstmt = conn.prepareStatement("SELECT * FROM promocoes WHERE id = ?");
            pstmt.setInt(1, promoId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                descricaoPromo = rs.getString("descricao");
                idProduto = rs.getInt("id_produto");
                percentagem = rs.getInt("percentagem_desconto");
                dataInicio = rs.getString("data_inicio");
                dataFim = rs.getString("data_fim");
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

<h1 class="page-title"><%= modoEdicao ? "&#9999; Editar Promoção" : "&#10133; Nova Promoção" %></h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<div class="card" style="max-width: 600px; margin: 0 auto;">
    <div class="card-header"><h2><%= modoEdicao ? "Editar Dados" : "Criar Promoção" %></h2></div>
    <form method="post" action="admin_promocao_form.jsp<%= modoEdicao ? "?id=" + promoId : "" %>">
        <div class="form-group">
            <label for="descricao">Descrição: *</label>
            <textarea id="descricao" name="descricao" rows="2" required class="form-control"><%= descricaoPromo %></textarea>
        </div>
        <div class="form-group">
            <label for="id_produto">Produto (opcional - vazio = promoção geral):</label>
            <select id="id_produto" name="id_produto" class="form-control">
                <option value="">-- Promoção Geral --</option>
<%
    try {
        if (conn == null) conn = getConnection();
        pstmt = conn.prepareStatement("SELECT id, nome FROM produtos WHERE ativo = 1 ORDER BY nome");
        rs = pstmt.executeQuery();
        while (rs.next()) {
%>
                <option value="<%= rs.getInt("id") %>" <%= rs.getInt("id") == idProduto ? "selected" : "" %>>
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
            <label for="percentagem_desconto">Percentagem de Desconto (%): *</label>
            <input type="number" id="percentagem_desconto" name="percentagem_desconto" 
                value="<%= percentagem %>" min="1" max="100" required class="form-control">
        </div>
        <div class="grid-2">
            <div class="form-group">
                <label for="data_inicio">Data de Início: *</label>
                <input type="date" id="data_inicio" name="data_inicio" value="<%= dataInicio %>" required class="form-control">
            </div>
            <div class="form-group">
                <label for="data_fim">Data de Fim: *</label>
                <input type="date" id="data_fim" name="data_fim" value="<%= dataFim %>" required class="form-control">
            </div>
        </div>
        <div class="btn-group">
            <button type="submit" class="btn btn-primary"><%= modoEdicao ? "Guardar Alterações" : "Criar Promoção" %></button>
            <a href="admin_promocoes.jsp" class="btn btn-secondary">Cancelar</a>
        </div>
    </form>
</div>

<%@ include file="footer.jsp" %>
