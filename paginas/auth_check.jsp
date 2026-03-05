<%-- =========================================================================
  auth_check.jsp - Verificacao de Autenticacao e Autorizacao
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Modulo de protecao de paginas. Verifica se o utilizador tem
             sessao ativa e se o seu perfil tem permissao para aceder
             a pagina atual. Se nao autorizado, redireciona para login.jsp.
  
  Utilizacao: Incluir no topo de cada pagina protegida ANTES de qualquer
              output HTML. Definir a variavel 'perfilNecessario' antes
              de incluir este ficheiro.
  Exemplo:
      <% String perfilNecessario = "cliente"; %>
      <%@ include file="auth_check.jsp" %>
========================================================================= --%>
<%
    // -----------------------------------------------------------------------
    // Verificar se existe sessao ativa (utilizador logado)
    // Se nao existir, redirecionar para a pagina de login com mensagem
    // -----------------------------------------------------------------------
    String authUsername = (String) session.getAttribute("username");
    String authPerfil = (String) session.getAttribute("perfil");

    if (authUsername == null || authPerfil == null) {
        // Utilizador nao esta logado - redirecionar para login
        session.setAttribute("mensagem_erro", "Tem de iniciar sessão para aceder a esta página.");
        response.sendRedirect("login.jsp");
        return;
    }

    // -----------------------------------------------------------------------
    // Verificar se o perfil do utilizador tem permissao para esta pagina
    // A variavel 'perfilNecessario' deve ser definida antes do include.
    // Logica de permissoes:
    //   - "cliente" -> so clientes
    //   - "funcionario" -> funcionarios e admins
    //   - "admin" -> so admins
    //   - "logado" -> qualquer utilizador autenticado
    // -----------------------------------------------------------------------
    if (perfilNecessario != null && !"logado".equals(perfilNecessario)) {
        boolean autorizado = false;

        if ("admin".equals(perfilNecessario)) {
            // Paginas de admin: so administradores
            autorizado = "admin".equals(authPerfil);
        } else if ("funcionario".equals(perfilNecessario)) {
            // Paginas de funcionario: funcionarios E administradores
            autorizado = "funcionario".equals(authPerfil) || "admin".equals(authPerfil);
        } else if ("cliente".equals(perfilNecessario)) {
            // Paginas de cliente: so clientes
            autorizado = "cliente".equals(authPerfil);
        }

        if (!autorizado) {
            // Perfil sem permissao - redirecionar para login com mensagem
            session.setAttribute("mensagem_erro", "Não tem permissão para aceder a esta página.");
            response.sendRedirect("login.jsp");
            return;
        }
    }
%>
