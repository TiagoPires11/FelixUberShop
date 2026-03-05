<%-- =========================================================================
  cliente_editar_encomenda.jsp - Editar Encomenda Pendente
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Permite ao cliente editar uma encomenda com estado 'pendente'.
             Pode alterar quantidades dos itens e observacoes. Recalcula
             o valor total e ajusta o saldo da carteira (devolve a diferenca
             ou cobra o adicional). Repoe stock quando itens sao removidos.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "cliente"; %>
<%@ include file="auth_check.jsp" %>

<%
    int userId = (Integer) session.getAttribute("user_id");
    String idParam = request.getParameter("id");
    String erro = null;
    
    if (idParam == null || idParam.isEmpty()) {
        response.sendRedirect("cliente_encomendas.jsp");
        return;
    }
    
    int encomendaId = Integer.parseInt(idParam);
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
        
        // Verificar se a encomenda pertence ao cliente e esta pendente
        pstmt = conn.prepareStatement(
            "SELECT id, codigo_unico, valor_total, observacoes FROM encomendas " +
            "WHERE id = ? AND id_cliente = ? AND estado = 'pendente'"
        );
        pstmt.setInt(1, encomendaId);
        pstmt.setInt(2, userId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
            session.setAttribute("mensagem_erro", "Encomenda não encontrada ou não pode ser editada.");
            response.sendRedirect("cliente_encomendas.jsp");
            return;
        }
        
        String codigoUnico = rs.getString("codigo_unico");
        double valorAnterior = rs.getDouble("valor_total");
        String observacoesAtuais = rs.getString("observacoes");
        rs.close();
        pstmt.close();
        
        // -------------------------------------------------------------------
        // Processar edicao (POST)
        // -------------------------------------------------------------------
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String[] itemIds = request.getParameterValues("item_id");
            String[] quantidades = request.getParameterValues("quantidade");
            String observacoes = request.getParameter("observacoes");
            
            conn.setAutoCommit(false);
            
            double novoTotal = 0;
            
            // Atualizar cada item
            for (int i = 0; i < itemIds.length; i++) {
                int itemId = Integer.parseInt(itemIds[i]);
                int novaQtd = 0;
                try { novaQtd = Integer.parseInt(quantidades[i]); } catch (Exception ex) {}
                
                // Obter dados atuais do item
                pstmt = conn.prepareStatement(
                    "SELECT ie.quantidade, ie.preco_unitario, ie.id_produto " +
                    "FROM itens_encomenda ie WHERE ie.id = ? AND ie.id_encomenda = ?"
                );
                pstmt.setInt(1, itemId);
                pstmt.setInt(2, encomendaId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    int qtdAnterior = rs.getInt("quantidade");
                    double precoUnit = rs.getDouble("preco_unitario");
                    int produtoId = rs.getInt("id_produto");
                    rs.close();
                    pstmt.close();
                    
                    if (novaQtd <= 0) {
                        // Remover item - repor stock
                        pstmt = conn.prepareStatement("DELETE FROM itens_encomenda WHERE id = ?");
                        pstmt.setInt(1, itemId);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        pstmt = conn.prepareStatement("UPDATE produtos SET stock = stock + ? WHERE id = ?");
                        pstmt.setInt(1, qtdAnterior);
                        pstmt.setInt(2, produtoId);
                        pstmt.executeUpdate();
                        pstmt.close();
                    } else {
                        // Atualizar quantidade
                        int diff = novaQtd - qtdAnterior;
                        
                        pstmt = conn.prepareStatement("UPDATE itens_encomenda SET quantidade = ? WHERE id = ?");
                        pstmt.setInt(1, novaQtd);
                        pstmt.setInt(2, itemId);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        // Ajustar stock (positivo = retirar mais, negativo = repor)
                        pstmt = conn.prepareStatement("UPDATE produtos SET stock = stock - ? WHERE id = ?");
                        pstmt.setInt(1, diff);
                        pstmt.setInt(2, produtoId);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        novoTotal += precoUnit * novaQtd;
                    }
                } else {
                    rs.close();
                    pstmt.close();
                }
            }
            
            // Verificar se ainda tem itens
            pstmt = conn.prepareStatement("SELECT COUNT(*) AS c FROM itens_encomenda WHERE id_encomenda = ?");
            pstmt.setInt(1, encomendaId);
            rs = pstmt.executeQuery();
            rs.next();
            int numItens = rs.getInt("c");
            rs.close();
            pstmt.close();
            
            if (numItens == 0) {
                erro = "A encomenda deve ter pelo menos um item. Use cancelar para remover a encomenda.";
                conn.rollback();
            } else {
                // Ajustar carteiras pela diferenca de valor
                double diferenca = novoTotal - valorAnterior;
                
                // Obter carteiras
                pstmt = conn.prepareStatement("SELECT id FROM carteiras WHERE id_utilizador = ? AND tipo = 'cliente'");
                pstmt.setInt(1, userId);
                rs = pstmt.executeQuery();
                rs.next();
                int carteiraClienteId = rs.getInt("id");
                rs.close();
                pstmt.close();
                
                pstmt = conn.prepareStatement("SELECT id FROM carteiras WHERE tipo = 'loja'");
                rs = pstmt.executeQuery();
                rs.next();
                int carteiraLojaId = rs.getInt("id");
                rs.close();
                pstmt.close();
                
                if (diferenca > 0) {
                    // Encomenda ficou mais cara - cobrar mais ao cliente
                    pstmt = conn.prepareStatement("SELECT saldo FROM carteiras WHERE id = ?");
                    pstmt.setInt(1, carteiraClienteId);
                    rs = pstmt.executeQuery();
                    rs.next();
                    double saldoCliente = rs.getDouble("saldo");
                    rs.close();
                    pstmt.close();
                    
                    if (diferenca > saldoCliente) {
                        erro = "Saldo insuficiente para o aumento do valor.";
                        conn.rollback();
                    } else {
                        // Debitar diferenca
                        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id = ?");
                        pstmt.setDouble(1, diferenca);
                        pstmt.setInt(2, carteiraClienteId);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id = ?");
                        pstmt.setDouble(1, diferenca);
                        pstmt.setInt(2, carteiraLojaId);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        // Registar auditoria
                        pstmt = conn.prepareStatement(
                            "INSERT INTO operacoes_carteira (id_carteira_origem, id_carteira_destino, tipo_operacao, valor, descricao) VALUES (?, ?, 'pagamento', ?, ?)"
                        );
                        pstmt.setInt(1, carteiraClienteId);
                        pstmt.setInt(2, carteiraLojaId);
                        pstmt.setDouble(3, diferenca);
                        pstmt.setString(4, "Ajuste (aumento) encomenda " + codigoUnico);
                        pstmt.executeUpdate();
                        pstmt.close();
                    }
                } else if (diferenca < 0) {
                    // Encomenda ficou mais barata - devolver ao cliente
                    double devolucao = Math.abs(diferenca);
                    
                    pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id = ?");
                    pstmt.setDouble(1, devolucao);
                    pstmt.setInt(2, carteiraClienteId);
                    pstmt.executeUpdate();
                    pstmt.close();
                    
                    pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id = ?");
                    pstmt.setDouble(1, devolucao);
                    pstmt.setInt(2, carteiraLojaId);
                    pstmt.executeUpdate();
                    pstmt.close();
                    
                    pstmt = conn.prepareStatement(
                        "INSERT INTO operacoes_carteira (id_carteira_origem, id_carteira_destino, tipo_operacao, valor, descricao) VALUES (?, ?, 'reembolso', ?, ?)"
                    );
                    pstmt.setInt(1, carteiraLojaId);
                    pstmt.setInt(2, carteiraClienteId);
                    pstmt.setDouble(3, devolucao);
                    pstmt.setString(4, "Reembolso parcial edição encomenda " + codigoUnico);
                    pstmt.executeUpdate();
                    pstmt.close();
                }
                
                if (erro == null) {
                    // Atualizar valor total e observacoes da encomenda
                    pstmt = conn.prepareStatement("UPDATE encomendas SET valor_total = ?, observacoes = ? WHERE id = ?");
                    pstmt.setDouble(1, novoTotal);
                    pstmt.setString(2, observacoes != null && !observacoes.trim().isEmpty() ? observacoes.trim() : null);
                    pstmt.setInt(3, encomendaId);
                    pstmt.executeUpdate();
                    pstmt.close();
                    
                    conn.commit();
                    
                    session.setAttribute("mensagem_sucesso", "Encomenda " + codigoUnico + " atualizada com sucesso!");
                    response.sendRedirect("cliente_encomendas.jsp");
                    return;
                }
            }
        }
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#9999;&#65039; Editar Encomenda: <%= codigoUnico %></h1>

