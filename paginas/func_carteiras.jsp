<%-- =========================================================================
  func_carteiras.jsp - Gestao de Carteiras (Funcionario)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Permite ao funcionario visualizar e gerir as carteiras
             dos clientes. Pode consultar saldos, historico de operacoes
             e efetuar depositos/levantamentos nas carteiras dos clientes.
             Acessivel a funcionarios e administradores.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "funcionario"; %>
<%@ include file="auth_check.jsp" %>

<%
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    String mensagem = null;
    String tipoMensagem = null;
    
    // Processar operacao na carteira
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String acao = request.getParameter("acao");
        
        if ("operacao_carteira".equals(acao)) {
            int carteiraId = Integer.parseInt(request.getParameter("carteira_id"));
            String tipo = request.getParameter("tipo_operacao");
            String valorStr = request.getParameter("valor");
            String descricao = request.getParameter("descricao");
            
            try {
                double valor = Double.parseDouble(valorStr);
                if (valor <= 0) throw new Exception("Valor deve ser positivo.");
                if (descricao == null || descricao.trim().isEmpty()) descricao = "Operação pelo funcionário";
                
                conn = getConnection();
                conn.setAutoCommit(false);
                
                // Verificar carteira
                pstmt = conn.prepareStatement("SELECT saldo, id_utilizador FROM carteiras WHERE id = ? FOR UPDATE");
                pstmt.setInt(1, carteiraId);
                rs = pstmt.executeQuery();
                
                if (!rs.next()) {
                    throw new Exception("Carteira não encontrada.");
                }
                
                double saldoAtual = rs.getDouble("saldo");
                rs.close(); pstmt.close();
                
                if ("levantamento".equals(tipo) && saldoAtual < valor) {
                    conn.rollback();
                    mensagem = "Saldo insuficiente! Saldo atual: " + String.format("%.2f", saldoAtual) + " €";
                    tipoMensagem = "error";
                } else {
                    // Atualizar saldo
                    if ("deposito".equals(tipo)) {
                        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id = ?");
                    } else {
                        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id = ?");
                    }
                    pstmt.setDouble(1, valor);
                    pstmt.setInt(2, carteiraId);
                    pstmt.executeUpdate();
                    pstmt.close();
                    
                    // Registar auditoria
                    pstmt = conn.prepareStatement(
                        "INSERT INTO operacoes_carteira (id_carteira, tipo, valor, descricao) VALUES (?, ?, ?, ?)"
                    );
                    pstmt.setInt(1, carteiraId);
                    pstmt.setString(2, tipo);
                    pstmt.setDouble(3, valor);
                    pstmt.setString(4, descricao.trim() + " (por funcionário)");
                    pstmt.executeUpdate();
                    pstmt.close();
                    
                    conn.commit();
                    mensagem = tipo.substring(0,1).toUpperCase() + tipo.substring(1) + 
                              " de " + String.format("%.2f", valor) + " € realizado com sucesso!";
                    tipoMensagem = "success";
                }
                
                conn.setAutoCommit(true);
                fecharConexao(conn);
                conn = null;
            } catch (NumberFormatException nfe) {
                mensagem = "Valor inválido.";
                tipoMensagem = "error";
                if (conn != null) { try { conn.rollback(); } catch(Exception ex){} fecharConexao(conn); conn = null; }
            } catch (Exception e) {
                mensagem = "Erro: " + e.getMessage();
                tipoMensagem = "error";
                if (conn != null) { try { conn.rollback(); } catch(Exception ex){} fecharConexao(conn); conn = null; }
            }
        }
    }
    
    // Filtro pesquisa
    String pesquisa = request.getParameter("pesquisa");
    if (pesquisa == null) pesquisa = "";
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#128176; Gestão de Carteiras</h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<%-- Pesquisa --%>
<div class="card">
    <div class="card-header"><h2>Pesquisar Clientes</h2></div>
    <form method="get" action="func_carteiras.jsp" class="form-inline">
        <div class="grid-2">
            <div class="form-group">
                <label for="pesquisa">Nome ou Username:</label>
                <input type="text" name="pesquisa" id="pesquisa" value="<%= pesquisa %>" 
                    placeholder="Pesquisar..." class="form-control">
            </div>
            <div class="form-group" style="display:flex; align-items:flex-end;">
                <button type="submit" class="btn btn-primary">&#128269; Pesquisar</button>
                &nbsp;<a href="func_carteiras.jsp" class="btn btn-secondary">Limpar</a>
            </div>
        </div>
    </form>
</div>

