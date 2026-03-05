<%-- =========================================================================
  func_encomenda_detalhe.jsp - Detalhe de Encomenda (Funcionario)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Mostra os detalhes completos de uma encomenda incluindo
             itens, valores, dados do cliente, e permite alterar o estado.
             Serve tambem para validacao presencial pelo codigo unico.
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
    
    // Processar alteracao de estado
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String acao = request.getParameter("acao");
        if ("alterar_estado".equals(acao)) {
            int encId = Integer.parseInt(request.getParameter("encomenda_id"));
            String novoEstado = request.getParameter("novo_estado");
            
            try {
                conn = getConnection();
                pstmt = conn.prepareStatement("SELECT estado FROM encomendas WHERE id = ?");
                pstmt.setInt(1, encId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    String estadoAtual = rs.getString("estado");
                    boolean ok = false;
                    if ("pendente".equals(estadoAtual) && "confirmada".equals(novoEstado)) ok = true;
                    else if ("confirmada".equals(estadoAtual) && "em_preparacao".equals(novoEstado)) ok = true;
                    else if ("em_preparacao".equals(estadoAtual) && "pronta".equals(novoEstado)) ok = true;
                    else if ("pronta".equals(estadoAtual) && "entregue".equals(novoEstado)) ok = true;
                    
                    if (ok) {
                        rs.close(); pstmt.close();
                        pstmt = conn.prepareStatement("UPDATE encomendas SET estado = ? WHERE id = ?");
                        pstmt.setString(1, novoEstado);
                        pstmt.setInt(2, encId);
                        pstmt.executeUpdate();
                        mensagem = "Estado atualizado para '" + novoEstado.replace("_"," ") + "'!";
                        tipoMensagem = "success";
                    } else {
                        mensagem = "Transição de estado não permitida.";
                        tipoMensagem = "error";
                    }
                }
                fecharRecursos(rs, pstmt, conn);
                conn = null;
            } catch (Exception e) {
                mensagem = "Erro: " + e.getMessage();
                tipoMensagem = "error";
                if (conn != null) { fecharConexao(conn); conn = null; }
            }
        }
    }
    
    // Parametro - ID da encomenda
    String idParam = request.getParameter("id");
    if (idParam == null || idParam.isEmpty()) {
        response.sendRedirect("func_encomendas.jsp");
        return;
    }
    int encId = Integer.parseInt(idParam);
%>

<%@ include file="header.jsp" %>

