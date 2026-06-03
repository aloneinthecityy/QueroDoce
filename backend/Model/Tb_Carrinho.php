<?php

require_once(__DIR__ . '/Base.php');

class Tb_Carrinho extends Base
{
    private $id_pessoa;
    private $id_produto;
    private $nu_qtd;

    function __construct($p_banco)
    {
        parent::__construct($p_banco);
    }

    function SetIdPessoa($id)
    {
        $this->id_pessoa = $id;
    }

    function SetIdProduto($id)
    {
        $this->id_produto = $id;
    }

    function SetNuQtd($qtd)
    {
        $this->nu_qtd = $qtd;
    }

    public function verificaExistencia()
    {
        $stmt = $this->conexao->prepare("SELECT 1 FROM tb_carrinho WHERE id_pessoa = :id_pessoa AND id_produto = :id_produto");
        $stmt->bindValue(':id_pessoa', $this->id_pessoa, PDO::PARAM_INT);
        $stmt->bindValue(':id_produto', $this->id_produto, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        return $ret;
    }

    public function Inserir()
    {
        try {
            $existe = $this->verificaExistencia();
            
            if ($existe) {
                // Se já existe, atualiza a quantidade
                $stmt = $this->conexao->prepare("
                    UPDATE tb_carrinho SET nu_qtd = nu_qtd + :nu_qtd 
                    WHERE id_pessoa = :id_pessoa AND id_produto = :id_produto
                ");
                $stmt->bindValue(':id_pessoa', $this->id_pessoa, PDO::PARAM_INT);
                $stmt->bindValue(':id_produto', $this->id_produto, PDO::PARAM_INT);
                $stmt->bindValue(':nu_qtd', $this->nu_qtd, PDO::PARAM_INT);
            } else {
                // Se não existe, insere novo
                $stmt = $this->conexao->prepare("
                    INSERT INTO tb_carrinho (id_pessoa, id_produto, nu_qtd) 
                    VALUES (:id_pessoa, :id_produto, :nu_qtd)
                ");
                $stmt->bindValue(':id_pessoa', $this->id_pessoa, PDO::PARAM_INT);
                $stmt->bindValue(':id_produto', $this->id_produto, PDO::PARAM_INT);
                $stmt->bindValue(':nu_qtd', $this->nu_qtd, PDO::PARAM_INT);
            }

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Item adicionado ao carrinho com sucesso");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function AlterarQuantidade()
    {
        try {
            $stmt = $this->conexao->prepare("
                UPDATE tb_carrinho SET nu_qtd = :nu_qtd 
                WHERE id_pessoa = :id_pessoa AND id_produto = :id_produto
            ");
            $stmt->bindValue(':id_pessoa', $this->id_pessoa, PDO::PARAM_INT);
            $stmt->bindValue(':id_produto', $this->id_produto, PDO::PARAM_INT);
            $stmt->bindValue(':nu_qtd', $this->nu_qtd, PDO::PARAM_INT);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Quantidade alterada com sucesso");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Excluir()
    {
        try {
            $stmt = $this->conexao->prepare("
                DELETE FROM tb_carrinho 
                WHERE id_pessoa = :id_pessoa AND id_produto = :id_produto
            ");
            $stmt->bindValue(':id_pessoa', $this->id_pessoa, PDO::PARAM_INT);
            $stmt->bindValue(':id_produto', $this->id_produto, PDO::PARAM_INT);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Item removido do carrinho com sucesso");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function ListarPorPessoa($id_pessoa)
    {
        $stmt = $this->conexao->prepare("
            SELECT c.*, p.id_empresa, p.nm_produto, p.ds_produto, p.vl_produto, p.nm_imagem, e.nm_empresa
            FROM tb_carrinho c
            JOIN tb_produto p ON c.id_produto = p.id_produto
            JOIN tb_empresa e ON p.id_empresa = e.id_empresa
            WHERE c.id_pessoa = :id_pessoa
        ");
        $stmt->bindValue(':id_pessoa', $id_pessoa, PDO::PARAM_INT);
        $stmt->execute();

        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->banco->setMensagem(1, "Itens do carrinho listados com sucesso");
        $this->banco->setDados(count($ret), $ret);
    }

    public function LimparCarrinho($id_pessoa)
    {
        try {
            $stmt = $this->conexao->prepare("DELETE FROM tb_carrinho WHERE id_pessoa = :id_pessoa");
            $stmt->bindValue(':id_pessoa', $id_pessoa, PDO::PARAM_INT);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Carrinho limpo com sucesso");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }
}