<%-- Lista de carteiras --%>
<div class="card">
    <div class="card-header"><h2>Carteiras dos Clientes</h2></div>
<%
    try {
        conn = getConnection();
        
        StringBuilder sql = new StringBuilder(
            "SELECT c.id AS carteira_id, c.saldo, u.id AS user_id, u.nome, u.username, u.email " +
            "FROM carteiras c JOIN utilizadores u ON c.id_utilizador = u.id " +
            "WHERE c.tipo = 'cliente' "
        );
        
        if (!pesquisa.trim().isEmpty()) {
            sql.append("AND (u.nome LIKE ? OR u.username LIKE ?) ");
        }
        sql.append("ORDER BY u.nome");
        
        pstmt = conn.prepareStatement(sql.toString());
        if (!pesquisa.trim().isEmpty()) {
            String like = "%" + pesquisa.trim() + "%";
            pstmt.setString(1, like);
            pstmt.setString(2, like);
        }
        rs = pstmt.executeQuery();
        boolean tem = false;
%>
    <table>
        <thead>
            <tr><th>Cliente</th><th>Username</th><th>Email</th><th>Saldo</th><th>Ações</th></tr>
        </thead>
        <tbody>
<%
        while (rs.next()) {
            tem = true;
            int carteiraId = rs.getInt("carteira_id");
            double saldo = rs.getDouble("saldo");
%>
            <tr>
                <td><strong><%= rs.getString("nome") %></strong></td>
                <td><%= rs.getString("username") %></td>
                <td><%= rs.getString("email") %></td>
                <td>
                    <span class="wallet-balance" style="font-size:1.1em;">
                        <%= String.format("%.2f", saldo) %> &euro;
                    </span>
                </td>
                <td>
                    <a href="func_carteira_detalhe.jsp?carteira_id=<%= carteiraId %>" class="btn btn-sm btn-info">Histórico</a>
                    <button class="btn btn-sm btn-success" onclick="mostrarFormCarteira(<%= carteiraId %>, '<%= rs.getString("nome").replace("'", "\\'") %>')">Operação</button>
                </td>
            </tr>
<%
        }
        if (!tem) {
%>
            <tr><td colspan="5" class="text-center text-muted">Nenhuma carteira encontrada.</td></tr>
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

<%-- Modal de operacao (via JS) --%>
<div id="modalCarteira" class="card" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); z-index:1000; width:400px; box-shadow:0 8px 32px rgba(0,0,0,0.3);">
    <div class="card-header">
        <h2>Operação na Carteira</h2>
        <button onclick="fecharModal()" style="float:right; background:none; border:none; font-size:1.5em; cursor:pointer;">&times;</button>
    </div>
    <p id="modalCliente" style="padding:0 15px;"></p>
    <form method="post" action="func_carteiras.jsp" style="padding:15px;">
        <input type="hidden" name="acao" value="operacao_carteira">
        <input type="hidden" name="carteira_id" id="modalCarteiraId">
        <input type="hidden" name="pesquisa" value="<%= pesquisa %>">
        <div class="form-group">
            <label for="tipo_operacao">Tipo:</label>
            <select name="tipo_operacao" id="tipo_operacao" class="form-control" required>
                <option value="deposito">Depósito</option>
                <option value="levantamento">Levantamento</option>
            </select>
        </div>
        <div class="form-group">
            <label for="valor">Valor (&euro;):</label>
            <input type="number" name="valor" id="valor" step="0.01" min="0.01" required class="form-control">
        </div>
        <div class="form-group">
            <label for="descricao">Descrição:</label>
            <input type="text" name="descricao" id="descricao" placeholder="Motivo da operação..." class="form-control">
        </div>
        <button type="submit" class="btn btn-primary" style="width:100%;">Confirmar Operação</button>
    </form>
</div>
<div id="modalOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); z-index:999;" onclick="fecharModal()"></div>

<script>
function mostrarFormCarteira(carteiraId, nomeCliente) {
    document.getElementById('modalCarteiraId').value = carteiraId;
    document.getElementById('modalCliente').innerHTML = '<strong>Cliente:</strong> ' + nomeCliente;
    document.getElementById('modalCarteira').style.display = 'block';
    document.getElementById('modalOverlay').style.display = 'block';
}
function fecharModal() {
    document.getElementById('modalCarteira').style.display = 'none';
    document.getElementById('modalOverlay').style.display = 'none';
}
</script>

<div class="text-center" style="margin-top:20px;">
    <a href="func_dashboard.jsp" class="btn btn-secondary">&larr; Voltar ao Painel</a>
</div>

<%@ include file="footer.jsp" %>
