<?php

require_once(__DIR__ . '/Base.php');

class Tb_Entregador extends Base
{
    private $id_entregador;
    private $tp_locomocao;
    private $nu_cnh;

    function __construct($p_banco)
    {
        parent::__construct($p_banco);
    }

    // ---------------- SETTERS ----------------

    function SetIdEntregador($id)
    {
        $this->id_entregador = $id;
    }

    function SetTpLocomocao($tp)
    {
        $this->tp_locomocao = substr(trim($tp), 0, 1);
    }

    function SetNuCNH($cnh)
    {
        $cnhLimpa = preg_replace('/\D/', '', $cnh);
        $this->nu_cnh = substr($cnhLimpa, 0, 11);
    }

    // ---------------- LOGIN ----------------

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
                throw new Exception("E-mail ou senha inválidos");
            }

            if (!password_verify($senha, $pessoa['ds_senha'])) {
                throw new Exception("E-mail ou senha inválidos");
            }

            $stmt2 = $this->conexao->prepare("
            SELECT * FROM tb_entregador
            WHERE id_entregador = :id
        ");

            $stmt2->bindValue(':id', $pessoa['id_pessoa'], PDO::PARAM_INT);
            $stmt2->execute();

            $entregador = $stmt2->fetch(PDO::FETCH_ASSOC);

            if (!$entregador) {
                throw new Exception("Usuário não é entregador");
            }

            $resultado = [
                "id_pessoa" => $pessoa['id_pessoa'],
                "nm_pessoa" => $pessoa['nm_pessoa'],
                "ds_email" => $pessoa['ds_email'],
                "nu_cel" => $pessoa['nu_cel'],
                "tp_locomocao" => $entregador['tp_locomocao'],
                "nu_cnh" => $entregador['nu_cnh']
            ];

            $this->banco->setMensagem(1, "Login permitido");
            $this->banco->setDados(1, $resultado);
        } catch (Exception $e) {
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    // ---------------- VERIFICA CNH ----------------

    public function verificaCNH()
    {
        $stmt = $this->conexao->prepare("
            SELECT 1 FROM tb_entregador
            WHERE nu_cnh = :nu_cnh
        ");
        $stmt->bindValue(':nu_cnh', $this->nu_cnh, PDO::PARAM_STR);
        $stmt->execute();

        if ($stmt->fetch(PDO::FETCH_ASSOC)) {
            throw new Exception("CNH já cadastrada");
        }
    }

    // ---------------- BUSCA ----------------

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
            throw new Exception("Entregador não localizado");
        }

        return $ret;
    }

    // ---------------- INSERT ----------------

    public function Inserir()
    {
        try {

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
            $stmt->bindValue(':nu_cnh', $this->nu_cnh, PDO::PARAM_STR);

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

    // ---------------- ALTERAR ----------------

    public function Alterar()
    {
        try {

            $dadosAtuais = $this->buscaEntregador();

            $campos = [];
            $bind = [':id' => $this->id_entregador];

            if (!empty($this->tp_locomocao) && $this->tp_locomocao != $dadosAtuais['tp_locomocao']) {
                $campos[] = "tp_locomocao = :tp_locomocao";
                $bind[':tp_locomocao'] = $this->tp_locomocao;
            }

            if (!empty($this->nu_cnh) && $this->nu_cnh != $dadosAtuais['nu_cnh']) {
                $this->verificaCNH();
                $campos[] = "nu_cnh = :nu_cnh";
                $bind[':nu_cnh'] = $this->nu_cnh;
            }

            if (empty($campos)) {
                $this->banco->setMensagem(1, "Nenhuma alteração realizada");
                return;
            }

            $sql = "UPDATE tb_entregador SET " . implode(", ", $campos) . "
                    WHERE id_entregador = :id";

            $stmt = $this->conexao->prepare($sql);

            foreach ($bind as $k => $v) {
                $stmt->bindValue($k, $v, PDO::PARAM_STR);
            }

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Atualizado com sucesso");
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    // ---------------- EXCLUIR ----------------

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

            $this->banco->setMensagem(1, "Excluído com sucesso");
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    // ---------------- CONSULTAR ----------------

    public function Consultar()
    {
        try {

            $stmt = $this->conexao->prepare("
                SELECT e.*, p.nm_pessoa, p.ds_email, p.nu_cel
                FROM tb_entregador e
                JOIN tb_pessoa p ON p.id_pessoa = e.id_entregador
                WHERE e.id_entregador = :id
            ");

            $stmt->bindValue(':id', $this->id_entregador, PDO::PARAM_INT);
            $stmt->execute();

            $ret = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$ret) {
                throw new Exception("Entregador não encontrado");
            }

            $this->banco->setMensagem(1, "Consulta OK");
            $this->banco->setDados(1, $ret);
        } catch (Exception $e) {
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    // ---------------- LISTAR ----------------

    public function Listar()
    {
        $stmt = $this->conexao->query("
            SELECT e.*, p.nm_pessoa, p.ds_email
            FROM tb_entregador e
            JOIN tb_pessoa p ON p.id_pessoa = e.id_entregador
        ");

        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $this->banco->setMensagem(1, "Lista OK");
        $this->banco->setDados(count($ret), $ret);
    }
}
