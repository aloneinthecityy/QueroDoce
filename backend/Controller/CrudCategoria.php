<?php
header("Access-Control-Allow-Origin: *");

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Tb_Categoria.php');
require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Banco.php');

$i_id_categoria = isset($_REQUEST['id_categoria']) ? $_REQUEST['id_categoria'] : 0;
$s_nm_categoria = isset($_REQUEST['nm_categoria']) ? $_REQUEST['nm_categoria'] : "";

$Oper = isset($_REQUEST['oper']) ? $_REQUEST['oper'] : "";

try {
    $banco = new Banco(null, null, null, null, null, null);
    $Tb_categoria = new Tb_Categoria($banco);

    $Tb_categoria->setOper($Oper);
    $Tb_categoria->SetIdCategoria($i_id_categoria);
    $Tb_categoria->SetNmCategoria($s_nm_categoria);

    switch ($Oper) {
        case 'Inserir':
            $Tb_categoria->Inserir();
            break;
        case 'Alterar':
            $Tb_categoria->AlterarDadosCategoria();
            break;
        case 'Excluir':
            $Tb_categoria->Excluir();
            break;
        case 'Consultar':
            $Tb_categoria->Consultar();
            break;
        case 'Listar':
            $Tb_categoria->Listar();
            break;
        default:
            $banco->setMensagem(1, 'Operacao informada nao tratada');
            break;
    }

    echo $banco->getRetorno();
    unset($banco);
} catch (Exception $e) {
    if (isset($banco)) {
        $banco->setMensagem(1, $e->getMessage());
        echo $banco->getRetorno();
        unset($banco);
    } else {
        echo $e->getMessage();
    }
}

