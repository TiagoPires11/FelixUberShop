<%-- =========================================================================
  admin_utilizador_form.jsp - Formulario de Utilizador (Admin)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Formulario para criar ou editar utilizadores. Permite definir
             nome, email, username, password, perfil e estado ativo.
             Ao criar um cliente, cria automaticamente a sua carteira.
             Acessivel apenas a administradores.
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
    
    // Determinar se e edicao ou criacao
    String idParam = request.getParameter("id");
    boolean modoEdicao = (idParam != null && !idParam.isEmpty());
    int userId = modoEdicao ? Integer.parseInt(idParam) : 0;
    
    // Dados do formulario (valores iniciais)
    String nome = "", email = "", username = "", morada = "", telefone = "";
    String perfil = "cliente";
    int ativo = 1;
    
    // Processar POST
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        nome = request.getParameter("nome");
        email = request.getParameter("email");
        username = request.getParameter("username");
        String password = request.getParameter("password");
        perfil = request.getParameter("perfil");
        morada = request.getParameter("morada");
        telefone = request.getParameter("telefone");
        String ativoStr = request.getParameter("ativo");
        ativo = "1".equals(ativoStr) ? 1 : 0;
        
        if (nome == null || nome.trim().isEmpty() || email == null || email.trim().isEmpty() ||
            username == null || username.trim().isEmpty()) {
            mensagem = "Nome, email e username são obrigatórios.";
            tipoMensagem = "error";
        } else if (!modoEdicao && (password == null || password.isEmpty())) {
            mensagem = "A password é obrigatória ao criar utilizador.";
            tipoMensagem = "error";
        } else {
            try {
                conn = getConnection();
                conn.setAutoCommit(false);
                
                // Verificar username/email unicos
                String sqlCheck = modoEdicao ?
                    "SELECT id FROM utilizadores WHERE (username = ? OR email = ?) AND id != ?" :
                    "SELECT id FROM utilizadores WHERE (username = ? OR email = ?)";
                pstmt = conn.prepareStatement(sqlCheck);
                pstmt.setString(1, username.trim());
                pstmt.setString(2, email.trim());
                if (modoEdicao) pstmt.setInt(3, userId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    conn.rollback();
                    mensagem = "Username ou email já existe!";
                    tipoMensagem = "error";
                } else {
                    rs.close(); pstmt.close();
                    
                    if (modoEdicao) {
                        // Atualizar
                        if (password != null && !password.isEmpty()) {
                            // Com password
                            MessageDigest md = MessageDigest.getInstance("SHA-256");
                            byte[] hash = md.digest(password.getBytes("UTF-8"));
                            StringBuilder sb = new StringBuilder();
                            for (byte b : hash) sb.append(String.format("%02x", b));
                            
                            pstmt = conn.prepareStatement(
                                "UPDATE utilizadores SET nome=?, email=?, username=?, password_hash=?, " +
                                "perfil=?, morada=?, telefone=?, ativo=? WHERE id=?"
                            );
                            pstmt.setString(1, nome.trim());
                            pstmt.setString(2, email.trim());
                            pstmt.setString(3, username.trim());
                            pstmt.setString(4, sb.toString());
                            pstmt.setString(5, perfil);
                            pstmt.setString(6, morada != null ? morada.trim() : null);
                            pstmt.setString(7, telefone != null ? telefone.trim() : null);
                            pstmt.setInt(8, ativo);
                            pstmt.setInt(9, userId);
                        } else {
                            // Sem password
                            pstmt = conn.prepareStatement(
                                "UPDATE utilizadores SET nome=?, email=?, username=?, " +
                                "perfil=?, morada=?, telefone=?, ativo=? WHERE id=?"
                            );
                            pstmt.setString(1, nome.trim());
                            pstmt.setString(2, email.trim());
                            pstmt.setString(3, username.trim());
                            pstmt.setString(4, perfil);
                            pstmt.setString(5, morada != null ? morada.trim() : null);
                            pstmt.setString(6, telefone != null ? telefone.trim() : null);
                            pstmt.setInt(7, ativo);
                            pstmt.setInt(8, userId);
                        }
                        pstmt.executeUpdate(); pstmt.close();
                        conn.commit();
                        mensagem = "Utilizador atualizado com sucesso!";
                        tipoMensagem = "success";
                    } else {
                        // Criar novo
                        MessageDigest md = MessageDigest.getInstance("SHA-256");
                        byte[] hash = md.digest(password.getBytes("UTF-8"));
                        StringBuilder sb = new StringBuilder();
                        for (byte b : hash) sb.append(String.format("%02x", b));
                        
                        pstmt = conn.prepareStatement(
                            "INSERT INTO utilizadores (nome, email, username, password_hash, perfil, morada, telefone, ativo) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                            Statement.RETURN_GENERATED_KEYS
                        );
                        pstmt.setString(1, nome.trim());
                        pstmt.setString(2, email.trim());
                        pstmt.setString(3, username.trim());
                        pstmt.setString(4, sb.toString());
                        pstmt.setString(5, perfil);
                        pstmt.setString(6, morada != null ? morada.trim() : null);
                        pstmt.setString(7, telefone != null ? telefone.trim() : null);
                        pstmt.setInt(8, ativo);
                        pstmt.executeUpdate();
                        
                        // Criar carteira se for cliente
                        if ("cliente".equals(perfil)) {
                            rs = pstmt.getGeneratedKeys();
                            if (rs.next()) {
                                int novoId = rs.getInt(1);
                                rs.close(); pstmt.close();
                                pstmt = conn.prepareStatement(
                                    "INSERT INTO carteiras (id_utilizador, tipo, saldo) VALUES (?, 'cliente', 0.00)"
                                );
                                pstmt.setInt(1, novoId);
                                pstmt.executeUpdate();
                            }
                        }
                        pstmt.close();
                        conn.commit();
                        
                        mensagem = "Utilizador criado com sucesso!";
                        tipoMensagem = "success";
                        // Limpar campos
                        nome = ""; email = ""; username = ""; morada = ""; telefone = "";
                        perfil = "cliente"; ativo = 1;
                        modoEdicao = false;
                    }
                }
                if (rs != null && !rs.isClosed()) rs.close();
                conn.setAutoCommit(true);
                fecharConexao(conn); conn = null;
            } catch (Exception e) {
                mensagem = "Erro: " + e.getMessage();
                tipoMensagem = "error";
                if (conn != null) { try { conn.rollback(); } catch(Exception ex){} fecharConexao(conn); conn = null; }
            }
        }
    }
    
    // Carregar dados para edicao
    if (modoEdicao && "GET".equalsIgnoreCase(request.getMethod())) {
        try {
            conn = getConnection();
            pstmt = conn.prepareStatement("SELECT * FROM utilizadores WHERE id = ?");
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                nome = rs.getString("nome");
                email = rs.getString("email");
                username = rs.getString("username");
                perfil = rs.getString("perfil");
                morada = rs.getString("morada") != null ? rs.getString("morada") : "";
                telefone = rs.getString("telefone") != null ? rs.getString("telefone") : "";
                ativo = rs.getInt("ativo");
            }
        } catch (Exception e) {
            mensagem = "Erro: " + e.getMessage();
            tipoMensagem = "error";
        } finally {
            fecharRecursos(rs, pstmt, conn);
        }
    }
