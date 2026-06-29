<?php

require_once(__DIR__ . '/Base.php');

class Tb_Entregador extends Base
{
    private $id_entregador;
    private $tp_locomocao;
    private $nu_cnh;
    private $nm_pessoa;
    private $nu_cpf;
    private $nu_cel;
    private $ds_email;
    private $ds_senha;
    private $nu_cep;
    private $ds_complemento;
    private $nu_endereco;

    function __construct($p_banco)
    {
        parent::__construct($p_banco);
    }

    function SetIdEntregador($id)
    {
        $this->id_entregador = intval($id);
    }

    function SetTpLocomocao($tp)
    {
        $this->tp_locomocao = strtoupper(substr(trim($tp), 0, 1));
    }

    function SetNuCNH($cnh)
    {
        $cnhLimpa = preg_replace('/\D/', '', $cnh);
        $this->nu_cnh = substr($cnhLimpa, 0, 11);
    }

    function SetNmPessoa($nome)
    {
        $this->nm_pessoa = substr(trim($nome), 0, 50);
    }

    function SetNuCPF($cpf)
    {
        $cpfLimpo = preg_replace('/\D/', '', $cpf);
        $this->nu_cpf = substr($cpfLimpo, 0, 11);
    }

    function SetNuCel($cel)
    {
        $celLimpo = preg_replace('/\D/', '', $cel);
        $this->nu_cel = substr($celLimpo, 0, 13);
    }

    function SetDsEmail($email)
    {
        $this->ds_email = substr(trim($email), 0, 100);
    }

    function SetDsSenha($senha)
    {
        $this->ds_senha = $senha;
    }

    function SetNuCep($cep)
    {
        $cepLimpo = preg_replace('/\D/', '', $cep);
        $this->nu_cep = substr($cepLimpo, 0, 8);
    }

    function SetDsComplemento($complemento)
    {
        $this->ds_complemento = substr(trim($complemento), 0, 50);
    }

    function SetNuEndereco($num_endereco)
    {
        $this->nu_endereco = intval($num_endereco);
    }

    private function cpfValido($cpf)
    {
        if (strlen($cpf) != 11 || preg_match('/^(\d)\1{10}$/', $cpf)) {
            return false;
        }

        for ($t = 9; $t < 11; $t++) {
            $soma = 0;
            for ($i = 0; $i < $t; $i++) {
                $soma += intval($cpf[$i]) * (($t + 1) - $i);
            }
            $digito = ((10 * $soma) % 11) % 10;
            if (intval($cpf[$t]) !== $digito) {
                return false;
            }
        }

        return true;
    }

    private function validarCadastroCompleto()
    {
        if (empty($this->nm_pessoa)) {
            throw new Exception("Informe o nome do entregador para continuar.");
        }

        if (!$this->cpfValido($this->nu_cpf)) {
            throw new Exception("Informe um CPF valido.");
        }

        if (empty($this->nu_cel) || strlen($this->nu_cel) < 10) {
            throw new Exception("Informe um celular valido para continuar.");
        }

        if (empty($this->ds_email) || !filter_var($this->ds_email, FILTER_VALIDATE_EMAIL)) {
            throw new Exception("Informe um e-mail valido para o entregador.");
        }

        if (empty($this->ds_senha) || strlen($this->ds_senha) < 6) {
            throw new Exception("Crie uma senha com pelo menos 6 caracteres.");
        }

        if (empty($this->nu_cep) || strlen($this->nu_cep) != 8) {
            throw new Exception("Informe um CEP valido com 8 digitos.");
        }

        if (empty($this->nu_endereco) || $this->nu_endereco <= 0) {
            throw new Exception("Informe o numero do endereco do entregador.");
        }

        if (empty($this->tp_locomocao) || !in_array($this->tp_locomocao, ['M', 'C', 'B'])) {
            throw new Exception("Escolha como o entregador faz as entregas.");
        }

        if ($this->tp_locomocao !== 'B' && (empty($this->nu_cnh) || strlen($this->nu_cnh) != 11)) {
            throw new Exception("Informe uma CNH valida com 11 digitos.");
        }
    }

