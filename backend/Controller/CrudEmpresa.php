<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Tb_Empresa.php');

require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Banco.php');

$s_nm_empresa      = isset($_REQUEST['nm_empresa']) ? $_REQUEST['nm_empresa'] : "";
$i_id_empresa      = isset($_REQUEST['id_empresa']) ? $_REQUEST['id_empresa'] : 0;
$s_nu_cnpj         = isset($_REQUEST['nu_cnpj']) ? $_REQUEST['nu_cnpj'] : "";
$s_ds_email       = isset($_REQUEST['ds_email']) ? $_REQUEST['ds_email'] : "";
$s_ds_senha       = isset($_REQUEST['ds_senha']) ? $_REQUEST['ds_senha'] : "";
$s_nu_cep         = isset($_REQUEST['nu_cep']) ? $_REQUEST['nu_cep'] : "";
$s_ds_complemento = isset($_REQUEST['ds_complemento']) ? $_REQUEST['ds_complemento'] : "";
$i_nu_endereco    = isset($_REQUEST['nu_endereco']) ? $_REQUEST['nu_endereco'] : 0;
$s_nm_imagem       = isset($_REQUEST['nm_imagem']) ? $_REQUEST['nm_imagem'] : "";
$i_id_categoria    = isset($_REQUEST['id_categoria']) ? $_REQUEST['id_categoria'] : 0;
$s_id_categorias   = isset($_REQUEST['id_categorias']) ? $_REQUEST['id_categorias'] : $i_id_categoria;



/*-------------------------------------------------------------*/

$Oper       =  isset($_REQUEST['oper'])    ? $_REQUEST['oper'] : "";


try {
    $banco = new Banco(null, null, null, null, null, null);

    $Tb_empresa = new Tb_empresa($banco);

    $Tb_empresa->setOper($Oper);
    $Tb_empresa->SetIdEmpresa($i_id_empresa);
    $Tb_empresa->SetNmEmpresa($s_nm_empresa);
    $Tb_empresa->SetNuCNPJ($s_nu_cnpj);
    $Tb_empresa->SetDsEmail($s_ds_email);
    $Tb_empresa->SetDsSenha($s_ds_senha);
    $Tb_empresa->SetNuCep($s_nu_cep);
    $Tb_empresa->SetDsComplemento($s_ds_complemento);
    $Tb_empresa->SetNuEndereco($i_nu_endereco);
    $Tb_empresa->SetNmImagem($s_nm_imagem);
    $Tb_empresa->SetIdCategoria($s_id_categorias);


    switch ($Oper) {
        case 'Inserir':
            $Tb_empresa->Inserir();
            break;
        case 'Alterar':
            $Tb_empresa->AlterarDadosEmpresa();
            break;
        case 'Excluir':
            $Tb_empresa->Excluir();
            break;
        case 'Consultar':
            $Tb_empresa->Consultar();
            break;
        case 'Listar':
            $Tb_empresa->Listar();
            break;
        case 'Login':
            $Tb_empresa->Login();
            break;
        case 'ListarPorCategoria':
            $id_categoria = isset($_REQUEST['id_categoria']) ? intval($_REQUEST['id_categoria']) : 0;
            $Tb_empresa->ListarPorCategoria($id_categoria);
            break;
        default:
            $banco->setMensagem(1, 'Operacao informada nao tratada');
            break;
    }

    echo $banco->getRetorno();
    unset($banco);
} catch (Exception $e) {
    if (isset($banco)) {
        $banco->setMensagem(0, $e->getMessage());
        echo $banco->getRetorno();
        unset($banco);
    } else {
        echo $e->getMessage();
    }
}