%>

<%@ include file="header.jsp" %>

<h1 class="page-title"><%= modoEdicao ? "&#9999; Editar Utilizador" : "&#10133; Novo Utilizador" %></h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<div class="card" style="max-width: 600px; margin: 0 auto;">
    <div class="card-header"><h2><%= modoEdicao ? "Editar Dados" : "Criar Utilizador" %></h2></div>
    <form method="post" action="admin_utilizador_form.jsp<%= modoEdicao ? "?id=" + userId : "" %>">
        <div class="form-group">
            <label for="nome">Nome Completo: *</label>
            <input type="text" id="nome" name="nome" value="<%= nome %>" required class="form-control">
        </div>
        <div class="form-group">
            <label for="email">Email: *</label>
            <input type="email" id="email" name="email" value="<%= email %>" required class="form-control">
        </div>
        <div class="form-group">
            <label for="username">Username: *</label>
            <input type="text" id="username" name="username" value="<%= username %>" 
                <%= modoEdicao ? "" : "required" %> class="form-control">
        </div>
        <div class="form-group">
            <label for="password">Password: <%= modoEdicao ? "(deixar vazio para manter)" : "*" %></label>
            <input type="password" id="password" name="password" 
                <%= modoEdicao ? "" : "required" %> class="form-control">
        </div>
        <div class="grid-2">
            <div class="form-group">
                <label for="perfil">Perfil: *</label>
                <select id="perfil" name="perfil" class="form-control" required>
                    <option value="cliente" <%= "cliente".equals(perfil) ? "selected" : "" %>>Cliente</option>
                    <option value="funcionario" <%= "funcionario".equals(perfil) ? "selected" : "" %>>Funcionário</option>
                    <option value="admin" <%= "admin".equals(perfil) ? "selected" : "" %>>Administrador</option>
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
            <label for="morada">Morada:</label>
            <input type="text" id="morada" name="morada" value="<%= morada %>" class="form-control">
        </div>
        <div class="form-group">
            <label for="telefone">Telefone:</label>
            <input type="text" id="telefone" name="telefone" value="<%= telefone %>" class="form-control">
        </div>
        <div class="btn-group">
            <button type="submit" class="btn btn-primary"><%= modoEdicao ? "Guardar Alterações" : "Criar Utilizador" %></button>
            <a href="admin_utilizadores.jsp" class="btn btn-secondary">Cancelar</a>
        </div>
    </form>
</div>

<%@ include file="footer.jsp" %>