    private function verificaPessoaCadastro()
    {
        $stmt = $this->conexao->prepare("
            SELECT nu_cpf, ds_email, nu_cel
            FROM tb_pessoa
            WHERE nu_cpf = :nu_cpf OR ds_email = :ds_email OR nu_cel = :nu_cel
            LIMIT 1
        ");
        $stmt->bindValue(':nu_cpf', $this->nu_cpf, PDO::PARAM_STR);
        $stmt->bindValue(':ds_email', $this->ds_email, PDO::PARAM_STR);
        $stmt->bindValue(':nu_cel', $this->nu_cel, PDO::PARAM_STR);
        $stmt->execute();

        $ret = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$ret) {
            return;
        }

        if (isset($ret['ds_email']) && $ret['ds_email'] === $this->ds_email) {
            throw new Exception("Ja existe um entregador cadastrado com esse e-mail.");
        }

        if (isset($ret['nu_cpf']) && $ret['nu_cpf'] === $this->nu_cpf) {
            throw new Exception("Ja existe um cadastro com esse CPF.");
        }

        if (isset($ret['nu_cel']) && $ret['nu_cel'] === $this->nu_cel) {
            throw new Exception("Ja existe um cadastro com esse celular.");
        }

        throw new Exception("Ja existe um cadastro com esses dados.");
    }

    private function verificaPessoaAlteracao()
    {
        $stmt = $this->conexao->prepare("
            SELECT nu_cpf, ds_email, nu_cel
            FROM tb_pessoa
            WHERE id_pessoa != :id_pessoa
              AND (nu_cpf = :nu_cpf OR ds_email = :ds_email OR nu_cel = :nu_cel)
            LIMIT 1
        ");
        $stmt->bindValue(':id_pessoa', $this->id_entregador, PDO::PARAM_INT);
        $stmt->bindValue(':nu_cpf', $this->nu_cpf, PDO::PARAM_STR);
        $stmt->bindValue(':ds_email', $this->ds_email, PDO::PARAM_STR);
        $stmt->bindValue(':nu_cel', $this->nu_cel, PDO::PARAM_STR);
        $stmt->execute();

        $ret = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$ret) {
            return;
        }

        if (isset($ret['ds_email']) && $ret['ds_email'] === $this->ds_email) {
            throw new Exception("Ja existe outro cadastro com esse e-mail.");
        }

        if (isset($ret['nu_cpf']) && $ret['nu_cpf'] === $this->nu_cpf) {
            throw new Exception("Ja existe outro cadastro com esse CPF.");
        }

        if (isset($ret['nu_cel']) && $ret['nu_cel'] === $this->nu_cel) {
            throw new Exception("Ja existe outro cadastro com esse celular.");
        }

        throw new Exception("Ja existe outro cadastro com esses dados.");
    }

    private function validarAlteracaoCompleta()
    {
        if (empty($this->nm_pessoa)) {
            throw new Exception("Informe o nome do entregador para continuar.");
        }

        if (!$this->cpfValido($this->nu_cpf)) {
            throw new Exception("Informe um CPF valido.");
        }

        if (empty($this->nu_cel) || strlen($this->nu_cel) < 10) {
            throw new Exception("Informe um celular valido para continuar.");
        }

        if (empty($this->ds_email) || !filter_var($this->ds_email, FILTER_VALIDATE_EMAIL)) {
            throw new Exception("Informe um e-mail valido para o entregador.");
        }

        if (!empty($this->ds_senha) && strlen($this->ds_senha) < 6) {
            throw new Exception("A nova senha precisa ter pelo menos 6 caracteres.");
        }

        if (empty($this->nu_cep) || strlen($this->nu_cep) != 8) {
            throw new Exception("Informe um CEP valido com 8 digitos.");
        }

        if (empty($this->nu_endereco) || $this->nu_endereco <= 0) {
            throw new Exception("Informe o numero do endereco do entregador.");
        }

        if (empty($this->tp_locomocao) || !in_array($this->tp_locomocao, ['M', 'C', 'B'])) {
            throw new Exception("Escolha como o entregador faz as entregas.");
        }

        if ($this->tp_locomocao !== 'B' && (empty($this->nu_cnh) || strlen($this->nu_cnh) != 11)) {
            throw new Exception("Informe uma CNH valida com 11 digitos.");
        }
    }

