<%-- =========================================================================
  promocoes.jsp - Pagina de Promocoes
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Apresenta todas as promocoes e informacoes dinamicas definidas
             pelos administradores. Mostra promocoes ativas (com data valida)
             e permite ver o historico. Acessivel a todos os perfis.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="basedados.h" %>
<%@ include file="header.jsp" %>

<%
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
%>

<h1 class="page-title">&#127873; Promoções e Informações</h1>

<%-- Promocoes ativas (data atual dentro do intervalo) --%>
<h2 style="color: #2e7d32; margin-bottom: 15px;">Promoções Ativas</h2>

<%
        // Carregar promocoes ativas (data atual entre data_inicio e data_fim)
        pstmt = conn.prepareStatement(
            "SELECT titulo, descricao, data_inicio, data_fim " +
            "FROM promocoes WHERE ativo = 1 AND data_inicio <= CURDATE() AND data_fim >= CURDATE() " +
            "ORDER BY data_fim ASC"
        );
        rs = pstmt.executeQuery();
        
        boolean temAtivas = false;
        while (rs.next()) {
            temAtivas = true;
%>
            <div class="promo-card">
                <h3>&#11088; <%= rs.getString("titulo") %></h3>
                <p><%= rs.getString("descricao") %></p>
                <p class="promo-data">
                    &#128197; Válido de <strong><%= rs.getString("data_inicio") %></strong> 
                    até <strong><%= rs.getString("data_fim") %></strong>
                </p>
            </div>
<%
        }
        
        if (!temAtivas) {
%>
            <div class="card text-center">
                <p class="text-muted">Não existem promoções ativas de momento. Volte em breve!</p>
            </div>
<%
        }
        rs.close();
        pstmt.close();
%>

<%-- Promocoes futuras --%>
<h2 style="color: #2e7d32; margin-top: 30px; margin-bottom: 15px;">Brevemente</h2>

<%
        // Carregar promocoes futuras (data_inicio > hoje)
        pstmt = conn.prepareStatement(
            "SELECT titulo, descricao, data_inicio, data_fim " +
            "FROM promocoes WHERE ativo = 1 AND data_inicio > CURDATE() " +
            "ORDER BY data_inicio ASC"
        );
        rs = pstmt.executeQuery();
        
        boolean temFuturas = false;
        while (rs.next()) {
            temFuturas = true;
%>
            <div class="card">
                <h3 style="color: #0277bd;"><%= rs.getString("titulo") %></h3>
                <p><%= rs.getString("descricao") %></p>
                <p class="text-muted" style="margin-top: 8px;">
                    &#128197; Começa em <strong><%= rs.getString("data_inicio") %></strong>
                </p>
            </div>
<%
        }
        
        if (!temFuturas) {
%>
            <div class="card text-center">
                <p class="text-muted">Não existem promoções agendadas para breve.</p>
            </div>
<%
        }
        rs.close();
        pstmt.close();
        
    } catch (Exception e) {
%>
    <div class="alert alert-error">
        Erro ao carregar promoções: <%= e.getMessage() %>
    </div>
<%
    } finally {
        fecharRecursos(rs, pstmt, conn);
    }
%>

<%@ include file="footer.jsp" %>
