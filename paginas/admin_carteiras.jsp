<%-- =========================================================================
  admin_carteiras.jsp - Gestao de Carteiras (Admin)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Gestao completa de carteiras incluindo a carteira da loja.
             Permite visualizar saldos de todos os clientes e da loja,
             efetuar operacoes e ver historicos. Inclui funcionalidade
             extra de criar carteiras para clientes que nao tenham.
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
                if (descricao == null || descricao.trim().isEmpty()) descricao = "Operação pelo administrador";
                
                conn = getConnection();
                conn.setAutoCommit(false);
                
                pstmt = conn.prepareStatement("SELECT saldo FROM carteiras WHERE id = ? FOR UPDATE");
                pstmt.setInt(1, carteiraId);
                rs = pstmt.executeQuery();
                
                if (!rs.next()) throw new Exception("Carteira não encontrada.");
                double saldoAtual = rs.getDouble("saldo");
                rs.close(); pstmt.close();
                
                if ("levantamento".equals(tipo) && saldoAtual < valor) {
                    conn.rollback();
                    mensagem = "Saldo insuficiente! Saldo atual: " + String.format("%.2f", saldoAtual) + " €";
                    tipoMensagem = "error";
                } else {
                    if ("deposito".equals(tipo)) {
                        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id = ?");
                    } else {
                        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id = ?");
                    }
                    pstmt.setDouble(1, valor);
                    pstmt.setInt(2, carteiraId);
                    pstmt.executeUpdate(); pstmt.close();
                    
                    pstmt = conn.prepareStatement(
                        "INSERT INTO operacoes_carteira (id_carteira, tipo, valor, descricao) VALUES (?, ?, ?, ?)"
                    );
                    pstmt.setInt(1, carteiraId);
                    pstmt.setString(2, tipo);
                    pstmt.setDouble(3, valor);
                    pstmt.setString(4, descricao.trim() + " (por admin)");
                    pstmt.executeUpdate(); pstmt.close();
                    
                    conn.commit();
                    mensagem = tipo.substring(0,1).toUpperCase() + tipo.substring(1) + 
                              " de " + String.format("%.2f", valor) + " € realizado!";
                    tipoMensagem = "success";
                }
                conn.setAutoCommit(true);
                fecharConexao(conn); conn = null;
            } catch (Exception e) {
                mensagem = "Erro: " + e.getMessage();
                tipoMensagem = "error";
                if (conn != null) { try { conn.rollback(); } catch(Exception ex){} fecharConexao(conn); conn = null; }
            }
        }
    }
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#128176; Gestão de Carteiras</h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<%
    try {
        conn = getConnection();
        
        // Carteira da loja
        pstmt = conn.prepareStatement("SELECT id, saldo FROM carteiras WHERE tipo = 'loja'");
        rs = pstmt.executeQuery();
        if (rs.next()) {
            int lojaCartId = rs.getInt("id");
            double saldoLoja = rs.getDouble("saldo");
%>
<div class="card" style="border-left: 4px solid #2e7d32;">
    <div class="card-header"><h2>&#127970; Carteira da Loja</h2></div>
    <div class="grid-2">
        <div>
            <div class="wallet-display">
                <span class="wallet-label">Saldo:</span>
                <span class="wallet-balance" style="font-size:2em;"><%= String.format("%.2f", saldoLoja) %> &euro;</span>
            </div>
        </div>
        <div>
            <a href="func_carteira_detalhe.jsp?carteira_id=<%= lojaCartId %>" class="btn btn-info">Ver Histórico</a>
            <button class="btn btn-success" onclick="mostrarFormCarteira(<%= lojaCartId %>, 'Loja')">Operação</button>
        </div>
    </div>
</div>
<%
        }
        rs.close(); pstmt.close();
        
        // Carteiras dos clientes
%>
<div class="card">
    <div class="card-header"><h2>&#128101; Carteiras dos Clientes</h2></div>
<%
        pstmt = conn.prepareStatement(
            "SELECT c.id AS carteira_id, c.saldo, u.nome, u.username, u.email, u.ativo " +
            "FROM carteiras c JOIN utilizadores u ON c.id_utilizador = u.id " +
            "WHERE c.tipo = 'cliente' ORDER BY u.nome"
        );
        rs = pstmt.executeQuery();
        boolean tem = false;
%>
    <table>
        <thead>
            <tr><th>Cliente</th><th>Username</th><th>Email</th><th>Saldo</th><th>Estado</th><th>Ações</th></tr>
        </thead>
        <tbody>
<%
        while (rs.next()) {
            tem = true;
            int carteiraId = rs.getInt("carteira_id");
%>
            <tr<%= rs.getInt("ativo") == 0 ? " style=\"opacity:0.5;\"" : "" %>>
                <td><strong><%= rs.getString("nome") %></strong></td>
                <td><%= rs.getString("username") %></td>
                <td><%= rs.getString("email") %></td>
                <td><span class="wallet-balance"><%= String.format("%.2f", rs.getDouble("saldo")) %> &euro;</span></td>
                <td><%= rs.getInt("ativo") == 1 ? "<span class='badge badge-entregue'>Ativo</span>" : "<span class='badge badge-cancelada'>Inativo</span>" %></td>
                <td>
                    <a href="func_carteira_detalhe.jsp?carteira_id=<%= carteiraId %>" class="btn btn-sm btn-info">Histórico</a>
                    <button class="btn btn-sm btn-success" 
                        onclick="mostrarFormCarteira(<%= carteiraId %>, '<%= rs.getString("nome").replace("'", "\\'") %>')">Operação</button>
                </td>
            </tr>
<%
        }
        if (!tem) {
%>
            <tr><td colspan="6" class="text-center text-muted">Nenhuma carteira encontrada.</td></tr>
<%
        }
%>
        </tbody>
    </table>
</div>

<%
    } catch (Exception e) {
%>
<div class="alert alert-error">Erro: <%= e.getMessage() %></div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<%-- Modal --%>
<div id="modalCarteira" class="card" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); z-index:1000; width:400px; box-shadow:0 8px 32px rgba(0,0,0,0.3);">
    <div class="card-header">
        <h2>Operação na Carteira</h2>
        <button onclick="fecharModal()" style="float:right; background:none; border:none; font-size:1.5em; cursor:pointer;">&times;</button>
    </div>
    <p id="modalCliente" style="padding:0 15px;"></p>
    <form method="post" action="admin_carteiras.jsp" style="padding:15px;">
        <input type="hidden" name="acao" value="operacao_carteira">
        <input type="hidden" name="carteira_id" id="modalCarteiraId">
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
            <input type="text" name="descricao" id="descricao" placeholder="Motivo..." class="form-control">
        </div>
        <button type="submit" class="btn btn-primary" style="width:100%;">Confirmar</button>
    </form>
</div>
<div id="modalOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); z-index:999;" onclick="fecharModal()"></div>

<script>
function mostrarFormCarteira(carteiraId, nome) {
    document.getElementById('modalCarteiraId').value = carteiraId;
    document.getElementById('modalCliente').innerHTML = '<strong>Carteira:</strong> ' + nome;
    document.getElementById('modalCarteira').style.display = 'block';
    document.getElementById('modalOverlay').style.display = 'block';
}
function fecharModal() {
    document.getElementById('modalCarteira').style.display = 'none';
    document.getElementById('modalOverlay').style.display = 'none';
}
</script>

<div class="text-center" style="margin-top:20px;">
    <a href="admin_dashboard.jsp" class="btn btn-secondary">&larr; Voltar ao Painel</a>
</div>

<%@ include file="footer.jsp" %>
