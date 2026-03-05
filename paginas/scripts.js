/* ============================================================================
   scripts.js - JavaScript Auxiliar da Aplicacao FelixUberShop
   Autor: Tiago Pires
   Data: 2025/2026
   Descricao: Funcoes JavaScript para validacao de formularios no lado do
              cliente e interacoes da interface (confirmacoes, etc.).
   ============================================================================ */

/**
 * confirmarAcao() - Mostra uma caixa de confirmacao antes de executar uma acao
 * Utilizado em botoes de eliminar/cancelar/inativar para evitar acoes acidentais.
 * @param {string} mensagem - Texto a apresentar na caixa de confirmacao
 * @returns {boolean} - true se o utilizador confirmar, false caso contrario
 */
function confirmarAcao(mensagem) {
    return confirm(mensagem || 'Tem a certeza que deseja realizar esta ação?');
}

/**
 * validarFormLogin() - Valida o formulario de login antes do envio
 * Verifica se os campos username e password estao preenchidos.
 * @returns {boolean} - true se valido, false se invalido
 */
function validarFormLogin() {
    var username = document.getElementById('username').value.trim();
    var password = document.getElementById('password').value.trim();

    if (username === '') {
        alert('Por favor, introduza o nome de utilizador.');
        document.getElementById('username').focus();
        return false;
    }
    if (password === '') {
        alert('Por favor, introduza a password.');
        document.getElementById('password').focus();
        return false;
    }
    return true;
}

/**
 * validarFormRegisto() - Valida o formulario de registo antes do envio
 * Verifica campos obrigatorios, formato de email e confirmacao de password.
 * @returns {boolean} - true se valido, false se invalido
 */
function validarFormRegisto() {
    var nome = document.getElementById('nome').value.trim();
    var email = document.getElementById('email').value.trim();
    var username = document.getElementById('username').value.trim();
    var password = document.getElementById('password').value;
    var password2 = document.getElementById('password2').value;

    if (nome === '') {
        alert('Por favor, introduza o seu nome.');
        return false;
    }
    if (email === '') {
        alert('Por favor, introduza o seu email.');
        return false;
    }
    // Validacao simples de formato de email
    var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        alert('Por favor, introduza um email válido.');
        return false;
    }
    if (username === '') {
        alert('Por favor, introduza um nome de utilizador.');
        return false;
    }
    if (username.length < 3) {
        alert('O nome de utilizador deve ter pelo menos 3 caracteres.');
        return false;
    }
    if (password === '') {
        alert('Por favor, introduza uma password.');
        return false;
    }
    if (password.length < 4) {
        alert('A password deve ter pelo menos 4 caracteres.');
        return false;
    }
    if (password !== password2) {
        alert('As passwords não coincidem.');
        return false;
    }
    return true;
}

/**
 * validarValorMonetario() - Valida um valor monetario num formulario
 * Verifica se o valor e numerico e positivo.
 * @param {string} idCampo - ID do campo input a validar
 * @returns {boolean} - true se valido, false se invalido
 */
function validarValorMonetario(idCampo) {
    var valor = document.getElementById(idCampo).value;
    if (valor === '' || isNaN(valor) || parseFloat(valor) <= 0) {
        alert('Por favor, introduza um valor válido (maior que 0).');
        document.getElementById(idCampo).focus();
        return false;
    }
    return true;
}

/**
 * atualizarTotalEncomenda() - Calcula e atualiza o total da encomenda
 * Percorre os itens selecionados e calcula o valor total em tempo real.
 */
function atualizarTotalEncomenda() {
    var total = 0;
    var linhas = document.querySelectorAll('.item-encomenda');
    
    linhas.forEach(function(linha) {
        var quantidade = parseInt(linha.querySelector('.item-quantidade').value) || 0;
        var preco = parseFloat(linha.querySelector('.item-preco').getAttribute('data-preco')) || 0;
        var subtotal = quantidade * preco;
        
        // Atualizar subtotal da linha
        var subtotalEl = linha.querySelector('.item-subtotal');
        if (subtotalEl) {
            subtotalEl.textContent = subtotal.toFixed(2) + ' €';
        }
        
        total += subtotal;
    });
    
    // Atualizar total geral
    var totalEl = document.getElementById('total-encomenda');
    if (totalEl) {
        totalEl.textContent = total.toFixed(2) + ' €';
    }
}