<%
    try {
        conn = getConnection();
        
        // Dados da encomenda + cliente
        pstmt = conn.prepareStatement(
            "SELECT e.*, u.nome AS cliente_nome, u.username AS cliente_user, " +
            "u.email AS cliente_email, u.morada AS cliente_morada, u.telefone AS cliente_telefone " +
            "FROM encomendas e JOIN utilizadores u ON e.id_cliente = u.id WHERE e.id = ?"
        );
        pstmt.setInt(1, encId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
%>
<div class="alert alert-error">Encomenda não encontrada.</div>
<a href="func_encomendas.jsp" class="btn btn-secondary">&larr; Voltar</a>
<%
        } else {
            String codigoUnico = rs.getString("codigo_unico");
            String estado = rs.getString("estado");
            double valorTotal = rs.getDouble("valor_total");
            String dataEnc = rs.getString("data_encomenda");
            String clienteNome = rs.getString("cliente_nome");
            String clienteUser = rs.getString("cliente_user");
            String clienteEmail = rs.getString("cliente_email");
            String clienteMorada = rs.getString("cliente_morada");
            String clienteTelefone = rs.getString("cliente_telefone");
            
            String badgeClass = "badge-pendente";
            if ("confirmada".equals(estado)) badgeClass = "badge-confirmada";
            else if ("em_preparacao".equals(estado)) badgeClass = "badge-preparacao";
            else if ("pronta".equals(estado)) badgeClass = "badge-pronta";
            else if ("entregue".equals(estado)) badgeClass = "badge-entregue";
            else if ("cancelada".equals(estado)) badgeClass = "badge-cancelada";
            
            rs.close(); pstmt.close();
%>

<h1 class="page-title">&#128230; Detalhe da Encomenda</h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<%-- Info da encomenda --%>
<div class="grid-2">
    <div class="card">
        <div class="card-header"><h2>Informações da Encomenda</h2></div>
        <table class="table-detail">
            <tr><th>Código Único:</th><td><strong style="font-size:1.2em;"><%= codigoUnico %></strong></td></tr>
            <tr><th>Estado:</th><td><span class="badge <%= badgeClass %>"><%= estado.replace("_", " ") %></span></td></tr>
            <tr><th>Valor Total:</th><td><strong><%= String.format("%.2f", valorTotal) %> &euro;</strong></td></tr>
            <tr><th>Data:</th><td><%= dataEnc %></td></tr>
        </table>
    </div>
    
    <div class="card">
        <div class="card-header"><h2>Dados do Cliente</h2></div>
        <table class="table-detail">
            <tr><th>Nome:</th><td><%= clienteNome %></td></tr>
            <tr><th>Username:</th><td><%= clienteUser %></td></tr>
            <tr><th>Email:</th><td><%= clienteEmail != null ? clienteEmail : "N/A" %></td></tr>
            <tr><th>Morada:</th><td><%= clienteMorada != null ? clienteMorada : "N/A" %></td></tr>
            <tr><th>Telefone:</th><td><%= clienteTelefone != null ? clienteTelefone : "N/A" %></td></tr>
        </table>
    </div>
</div>

<%-- Itens da encomenda --%>
<div class="card">
    <div class="card-header"><h2>Itens da Encomenda</h2></div>
<%
            pstmt = conn.prepareStatement(
                "SELECT ie.quantidade, ie.preco_unitario, ie.subtotal, p.nome AS produto_nome, p.unidade " +
                "FROM itens_encomenda ie JOIN produtos p ON ie.id_produto = p.id WHERE ie.id_encomenda = ?"
            );
            pstmt.setInt(1, encId);
            rs = pstmt.executeQuery();
%>
    <table>
        <thead>
            <tr><th>Produto</th><th>Preço Unit.</th><th>Quantidade</th><th>Subtotal</th></tr>
        </thead>
        <tbody>
<%
            while (rs.next()) {
%>
            <tr>
                <td><%= rs.getString("produto_nome") %></td>
                <td><%= String.format("%.2f", rs.getDouble("preco_unitario")) %> &euro;/<%= rs.getString("unidade") %></td>
                <td><%= rs.getInt("quantidade") %></td>
                <td><strong><%= String.format("%.2f", rs.getDouble("subtotal")) %> &euro;</strong></td>
            </tr>
<%
            }
%>
        </tbody>
        <tfoot>
            <tr><td colspan="3" style="text-align:right;"><strong>TOTAL:</strong></td>
            <td><strong><%= String.format("%.2f", valorTotal) %> &euro;</strong></td></tr>
        </tfoot>
    </table>
</div>

<%-- Acoes --%>
<div class="card">
    <div class="card-header"><h2>Alterar Estado</h2></div>
    <div class="btn-group">
<%
            String proximoEstado = null, textoBtn = null;
            if ("pendente".equals(estado)) { proximoEstado = "confirmada"; textoBtn = "&#9989; Confirmar Encomenda"; }
            else if ("confirmada".equals(estado)) { proximoEstado = "em_preparacao"; textoBtn = "&#128259; Iniciar Preparação"; }
            else if ("em_preparacao".equals(estado)) { proximoEstado = "pronta"; textoBtn = "&#9989; Marcar como Pronta"; }
            else if ("pronta".equals(estado)) { proximoEstado = "entregue"; textoBtn = "&#128666; Marcar como Entregue"; }
            
            if (proximoEstado != null) {
%>
        <form method="post" action="func_encomenda_detalhe.jsp?id=<%= encId %>" style="display:inline;">
            <input type="hidden" name="acao" value="alterar_estado">
            <input type="hidden" name="encomenda_id" value="<%= encId %>">
            <input type="hidden" name="novo_estado" value="<%= proximoEstado %>">
            <button type="submit" class="btn btn-success" 
                onclick="return confirm('Alterar estado para <%= proximoEstado.replace("_"," ") %>?');">
                <%= textoBtn %>
            </button>
        </form>
<%
            } else {
%>
        <p class="text-muted">Esta encomenda está no estado final (<%= estado %>). Não é possível alterar.</p>
<%
            }
%>
    </div>
</div>

<%
        }
    } catch (Exception e) {
%>
<div class="alert alert-error">Erro: <%= e.getMessage() %></div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<div class="text-center" style="margin-top:20px;">
    <a href="func_encomendas.jsp" class="btn btn-secondary">&larr; Voltar às Encomendas</a>
</div>

<%@ include file="footer.jsp" %>
