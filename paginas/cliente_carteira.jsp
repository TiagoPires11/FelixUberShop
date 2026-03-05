<%-- =========================================================================
  cliente_carteira.jsp - Gestao de Carteira do Cliente
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Permite ao cliente consultar o saldo da sua carteira,
             adicionar saldo (deposito) e levantar saldo (levantamento).
             Todas as operacoes sao registadas na tabela operacoes_carteira
             para efeitos de auditoria. Mostra tambem o historico de
             operacoes recentes.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "cliente"; %>
<%@ include file="auth_check.jsp" %>

<%
    int userId = (Integer) session.getAttribute("user_id");
    String erro = null;
    String sucesso = null;
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    double saldo = 0;
    int carteiraId = 0;
    
    try {
        conn = getConnection();
        
        // Obter dados da carteira do cliente
        pstmt = conn.prepareStatement("SELECT id, saldo FROM carteiras WHERE id_utilizador = ? AND tipo = 'cliente'");
        pstmt.setInt(1, userId);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            carteiraId = rs.getInt("id");
            saldo = rs.getDouble("saldo");
        }
        rs.close();
        pstmt.close();
        
        // -------------------------------------------------------------------
        // Processar operacao de carteira (POST): deposito ou levantamento
        // -------------------------------------------------------------------
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String operacao = request.getParameter("operacao");
            String valorStr = request.getParameter("valor");
            
            if (valorStr != null && !valorStr.isEmpty()) {
                try {
                    double valor = Double.parseDouble(valorStr);
                    
                    if (valor <= 0) {
                        erro = "O valor deve ser maior que 0.";
                    } else if ("deposito".equals(operacao)) {
                        // ---------------------------------------------------
                        // DEPOSITO: adicionar saldo a carteira
                        // Transacao atomica: atualizar saldo + registar operacao
                        // ---------------------------------------------------
                        conn.setAutoCommit(false);
                        
                        // Atualizar saldo
                        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id = ?");
                        pstmt.setDouble(1, valor);
                        pstmt.setInt(2, carteiraId);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        // Registar operacao de auditoria
                        pstmt = conn.prepareStatement(
                            "INSERT INTO operacoes_carteira (id_carteira_origem, id_carteira_destino, tipo_operacao, valor, descricao) " +
                            "VALUES (NULL, ?, 'deposito', ?, ?)"
                        );
                        pstmt.setInt(1, carteiraId);
                        pstmt.setDouble(2, valor);
                        pstmt.setString(3, "Depósito de saldo pelo cliente");
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        conn.commit();
                        saldo += valor;
                        sucesso = "Depósito de " + String.format("%.2f", valor) + " € efetuado com sucesso!";
                        
                    } else if ("levantamento".equals(operacao)) {
                        // ---------------------------------------------------
                        // LEVANTAMENTO: retirar saldo da carteira
                        // Verifica se tem saldo suficiente antes de retirar
                        // ---------------------------------------------------
                        if (valor > saldo) {
                            erro = "Saldo insuficiente. O seu saldo atual é de " + String.format("%.2f", saldo) + " €.";
                        } else {
                            conn.setAutoCommit(false);
                            
                            // Atualizar saldo
                            pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id = ?");
                            pstmt.setDouble(1, valor);
                            pstmt.setInt(2, carteiraId);
                            pstmt.executeUpdate();
                            pstmt.close();
                            
                            // Registar operacao de auditoria
                            pstmt = conn.prepareStatement(
                                "INSERT INTO operacoes_carteira (id_carteira_origem, id_carteira_destino, tipo_operacao, valor, descricao) " +
                                "VALUES (?, NULL, 'levantamento', ?, ?)"
                            );
                            pstmt.setInt(1, carteiraId);
                            pstmt.setDouble(2, valor);
                            pstmt.setString(3, "Levantamento de saldo pelo cliente");
                            pstmt.executeUpdate();
                            pstmt.close();
                            
                            conn.commit();
                            saldo -= valor;
                            sucesso = "Levantamento de " + String.format("%.2f", valor) + " € efetuado com sucesso!";
                        }
                    }
                } catch (NumberFormatException e) {
                    erro = "Por favor, introduza um valor numérico válido.";
                }
            } else {
                erro = "Por favor, introduza um valor.";
            }
        }
        
    } catch (Exception e) {
        try { if (conn != null) conn.rollback(); } catch (Exception ex) {}
        erro = "Erro ao processar operação: " + e.getMessage();
    }
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#128176; Minha Carteira</h1>

