<?php

class Banco
{
    private $Driver;
    private $Host;
    private $Porta;
    private $User;
    private $Password;
    private $Database;
    private $conexao;
    private $Mensagem;
    private $NumMensagem;
    private $Dados;
    private $NumRegistros;

    /*
   $this->Host     = is_null($p_Host)     ? "200.19.1.18" :$p_Host;
   Use este ip (200.19.1.18) caso sua aplicação esteja na sua máquina (XAMPP)
   Caso sua aplicação tenha sido colocado dentro do seridor de aplicação do IF Gravatai, use
   o IP 192.168.20.18
    
*/
    function __construct(
        $p_Driver,
        $p_Host,
        $p_Porta,
        $p_User,
        $p_Password,
        $p_Database
    ) {
        $this->Abre_Banco($p_Driver, $p_Host, $p_Porta, $p_User, $p_Password, $p_Database);
    }


    function Abre_Banco(
        $p_Driver,
        $p_Host,
        $p_Porta,
        $p_User,
        $p_Password,
        $p_Database
    ) {

        $this->User     = is_null($p_User)     ? "postgres"    : $p_User;
        $this->Password = is_null($p_Password) ? "123456"      : $p_Password;
        $this->Database = is_null($p_Database) ? "querodoce"    : $p_Database;

        $this->Host     = $this->setHost($p_Host);

        $this->Driver   = is_null($p_Driver)   ? "pgsql" : $p_Driver;
        $this->Porta    = is_null($p_Porta)    ? "5432"  : $p_Porta;



        $this->conexao  = null;
        try {
            $this->criaConexao();
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    private function setHost($p_Host)
    {
        if (is_null($p_Host)) {
            $p_Host = "localhost";
        }

        return $p_Host;
    }

    // Função para criar a conexão com o banco de dados

    private function criaConexao()
    {
        try {
            $dsn = $this->Driver .
                ":host="      . $this->Host  .
                ";port="      . $this->Porta .
                ";dbname="    . $this->Database;

            $this->conexao = new PDO(
                $dsn,
                $this->User,
                $this->Password,
                array(
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8" // Para MySQL
                )
            );

            // Garante que a conexão use UTF-8
            if ($this->Driver === 'pgsql') {
                $this->conexao->exec("SET client_encoding TO 'UTF8'");
            }
        } catch (PDOException $e) {
            throw new Exception($e->getMessage());
        } catch (Exception $e) {
            throw new Exception("Usuario/Senha Inexistentes");
        }
    }

    public function getConexao()
    {
        return $this->conexao;
    }

    public function setMensagem($p_num, $p_mensagem)
    {
        $this->NumMensagem = $p_num;
        $this->Mensagem    = $p_mensagem;
    }

    public function setDados($p_numRegistros, $p_dados)
    {
        $this->Dados = $p_dados;
        $this->NumRegistros = $p_numRegistros;
    }

    private function converterParaUTF8($dados)
    {
        if (is_array($dados)) {
            foreach ($dados as $chave => $valor) {
                $dados[$chave] = $this->converterParaUTF8($valor);
            }
        } elseif (is_string($dados)) {
            // Verifica se a string já está em UTF-8 válido
            if (!mb_check_encoding($dados, 'UTF-8')) {
                // Tenta detectar e converter o encoding
                $encoding = mb_detect_encoding($dados, array('UTF-8', 'ISO-8859-1', 'Windows-1252'), true);
                if ($encoding && $encoding !== 'UTF-8') {
                    $dados = mb_convert_encoding($dados, 'UTF-8', $encoding);
                } else {
                    // Se não conseguir detectar, tenta converter de ISO-8859-1
                    $dados = @mb_convert_encoding($dados, 'UTF-8', 'ISO-8859-1');
                }
            }

            // Remove caracteres de controle inválidos (mantém caracteres especiais válidos)
            $dados = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/u', '', $dados);

            // Garante que a string está em UTF-8 válido após limpeza
            if (!mb_check_encoding($dados, 'UTF-8')) {
                // Se ainda não estiver válido, tenta usar iconv
                $dados = @iconv('UTF-8', 'UTF-8//IGNORE', $dados);
            }
        }
        return $dados;
    }

    public function getRetorno()
    {
        try {
            $operacao = isset($GLOBALS["Oper"]) ? $GLOBALS["Oper"] : (isset($_REQUEST['oper']) ? $_REQUEST['oper'] : "");

            // Converte todos os dados para UTF-8 antes de fazer json_encode
            $dadosUTF8 = $this->converterParaUTF8($this->Dados);
            $mensagemUTF8 = $this->converterParaUTF8($this->Mensagem);

            $retorno = array(
                "operacao"  => $operacao,
                "NumMens"   => $this->NumMensagem,
                "Mensagem"  => $mensagemUTF8,
                "registros" => $this->NumRegistros,
                "dados"     => $dadosUTF8
            );

            // Usa JSON_UNESCAPED_UNICODE para manter caracteres especiais corretamente
            $json = json_encode($retorno, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

            if (json_last_error() !== JSON_ERROR_NONE) {
                error_log("Banco::getRetorno JSON Error: " . json_last_error_msg());
                // Retorna JSON de erro se houver problema na serialização
                return json_encode(array(
                    "operacao"  => $operacao,
                    "NumMens"   => 0,
                    "Mensagem"  => "Erro ao gerar resposta JSON: " . json_last_error_msg(),
                    "registros" => 0,
                    "dados"     => null
                ), JSON_UNESCAPED_UNICODE);
            }

            return $json;
        } catch (Exception $e) {
            error_log("Banco::getRetorno Exception: " . $e->getMessage());
            $operacao = isset($GLOBALS["Oper"]) ? $GLOBALS["Oper"] : (isset($_REQUEST['oper']) ? $_REQUEST['oper'] : "");
            return json_encode(array(
                "operacao"  => $operacao,
                "NumMens"   => 0,
                "Mensagem"  => "Erro ao gerar resposta: " . $e->getMessage(),
                "registros" => 0,
                "dados"     => null
            ), JSON_UNESCAPED_UNICODE);
        }
    }

    public function ErroConexao()
    {
        echo array("Erro" => "Falha com a Conexão do Banco de Dados");
    }

    public function Consiste_Param()
    {
        $GLOBALS["Dados"] =  isset($_REQUEST['dados']) ? $_REQUEST['dados'] : "";
        $GLOBALS["Oper"]  =  isset($_REQUEST['oper']) ? $_REQUEST['oper'] : "";
        if (empty($GLOBALS["Dados"])) {
            throw new Exception("Dados nao fornecidos");
        }
        if (empty($GLOBALS["Oper"])) {
            throw new Exception("Operacao nao fornecida");
        }
        $GLOBALS["Dados"] = json_decode($GLOBALS["Dados"]);
    }
}
