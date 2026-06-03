<?php
ob_start();
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);
require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Tb_Pessoa.php');

require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Banco.php');

$s_nm_pessoa      = isset($_REQUEST['nm_pessoa']) ? $_REQUEST['nm_pessoa'] : "";
$i_id_pessoa      = isset($_REQUEST['id_pessoa']) ? $_REQUEST['id_pessoa'] : 0;
$s_nu_cpf         = isset($_REQUEST['nu_cpf']) ? $_REQUEST['nu_cpf'] : "";
$s_nu_cel         = isset($_REQUEST['nu_cel']) ? $_REQUEST['nu_cel'] : "";
$s_ds_email       = isset($_REQUEST['ds_email']) ? $_REQUEST['ds_email'] : "";
$s_ds_senha       = isset($_REQUEST['ds_senha']) ? $_REQUEST['ds_senha'] : "";
$s_nu_cep         = isset($_REQUEST['nu_cep']) ? $_REQUEST['nu_cep'] : "";
$s_ds_complemento = isset($_REQUEST['ds_complemento']) ? $_REQUEST['ds_complemento'] : "";
$i_nu_endereco    = isset($_REQUEST['nu_endereco']) ? $_REQUEST['nu_endereco'] : 0;



/*-------------------------------------------------------------*/

$Oper       =  isset($_REQUEST['oper'])    ? $_REQUEST['oper'] : "";


try {
    $banco = new Banco(null, null, null, null, null, null);

    $Tb_pessoa = new Tb_pessoa($banco);

    $Tb_pessoa->setOper($Oper);
    $Tb_pessoa->SetIdpessoa($i_id_pessoa);
    $Tb_pessoa->SetNmPessoa($s_nm_pessoa);
    $Tb_pessoa->SetNuCPF($s_nu_cpf);
    $Tb_pessoa->SetNuCel($s_nu_cel);
    $Tb_pessoa->SetDsEmail($s_ds_email);
    $Tb_pessoa->SetDsSenha($s_ds_senha);
    $Tb_pessoa->SetNuCep($s_nu_cep);
    $Tb_pessoa->SetDsComplemento($s_ds_complemento);
    $Tb_pessoa->SetNuEndereco($i_nu_endereco);


    switch ($Oper) {
        case 'Inserir':
            $Tb_pessoa->Inserir();
            break;
        case 'Alterar':
            $Tb_pessoa->AlterarDadospessoa();
            break;
        case 'Excluir':
            $Tb_pessoa->Excluir();
            break;
        case 'Consultar':
            $Tb_pessoa->Consultar();
            break;
        case 'Listar':
            $Tb_pessoa->Listar();
            break;
        case 'Login':
            $Tb_pessoa->Login();
            break;
        case 'BuscarEndereco':
            $id_pessoa = isset($_REQUEST['id_pessoa']) ? intval($_REQUEST['id_pessoa']) : 0;
            $Tb_pessoa->BuscarEndereco($id_pessoa);
            break;
        case 'EsqueceuSenha':
            $Tb_pessoa->EsqueceuSenha();
            break;
        default:
            $banco->setMensagem(1, 'Operacao informada nao tratada');
            break;
    }

    $retorno = $banco->getRetorno();
    ob_end_clean();
    
    if (empty($retorno)) {
        error_log("CrudUsuario: Retorno vazio para operação: " . $Oper);
        echo json_encode(array(
            "operacao" => $Oper,
            "NumMens" => 0,
            "Mensagem" => "Erro: resposta vazia do servidor",
            "registros" => 0,
            "dados" => null
        ));
    } else {
        echo $retorno;
    }
    unset($banco);
} catch (Exception $e) {
    ob_end_clean();
    error_log("CrudUsuario Exception: " . $e->getMessage());
    if (isset($banco)) {
        $banco->setMensagem(0, $e->getMessage());
        echo $banco->getRetorno();
        unset($banco);
    } else {
        echo json_encode(array(
            "operacao" => isset($Oper) ? $Oper : "",
            "NumMens" => 0,
            "Mensagem" => $e->getMessage(),
            "registros" => 0,
            "dados" => null
        ));
    }
} catch (Error $e) {
    ob_end_clean();
    error_log("CrudUsuario Fatal Error: " . $e->getMessage());
    echo json_encode(array(
        "operacao" => isset($Oper) ? $Oper : "",
        "NumMens" => 0,
        "Mensagem" => "Erro fatal: " . $e->getMessage(),
        "registros" => 0,
        "dados" => null
    ));
}
