<%-- =========================================================================
  admin_utilizadores.jsp - Gestao de Utilizadores (Admin)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: CRUD completo de utilizadores. Lista todos os utilizadores
             com filtros por perfil. Permite criar, editar, ativar/desativar
             e eliminar utilizadores. Acessivel apenas a administradores.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.security.MessageDigest" %>
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
                int uid = Integer.parseInt(request.getParameter("user_id"));
                int ativo = Integer.parseInt(request.getParameter("ativo"));
                pstmt = conn.prepareStatement("UPDATE utilizadores SET ativo = ? WHERE id = ?");
                pstmt.setInt(1, ativo == 1 ? 0 : 1);
                pstmt.setInt(2, uid);
                pstmt.executeUpdate();
                pstmt.close();
                mensagem = "Estado do utilizador alterado com sucesso!";
                tipoMensagem = "success";
                
            } else if ("eliminar".equals(acao)) {
                int uid = Integer.parseInt(request.getParameter("user_id"));
                int adminId = (Integer) session.getAttribute("user_id");
                
                if (uid == adminId) {
                    mensagem = "Não pode eliminar a sua própria conta!";
                    tipoMensagem = "error";
                } else {
                    // Verificar se tem encomendas
                    pstmt = conn.prepareStatement("SELECT COUNT(*) AS t FROM encomendas WHERE id_cliente = ?");
                    pstmt.setInt(1, uid);
                    rs = pstmt.executeQuery();
                    rs.next();
                    int encCount = rs.getInt("t");
                    rs.close(); pstmt.close();
                    
                    if (encCount > 0) {
                        // Desativar em vez de eliminar
                        pstmt = conn.prepareStatement("UPDATE utilizadores SET ativo = 0 WHERE id = ?");
                        pstmt.setInt(1, uid);
                        pstmt.executeUpdate();
                        pstmt.close();
                        mensagem = "Utilizador desativado (tem encomendas associadas, não pode ser eliminado).";
                        tipoMensagem = "warning";
                    } else {
                        conn.setAutoCommit(false);
                        // Eliminar operacoes de carteira
                        pstmt = conn.prepareStatement(
                            "DELETE FROM operacoes_carteira WHERE id_carteira IN (SELECT id FROM carteiras WHERE id_utilizador = ?)"
                        );
                        pstmt.setInt(1, uid);
                        pstmt.executeUpdate(); pstmt.close();
                        // Eliminar carteira
                        pstmt = conn.prepareStatement("DELETE FROM carteiras WHERE id_utilizador = ?");
                        pstmt.setInt(1, uid);
                        pstmt.executeUpdate(); pstmt.close();
                        // Eliminar utilizador
                        pstmt = conn.prepareStatement("DELETE FROM utilizadores WHERE id = ?");
                        pstmt.setInt(1, uid);
                        pstmt.executeUpdate(); pstmt.close();
                        conn.commit();
                        conn.setAutoCommit(true);
                        mensagem = "Utilizador eliminado com sucesso!";
                        tipoMensagem = "success";
                    }
                }
            }
            
            fecharConexao(conn); conn = null;
        } catch (Exception e) {
            mensagem = "Erro: " + e.getMessage();
            tipoMensagem = "error";
            if (conn != null) { try { conn.rollback(); } catch(Exception ex){} fecharConexao(conn); conn = null; }
        }
    }
    
    // Filtros
    String filtroPerfil = request.getParameter("perfil");
    if (filtroPerfil == null) filtroPerfil = "";
    String pesquisa = request.getParameter("pesquisa");
    if (pesquisa == null) pesquisa = "";
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#128101; Gestão de Utilizadores</h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<%-- Filtros + botao criar --%>
<div class="card">
    <div class="card-header">
        <h2>Filtrar</h2>
        <a href="admin_utilizador_form.jsp" class="btn btn-success" style="float:right; margin-top:-35px;">+ Novo Utilizador</a>
    </div>
    <form method="get" action="admin_utilizadores.jsp" class="form-inline">
        <div class="grid-3">
            <div class="form-group">
                <label for="perfil">Perfil:</label>
                <select name="perfil" id="perfil" class="form-control">
                    <option value="">-- Todos --</option>
                    <option value="cliente" <%= "cliente".equals(filtroPerfil) ? "selected" : "" %>>Cliente</option>
                    <option value="funcionario" <%= "funcionario".equals(filtroPerfil) ? "selected" : "" %>>Funcionário</option>
                    <option value="admin" <%= "admin".equals(filtroPerfil) ? "selected" : "" %>>Admin</option>
                </select>
            </div>
            <div class="form-group">
                <label for="pesquisa">Nome / Username:</label>
                <input type="text" name="pesquisa" id="pesquisa" value="<%= pesquisa %>" class="form-control">
            </div>
            <div class="form-group" style="display:flex; align-items:flex-end;">
                <button type="submit" class="btn btn-primary">&#128269; Filtrar</button>
                &nbsp;<a href="admin_utilizadores.jsp" class="btn btn-secondary">Limpar</a>
            </div>
        </div>
    </form>
