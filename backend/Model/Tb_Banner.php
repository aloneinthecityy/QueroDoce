<?php

require_once(__DIR__ . '/Base.php');

class Tb_Banner extends Base
{
    private $id_banner;
    private $dt_banner;
    private $nm_imagem;

    function __construct($p_banco)
    {
        parent::__construct($p_banco);
    }

    function SetIdBanner($id)
    {
        $this->id_banner = $id;
    }

    function SetDtBanner($data)
    {
        $this->dt_banner = $data;
    }

    function SetNmImagem($imagem)
    {
        $this->nm_imagem = $imagem;
    }

    public function verificaExistencia()
    {
        $stmt = $this->conexao->prepare("SELECT 1 FROM tb_banner WHERE id_banner = :id");
        $stmt->bindValue(':id', $this->id_banner, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Banner não localizado");
        }

        return $ret;
    }

    public function buscaBanner()
    {
        $stmt = $this->conexao->prepare("SELECT * FROM tb_banner WHERE id_banner = :id");
        $stmt->bindValue(':id', $this->id_banner, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Banner não localizado");
        }
        return $ret;
    }

    public function Inserir()
    {
        try {
            $stmt = $this->conexao->prepare("
                INSERT INTO tb_banner (dt_banner, nm_imagem) VALUES (:dt_banner, :nm_imagem)
            ");

            $stmt->bindValue(':dt_banner', $this->dt_banner, PDO::PARAM_STR);
            $stmt->bindValue(':nm_imagem', $this->nm_imagem, PDO::PARAM_STR);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Banner adicionado com sucesso");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function AlterarDadosBanner()
    {
        try {
            $this->buscaBanner();
            $stmt = $this->conexao->prepare("UPDATE tb_banner SET dt_banner = :dt_banner, nm_imagem = :nm_imagem WHERE id_banner = :id_banner");
            $stmt->bindValue(':id_banner', $this->id_banner, PDO::PARAM_INT);
            $stmt->bindValue(':dt_banner', $this->dt_banner, PDO::PARAM_STR);
            $stmt->bindValue(':nm_imagem', $this->nm_imagem, PDO::PARAM_STR);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Dados do banner alterados");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Excluir()
    {
        try {
            $this->buscaBanner();

            $stmt = $this->conexao->prepare("DELETE FROM tb_banner WHERE id_banner = :id_banner");
            $stmt->bindValue(':id_banner', $this->id_banner, PDO::PARAM_INT);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Banner excluído com sucesso");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Consultar()
    {
        try {
            $ret = $this->buscaBanner();
            $this->banco->setMensagem(1, "Consulta efetuada com sucesso");
            $this->banco->setDados(count($ret), $ret);
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Listar()
    {
        $stmt = $this->conexao->query("SELECT * FROM tb_banner ORDER BY dt_banner DESC");
        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->banco->setMensagem(1, "Sucesso na pesquisa");
        $this->banco->setDados(count($ret), $ret);
    }

    public function BuscarUltimoBanner()
    {
        $stmt = $this->conexao->query("SELECT * FROM tb_banner ORDER BY dt_banner DESC LIMIT 1");
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$ret) {
            $this->banco->setMensagem(0, "Nenhum banner encontrado");
            $this->banco->setDados(0, null);
        } else {
            $this->banco->setMensagem(1, "Banner encontrado");
            $this->banco->setDados(1, $ret);
        }
    }
}

