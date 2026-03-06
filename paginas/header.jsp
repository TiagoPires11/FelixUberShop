<%-- =========================================================================
  header.jsp - Cabecalho e Barra de Navegacao
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Componente reutilizavel que gera o cabecalho HTML, inclusao
             de CSS e a barra de navegacao. O menu adapta-se ao perfil do
             utilizador em sessao (visitante, cliente, funcionario, admin).
             Incluido no topo de todas as paginas via <%@ include %>.
========================================================================= --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FelixUberShop - Mercearia Online</title>
    <link rel="stylesheet" href="estilos.css">
</head>
<body>

<%-- Obter dados da sessao do utilizador (se existir login) --%>
<%
    // Variaveis de sessao para controlo de navegacao
    String sessaoUsername = (session.getAttribute("username") != null) ? (String) session.getAttribute("username") : null;
    String sessaoPerfil = (session.getAttribute("perfil") != null) ? (String) session.getAttribute("perfil") : null;
    String sessaoNome = (session.getAttribute("nome") != null) ? (String) session.getAttribute("nome") : "Utilizador";
    boolean estaLogado = (sessaoUsername != null);
    boolean eCliente = "cliente".equals(sessaoPerfil);
    boolean eFuncionario = "funcionario".equals(sessaoPerfil);
    boolean eAdmin = "admin".equals(sessaoPerfil);
%>

<%-- Barra de navegacao principal --%>
<nav class="navbar">
    <div class="navbar-container">

        <%-- Logo/Brand --%>
        <a href="index.jsp" class="navbar-brand">
            &#127819; FelixUberShop
        </a>

        <%-- Links de navegacao (adaptam-se ao perfil) --%>
        <ul class="navbar-nav">

            <%-- Links publicos (visiveis a todos) --%>
            <li><a href="index.jsp">Início</a></li>
            <li><a href="produtos.jsp">Produtos</a></li>
            <li><a href="promocoes.jsp">Promoções</a></li>

            <%-- Links para Clientes --%>
            <% if (eCliente) { %>
                <li><a href="cliente_dashboard.jsp">Minha Conta</a></li>
                <li><a href="cliente_encomendas.jsp">Encomendas</a></li>
                <li><a href="cliente_carteira.jsp">Carteira</a></li>
            <% } %>

            <%-- Links para Funcionarios --%>
            <% if (eFuncionario) { %>
                <li><a href="func_dashboard.jsp">Painel</a></li>
                <li><a href="func_encomendas.jsp">Encomendas</a></li>
                <li><a href="func_carteiras.jsp">Carteiras</a></li>
            <% } %>

            <%-- Links para Administradores (acesso total) --%>
            <% if (eAdmin) { %>
                <li><a href="admin_dashboard.jsp">Painel Admin</a></li>
                <li><a href="admin_produtos.jsp">Produtos</a></li>
                <li><a href="admin_encomendas.jsp">Encomendas</a></li>
                <li><a href="admin_utilizadores.jsp">Utilizadores</a></li>
                <li><a href="admin_promocoes.jsp">Promoções</a></li>
            <% } %>
        </ul>

        <%-- Area do utilizador (login/logout) --%>
        <div class="navbar-user">
            <% if (estaLogado) { %>
                <%-- Mostrar nome e perfil do utilizador logado --%>
                <span>Olá, <strong><%= sessaoNome %></strong>
                    (<%= sessaoPerfil %>)</span>
                <a href="logout.jsp" class="btn-logout">Sair</a>
            <% } else { %>
                <%-- Links para login e registo --%>
                <a href="login.jsp" class="btn btn-sm btn-secondary">Entrar</a>
                <a href="registo.jsp" class="btn btn-sm btn-primary">Registar</a>
            <% } %>
        </div>

    </div>
</nav>

<%-- Inicio do container principal de conteudo --%>
<div class="container">