<%-- Mostrar saldo atual --%>
<div class="card">
    <div class="saldo-display">
        <%= String.format("%.2f", saldo) %> &euro;
    </div>
    <p class="text-center text-muted">Saldo disponível</p>
</div>

<% if (erro != null) { %>
    <div class="alert alert-error"><%= erro %></div>
<% } %>
<% if (sucesso != null) { %>
    <div class="alert alert-success"><%= sucesso %></div>
<% } %>

<%-- Formularios de deposito e levantamento lado a lado --%>
<div class="grid-2">
    <%-- Formulario de deposito --%>
    <div class="card">
        <div class="card-header">
            <h3>&#10133; Adicionar Saldo</h3>
        </div>
        <form method="post" action="cliente_carteira.jsp" onsubmit="return validarValorMonetario('valor_deposito');">
            <input type="hidden" name="operacao" value="deposito">
            <div class="form-group">
                <label for="valor_deposito">Valor a depositar (&euro;):</label>
                <input type="number" id="valor_deposito" name="valor" step="0.01" min="0.01" 
                       placeholder="0.00" required>
            </div>
            <button type="submit" class="btn btn-primary btn-block">Depositar</button>
        </form>
    </div>
    
    <%-- Formulario de levantamento --%>
    <div class="card">
        <div class="card-header">
            <h3>&#10134; Levantar Saldo</h3>
        </div>
        <form method="post" action="cliente_carteira.jsp" onsubmit="return validarValorMonetario('valor_levantamento');">
            <input type="hidden" name="operacao" value="levantamento">
            <div class="form-group">
                <label for="valor_levantamento">Valor a levantar (&euro;):</label>
                <input type="number" id="valor_levantamento" name="valor" step="0.01" min="0.01" 
                       max="<%= String.format("%.2f", saldo) %>" placeholder="0.00" required>
            </div>
            <button type="submit" class="btn btn-danger btn-block">Levantar</button>
        </form>
    </div>
</div>

<%-- Historico de operacoes --%>
<div class="card" style="margin-top: 20px;">
    <div class="card-header">
        <h2>Histórico de Operações</h2>
    </div>
    
<%
    try {
        if (conn == null || conn.isClosed()) {
            conn = getConnection();
        }
        
        // Carregar historico de operacoes da carteira do cliente
        pstmt = conn.prepareStatement(
            "SELECT tipo_operacao, valor, descricao, data_operacao " +
            "FROM operacoes_carteira " +
            "WHERE id_carteira_origem = ? OR id_carteira_destino = ? " +
            "ORDER BY data_operacao DESC LIMIT 20"
        );
        pstmt.setInt(1, carteiraId);
        pstmt.setInt(2, carteiraId);
        rs = pstmt.executeQuery();
        
        boolean temOperacoes = false;
%>
    <table>
        <thead>
            <tr>
                <th>Tipo</th>
                <th>Valor</th>
                <th>Descrição</th>
                <th>Data</th>
            </tr>
        </thead>
        <tbody>
<%
        while (rs.next()) {
            temOperacoes = true;
            String tipo = rs.getString("tipo_operacao");
            String classCor = "deposito".equals(tipo) || "reembolso".equals(tipo) ? "text-success" : "text-danger";
            String sinal = "deposito".equals(tipo) || "reembolso".equals(tipo) ? "+" : "-";
%>
            <tr>
                <td><span class="badge badge-<%= tipo.equals("deposito") || tipo.equals("reembolso") ? "ativo" : "inativo" %>"><%= tipo %></span></td>
                <td class="<%= classCor %>"><strong><%= sinal %><%= String.format("%.2f", rs.getDouble("valor")) %> &euro;</strong></td>
                <td><%= rs.getString("descricao") != null ? rs.getString("descricao") : "-" %></td>
                <td><%= rs.getString("data_operacao") %></td>
            </tr>
<%
        }
        
        if (!temOperacoes) {
%>
            <tr><td colspan="4" class="text-center text-muted">Sem operações registadas.</td></tr>
<%
        }
%>
        </tbody>
    </table>
<%
    } catch (Exception e) {
%>
        <div class="alert alert-error">Erro ao carregar histórico: <%= e.getMessage() %></div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>
</div>

<div class="mt-20">
    <a href="cliente_dashboard.jsp" class="btn btn-secondary">&#8592; Voltar ao Painel</a>
</div>

<script src="scripts.js"></script>
<%@ include file="footer.jsp" %>
