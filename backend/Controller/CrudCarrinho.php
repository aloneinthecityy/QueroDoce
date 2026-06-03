<?php
ob_start();
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);
require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Tb_Carrinho.php');
require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Banco.php');

$i_id_pessoa = isset($_REQUEST['id_pessoa']) ? $_REQUEST['id_pessoa'] : 0;
$i_id_produto = isset($_REQUEST['id_produto']) ? $_REQUEST['id_produto'] : 0;
$i_nu_qtd = isset($_REQUEST['nu_qtd']) ? $_REQUEST['nu_qtd'] : 1;

$Oper = isset($_REQUEST['oper']) ? $_REQUEST['oper'] : "";

try {
    $banco = new Banco(null, null, null, null, null, null);
    $Tb_carrinho = new Tb_Carrinho($banco);

    $Tb_carrinho->setOper($Oper);
    $Tb_carrinho->SetIdPessoa($i_id_pessoa);
    $Tb_carrinho->SetIdProduto($i_id_produto);
    $Tb_carrinho->SetNuQtd($i_nu_qtd);

    switch ($Oper) {
        case 'Inserir':
            $Tb_carrinho->Inserir();
            break;
        case 'AlterarQuantidade':
            $Tb_carrinho->AlterarQuantidade();
            break;
        case 'Excluir':
            $Tb_carrinho->Excluir();
            break;
        case 'ListarPorPessoa':
            $id_pessoa = isset($_REQUEST['id_pessoa']) ? intval($_REQUEST['id_pessoa']) : 0;
            $Tb_carrinho->ListarPorPessoa($id_pessoa);
            break;
        case 'LimparCarrinho':
            $id_pessoa = isset($_REQUEST['id_pessoa']) ? intval($_REQUEST['id_pessoa']) : 0;
            $Tb_carrinho->LimparCarrinho($id_pessoa);
            break;
        default:
            $banco->setMensagem(1, 'Operacao informada nao tratada');
            break;
    }

    $retorno = $banco->getRetorno();
    ob_end_clean();
    echo $retorno;
    unset($banco);
} catch (Exception $e) {
    ob_end_clean();
    if (isset($banco)) {
        $banco->setMensagem(0, $e->getMessage());
        echo $banco->getRetorno();
        unset($banco);
    } else {
        echo json_encode(array(
            "operacao" => isset($Oper) ? $Oper : "",
            "NumMens" => 0,
            "Message" => $e->getMessage(),
            "registros" => 0,
            "dados" => null
        ));
    }
}
