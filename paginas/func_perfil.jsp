<%-- =========================================================================
  func_perfil.jsp - Perfil do Funcionario
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Permite ao funcionario visualizar e editar os seus dados
             pessoais (nome, email, morada, telefone) e alterar a password.
             Acessivel a funcionarios e administradores.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.security.MessageDigest" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "funcionario"; %>
<%@ include file="auth_check.jsp" %>

<%
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    String mensagem = null;
    String tipoMensagem = null;
    int userId = (Integer) session.getAttribute("user_id");
    
    // Processar edicao
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String acao = request.getParameter("acao");
        
        try {
            conn = getConnection();
            
            if ("editar_dados".equals(acao)) {
                String nome = request.getParameter("nome");
                String email = request.getParameter("email");
                String morada = request.getParameter("morada");
                String telefone = request.getParameter("telefone");
                
                if (nome == null || nome.trim().isEmpty() || email == null || email.trim().isEmpty()) {
                    mensagem = "Nome e email são obrigatórios.";
                    tipoMensagem = "error";
                } else {
                    // Verificar email unico
                    pstmt = conn.prepareStatement("SELECT id FROM utilizadores WHERE email = ? AND id != ?");
                    pstmt.setString(1, email.trim());
                    pstmt.setInt(2, userId);
                    rs = pstmt.executeQuery();
                    if (rs.next()) {
                        mensagem = "Este email já está em uso por outro utilizador.";
                        tipoMensagem = "error";
                    } else {
                        rs.close(); pstmt.close();
                        pstmt = conn.prepareStatement(
                            "UPDATE utilizadores SET nome=?, email=?, morada=?, telefone=? WHERE id=?"
                        );
                        pstmt.setString(1, nome.trim());
                        pstmt.setString(2, email.trim());
                        pstmt.setString(3, morada != null ? morada.trim() : null);
                        pstmt.setString(4, telefone != null ? telefone.trim() : null);
                        pstmt.setInt(5, userId);
                        pstmt.executeUpdate();
                        
                        session.setAttribute("nome", nome.trim());
                        session.setAttribute("email", email.trim());
                        mensagem = "Dados atualizados com sucesso!";
                        tipoMensagem = "success";
                    }
                    if (rs != null && !rs.isClosed()) rs.close();
                    pstmt.close();
                }
            } else if ("alterar_password".equals(acao)) {
                String passAtual = request.getParameter("password_atual");
                String passNova = request.getParameter("password_nova");
                String passConfirm = request.getParameter("password_confirmar");
                
                if (passAtual == null || passNova == null || passConfirm == null ||
                    passAtual.isEmpty() || passNova.isEmpty() || passConfirm.isEmpty()) {
                    mensagem = "Todos os campos de password são obrigatórios.";
                    tipoMensagem = "error";
                } else if (!passNova.equals(passConfirm)) {
                    mensagem = "A nova password e a confirmação não coincidem.";
                    tipoMensagem = "error";
                } else if (passNova.length() < 4) {
                    mensagem = "A nova password deve ter pelo menos 4 caracteres.";
                    tipoMensagem = "error";
                } else {
                    MessageDigest md = MessageDigest.getInstance("SHA-256");
                    byte[] hashAtual = md.digest(passAtual.getBytes("UTF-8"));
                    StringBuilder sbAtual = new StringBuilder();
                    for (byte b : hashAtual) sbAtual.append(String.format("%02x", b));
                    
                    pstmt = conn.prepareStatement("SELECT password_hash FROM utilizadores WHERE id = ?");
                    pstmt.setInt(1, userId);
                    rs = pstmt.executeQuery();
                    if (rs.next() && rs.getString("password_hash").equals(sbAtual.toString())) {
                        rs.close(); pstmt.close();
                        
                        md.reset();
                        byte[] hashNova = md.digest(passNova.getBytes("UTF-8"));
                        StringBuilder sbNova = new StringBuilder();
                        for (byte b : hashNova) sbNova.append(String.format("%02x", b));
                        
                        pstmt = conn.prepareStatement("UPDATE utilizadores SET password_hash = ? WHERE id = ?");
                        pstmt.setString(1, sbNova.toString());
                        pstmt.setInt(2, userId);
                        pstmt.executeUpdate();
                        
                        mensagem = "Password alterada com sucesso!";
                        tipoMensagem = "success";
                    } else {
                        mensagem = "A password atual está incorreta.";
                        tipoMensagem = "error";
                    }
                    if (rs != null && !rs.isClosed()) rs.close();
                    pstmt.close();
                }
            }
            
            fecharConexao(conn);
            conn = null;
        } catch (Exception e) {
            mensagem = "Erro: " + e.getMessage();
            tipoMensagem = "error";
            if (conn != null) fecharConexao(conn);
            conn = null;
        }
    }
    
    // Carregar dados atuais
    String nome = "", email = "", username = "", morada = "", telefone = "";
    try {
        conn = getConnection();
        pstmt = conn.prepareStatement("SELECT * FROM utilizadores WHERE id = ?");
        pstmt.setInt(1, userId);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            nome = rs.getString("nome");
            email = rs.getString("email");
            username = rs.getString("username");
            morada = rs.getString("morada") != null ? rs.getString("morada") : "";
            telefone = rs.getString("telefone") != null ? rs.getString("telefone") : "";
        }
    } catch (Exception e) {
        mensagem = "Erro ao carregar dados: " + e.getMessage();
        tipoMensagem = "error";
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#128221; Meu Perfil</h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<div class="grid-2">
    <%-- Dados pessoais --%>
    <div class="card">
        <div class="card-header"><h2>Dados Pessoais</h2></div>
        <form method="post" action="func_perfil.jsp">
            <input type="hidden" name="acao" value="editar_dados">
            <div class="form-group">
                <label for="username">Username:</label>
                <input type="text" id="username" value="<%= username %>" disabled class="form-control">
                <small class="text-muted">O username não pode ser alterado.</small>
            </div>
            <div class="form-group">
                <label for="nome">Nome Completo: *</label>
                <input type="text" id="nome" name="nome" value="<%= nome %>" required class="form-control">
            </div>
            <div class="form-group">
                <label for="email">Email: *</label>
                <input type="email" id="email" name="email" value="<%= email %>" required class="form-control">
            </div>
            <div class="form-group">
                <label for="morada">Morada:</label>
                <input type="text" id="morada" name="morada" value="<%= morada %>" class="form-control">
            </div>
            <div class="form-group">
                <label for="telefone">Telefone:</label>
                <input type="text" id="telefone" name="telefone" value="<%= telefone %>" class="form-control">
            </div>
            <button type="submit" class="btn btn-primary">Guardar Alterações</button>
        </form>
    </div>

    <%-- Alterar password --%>
    <div class="card">
        <div class="card-header"><h2>Alterar Password</h2></div>
        <form method="post" action="func_perfil.jsp">
            <input type="hidden" name="acao" value="alterar_password">
            <div class="form-group">
                <label for="password_atual">Password Atual: *</label>
                <input type="password" id="password_atual" name="password_atual" required class="form-control">
            </div>
            <div class="form-group">
                <label for="password_nova">Nova Password: *</label>
                <input type="password" id="password_nova" name="password_nova" required minlength="4" class="form-control">
            </div>
            <div class="form-group">
                <label for="password_confirmar">Confirmar Nova Password: *</label>
                <input type="password" id="password_confirmar" name="password_confirmar" required class="form-control">
            </div>
            <button type="submit" class="btn btn-primary">Alterar Password</button>
        </form>
    </div>
</div>

<div class="text-center" style="margin-top:20px;">
    <a href="func_dashboard.jsp" class="btn btn-secondary">&larr; Voltar ao Painel</a>
</div>

<%@ include file="footer.jsp" %>
