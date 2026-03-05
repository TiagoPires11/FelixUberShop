<%-- =========================================================================
  erro.jsp - Pagina de Erro
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Pagina generica de erro para erros 404 e 500.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ include file="header.jsp" %>

<div class="card" style="text-align:center; padding:40px;">
    <h1 style="font-size:3em; color:#c62828;">&#9888; Erro</h1>
    <% 
        Integer statusCode = (Integer) request.getAttribute("javax.servlet.error.status_code");
        if (statusCode == null) statusCode = 0;
    %>
    <% if (statusCode == 404) { %>
        <h2>Página Não Encontrada (404)</h2>
        <p>A página que procura não existe ou foi removida.</p>
    <% } else if (statusCode == 500) { %>
        <h2>Erro Interno do Servidor (500)</h2>
        <p>Ocorreu um erro inesperado. Tente novamente mais tarde.</p>
    <% } else { %>
        <h2>Ocorreu um Erro</h2>
        <p>Algo não correu como esperado.</p>
    <% } %>
    <br>
    <a href="index.jsp" class="btn btn-primary">&#127968; Voltar à Página Inicial</a>
</div>

<%@ include file="footer.jsp" %>
