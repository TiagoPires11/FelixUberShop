<%-- =========================================================================
  cliente_perfil.jsp - Perfil do Cliente (Consultar e Editar)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Permite ao cliente consultar e editar os seus dados pessoais
             (nome, email, morada, telefone). A password pode ser alterada
             opcionalmente. Os dados sao carregados da BD e atualizados
             via formulario POST.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<%@ page import="java.security.MessageDigest" %>
<% String perfilNecessario = "cliente"; %>
<%@ include file="auth_check.jsp" %>

<%
    int userId = (Integer) session.getAttribute("user_id");
    String erro = null;
    String sucesso = null;
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Variaveis para os dados do formulario
    String nome = "";
    String email = "";
    String morada = "";
    String telefone = "";
    
    try {
        conn = getConnection();
        
        // -------------------------------------------------------------------
        // Processar atualizacao de perfil (POST)
        // -------------------------------------------------------------------
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            nome = request.getParameter("nome") != null ? request.getParameter("nome").trim() : "";
            email = request.getParameter("email") != null ? request.getParameter("email").trim() : "";
            morada = request.getParameter("morada") != null ? request.getParameter("morada").trim() : "";
            telefone = request.getParameter("telefone") != null ? request.getParameter("telefone").trim() : "";
            String novaPassword = request.getParameter("nova_password");
            String confirmarPassword = request.getParameter("confirmar_password");
            
            if (nome.isEmpty() || email.isEmpty()) {
                erro = "Nome e email são obrigatórios.";
            } else {
                // Verificar se o email ja esta em uso por outro utilizador
                pstmt = conn.prepareStatement("SELECT id FROM utilizadores WHERE email = ? AND id != ?");
                pstmt.setString(1, email);
                pstmt.setInt(2, userId);
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    erro = "Este email já está em uso por outro utilizador.";
                } else {
                    // Atualizar dados basicos
                    if (novaPassword != null && !novaPassword.isEmpty()) {
                        // Atualizar COM nova password
                        if (novaPassword.length() < 4) {
                            erro = "A nova password deve ter pelo menos 4 caracteres.";
                        } else if (!novaPassword.equals(confirmarPassword)) {
                            erro = "As passwords não coincidem.";
                        } else {
                            // Calcular hash SHA-256
                            MessageDigest md = MessageDigest.getInstance("SHA-256");
                            byte[] hash = md.digest(novaPassword.getBytes("UTF-8"));
                            StringBuilder sb = new StringBuilder();
                            for (byte b : hash) {
                                sb.append(String.format("%02x", b));
                            }
                            
                            pstmt = conn.prepareStatement(
                                "UPDATE utilizadores SET nome=?, email=?, morada=?, telefone=?, password=? WHERE id=?"
                            );
                            pstmt.setString(1, nome);
                            pstmt.setString(2, email);
                            pstmt.setString(3, morada.isEmpty() ? null : morada);
                            pstmt.setString(4, telefone.isEmpty() ? null : telefone);
                            pstmt.setString(5, sb.toString());
                            pstmt.setInt(6, userId);
                            pstmt.executeUpdate();
                            pstmt.close();
                            
                            sucesso = "Dados e password atualizados com sucesso!";
                            session.setAttribute("nome", nome);
                            session.setAttribute("email", email);
                        }
                    } else {
                        // Atualizar SEM alterar password
                        pstmt = conn.prepareStatement(
                            "UPDATE utilizadores SET nome=?, email=?, morada=?, telefone=? WHERE id=?"
                        );
                        pstmt.setString(1, nome);
                        pstmt.setString(2, email);
                        pstmt.setString(3, morada.isEmpty() ? null : morada);
                        pstmt.setString(4, telefone.isEmpty() ? null : telefone);
                        pstmt.setInt(5, userId);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        sucesso = "Dados atualizados com sucesso!";
                        session.setAttribute("nome", nome);
                        session.setAttribute("email", email);
                    }
                }
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
            }
        }
        
        // -------------------------------------------------------------------
        // Carregar dados atuais do utilizador (para GET ou apos erro)
        // -------------------------------------------------------------------
        if (erro != null || !"POST".equalsIgnoreCase(request.getMethod())) {
            pstmt = conn.prepareStatement("SELECT nome, email, morada, telefone FROM utilizadores WHERE id = ?");
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                nome = rs.getString("nome") != null ? rs.getString("nome") : "";
                email = rs.getString("email") != null ? rs.getString("email") : "";
                morada = rs.getString("morada") != null ? rs.getString("morada") : "";
                telefone = rs.getString("telefone") != null ? rs.getString("telefone") : "";
            }
            rs.close();
            pstmt.close();
        }
        
    } catch (Exception e) {
        erro = "Erro ao processar perfil: " + e.getMessage();
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#128221; Meu Perfil</h1>

<div class="form-login" style="max-width: 500px;">
    <div class="card">
        <% if (erro != null) { %>
            <div class="alert alert-error"><%= erro %></div>
        <% } %>
        <% if (sucesso != null) { %>
            <div class="alert alert-success"><%= sucesso %></div>
        <% } %>
        
        <form method="post" action="cliente_perfil.jsp">
            <div class="form-group">
                <label for="nome">Nome Completo: *</label>
                <input type="text" id="nome" name="nome" value="<%= nome %>" required>
            </div>
            <div class="form-group">
                <label for="email">Email: *</label>
                <input type="email" id="email" name="email" value="<%= email %>" required>
            </div>
            <div class="form-group">
                <label for="morada">Morada:</label>
                <input type="text" id="morada" name="morada" value="<%= morada %>">
            </div>
            <div class="form-group">
                <label for="telefone">Telefone:</label>
                <input type="text" id="telefone" name="telefone" value="<%= telefone %>">
            </div>
            
            <hr style="margin: 20px 0;">
            <p class="text-muted mb-10">Alterar password (deixe em branco para manter a atual):</p>
            
            <div class="form-group">
                <label for="nova_password">Nova Password:</label>
                <input type="password" id="nova_password" name="nova_password" placeholder="Mínimo 4 caracteres">
            </div>
            <div class="form-group">
                <label for="confirmar_password">Confirmar Nova Password:</label>
                <input type="password" id="confirmar_password" name="confirmar_password">
            </div>
            
            <div class="btn-group">
                <button type="submit" class="btn btn-primary">Guardar Alterações</button>
                <a href="cliente_dashboard.jsp" class="btn btn-secondary">Voltar</a>
            </div>
        </form>
    </div>
</div>

<%@ include file="footer.jsp" %>
