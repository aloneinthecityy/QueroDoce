<?php

require_once(__DIR__ . '/Base.php');

class Tb_Categoria extends Base
{
    private $id_categoria;
    private $nm_categoria;

    function __construct($p_banco)
    {
        parent::__construct($p_banco);
    }

    function SetIdCategoria($id)
    {
        $this->id_categoria = $id;
    }

    function SetNmCategoria($nome)
    {
        $this->nm_categoria = $nome;
    }

    public function verificaExistencia()
    {
        $stmt = $this->conexao->prepare("SELECT 1 FROM tb_categoria WHERE id_categoria = :id");
        $stmt->bindValue(':id', $this->id_categoria, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Categoria não localizada");
        }

        return $ret;
    }

    public function buscaCategoria()
    {
        $stmt = $this->conexao->prepare("SELECT * FROM tb_categoria WHERE id_categoria = :id");
        $stmt->bindValue(':id', $this->id_categoria, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Categoria não localizada");
        }
        return $ret;
    }

    public function Inserir()
    {
        try {
            $this->verificaExistencia();
            $this->banco->setMensagem(0, "Categoria já cadastrada");
        } catch (Exception $e) {
            $stmt = $this->conexao->prepare("
                INSERT INTO tb_categoria (nm_categoria) VALUES (:nm_categoria)
            ");

            $stmt->bindValue(':nm_categoria', $this->nm_categoria, PDO::PARAM_STR);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Categoria adicionada com sucesso");
        }
    }

    public function AlterarDadosCategoria()
    {
        try {
            $this->buscaCategoria();
            $stmt = $this->conexao->prepare("UPDATE tb_categoria SET nm_categoria = :nm_categoria WHERE id_categoria = :id_categoria");
            $stmt->bindValue(':id_categoria', $this->id_categoria, PDO::PARAM_INT);
            $stmt->bindValue(':nm_categoria', $this->nm_categoria, PDO::PARAM_STR);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Dados da categoria alterados");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Excluir()
    {
        try {
            $this->buscaCategoria();

            $stmt = $this->conexao->prepare("DELETE FROM tb_categoria WHERE id_categoria = :id_categoria");
            $stmt->bindValue(':id_categoria', $this->id_categoria, PDO::PARAM_INT);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Categoria excluída com sucesso");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Consultar()
    {
        try {
            $ret = $this->buscaCategoria();
            $this->banco->setMensagem(1, "Consulta efetuada com sucesso");
            $this->banco->setDados(count($ret), $ret);
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Listar()
    {
        $stmt = $this->conexao->query("SELECT * FROM tb_categoria ORDER BY nm_categoria");
        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->banco->setMensagem(1, "Sucesso na pesquisa");
        $this->banco->setDados(count($ret), $ret);
    }
}

