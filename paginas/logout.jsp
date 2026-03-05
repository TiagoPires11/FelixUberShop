<%-- =========================================================================
  logout.jsp - Terminar Sessao
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Destroi a sessao do utilizador (logout) e redireciona para
             a pagina de login com mensagem de confirmacao. Invalida todos
             os atributos de sessao para garantir seguranca.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // -------------------------------------------------------------------
    // Invalidar a sessao completamente (remover todos os atributos)
    // e redirecionar para a pagina de login
    // -------------------------------------------------------------------
    session.invalidate();
    
    // Criar nova sessao apenas para a mensagem de feedback
    HttpSession novaSessao = request.getSession(true);
    novaSessao.setAttribute("mensagem_sucesso", "Sessão terminada com sucesso.");
    
    response.sendRedirect("login.jsp");
%>
