<%-- =========================================================================
  login.jsp - Pagina de Login
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Formulario de autenticacao de utilizadores. Valida as
             credenciais contra a base de dados (password em SHA-256).
             Cria uma sessao com os dados do utilizador apos login
             bem-sucedido e redireciona conforme o perfil.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.math.BigInteger" %>

<%
    // -------------------------------------------------------------------
    // Se o utilizador ja esta logado, redirecionar para a pagina adequada
    // -------------------------------------------------------------------
    if (session.getAttribute("username") != null) {
        String perfil = (String) session.getAttribute("perfil");
        if ("admin".equals(perfil)) {
            response.sendRedirect("admin_dashboard.jsp");
        } else if ("funcionario".equals(perfil)) {
            response.sendRedirect("func_dashboard.jsp");
        } else {
            response.sendRedirect("cliente_dashboard.jsp");
        }
        return;
    }

    // -------------------------------------------------------------------
    // Processar o formulario de login (se foi submetido via POST)
    // -------------------------------------------------------------------
    String erro = null;
    String sucesso = null;
    
    // Verificar se existe mensagem da sessao (ex: de auth_check ou registo)
    if (session.getAttribute("mensagem_erro") != null) {
        erro = (String) session.getAttribute("mensagem_erro");
        session.removeAttribute("mensagem_erro");
    }
    if (session.getAttribute("mensagem_sucesso") != null) {
        sucesso = (String) session.getAttribute("mensagem_sucesso");
        session.removeAttribute("mensagem_sucesso");
    }
    
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        
        if (username != null && password != null && 
            !username.trim().isEmpty() && !password.trim().isEmpty()) {
            
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            
            try {
                conn = getConnection();
                
                // Calcular hash SHA-256 da password introduzida
                MessageDigest md = MessageDigest.getInstance("SHA-256");
                byte[] hash = md.digest(password.getBytes("UTF-8"));
                StringBuilder sb = new StringBuilder();
                for (byte b : hash) {
                    sb.append(String.format("%02x", b));
                }
                String passwordHash = sb.toString();
                
                // Procurar utilizador com username e password correspondentes
                pstmt = conn.prepareStatement(
                    "SELECT id, nome, email, username, perfil " +
                    "FROM utilizadores WHERE username = ? AND password = ? AND ativo = 1"
                );
                pstmt.setString(1, username.trim());
                pstmt.setString(2, passwordHash);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    // Login bem-sucedido: criar sessao com dados do utilizador
                    session.setAttribute("user_id", rs.getInt("id"));
                    session.setAttribute("nome", rs.getString("nome"));
                    session.setAttribute("email", rs.getString("email"));
                    session.setAttribute("username", rs.getString("username"));
                    session.setAttribute("perfil", rs.getString("perfil"));
                    
                    // Redirecionar conforme o perfil
                    String perfil = rs.getString("perfil");
                    if ("admin".equals(perfil)) {
                        response.sendRedirect("admin_dashboard.jsp");
                    } else if ("funcionario".equals(perfil)) {
                        response.sendRedirect("func_dashboard.jsp");
                    } else {
                        response.sendRedirect("cliente_dashboard.jsp");
                    }
                    return;
                } else {
                    // Credenciais invalidas
                    erro = "Nome de utilizador ou password incorretos.";
                }
                
            } catch (Exception e) {
                erro = "Erro ao processar login: " + e.getMessage();
            } finally {
                fecharRecursos(rs, pstmt, conn);
            }
        } else {
            erro = "Por favor, preencha todos os campos.";
        }
    }
%>

<%@ include file="header.jsp" %>

<div class="form-login">
    <div class="card">
        <div class="card-header">
            <h2>&#128274; Iniciar Sessão</h2>
        </div>
        
        <%-- Mensagens de erro ou sucesso --%>
        <% if (erro != null) { %>
            <div class="alert alert-error"><%= erro %></div>
        <% } %>
        <% if (sucesso != null) { %>
            <div class="alert alert-success"><%= sucesso %></div>
        <% } %>
        
        <%-- Formulario de login --%>
        <form method="post" action="login.jsp" onsubmit="return validarFormLogin();">
            <div class="form-group">
                <label for="username">Nome de Utilizador:</label>
                <input type="text" id="username" name="username" 
                       placeholder="Introduza o seu username" required>
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" 
                       placeholder="Introduza a sua password" required>
            </div>
            <div class="form-group">
                <button type="submit" class="btn btn-primary btn-block">Entrar</button>
            </div>
        </form>
        
        <p class="text-center mt-20">
            Não tem conta? <a href="registo.jsp">Registar-se aqui</a>
        </p>
    </div>
</div>

<script src="scripts.js"></script>
<%@ include file="footer.jsp" %>