    public function LoginEntregador($email, $senha)
    {
        try {
            $stmt = $this->conexao->prepare("
                SELECT * FROM tb_pessoa
                WHERE ds_email = :email
            ");

            $stmt->bindValue(':email', $email, PDO::PARAM_STR);
            $stmt->execute();

            $pessoa = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$pessoa) {
                throw new Exception("E-mail ou senha invalidos.");
            }

            if (!password_verify($senha, $pessoa['ds_senha'])) {
                throw new Exception("E-mail ou senha invalidos.");
            }

            $stmt2 = $this->conexao->prepare("
                SELECT * FROM tb_entregador
                WHERE id_entregador = :id
            ");

            $stmt2->bindValue(':id', $pessoa['id_pessoa'], PDO::PARAM_INT);
            $stmt2->execute();

            $entregador = $stmt2->fetch(PDO::FETCH_ASSOC);

            if (!$entregador) {
                throw new Exception("Essa conta ainda nao esta vinculada a um entregador.");
            }

            $resultado = [
                "id_pessoa" => $pessoa['id_pessoa'],
                "nm_pessoa" => $pessoa['nm_pessoa'],
                "nome" => $pessoa['nm_pessoa'],
                "ds_email" => $pessoa['ds_email'],
                "nu_cel" => $pessoa['nu_cel'],
                "nu_cpf" => $pessoa['nu_cpf'],
                "nu_cep" => $pessoa['nu_cep'],
                "ds_complemento" => $pessoa['ds_complemento'],
                "nu_endereco" => $pessoa['nu_endereco'],
                "tp_locomocao" => $entregador['tp_locomocao'],
                "nu_cnh" => $entregador['nu_cnh']
            ];

            $this->banco->setMensagem(1, "Login permitido");
            $this->banco->setDados(1, $resultado);
        } catch (Exception $e) {
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    public function verificaCNH()
    {
        if (empty($this->nu_cnh)) {
            return;
        }

        $stmt = $this->conexao->prepare("
            SELECT 1 FROM tb_entregador
            WHERE nu_cnh = :nu_cnh
        ");
        $stmt->bindValue(':nu_cnh', $this->nu_cnh, PDO::PARAM_STR);
        $stmt->execute();

        if ($stmt->fetch(PDO::FETCH_ASSOC)) {
            throw new Exception("Ja existe um entregador cadastrado com essa CNH.");
        }
    }

    public function buscaEntregador()
    {
        $stmt = $this->conexao->prepare("
            SELECT * FROM tb_entregador
            WHERE id_entregador = :id
        ");
        $stmt->bindValue(':id', $this->id_entregador, PDO::PARAM_INT);
        $stmt->execute();

        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Entregador nao localizado");
        }

        return $ret;
    }

    public function CadastrarCompleto()
    {
        try {
            $this->validarCadastroCompleto();
            $this->verificaPessoaCadastro();
            $this->verificaCNH();

            $stmtPessoa = $this->conexao->prepare("
                INSERT INTO tb_pessoa (
                    nm_pessoa, nu_cpf, nu_cel, ds_email, ds_senha,
                    nu_cep, ds_complemento, nu_endereco
                ) VALUES (
                    :nm_pessoa, :nu_cpf, :nu_cel, :ds_email, :ds_senha,
                    :nu_cep, :ds_complemento, :nu_endereco
                )
                RETURNING id_pessoa
            ");

            $senhaHash = password_hash($this->ds_senha, PASSWORD_DEFAULT);

            $stmtPessoa->bindValue(':nm_pessoa', $this->nm_pessoa, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':nu_cpf', $this->nu_cpf, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':nu_cel', $this->nu_cel, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':ds_email', $this->ds_email, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':ds_senha', $senhaHash, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':nu_cep', $this->nu_cep, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':ds_complemento', $this->ds_complemento, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':nu_endereco', $this->nu_endereco, PDO::PARAM_INT);

            $stmtEntregador = $this->conexao->prepare("
                INSERT INTO tb_entregador (
                    id_entregador,
                    tp_locomocao,
                    nu_cnh
                ) VALUES (
                    :id_entregador,
                    :tp_locomocao,
                    :nu_cnh
                )
            ");

            $this->conexao->beginTransaction();

            $stmtPessoa->execute();
            $idPessoa = intval($stmtPessoa->fetchColumn());

            if ($idPessoa <= 0) {
                throw new Exception("Nao foi possivel concluir o cadastro do entregador.");
            }

            $stmtEntregador->bindValue(':id_entregador', $idPessoa, PDO::PARAM_INT);
            $stmtEntregador->bindValue(':tp_locomocao', $this->tp_locomocao, PDO::PARAM_STR);
            $nuCnhBanco = $this->tp_locomocao === 'B' ? '' : $this->nu_cnh;
            $stmtEntregador->bindValue(':nu_cnh', $nuCnhBanco, PDO::PARAM_STR);
            $stmtEntregador->execute();

            $this->conexao->commit();

            $this->banco->setMensagem(1, "Cadastro do entregador realizado com sucesso.");
            $this->banco->setDados(1, [
                "id_entregador" => $idPessoa,
                "nm_pessoa" => $this->nm_pessoa,
                "ds_email" => $this->ds_email,
                "nu_cel" => $this->nu_cel,
                "tp_locomocao" => $this->tp_locomocao,
                "nu_cnh" => $nuCnhBanco
            ]);
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    public function Inserir()
    {
        try {
            if (empty($this->tp_locomocao) || !in_array($this->tp_locomocao, ['M', 'C', 'B'])) {
                throw new Exception("Escolha como o entregador faz as entregas.");
            }

            if ($this->tp_locomocao !== 'B' && (empty($this->nu_cnh) || strlen($this->nu_cnh) != 11)) {
                throw new Exception("Informe uma CNH valida com 11 digitos.");
            }

            $this->verificaCNH();

            $stmt = $this->conexao->prepare("
                INSERT INTO tb_entregador (
                    id_entregador,
                    tp_locomocao,
                    nu_cnh
                ) VALUES (
                    :id_entregador,
                    :tp_locomocao,
                    :nu_cnh
                )
            ");

            $stmt->bindValue(':id_entregador', $this->id_entregador, PDO::PARAM_INT);
            $stmt->bindValue(':tp_locomocao', $this->tp_locomocao, PDO::PARAM_STR);
            $stmt->bindValue(':nu_cnh', $this->tp_locomocao === 'B' ? '' : $this->nu_cnh, PDO::PARAM_STR);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Entregador cadastrado com sucesso");
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    public function Alterar()
    {
        try {
            $this->buscaEntregador();
            $this->validarAlteracaoCompleta();
            $this->verificaPessoaAlteracao();

            $nuCnhBanco = $this->tp_locomocao === 'B' ? '' : $this->nu_cnh;
            if (!empty($nuCnhBanco)) {
                $stmtCnh = $this->conexao->prepare("
                    SELECT 1 FROM tb_entregador
                    WHERE nu_cnh = :nu_cnh AND id_entregador != :id_entregador
                    LIMIT 1
                ");
                $stmtCnh->bindValue(':nu_cnh', $nuCnhBanco, PDO::PARAM_STR);
                $stmtCnh->bindValue(':id_entregador', $this->id_entregador, PDO::PARAM_INT);
                $stmtCnh->execute();
                if ($stmtCnh->fetch(PDO::FETCH_ASSOC)) {
                    throw new Exception("Ja existe um entregador cadastrado com essa CNH.");
                }
            }

            $sqlPessoa = "
                UPDATE tb_pessoa SET
                    nm_pessoa = :nm_pessoa,
                    nu_cpf = :nu_cpf,
                    nu_cel = :nu_cel,
                    ds_email = :ds_email,
                    nu_cep = :nu_cep,
                    ds_complemento = :ds_complemento,
                    nu_endereco = :nu_endereco
            ";

            if (!empty($this->ds_senha)) {
                $sqlPessoa .= ", ds_senha = :ds_senha";
            }

            $sqlPessoa .= " WHERE id_pessoa = :id_pessoa";

            $stmtPessoa = $this->conexao->prepare($sqlPessoa);
            $stmtPessoa->bindValue(':id_pessoa', $this->id_entregador, PDO::PARAM_INT);
            $stmtPessoa->bindValue(':nm_pessoa', $this->nm_pessoa, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':nu_cpf', $this->nu_cpf, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':nu_cel', $this->nu_cel, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':ds_email', $this->ds_email, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':nu_cep', $this->nu_cep, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':ds_complemento', $this->ds_complemento, PDO::PARAM_STR);
            $stmtPessoa->bindValue(':nu_endereco', $this->nu_endereco, PDO::PARAM_INT);
            if (!empty($this->ds_senha)) {
                $stmtPessoa->bindValue(':ds_senha', password_hash($this->ds_senha, PASSWORD_DEFAULT), PDO::PARAM_STR);
            }

            $stmtEntregador = $this->conexao->prepare("
                UPDATE tb_entregador SET
                    tp_locomocao = :tp_locomocao,
                    nu_cnh = :nu_cnh
                WHERE id_entregador = :id_entregador
            ");
            $stmtEntregador->bindValue(':id_entregador', $this->id_entregador, PDO::PARAM_INT);
            $stmtEntregador->bindValue(':tp_locomocao', $this->tp_locomocao, PDO::PARAM_STR);
            $stmtEntregador->bindValue(':nu_cnh', $nuCnhBanco, PDO::PARAM_STR);

            $this->conexao->beginTransaction();
            $stmtPessoa->execute();
            $stmtEntregador->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Dados do entregador atualizados com sucesso.");
            $this->Consultar();
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    public function Excluir()
    {
        try {
            $this->buscaEntregador();

            $this->conexao->beginTransaction();

            $stmt = $this->conexao->prepare("
                DELETE FROM tb_entregador
                WHERE id_entregador = :id
            ");
            $stmt->bindValue(':id', $this->id_entregador, PDO::PARAM_INT);
            $stmt->execute();

            $stmt2 = $this->conexao->prepare("
                DELETE FROM tb_pessoa
                WHERE id_pessoa = :id
            ");
            $stmt2->bindValue(':id', $this->id_entregador, PDO::PARAM_INT);
            $stmt2->execute();

            $this->conexao->commit();

            $this->banco->setMensagem(1, "Entregador excluido com sucesso");
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    public function Consultar()
    {
        try {
            $stmt = $this->conexao->prepare("
                SELECT
                    e.*,
                    p.nm_pessoa,
                    p.nu_cpf,
                    p.nu_cel,
                    p.ds_email,
                    p.nu_cep,
                    p.ds_complemento,
                    p.nu_endereco
                FROM tb_entregador e
                JOIN tb_pessoa p ON p.id_pessoa = e.id_entregador
                WHERE e.id_entregador = :id
            ");

            $stmt->bindValue(':id', $this->id_entregador, PDO::PARAM_INT);
            $stmt->execute();

            $ret = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$ret) {
                throw new Exception("Entregador nao encontrado");
            }

            $this->banco->setMensagem(1, "Consulta realizada com sucesso");
            $this->banco->setDados(1, $ret);
        } catch (Exception $e) {
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    public function Listar()
    {
        $stmt = $this->conexao->query("
            SELECT
                e.*,
                p.nm_pessoa,
                p.nu_cpf,
                p.nu_cel,
                p.ds_email,
                p.nu_cep,
                p.ds_complemento,
                p.nu_endereco
            FROM tb_entregador e
            JOIN tb_pessoa p ON p.id_pessoa = e.id_entregador
        ");

        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $this->banco->setMensagem(1, "Lista realizada com sucesso");
        $this->banco->setDados(count($ret), $ret);
    }
}
