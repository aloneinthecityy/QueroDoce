<?php
ob_start();
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);
require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Tb_Produto.php');

require_once('..' . DIRECTORY_SEPARATOR . 'Model' . DIRECTORY_SEPARATOR . 'Banco.php');

$s_nm_produto      = isset($_REQUEST['nm_produto']) ? $_REQUEST['nm_produto'] : "";
$i_id_produto      = isset($_REQUEST['id_produto']) ? $_REQUEST['id_produto'] : 0;
$i_id_empresa      = isset($_REQUEST['id_empresa']) ? $_REQUEST['id_empresa'] : 0;
$s_ds_produto         = isset($_REQUEST['ds_produto']) ? $_REQUEST['ds_produto'] : "";
$s_nm_imagem       = isset($_REQUEST['nm_imagem']) ? $_REQUEST['nm_imagem'] : "";
$s_vl_produto       = isset($_REQUEST['vl_produto']) ? $_REQUEST['vl_produto'] : "";
$s_nu_qtd       = isset($_REQUEST['nu_qtd']) ? $_REQUEST['nu_qtd'] : "";
$s_fl_disponivel         = isset($_REQUEST['fl_disponivel']) ? $_REQUEST['fl_disponivel'] : "";

/*-------------------------------------------------------------*/

$Oper       =  isset($_REQUEST['oper'])    ? $_REQUEST['oper'] : "";


try {
    $banco = new Banco(null, null, null, null, null, null);

    $Tb_produto = new Tb_produto($banco);

    $Tb_produto->setOper($Oper);
    $Tb_produto->SetIdProduto($i_id_produto);
    $Tb_produto->SetIdEmpresa($i_id_empresa);
    $Tb_produto->SetNmProduto($s_nm_produto);
    $Tb_produto->SetDsProduto($s_ds_produto);
    $Tb_produto->SetNmImagem($s_nm_imagem);
    $Tb_produto->SetVlProduto($s_vl_produto);
    $Tb_produto->SetNuQtd($s_nu_qtd);
    $Tb_produto->SetFlDisponivel($s_fl_disponivel);


    switch ($Oper) {
                case 'PesquisarPorNome':
                    $nm_produto = isset($_REQUEST['nm_produto']) ? $_REQUEST['nm_produto'] : "";
                    $Tb_produto->PesquisarPorNome($nm_produto);
                    break;
        case 'Inserir':
            $Tb_produto->Inserir();
            break;
        case 'Alterar':
            $Tb_produto->AlterarDadosProduto();
            break;
        case 'Excluir':
            $Tb_produto->Excluir();
            break;
        case 'Consultar':
            $Tb_produto->Consultar();
            break;
        case 'Listar':
            $Tb_produto->Listar();
            break;
        case 'ListarProdutosPorEmpresa':
            $id_empresa = isset($_REQUEST['id_empresa']) ? intval($_REQUEST['id_empresa']) : 0;
            $Tb_produto->ListarPorEmpresa($id_empresa);
            break;
        case 'ListarProdutosPorCategoria':
            $id_categoria = isset($_REQUEST['id_categoria']) ? intval($_REQUEST['id_categoria']) : 0;
            $Tb_produto->ListarProdutosPorCategoria($id_categoria);
            break;
        case 'ListarProdutosRecentes':
            $Tb_produto->ListarProdutosRecentes();
            break;
        default:
            $banco->setMensagem(1, 'Operacao informada nao tratada');
            break;
    }

    ob_end_clean();
    echo $banco->getRetorno();
    unset($banco);
} catch (Exception $e) {
    ob_end_clean();
    error_log("Erro em CrudProduto: " . $e->getMessage() . " | Operação: " . (isset($Oper) ? $Oper : "N/A"));
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
    error_log("Erro fatal em CrudProduto: " . $e->getMessage() . " | Operação: " . (isset($Oper) ? $Oper : "N/A"));
    echo json_encode(array(
        "operacao" => isset($Oper) ? $Oper : "",
        "NumMens" => 0,
        "Mensagem" => "Erro interno do servidor: " . $e->getMessage(),
        "registros" => 0,
        "dados" => null
    ));
}
