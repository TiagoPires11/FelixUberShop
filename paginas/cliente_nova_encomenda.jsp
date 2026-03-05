<%-- =========================================================================
  cliente_nova_encomenda.jsp - Nova Encomenda
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Permite ao cliente criar uma nova encomenda selecionando
             produtos e quantidades. Calcula o total, verifica saldo
             disponivel na carteira, efetua o pagamento (transferencia
             da carteira do cliente para a carteira da FelixUberShop)
             e gera um codigo unico para a encomenda.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "cliente"; %>
<%@ include file="auth_check.jsp" %>

<%
    int userId = (Integer) session.getAttribute("user_id");
    String erro = null;
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
        
        // -------------------------------------------------------------------
        // Processar nova encomenda (POST)
        // -------------------------------------------------------------------
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String[] produtoIds = request.getParameterValues("produto_id");
            String[] quantidades = request.getParameterValues("quantidade");
            String observacoes = request.getParameter("observacoes");
            
            if (produtoIds == null || produtoIds.length == 0) {
                erro = "Selecione pelo menos um produto.";
            } else {
                conn.setAutoCommit(false); // Iniciar transacao
                
                // Calcular valor total da encomenda
                double valorTotal = 0;
                java.util.ArrayList<int[]> itens = new java.util.ArrayList<int[]>(); // [produtoId, quantidade]
                java.util.ArrayList<Double> precos = new java.util.ArrayList<Double>();
                
                for (int i = 0; i < produtoIds.length; i++) {
                    int qtd = 0;
                    try { qtd = Integer.parseInt(quantidades[i]); } catch (Exception ex) {}
                    
                    if (qtd > 0) {
                        int prodId = Integer.parseInt(produtoIds[i]);
                        
                        // Obter preco e verificar stock do produto
                        pstmt = conn.prepareStatement("SELECT preco, stock FROM produtos WHERE id = ? AND ativo = 1");
                        pstmt.setInt(1, prodId);
                        rs = pstmt.executeQuery();
                        
                        if (rs.next()) {
                            double preco = rs.getDouble("preco");
                            int stock = rs.getInt("stock");
                            
                            if (qtd > stock) {
                                erro = "Stock insuficiente para um dos produtos selecionados.";
                                rs.close();
                                pstmt.close();
                                conn.rollback();
                                break;
                            }
                            
                            itens.add(new int[]{prodId, qtd});
                            precos.add(preco);
                            valorTotal += preco * qtd;
                        }
                        rs.close();
                        pstmt.close();
                    }
                }
                
                if (erro == null && itens.isEmpty()) {
                    erro = "Selecione pelo menos um produto com quantidade maior que 0.";
                }
                
                if (erro == null) {
                    // Verificar saldo do cliente
                    pstmt = conn.prepareStatement("SELECT id, saldo FROM carteiras WHERE id_utilizador = ? AND tipo = 'cliente'");
                    pstmt.setInt(1, userId);
                    rs = pstmt.executeQuery();
                    
                    int carteiraClienteId = 0;
                    double saldoCliente = 0;
                    if (rs.next()) {
                        carteiraClienteId = rs.getInt("id");
                        saldoCliente = rs.getDouble("saldo");
                    }
                    rs.close();
                    pstmt.close();
                    
                    if (valorTotal > saldoCliente) {
                        erro = "Saldo insuficiente. Necessita de " + String.format("%.2f", valorTotal) + 
                               " € mas tem " + String.format("%.2f", saldoCliente) + " €.";
                        conn.rollback();
                    } else {
                        // Obter carteira da loja
                        pstmt = conn.prepareStatement("SELECT id FROM carteiras WHERE tipo = 'loja'");
                        rs = pstmt.executeQuery();
                        int carteiraLojaId = 0;
                        if (rs.next()) carteiraLojaId = rs.getInt("id");
                        rs.close();
                        pstmt.close();
                        
                        // Gerar codigo unico (8 caracteres alfanumericos)
                        String codigoUnico = java.util.UUID.randomUUID().toString().substring(0, 8).toUpperCase();
                        
                        // Criar encomenda
                        pstmt = conn.prepareStatement(
                            "INSERT INTO encomendas (id_cliente, codigo_unico, estado, valor_total, observacoes) " +
                            "VALUES (?, ?, 'pendente', ?, ?)",
                            Statement.RETURN_GENERATED_KEYS
                        );
                        pstmt.setInt(1, userId);
                        pstmt.setString(2, codigoUnico);
                        pstmt.setDouble(3, valorTotal);
                        pstmt.setString(4, observacoes != null && !observacoes.trim().isEmpty() ? observacoes.trim() : null);
                        pstmt.executeUpdate();
                        
                        rs = pstmt.getGeneratedKeys();
                        int encomendaId = 0;
                        if (rs.next()) encomendaId = rs.getInt(1);
                        rs.close();
                        pstmt.close();
                        
                        // Inserir itens da encomenda e atualizar stock
                        for (int i = 0; i < itens.size(); i++) {
                            int[] item = itens.get(i);
                            double preco = precos.get(i);
                            
                            // Inserir item
                            pstmt = conn.prepareStatement(
                                "INSERT INTO itens_encomenda (id_encomenda, id_produto, quantidade, preco_unitario) VALUES (?, ?, ?, ?)"
                            );
                            pstmt.setInt(1, encomendaId);
                            pstmt.setInt(2, item[0]);
                            pstmt.setInt(3, item[1]);
                            pstmt.setDouble(4, preco);
                            pstmt.executeUpdate();
                            pstmt.close();
                            
                            // Atualizar stock
                            pstmt = conn.prepareStatement("UPDATE produtos SET stock = stock - ? WHERE id = ?");
                            pstmt.setInt(1, item[1]);
                            pstmt.setInt(2, item[0]);
                            pstmt.executeUpdate();
                            pstmt.close();
                        }
                        
                        // Transferir valor: debitar carteira cliente
                        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id = ?");
                        pstmt.setDouble(1, valorTotal);
                        pstmt.setInt(2, carteiraClienteId);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        // Transferir valor: creditar carteira loja
                        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id = ?");
                        pstmt.setDouble(1, valorTotal);
                        pstmt.setInt(2, carteiraLojaId);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        // Registar operacao de auditoria (pagamento)
                        pstmt = conn.prepareStatement(
                            "INSERT INTO operacoes_carteira (id_carteira_origem, id_carteira_destino, tipo_operacao, valor, descricao) " +
                            "VALUES (?, ?, 'pagamento', ?, ?)"
                        );
                        pstmt.setInt(1, carteiraClienteId);
                        pstmt.setInt(2, carteiraLojaId);
                        pstmt.setDouble(3, valorTotal);
                        pstmt.setString(4, "Pagamento da encomenda " + codigoUnico);
                        pstmt.executeUpdate();
                        pstmt.close();
                        
                        conn.commit();
                        
                        session.setAttribute("mensagem_sucesso", 
                            "Encomenda criada com sucesso! Código: " + codigoUnico);
                        response.sendRedirect("cliente_encomendas.jsp");
                        return;
                    }
                }
            }
        }
        
    } catch (Exception e) {
        try { if (conn != null) conn.rollback(); } catch (Exception ex) {}
        erro = "Erro ao processar encomenda: " + e.getMessage();
    }