</div>

<%-- Lista --%>
<div class="card">
    <div class="card-header"><h2>Utilizadores</h2></div>
<%
    try {
        conn = getConnection();
        StringBuilder sql = new StringBuilder(
            "SELECT id, nome, username, email, perfil, ativo, data_registo FROM utilizadores WHERE 1=1 "
        );
        java.util.List<String> params = new java.util.ArrayList<>();
        if (!filtroPerfil.isEmpty()) { sql.append("AND perfil = ? "); params.add(filtroPerfil); }
        if (!pesquisa.trim().isEmpty()) {
            sql.append("AND (nome LIKE ? OR username LIKE ?) ");
            params.add("%" + pesquisa.trim() + "%");
            params.add("%" + pesquisa.trim() + "%");
        }
        sql.append("ORDER BY data_registo DESC");
        
        pstmt = conn.prepareStatement(sql.toString());
        for (int i = 0; i < params.size(); i++) pstmt.setString(i + 1, params.get(i));
        rs = pstmt.executeQuery();
        boolean tem = false;
%>
    <table>
        <thead>
            <tr><th>ID</th><th>Nome</th><th>Username</th><th>Email</th><th>Perfil</th><th>Estado</th><th>Registo</th><th>Ações</th></tr>
        </thead>
        <tbody>
<%
        int adminId = (Integer) session.getAttribute("user_id");
        while (rs.next()) {
            tem = true;
            int uid = rs.getInt("id");
            int ativo = rs.getInt("ativo");
            String perfil = rs.getString("perfil");
%>
            <tr<%= ativo == 0 ? " style=\"opacity:0.5;\"" : "" %>>
                <td><%= uid %></td>
                <td><strong><%= rs.getString("nome") %></strong></td>
                <td><%= rs.getString("username") %></td>
                <td><%= rs.getString("email") %></td>
                <td><span class="badge badge-<%= "admin".equals(perfil) ? "cancelada" : "funcionario".equals(perfil) ? "preparacao" : "entregue" %>"><%= perfil %></span></td>
                <td><%= ativo == 1 ? "<span class='badge badge-entregue'>Ativo</span>" : "<span class='badge badge-cancelada'>Inativo</span>" %></td>
                <td><%= rs.getString("data_registo") %></td>
                <td>
                    <a href="admin_utilizador_form.jsp?id=<%= uid %>" class="btn btn-sm btn-info">Editar</a>
<%
            if (uid != adminId) {
%>
                    <form method="post" action="admin_utilizadores.jsp" style="display:inline;">
                        <input type="hidden" name="acao" value="toggle_ativo">
                        <input type="hidden" name="user_id" value="<%= uid %>">
                        <input type="hidden" name="ativo" value="<%= ativo %>">
                        <button type="submit" class="btn btn-sm <%= ativo == 1 ? "btn-warning" : "btn-success" %>">
                            <%= ativo == 1 ? "Desativar" : "Ativar" %>
                        </button>
                    </form>
                    <form method="post" action="admin_utilizadores.jsp" style="display:inline;">
                        <input type="hidden" name="acao" value="eliminar">
                        <input type="hidden" name="user_id" value="<%= uid %>">
                        <button type="submit" class="btn btn-sm btn-danger" 
                            onclick="return confirm('Tem certeza que deseja eliminar este utilizador?');">Eliminar</button>
                    </form>
<%
            }
%>
                </td>
            </tr>
<%
        }
        if (!tem) {
%>
            <tr><td colspan="8" class="text-center text-muted">Nenhum utilizador encontrado.</td></tr>
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
