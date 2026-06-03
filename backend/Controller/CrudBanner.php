<?php
header("Access-Control-Allow-Origin: *");

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Tb_Banner.php');
require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Banco.php');

$i_id_banner = isset($_REQUEST['id_banner']) ? $_REQUEST['id_banner'] : 0;
$s_dt_banner = isset($_REQUEST['dt_banner']) ? $_REQUEST['dt_banner'] : "";
$s_nm_imagem = isset($_REQUEST['nm_imagem']) ? $_REQUEST['nm_imagem'] : "";

$Oper = isset($_REQUEST['oper']) ? $_REQUEST['oper'] : "";

try {
    $banco = new Banco(null, null, null, null, null, null);
    $Tb_banner = new Tb_Banner($banco);

    $Tb_banner->setOper($Oper);
    $Tb_banner->SetIdBanner($i_id_banner);
    $Tb_banner->SetDtBanner($s_dt_banner);
    $Tb_banner->SetNmImagem($s_nm_imagem);

    switch ($Oper) {
        case 'Inserir':
            $Tb_banner->Inserir();
            break;
        case 'Alterar':
            $Tb_banner->AlterarDadosBanner();
            break;
        case 'Excluir':
            $Tb_banner->Excluir();
            break;
        case 'Consultar':
            $Tb_banner->Consultar();
            break;
        case 'Listar':
            $Tb_banner->Listar();
            break;
        case 'BuscarUltimoBanner':
            $Tb_banner->BuscarUltimoBanner();
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

