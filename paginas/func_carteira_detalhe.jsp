<%-- =========================================================================
  func_carteira_detalhe.jsp - Historico de Carteira (Funcionario)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Mostra o historico completo de operacoes de uma carteira
             de cliente, incluindo depositos, levantamentos, pagamentos
             e reembolsos. Acessivel a funcionarios e administradores.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "funcionario"; %>
<%@ include file="auth_check.jsp" %>

<%
    String carteiraIdParam = request.getParameter("carteira_id");
    if (carteiraIdParam == null || carteiraIdParam.isEmpty()) {
        response.sendRedirect("func_carteiras.jsp");
        return;
    }
    int carteiraId = Integer.parseInt(carteiraIdParam);
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
%>

<%@ include file="header.jsp" %>

<%
    try {
        conn = getConnection();
        
        // Dados da carteira e cliente
        pstmt = conn.prepareStatement(
            "SELECT c.saldo, u.nome, u.username, u.email " +
            "FROM carteiras c JOIN utilizadores u ON c.id_utilizador = u.id WHERE c.id = ?"
        );
        pstmt.setInt(1, carteiraId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
%>
<div class="alert alert-error">Carteira não encontrada.</div>
<a href="func_carteiras.jsp" class="btn btn-secondary">&larr; Voltar</a>
<%
        } else {
            double saldo = rs.getDouble("saldo");
            String nomeCliente = rs.getString("nome");
            String userCliente = rs.getString("username");
            rs.close(); pstmt.close();
%>

<h1 class="page-title">&#128176; Histórico da Carteira</h1>

<div class="card">
    <div class="card-header"><h2>Cliente: <%= nomeCliente %> (<%= userCliente %>)</h2></div>
    <div class="wallet-display">
        <span class="wallet-label">Saldo Atual:</span>
        <span class="wallet-balance"><%= String.format("%.2f", saldo) %> &euro;</span>
    </div>
</div>

<div class="card">
    <div class="card-header"><h2>Operações</h2></div>
<%
            pstmt = conn.prepareStatement(
                "SELECT tipo, valor, descricao, data_operacao " +
                "FROM operacoes_carteira WHERE id_carteira = ? ORDER BY data_operacao DESC"
            );
            pstmt.setInt(1, carteiraId);
            rs = pstmt.executeQuery();
            boolean tem = false;
%>
    <table>
        <thead>
            <tr><th>Data</th><th>Tipo</th><th>Valor</th><th>Descrição</th></tr>
        </thead>
        <tbody>
<%
            while (rs.next()) {
                tem = true;
                String tipo = rs.getString("tipo");
                boolean positivo = "deposito".equals(tipo) || "reembolso".equals(tipo);
%>
            <tr>
                <td><%= rs.getString("data_operacao") %></td>
                <td><span class="badge <%= positivo ? "badge-entregue" : "badge-cancelada" %>"><%= tipo %></span></td>
                <td style="color: <%= positivo ? "#2e7d32" : "#c62828" %>; font-weight:bold;">
                    <%= positivo ? "+" : "-" %><%= String.format("%.2f", rs.getDouble("valor")) %> &euro;
                </td>
                <td><%= rs.getString("descricao") != null ? rs.getString("descricao") : "" %></td>
            </tr>
<%
            }
            if (!tem) {
%>
            <tr><td colspan="4" class="text-center text-muted">Sem operações registadas.</td></tr>
<%
            }
%>
        </tbody>
    </table>
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
    <a href="func_carteiras.jsp" class="btn btn-secondary">&larr; Voltar às Carteiras</a>
</div>

<%@ include file="footer.jsp" %>