%>

<%@ include file="header.jsp" %>

<h1 class="page-title">&#128722; Nova Encomenda</h1>

<% if (erro != null) { %>
    <div class="alert alert-error"><%= erro %></div>
<% } %>

<%-- Mostrar saldo disponivel --%>
<%
    try {
        if (conn == null || conn.isClosed()) conn = getConnection();
        
        pstmt = conn.prepareStatement("SELECT saldo FROM carteiras WHERE id_utilizador = ? AND tipo = 'cliente'");
        pstmt.setInt(1, userId);
        rs = pstmt.executeQuery();
        double saldoAtual = 0;
        if (rs.next()) saldoAtual = rs.getDouble("saldo");
        rs.close();
        pstmt.close();
%>

<div class="alert alert-info">
    &#128176; Saldo disponível: <strong><%= String.format("%.2f", saldoAtual) %> &euro;</strong>
    | <a href="cliente_carteira.jsp">Adicionar saldo</a>
</div>

<%-- Formulario de encomenda com lista de produtos --%>
<form method="post" action="cliente_nova_encomenda.jsp">
    <div class="card">
        <div class="card-header">
            <h2>Selecione os Produtos</h2>
        </div>
        
        <table>
            <thead>
                <tr>
                    <th>Produto</th>
                    <th>Categoria</th>
                    <th>Preço</th>
                    <th>Stock</th>
                    <th>Quantidade</th>
                </tr>
            </thead>
            <tbody>
<%
        // Listar produtos disponiveis (ativos e com stock)
        pstmt = conn.prepareStatement(
            "SELECT p.id, p.nome, p.preco, p.stock, c.nome AS categoria " +
            "FROM produtos p LEFT JOIN categorias c ON p.id_categoria = c.id " +
            "WHERE p.ativo = 1 AND p.stock > 0 ORDER BY c.nome, p.nome"
        );
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
%>
                <tr class="item-encomenda">
                    <td>
                        <strong><%= rs.getString("nome") %></strong>
                        <input type="hidden" name="produto_id" value="<%= rs.getInt("id") %>">
                    </td>
                    <td><%= rs.getString("categoria") != null ? rs.getString("categoria") : "-" %></td>
                    <td>
                        <span class="item-preco" data-preco="<%= rs.getDouble("preco") %>">
                            <%= String.format("%.2f", rs.getDouble("preco")) %> &euro;
                        </span>
                    </td>
                    <td><%= rs.getInt("stock") %></td>
                    <td>
                        <input type="number" name="quantidade" class="item-quantidade" 
                               value="0" min="0" max="<%= rs.getInt("stock") %>" 
                               style="width: 80px;" onchange="atualizarTotalEncomenda();">
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
            Total: <strong id="total-encomenda">0.00 &euro;</strong>
        </div>
    </div>
    
    <div class="card">
        <div class="form-group">
            <label for="observacoes">Observações (opcional):</label>
            <textarea id="observacoes" name="observacoes" placeholder="Notas especiais para a sua encomenda..."></textarea>
        </div>
        
        <div class="btn-group">
            <button type="submit" class="btn btn-primary btn-lg">&#128722; Confirmar Encomenda</button>
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
