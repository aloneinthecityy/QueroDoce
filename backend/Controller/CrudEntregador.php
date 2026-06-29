<?php
ob_start();
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);

require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Tb_Entregador.php');
require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Banco.php');

/* ------------------- REQUEST ------------------- */

$i_id_entregador  = isset($_REQUEST['id_entregador']) ? $_REQUEST['id_entregador'] : 0;
$s_tp_locomocao   = isset($_REQUEST['tp_locomocao']) ? $_REQUEST['tp_locomocao'] : "";
$s_nu_cnh         = isset($_REQUEST['nu_cnh']) ? $_REQUEST['nu_cnh'] : "";
$s_nm_pessoa      = isset($_REQUEST['nm_pessoa']) ? $_REQUEST['nm_pessoa'] : "";
$s_nu_cpf         = isset($_REQUEST['nu_cpf']) ? $_REQUEST['nu_cpf'] : "";
$s_nu_cel         = isset($_REQUEST['nu_cel']) ? $_REQUEST['nu_cel'] : "";
$s_nu_cep         = isset($_REQUEST['nu_cep']) ? $_REQUEST['nu_cep'] : "";
$s_ds_complemento = isset($_REQUEST['ds_complemento']) ? $_REQUEST['ds_complemento'] : "";
$i_nu_endereco    = isset($_REQUEST['nu_endereco']) ? $_REQUEST['nu_endereco'] : 0;

$s_ds_email       = isset($_REQUEST['ds_email']) ? $_REQUEST['ds_email'] : "";
$s_ds_senha       = isset($_REQUEST['ds_senha']) ? $_REQUEST['ds_senha'] : "";

/* ------------------- OPER ------------------- */

$Oper = isset($_REQUEST['oper']) ? $_REQUEST['oper'] : "";

try {

    $banco = new Banco(null, null, null, null, null, null);

    $Tb_entregador = new Tb_Entregador($banco);

    $Tb_entregador->setOper($Oper);
    $Tb_entregador->SetIdEntregador($i_id_entregador);
    $Tb_entregador->SetTpLocomocao($s_tp_locomocao);
    $Tb_entregador->SetNuCNH($s_nu_cnh);
    $Tb_entregador->SetNmPessoa($s_nm_pessoa);
    $Tb_entregador->SetNuCPF($s_nu_cpf);
    $Tb_entregador->SetNuCel($s_nu_cel);
    $Tb_entregador->SetDsEmail($s_ds_email);
    $Tb_entregador->SetDsSenha($s_ds_senha);
    $Tb_entregador->SetNuCep($s_nu_cep);
    $Tb_entregador->SetDsComplemento($s_ds_complemento);
    $Tb_entregador->SetNuEndereco($i_nu_endereco);

    switch ($Oper) {

        case 'CadastrarCompleto':
            $Tb_entregador->CadastrarCompleto();
            break;

        case 'Inserir':
            $Tb_entregador->Inserir();
            break;

        case 'Alterar':
            $Tb_entregador->Alterar();
            break;

        case 'Excluir':
            $Tb_entregador->Excluir();
            break;

        case 'Consultar':
            $Tb_entregador->Consultar();
            break;

        case 'Listar':
            $Tb_entregador->Listar();
            break;

        case 'Login':
            $Tb_entregador->LoginEntregador($s_ds_email, $s_ds_senha);
            break;

        default:
            $banco->setMensagem(1, 'Operacao informada nao tratada');
            break;
    }

    $retorno = $banco->getRetorno();
    ob_end_clean();

    if (empty($retorno)) {
        echo json_encode([
            "operacao" => $Oper,
            "NumMens" => 0,
            "Mensagem" => "Erro: resposta vazia do servidor",
            "registros" => 0,
            "dados" => null
        ]);
    } else {
        echo $retorno;
    }

    unset($banco);

} catch (Exception $e) {

    ob_end_clean();

    if (isset($banco)) {
        $banco->setMensagem(0, $e->getMessage());
        echo $banco->getRetorno();
        unset($banco);
    } else {
        echo json_encode([
            "operacao" => $Oper,
            "NumMens" => 0,
            "Mensagem" => $e->getMessage(),
            "registros" => 0,
            "dados" => null
        ]);
    }
}
