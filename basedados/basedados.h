<%-- =========================================================================
  basedados.h - Modulo de Ligacao a Base de Dados
  Autor: Tiago Pires
  Data: 2025/2026
  Descricao: Este ficheiro contem TODAS as funcoes de ligacao ao MySQL.
             A conexao a base de dados e feita EXCLUSIVAMENTE atraves
             deste modulo. Nenhum outro ficheiro do projeto pode conter
             codigo de conexao ao MySQL diretamente.
  Utilizacao: Incluir no topo dos ficheiros JSP que necessitam de acesso
              a base de dados com: <%@ include file="basedados.h" %>
========================================================================= --%>
<%@ page import="java.sql.*" %>
<%!
    // -----------------------------------------------------------------------
    // Parametros de ligacao a base de dados MySQL
    // Suporta variaveis de ambiente (Railway) ou valores locais (XAMPP)
    // -----------------------------------------------------------------------
    private static String getEnv(String key, String defaultValue) {
        String val = System.getenv(key);
        return (val != null && !val.isEmpty()) ? val : defaultValue;
    }

    private static final String DB_HOST = getEnv("MYSQLHOST", "localhost");
    private static final String DB_PORT = getEnv("MYSQLPORT", "3306");
    private static final String DB_NAME = getEnv("MYSQLDATABASE", "felixubershop");
    private static final String DB_USER = getEnv("MYSQLUSER", "root");
    private static final String DB_PASS = getEnv("MYSQLPASSWORD", "");
    private static final String DB_URL  = "jdbc:mysql://" + DB_HOST + ":" + DB_PORT + "/" + DB_NAME
        + "?useUnicode=true&characterEncoding=UTF-8&useSSL=false&allowPublicKeyRetrieval=true";

    /**
     * getConnection() - Estabelece e retorna uma ligacao a base de dados MySQL.
     * Carrega o driver JDBC do MySQL e cria uma conexao com os parametros
     * definidos acima. No Railway, le automaticamente as variaveis de ambiente.
     * Localmente (XAMPP), usa localhost:3306 com root e sem password.
     *
     * @return Connection - objeto de conexao a base de dados
     * @throws SQLException - se ocorrer erro na conexao
     */
    public Connection getConnection() throws SQLException {
        try {
            // Carregar o driver JDBC do MySQL
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("Driver MySQL JDBC nao encontrado. Verifique se o mysql-connector-j.jar esta em WEB-INF/lib/", e);
        }
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }

    /**
     * fecharConexao() - Fecha de forma segura uma conexao a base de dados.
     * Verifica se a conexao nao e nula e nao esta ja fechada antes de fechar.
     *
     * @param conn - conexao a fechar
     */
    public void fecharConexao(Connection conn) {
        try {
            if (conn != null && !conn.isClosed()) {
                conn.close();
            }
        } catch (SQLException e) {
            // Log silencioso - nao propagar excecao ao fechar
            System.err.println("Erro ao fechar conexao: " + e.getMessage());
        }
    }

    /**
     * fecharRecursos() - Fecha de forma segura ResultSet, Statement e Connection.
     * Util para usar em blocos finally, garantindo que todos os recursos
     * da base de dados sao libertados corretamente.
     *
     * @param rs - ResultSet a fechar (pode ser null)
     * @param stmt - Statement a fechar (pode ser null)
     * @param conn - Connection a fechar (pode ser null)
     */
    public void fecharRecursos(ResultSet rs, Statement stmt, Connection conn) {
        try { if (rs != null) rs.close(); } catch (SQLException e) { /* ignorar */ }
        try { if (stmt != null) stmt.close(); } catch (SQLException e) { /* ignorar */ }
        fecharConexao(conn);
    }
%>
