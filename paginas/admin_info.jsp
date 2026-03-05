<%-- =========================================================================
  admin_info.jsp - Gestao da Info da Mercearia (Admin)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Permite ao administrador editar as informacoes da mercearia
             que aparecem na pagina inicial (nome, localizacao, contactos,
             horario, descricao). Usa a tabela info_mercearia (key-value).
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
    
    // Processar POST
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String acao = request.getParameter("acao");
        
        try {
            conn = getConnection();
            
            if ("atualizar".equals(acao)) {
                String[] chaves = {"nome_mercearia", "localizacao", "contacto_telefone", 
                                  "contacto_email", "horario", "descricao"};
                
                conn.setAutoCommit(false);
                for (String chave : chaves) {
                    String valor = request.getParameter(chave);
                    if (valor != null) {
                        // Verificar se existe
                        pstmt = conn.prepareStatement("SELECT id FROM info_mercearia WHERE chave = ?");
                        pstmt.setString(1, chave);
                        rs = pstmt.executeQuery();
                        
                        if (rs.next()) {
                            rs.close(); pstmt.close();
                            pstmt = conn.prepareStatement("UPDATE info_mercearia SET valor = ? WHERE chave = ?");
                            pstmt.setString(1, valor.trim());
                            pstmt.setString(2, chave);
                        } else {
                            rs.close(); pstmt.close();
                            pstmt = conn.prepareStatement("INSERT INTO info_mercearia (chave, valor) VALUES (?, ?)");
                            pstmt.setString(1, chave);
                            pstmt.setString(2, valor.trim());
                        }
                        pstmt.executeUpdate(); pstmt.close();
                    }
                }
                conn.commit();
                conn.setAutoCommit(true);
                mensagem = "Informações atualizadas com sucesso!";
                tipoMensagem = "success";
            } else if ("adicionar_campo".equals(acao)) {
                String novaChave = request.getParameter("nova_chave");
                String novoValor = request.getParameter("novo_valor");
                
                if (novaChave != null && !novaChave.trim().isEmpty()) {
                    pstmt = conn.prepareStatement(
                        "INSERT INTO info_mercearia (chave, valor) VALUES (?, ?) " +
                        "ON DUPLICATE KEY UPDATE valor = ?"
                    );
                    pstmt.setString(1, novaChave.trim());
                    pstmt.setString(2, novoValor != null ? novoValor.trim() : "");
                    pstmt.setString(3, novoValor != null ? novoValor.trim() : "");
                    pstmt.executeUpdate(); pstmt.close();
                    mensagem = "Campo adicionado com sucesso!";
                    tipoMensagem = "success";
                }
            } else if ("eliminar_campo".equals(acao)) {
                int infoId = Integer.parseInt(request.getParameter("info_id"));
                pstmt = conn.prepareStatement("DELETE FROM info_mercearia WHERE id = ?");
                pstmt.setInt(1, infoId);
                pstmt.executeUpdate(); pstmt.close();
                mensagem = "Campo eliminado!";
                tipoMensagem = "success";
            }
            
            fecharConexao(conn); conn = null;
        } catch (Exception e) {
            mensagem = "Erro: " + e.getMessage();
            tipoMensagem = "error";
            if (conn != null) { try { conn.rollback(); } catch(Exception ex){} fecharConexao(conn); conn = null; }
        }
    }
    
    // Carregar dados
    java.util.Map<String, String> info = new java.util.LinkedHashMap<>();
    java.util.Map<String, Integer> infoIds = new java.util.LinkedHashMap<>();
    try {
        conn = getConnection();
        pstmt = conn.prepareStatement("SELECT id, chave, valor FROM info_mercearia ORDER BY id");
        rs = pstmt.executeQuery();
        while (rs.next()) {
            info.put(rs.getString("chave"), rs.getString("valor"));
            infoIds.put(rs.getString("chave"), rs.getInt("id"));
        }
    } catch (Exception e) {
        if (mensagem == null) { mensagem = "Erro: " + e.getMessage(); tipoMensagem = "error"; }
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#9881; Informações da Mercearia</h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<%-- Formulario principal --%>
<div class="card">
    <div class="card-header"><h2>Editar Informações</h2></div>
    <form method="post" action="admin_info.jsp">
        <input type="hidden" name="acao" value="atualizar">
        <div class="form-group">
            <label for="nome_mercearia">Nome da Mercearia:</label>
            <input type="text" id="nome_mercearia" name="nome_mercearia" 
                value="<%= info.getOrDefault("nome_mercearia", "") %>" class="form-control">
        </div>
        <div class="form-group">
            <label for="localizacao">Localização:</label>
            <input type="text" id="localizacao" name="localizacao" 
                value="<%= info.getOrDefault("localizacao", "") %>" class="form-control">
        </div>
        <div class="grid-2">
            <div class="form-group">
                <label for="contacto_telefone">Telefone:</label>
                <input type="text" id="contacto_telefone" name="contacto_telefone" 
                    value="<%= info.getOrDefault("contacto_telefone", "") %>" class="form-control">
            </div>
            <div class="form-group">
                <label for="contacto_email">Email:</label>
                <input type="text" id="contacto_email" name="contacto_email" 
                    value="<%= info.getOrDefault("contacto_email", "") %>" class="form-control">
            </div>
        </div>
        <div class="form-group">
            <label for="horario">Horário:</label>
            <input type="text" id="horario" name="horario" 
                value="<%= info.getOrDefault("horario", "") %>" class="form-control">
        </div>
        <div class="form-group">
            <label for="descricao">Descrição:</label>
            <textarea id="descricao" name="descricao" rows="4" class="form-control"><%= info.getOrDefault("descricao", "") %></textarea>
        </div>
        <button type="submit" class="btn btn-primary">Guardar Alterações</button>
    </form>
</div>

<%-- Todos os campos --%>
<div class="card">
    <div class="card-header"><h2>Todos os Campos</h2></div>
    <table>
        <thead>
            <tr><th>Chave</th><th>Valor</th><th>Ações</th></tr>
        </thead>
        <tbody>
<%
    for (java.util.Map.Entry<String, String> entry : info.entrySet()) {
%>
            <tr>
                <td><strong><%= entry.getKey() %></strong></td>
                <td><%= entry.getValue() %></td>
                <td>
                    <form method="post" action="admin_info.jsp" style="display:inline;">
                        <input type="hidden" name="acao" value="eliminar_campo">
                        <input type="hidden" name="info_id" value="<%= infoIds.get(entry.getKey()) %>">
                        <button type="submit" class="btn btn-sm btn-danger" onclick="return confirm('Eliminar?');">Eliminar</button>
                    </form>
                </td>
            </tr>
<%
    }
%>
        </tbody>
    </table>
    
    <%-- Adicionar campo --%>
    <div style="margin-top:15px; padding-top:15px; border-top:1px solid #ddd;">
        <h3>Adicionar Campo Personalizado</h3>
        <form method="post" action="admin_info.jsp" class="form-inline">
            <input type="hidden" name="acao" value="adicionar_campo">
            <div class="grid-3">
                <div class="form-group">
                    <label for="nova_chave">Chave:</label>
                    <input type="text" name="nova_chave" id="nova_chave" required class="form-control" placeholder="ex: redes_sociais">
                </div>
                <div class="form-group">
                    <label for="novo_valor">Valor:</label>
                    <input type="text" name="novo_valor" id="novo_valor" class="form-control" placeholder="Valor...">
                </div>
                <div class="form-group" style="display:flex; align-items:flex-end;">
                    <button type="submit" class="btn btn-success">Adicionar</button>
                </div>
            </div>
        </form>
    </div>
</div>

<div class="text-center" style="margin-top:20px;">
    <a href="admin_dashboard.jsp" class="btn btn-secondary">&larr; Voltar ao Painel</a>
</div>

<%@ include file="footer.jsp" %>
