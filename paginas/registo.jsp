<%-- =========================================================================
  registo.jsp - Pagina de Registo de Novo Cliente
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Formulario de registo para novos clientes. Cria o utilizador
             na base de dados com perfil 'cliente', password em SHA-256,
             e cria automaticamente uma carteira com saldo 0. Apos registo
             bem-sucedido, redireciona para o login.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<%@ page import="java.security.MessageDigest" %>

<%
    // -------------------------------------------------------------------
    // Se ja esta logado, redirecionar para a dashboard
    // -------------------------------------------------------------------
    if (session.getAttribute("username") != null) {
        response.sendRedirect("cliente_dashboard.jsp");
        return;
    }

    String erro = null;
    String nome = "";
    String email = "";
    String username = "";
    String morada = "";
    String telefone = "";

    // -------------------------------------------------------------------
    // Processar o formulario de registo (POST)
    // -------------------------------------------------------------------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        nome = request.getParameter("nome") != null ? request.getParameter("nome").trim() : "";
        email = request.getParameter("email") != null ? request.getParameter("email").trim() : "";
        username = request.getParameter("username") != null ? request.getParameter("username").trim() : "";
        String password = request.getParameter("password");
        String password2 = request.getParameter("password2");
        morada = request.getParameter("morada") != null ? request.getParameter("morada").trim() : "";
        telefone = request.getParameter("telefone") != null ? request.getParameter("telefone").trim() : "";
        
        // Validacoes do lado do servidor
        if (nome.isEmpty() || email.isEmpty() || username.isEmpty() || 
            password == null || password.isEmpty()) {
            erro = "Por favor, preencha todos os campos obrigatórios.";
        } else if (password.length() < 4) {
            erro = "A password deve ter pelo menos 4 caracteres.";
        } else if (!password.equals(password2)) {
            erro = "As passwords não coincidem.";
        } else if (username.length() < 3) {
            erro = "O nome de utilizador deve ter pelo menos 3 caracteres.";
        } else {
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            
            try {
                conn = getConnection();
                conn.setAutoCommit(false); // Iniciar transacao
                
                // Verificar se o username ja existe
                pstmt = conn.prepareStatement("SELECT id FROM utilizadores WHERE username = ?");
                pstmt.setString(1, username);
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    erro = "Este nome de utilizador já está em uso.";
                    rs.close();
                    pstmt.close();
                    conn.rollback();
                } else {
                    rs.close();
                    pstmt.close();
                    
                    // Verificar se o email ja existe
                    pstmt = conn.prepareStatement("SELECT id FROM utilizadores WHERE email = ?");
                    pstmt.setString(1, email);
                    rs = pstmt.executeQuery();
                    if (rs.next()) {
                        erro = "Este email já está registado.";
                        rs.close();
                        pstmt.close();
                        conn.rollback();
                    } else {
                        rs.close();
                        pstmt.close();
                        
                        // Calcular hash SHA-256 da password
                        MessageDigest md = MessageDigest.getInstance("SHA-256");
                        byte[] hash = md.digest(password.getBytes("UTF-8"));
                        StringBuilder sb = new StringBuilder();
                        for (byte b : hash) {
                            sb.append(String.format("%02x", b));
                        }
                        String passwordHash = sb.toString();
                        
                        // Inserir novo utilizador com perfil 'cliente'
                        pstmt = conn.prepareStatement(
                            "INSERT INTO utilizadores (nome, email, username, password, morada, telefone, perfil, ativo) " +
                            "VALUES (?, ?, ?, ?, ?, ?, 'cliente', 1)",
                            Statement.RETURN_GENERATED_KEYS
                        );
                        pstmt.setString(1, nome);
                        pstmt.setString(2, email);
                        pstmt.setString(3, username);
                        pstmt.setString(4, passwordHash);
                        pstmt.setString(5, morada.isEmpty() ? null : morada);
                        pstmt.setString(6, telefone.isEmpty() ? null : telefone);
                        pstmt.executeUpdate();
                        
                        // Obter o ID do novo utilizador
                        rs = pstmt.getGeneratedKeys();
                        int novoId = 0;
                        if (rs.next()) {
                            novoId = rs.getInt(1);
                        }
                        rs.close();
                        pstmt.close();
                        
                        // Criar carteira para o novo cliente (saldo = 0)
                        pstmt = conn.prepareStatement(
                            "INSERT INTO carteiras (id_utilizador, saldo, tipo) VALUES (?, 0.00, 'cliente')"
                        );
                        pstmt.setInt(1, novoId);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        conn.commit(); // Confirmar transacao
                        
                        // Redirecionar para login com mensagem de sucesso
                        session.setAttribute("mensagem_sucesso", 
                            "Registo efetuado com sucesso! Pode agora iniciar sessão.");
                        response.sendRedirect("login.jsp");
                        return;
                    }
                }
            } catch (Exception e) {
                try { if (conn != null) conn.rollback(); } catch (Exception ex) {}
                erro = "Erro ao efetuar registo: " + e.getMessage();
            } finally {
                fecharRecursos(rs, pstmt, conn);
            }
        }
    }
%>

<%@ include file="header.jsp" %>

<div class="form-login" style="max-width: 500px;">
    <div class="card">
        <div class="card-header">
            <h2>&#128221; Registar Nova Conta</h2>
        </div>
        
        <% if (erro != null) { %>
            <div class="alert alert-error"><%= erro %></div>
        <% } %>
        
        <form method="post" action="registo.jsp" onsubmit="return validarFormRegisto();">
            <div class="form-group">
                <label for="nome">Nome Completo: *</label>
                <input type="text" id="nome" name="nome" 
                       value="<%= nome %>" placeholder="O seu nome completo" required>
            </div>
            <div class="form-group">
                <label for="email">Email: *</label>
                <input type="email" id="email" name="email" 
                       value="<%= email %>" placeholder="email@exemplo.pt" required>
            </div>
            <div class="form-group">
                <label for="username">Nome de Utilizador: *</label>
                <input type="text" id="username" name="username" 
                       value="<%= username %>" placeholder="Mínimo 3 caracteres" required>
            </div>
            <div class="form-group">
                <label for="password">Password: *</label>
                <input type="password" id="password" name="password" 
                       placeholder="Mínimo 4 caracteres" required>
            </div>
            <div class="form-group">
                <label for="password2">Confirmar Password: *</label>
                <input type="password" id="password2" name="password2" 
                       placeholder="Repita a password" required>
            </div>
            <div class="form-group">
                <label for="morada">Morada:</label>
                <input type="text" id="morada" name="morada" 
                       value="<%= morada %>" placeholder="A sua morada (opcional)">
            </div>
            <div class="form-group">
                <label for="telefone">Telefone:</label>
                <input type="text" id="telefone" name="telefone" 
                       value="<%= telefone %>" placeholder="O seu telefone (opcional)">
            </div>
            <div class="form-group">
                <button type="submit" class="btn btn-primary btn-block">Registar</button>
            </div>
        </form>
        
        <p class="text-center">
            Já tem conta? <a href="login.jsp">Iniciar sessão aqui</a>
        </p>
    </div>
</div>

<script src="scripts.js"></script>
<%@ include file="footer.jsp" %>
