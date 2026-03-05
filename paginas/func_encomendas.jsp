<%-- =========================================================================
  func_encomendas.jsp - Gestao de Encomendas (Funcionario)
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Lista todas as encomendas do sistema com filtros por estado.
             Permite ao funcionario alterar o estado das encomendas
             (pendente -> confirmada -> em_preparacao -> pronta -> entregue).
             Inclui pesquisa por codigo unico para validacao presencial.
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
            
            // Validar transicoes permitidas
            String[] estadosValidos = {"confirmada", "em_preparacao", "pronta", "entregue"};
            boolean estadoValido = false;
            for (String ev : estadosValidos) {
                if (ev.equals(novoEstado)) { estadoValido = true; break; }
            }
            
            if (!estadoValido) {
                mensagem = "Estado inválido.";
                tipoMensagem = "error";
            } else {
                try {
                    conn = getConnection();
                    
                    // Verificar estado atual e transicao valida
                    pstmt = conn.prepareStatement("SELECT estado FROM encomendas WHERE id = ?");
                    pstmt.setInt(1, encId);
                    rs = pstmt.executeQuery();
                    
                    if (rs.next()) {
                        String estadoAtual = rs.getString("estado");
                        boolean transicaoValida = false;
                        
                        if ("pendente".equals(estadoAtual) && "confirmada".equals(novoEstado)) transicaoValida = true;
                        else if ("confirmada".equals(estadoAtual) && "em_preparacao".equals(novoEstado)) transicaoValida = true;
                        else if ("em_preparacao".equals(estadoAtual) && "pronta".equals(novoEstado)) transicaoValida = true;
                        else if ("pronta".equals(estadoAtual) && "entregue".equals(novoEstado)) transicaoValida = true;
                        
                        if (transicaoValida) {
                            rs.close(); pstmt.close();
                            pstmt = conn.prepareStatement("UPDATE encomendas SET estado = ? WHERE id = ?");
                            pstmt.setString(1, novoEstado);
                            pstmt.setInt(2, encId);
                            pstmt.executeUpdate();
                            mensagem = "Estado atualizado para '" + novoEstado.replace("_", " ") + "' com sucesso!";
                            tipoMensagem = "success";
                        } else {
                            mensagem = "Transição de '" + estadoAtual + "' para '" + novoEstado + "' não é permitida.";
                            tipoMensagem = "error";
                        }
                    } else {
                        mensagem = "Encomenda não encontrada.";
                        tipoMensagem = "error";
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
    }
    
    // Filtros
    String filtroEstado = request.getParameter("estado");
    if (filtroEstado == null) filtroEstado = "";
    String filtroCodigo = request.getParameter("codigo");
    if (filtroCodigo == null) filtroCodigo = "";
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#128230; Gestão de Encomendas</h1>

<% if (mensagem != null) { %>
<div class="alert alert-<%= tipoMensagem %>"><%= mensagem %></div>
<% } %>

<%-- Filtros e pesquisa --%>
<div class="card">
    <div class="card-header"><h2>Filtrar / Pesquisar</h2></div>
    <form method="get" action="func_encomendas.jsp" class="form-inline">
        <div class="grid-3">
            <div class="form-group">
                <label for="estado">Estado:</label>
                <select name="estado" id="estado" class="form-control">
                    <option value="">-- Todos --</option>
                    <option value="pendente" <%= "pendente".equals(filtroEstado) ? "selected" : "" %>>Pendente</option>
                    <option value="confirmada" <%= "confirmada".equals(filtroEstado) ? "selected" : "" %>>Confirmada</option>
                    <option value="em_preparacao" <%= "em_preparacao".equals(filtroEstado) ? "selected" : "" %>>Em Preparação</option>
                    <option value="pronta" <%= "pronta".equals(filtroEstado) ? "selected" : "" %>>Pronta</option>
                    <option value="entregue" <%= "entregue".equals(filtroEstado) ? "selected" : "" %>>Entregue</option>
                    <option value="cancelada" <%= "cancelada".equals(filtroEstado) ? "selected" : "" %>>Cancelada</option>
                </select>
            </div>
            <div class="form-group">
                <label for="codigo">Código Único:</label>
                <input type="text" name="codigo" id="codigo" value="<%= filtroCodigo %>" placeholder="Pesquisar por código..." class="form-control">
            </div>
            <div class="form-group" style="display:flex; align-items:flex-end;">
                <button type="submit" class="btn btn-primary">&#128269; Filtrar</button>
                &nbsp;<a href="func_encomendas.jsp" class="btn btn-secondary">Limpar</a>
            </div>
        </div>
    </form>
</div>

<%-- Lista de encomendas --%>
<div class="card">
    <div class="card-header"><h2>Encomendas</h2></div>
<%
    try {
        conn = getConnection();
        
        StringBuilder sql = new StringBuilder(
            "SELECT e.id, e.codigo_unico, e.estado, e.valor_total, e.data_encomenda, " +
            "u.nome AS cliente_nome, u.username AS cliente_user " +
            "FROM encomendas e JOIN utilizadores u ON e.id_cliente = u.id WHERE 1=1 "
        );
        java.util.List<String> params = new java.util.ArrayList<>();
        
        if (!filtroEstado.isEmpty()) {
            sql.append("AND e.estado = ? ");
            params.add(filtroEstado);
        }
        if (!filtroCodigo.trim().isEmpty()) {
            sql.append("AND e.codigo_unico LIKE ? ");
            params.add("%" + filtroCodigo.trim() + "%");
        }
        sql.append("ORDER BY e.data_encomenda DESC");
        
        pstmt = conn.prepareStatement(sql.toString());
        for (int i = 0; i < params.size(); i++) {
            pstmt.setString(i + 1, params.get(i));
        }
        rs = pstmt.executeQuery();
        boolean tem = false;
%>
    <table>
        <thead>
            <tr>
                <th>Código</th>
                <th>Cliente</th>
                <th>Estado</th>
                <th>Valor</th>
                <th>Data</th>
                <th>Ações</th>
            </tr>
        </thead>
        <tbody>
<%
        while (rs.next()) {
            tem = true;
            String estado = rs.getString("estado");
            String badgeClass = "badge-pendente";
            if ("confirmada".equals(estado)) badgeClass = "badge-confirmada";
            else if ("em_preparacao".equals(estado)) badgeClass = "badge-preparacao";
            else if ("pronta".equals(estado)) badgeClass = "badge-pronta";
            else if ("entregue".equals(estado)) badgeClass = "badge-entregue";
            else if ("cancelada".equals(estado)) badgeClass = "badge-cancelada";
            
            String proximoEstado = null;
            String textoBtn = null;
            if ("pendente".equals(estado)) { proximoEstado = "confirmada"; textoBtn = "Confirmar"; }
            else if ("confirmada".equals(estado)) { proximoEstado = "em_preparacao"; textoBtn = "Iniciar Preparação"; }
            else if ("em_preparacao".equals(estado)) { proximoEstado = "pronta"; textoBtn = "Marcar Pronta"; }
            else if ("pronta".equals(estado)) { proximoEstado = "entregue"; textoBtn = "Marcar Entregue"; }
%>
            <tr>
                <td><strong><%= rs.getString("codigo_unico") %></strong></td>
                <td><%= rs.getString("cliente_nome") %> (<%= rs.getString("cliente_user") %>)</td>
                <td><span class="badge <%= badgeClass %>"><%= estado.replace("_", " ") %></span></td>
                <td><%= String.format("%.2f", rs.getDouble("valor_total")) %> &euro;</td>
                <td><%= rs.getString("data_encomenda") %></td>
                <td>
                    <a href="func_encomenda_detalhe.jsp?id=<%= rs.getInt("id") %>" class="btn btn-sm btn-info">Ver</a>
<%
            if (proximoEstado != null) {
%>
                    <form method="post" action="func_encomendas.jsp" style="display:inline;">
                        <input type="hidden" name="acao" value="alterar_estado">
                        <input type="hidden" name="encomenda_id" value="<%= rs.getInt("id") %>">
                        <input type="hidden" name="novo_estado" value="<%= proximoEstado %>">
                        <input type="hidden" name="estado" value="<%= filtroEstado %>">
                        <button type="submit" class="btn btn-sm btn-success" 
                            onclick="return confirm('Alterar estado para <%= proximoEstado.replace("_"," ") %>?');">
                            <%= textoBtn %>
                        </button>
                    </form>
<%
            }
%>
                </td>
            </tr>
<%
        }
        if (!tem) {
%>
            <tr><td colspan="6" class="text-center text-muted">Nenhuma encomenda encontrada.</td></tr>
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

<div class="text-center" style="margin-top:20px;">
    <a href="func_dashboard.jsp" class="btn btn-secondary">&larr; Voltar ao Painel</a>
</div>

<%@ include file="footer.jsp" %>