<% if (erro != null) { %>
    <div class="alert alert-error"><%= erro %></div>
<% } %>

<form method="post" action="cliente_editar_encomenda.jsp?id=<%= encomendaId %>">
    <div class="card">
        <div class="card-header"><h2>Itens da Encomenda</h2></div>
        <p class="text-muted mb-10">Altere as quantidades. Coloque 0 para remover um item.</p>
        
        <table>
            <thead>
                <tr>
                    <th>Produto</th>
                    <th>Preço Unit.</th>
                    <th>Quantidade</th>
                    <th>Subtotal</th>
                </tr>
            </thead>
            <tbody>
<%
        // Carregar itens atuais da encomenda
        pstmt = conn.prepareStatement(
            "SELECT ie.id, ie.quantidade, ie.preco_unitario, p.nome, p.stock " +
            "FROM itens_encomenda ie JOIN produtos p ON ie.id_produto = p.id " +
            "WHERE ie.id_encomenda = ?"
        );
        pstmt.setInt(1, encomendaId);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            int stockDisp = rs.getInt("stock") + rs.getInt("quantidade"); // stock atual + quantidade ja reservada
%>
                <tr class="item-encomenda">
                    <td>
                        <%= rs.getString("nome") %>
                        <input type="hidden" name="item_id" value="<%= rs.getInt("id") %>">
                    </td>
                    <td>
                        <span class="item-preco" data-preco="<%= rs.getDouble("preco_unitario") %>">
                            <%= String.format("%.2f", rs.getDouble("preco_unitario")) %> &euro;
                        </span>
                    </td>
                    <td>
                        <input type="number" name="quantidade" class="item-quantidade" 
                               value="<%= rs.getInt("quantidade") %>" min="0" max="<%= stockDisp %>" 
                               style="width: 80px;" onchange="atualizarTotalEncomenda();">
                    </td>
                    <td class="item-subtotal">
                        <%= String.format("%.2f", rs.getDouble("preco_unitario") * rs.getInt("quantidade")) %> &euro;
                    </td>
                </tr>
<%
        }
        rs.close();
        pstmt.close();
%>
            </tbody>
        </table>
        
        <div class="text-right" style="font-size: 1.3em; padding: 15px;">
            Total: <strong id="total-encomenda"><%= String.format("%.2f", valorAnterior) %> &euro;</strong>
        </div>
    </div>
    
    <div class="card">
        <div class="form-group">
            <label for="observacoes">Observações:</label>
            <textarea id="observacoes" name="observacoes"><%= observacoesAtuais != null ? observacoesAtuais : "" %></textarea>
        </div>
        
        <div class="btn-group">
            <button type="submit" class="btn btn-primary">Guardar Alterações</button>
            <a href="cliente_encomendas.jsp" class="btn btn-secondary">Cancelar</a>
        </div>
    </div>
</form>

<%
    } catch (Exception e) {
%>
    <div class="alert alert-error">Erro: <%= e.getMessage() %></div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<script src="scripts.js"></script>
<%@ include file="footer.jsp" %>
