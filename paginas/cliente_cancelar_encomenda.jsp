<%-- =========================================================================
  cliente_cancelar_encomenda.jsp - Cancelar Encomenda
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Cancela uma encomenda com estado 'pendente'. Devolve o valor
             total da encomenda a carteira do cliente, repoe o stock dos
             produtos e regista a operacao de reembolso para auditoria.
             So funciona para encomendas do proprio cliente com estado
             'pendente'.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<% String perfilNecessario = "cliente"; %>
<%@ include file="auth_check.jsp" %>

<%
    int userId = (Integer) session.getAttribute("user_id");
    String idParam = request.getParameter("id");
    
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
        conn.setAutoCommit(false);
        
        // Verificar se a encomenda pertence ao cliente e esta pendente
        pstmt = conn.prepareStatement(
            "SELECT id, codigo_unico, valor_total FROM encomendas " +
            "WHERE id = ? AND id_cliente = ? AND estado = 'pendente'"
        );
        pstmt.setInt(1, encomendaId);
        pstmt.setInt(2, userId);
        rs = pstmt.executeQuery();
        
        if (!rs.next()) {
            session.setAttribute("mensagem_erro", "Encomenda não encontrada ou não pode ser cancelada.");
            response.sendRedirect("cliente_encomendas.jsp");
            return;
        }
        
        String codigoUnico = rs.getString("codigo_unico");
        double valorTotal = rs.getDouble("valor_total");
        rs.close();
        pstmt.close();
        
        // -------------------------------------------------------------------
        // 1. Repor stock dos produtos
        // -------------------------------------------------------------------
        pstmt = conn.prepareStatement(
            "SELECT id_produto, quantidade FROM itens_encomenda WHERE id_encomenda = ?"
        );
        pstmt.setInt(1, encomendaId);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            PreparedStatement pstmt2 = conn.prepareStatement(
                "UPDATE produtos SET stock = stock + ? WHERE id = ?"
            );
            pstmt2.setInt(1, rs.getInt("quantidade"));
            pstmt2.setInt(2, rs.getInt("id_produto"));
            pstmt2.executeUpdate();
            pstmt2.close();
        }
        rs.close();
        pstmt.close();
        
        // -------------------------------------------------------------------
        // 2. Devolver valor a carteira do cliente
        // -------------------------------------------------------------------
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
        
        // Creditar carteira do cliente
        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id = ?");
        pstmt.setDouble(1, valorTotal);
        pstmt.setInt(2, carteiraClienteId);
        pstmt.executeUpdate();
        pstmt.close();
        
        // Debitar carteira da loja
        pstmt = conn.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id = ?");
        pstmt.setDouble(1, valorTotal);
        pstmt.setInt(2, carteiraLojaId);
        pstmt.executeUpdate();
        pstmt.close();
        
        // -------------------------------------------------------------------
        // 3. Registar operacao de reembolso para auditoria
        // -------------------------------------------------------------------
        pstmt = conn.prepareStatement(
            "INSERT INTO operacoes_carteira (id_carteira_origem, id_carteira_destino, tipo_operacao, valor, descricao) " +
            "VALUES (?, ?, 'reembolso', ?, ?)"
        );
        pstmt.setInt(1, carteiraLojaId);
        pstmt.setInt(2, carteiraClienteId);
        pstmt.setDouble(3, valorTotal);
        pstmt.setString(4, "Reembolso por cancelamento da encomenda " + codigoUnico);
        pstmt.executeUpdate();
        pstmt.close();
        
        // -------------------------------------------------------------------
        // 4. Atualizar estado da encomenda para 'cancelada'
        // -------------------------------------------------------------------
        pstmt = conn.prepareStatement("UPDATE encomendas SET estado = 'cancelada' WHERE id = ?");
        pstmt.setInt(1, encomendaId);
        pstmt.executeUpdate();
        pstmt.close();
        
        conn.commit();
        
        session.setAttribute("mensagem_sucesso", 
            "Encomenda " + codigoUnico + " cancelada com sucesso. " + 
            String.format("%.2f", valorTotal) + " € devolvidos à sua carteira.");
        response.sendRedirect("cliente_encomendas.jsp");
        
    } catch (Exception e) {
        try { if (conn != null) conn.rollback(); } catch (Exception ex) {}
        session.setAttribute("mensagem_erro", "Erro ao cancelar encomenda: " + e.getMessage());
        response.sendRedirect("cliente_encomendas.jsp");
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>
