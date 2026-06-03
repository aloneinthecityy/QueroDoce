<?php

require_once(__DIR__ . '/Base.php');

class Tb_Produto extends Base
{
    private $id_produto;
    private $id_empresa;
    private $nm_produto;
    private $ds_produto;
    private $nm_imagem;
    private $vl_produto;
    private $nu_qtd;
    private $fl_disponivel;


    // CREATE TABLE tb_produto (id_produto SERIAL,
    // id_empresa INTEGER NOT NULL,
    // nm_produto VARCHAR(50) NOT NULL,
    // ds_produto VARCHAR(100) NOT NULL,
    // vl_produto NUMERIC NOT NULL,
    // nu_qtd INTEGER NOT NULL,
    // fl_disponivel BOOLEAN)
    // ALTER TABLE tb_produto ADD CONSTRAINT pk_produto PRIMARY KEY(id_produto)


    function __construct($p_banco)
    {
        parent::__construct($p_banco);
    }

    function SetIdProduto($id)
    {
        $this->id_produto = $id;
    }
    function SetIdEmpresa($id_empresa)
    {
        $this->id_empresa = $id_empresa;
    }
    function SetNmProduto($nome)
    {
        $this->nm_produto = $nome;
    }
    function SetDsProduto($descricao)
    {
        $this->ds_produto = $descricao;
    }
    function SetNmImagem($imagem)
    {
        $this->nm_imagem = $imagem;
    }
    function SetVlProduto($valor)
    {
        $this->vl_produto = $valor;
    }
    function SetNuQtd($quantidade)
    {
        $this->nu_qtd = $quantidade;
    }
    function SetFlDisponivel($disponivel)
    {
        $this->fl_disponivel = $disponivel;
    }


    public function verificaExistencia()
    {
        $stmt = $this->conexao->prepare("SELECT 1 FROM tb_produto WHERE id_produto = :id");
        $stmt->bindValue(':id', $this->id_produto, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Produto não localizado");
        }

        return $ret;
    }

    public function buscaProduto()
    {
        $stmt = $this->conexao->prepare("
            SELECT p.*, e.nm_empresa 
            FROM tb_produto p
            JOIN tb_empresa e ON p.id_empresa = e.id_empresa
            WHERE p.id_produto = :id
        ");
        $stmt->bindValue(':id', $this->id_produto, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("produto não Localizado");
        }
        return $ret;
    }

    public function Inserir()
    {
        try {
            $this->verificaExistencia();
            $this->banco->setMensagem(0, "Produto já cadastrado");
        } catch (Exception $e) {
            $stmt = $this->conexao->prepare("
                INSERT INTO tb_produto (
                    id_empresa, nm_produto, ds_produto, nm_imagem, vl_produto, nu_qtd, fl_disponivel
                ) VALUES (
                    :id_empresa, :nm_produto, :ds_produto, :nm_imagem, :vl_produto, :nu_qtd, :fl_disponivel
                )
            ");

            $stmt->bindValue(':id_empresa', $this->id_empresa, PDO::PARAM_STR);
            $stmt->bindValue(':nm_produto', $this->nm_produto, PDO::PARAM_STR);
            $stmt->bindValue(':ds_produto', $this->ds_produto, PDO::PARAM_STR);
            $stmt->bindValue(':nm_imagem', $this->nm_imagem, PDO::PARAM_STR);
            $stmt->bindValue(':vl_produto', $this->vl_produto, PDO::PARAM_STR);
            $stmt->bindValue(':nu_qtd', $this->nu_qtd, PDO::PARAM_STR);
            $stmt->bindValue(':fl_disponivel', $this->fl_disponivel, PDO::PARAM_STR);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Produto adicionado com sucesso");
        }
    }

    public function AlterarDadosProduto()
    {
        try {
            $this->buscaProduto();
            $stmt = $this->conexao->prepare("UPDATE tb_produto set 
                                            id_empresa = :id_empresa,
                                            nm_produto = :nm_produto,
                                            ds_produto = :ds_produto,
                                            nm_imagem = :nm_imagem,
                                            vl_produto = :vl_produto,
                                            nu_qtd = :nu_qtd,
                                            fl_disponivel = :fl_disponivel
                                            WHERE id_produto = :id_produto");
            $stmt->bindValue(':id_produto', $this->id_produto, PDO::PARAM_INT);
            $stmt->bindValue(':id_empresa', $this->id_empresa, PDO::PARAM_INT);
            $stmt->bindValue(':nm_produto', $this->nm_produto, PDO::PARAM_STR);
            $stmt->bindValue(':ds_produto', $this->ds_produto, PDO::PARAM_STR);
            $stmt->bindValue(':nm_imagem', $this->nm_imagem, PDO::PARAM_STR);
            $stmt->bindValue(':vl_produto', $this->vl_produto, PDO::PARAM_STR);
            $stmt->bindValue(':nu_qtd', $this->nu_qtd, PDO::PARAM_STR);
            $stmt->bindValue(':fl_disponivel', $this->fl_disponivel, PDO::PARAM_STR);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Dados do Produto Alterados");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Excluir()
    {
        try {
            $this->buscaProduto();

            $stmt = $this->conexao->prepare("DELETE FROM tb_produto WHERE id_produto = :id_produto");
            $stmt->bindValue(':id_produto', $this->id_produto, PDO::PARAM_INT);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Produto excluído com sucesso");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Consultar()
    {
        try {
            $ret = $this->buscaProduto();
            $this->banco->setMensagem(1, "Consulta efetuada com sucesso");
            $this->banco->setDados(count($ret), $ret);
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Listar()
    {
        $stmt = $this->conexao->query("SELECT p.*, e.nm_empresa FROM tb_produto p JOIN tb_empresa e ON p.id_empresa = e.id_empresa");
        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->banco->setMensagem(1, "Sucesso na pesquisa");
        $this->banco->setDados(count($ret), $ret);
    }

    public function ListarPorEmpresa($id_empresa)
    {
        $stmt = $this->conexao->prepare("SELECT * FROM tb_produto WHERE id_empresa = :id_empresa");
        $stmt->bindValue(':id_empresa', $id_empresa, PDO::PARAM_INT);
        $stmt->execute();

        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->banco->setMensagem(1, "Produtos da empresa listados com sucesso");
        $this->banco->setDados(count($ret), $ret);
    }

    public function ListarProdutosPorCategoria($id_categoria)
    {
        $stmt = $this->conexao->prepare("
        SELECT p.*, e.nm_empresa FROM tb_produto p
        JOIN tb_empresa e ON p.id_empresa = e.id_empresa
        JOIN tb_categoria_empresa ec ON e.id_empresa = ec.id_empresa
        WHERE ec.id_categoria = :id_categoria AND p.fl_disponivel = 't'
        ORDER BY p.id_produto DESC
    ");

        $stmt->bindValue(':id_categoria', $id_categoria, PDO::PARAM_INT);
        $stmt->execute();

        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->banco->setMensagem(1, "Produtos listados por categoria com sucesso");
        $this->banco->setDados(count($ret), $ret);
    }

    public function PesquisarPorNome($nm_produto)
    {
        $stmt = $this->conexao->prepare("
            SELECT p.*, e.nm_empresa 
            FROM tb_produto p
            JOIN tb_empresa e ON p.id_empresa = e.id_empresa
            WHERE p.nm_produto ILIKE :nm_produto AND p.fl_disponivel = 't'
            ORDER BY p.id_produto DESC
        ");
        $stmt->bindValue(':nm_produto', '%' . $nm_produto . '%', PDO::PARAM_STR);
        $stmt->execute();
        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $this->banco->setMensagem(1, "Produtos encontrados por nome");
        $this->banco->setDados(count($ret), $ret);
    }

    public function ListarProdutosRecentes()
    {
        // PostgreSQL: fl_disponivel é BOOLEAN
        // Tenta primeiro com produtos disponíveis, depois lista todos se não encontrar
        try {
            // Primeira tentativa: produtos disponíveis
            // PostgreSQL armazena boolean como 't' ou 'f', então usamos apenas 't'
            $stmt = $this->conexao->query("
                SELECT p.*, e.nm_empresa 
                FROM tb_produto p
                INNER JOIN tb_empresa e ON p.id_empresa = e.id_empresa
                WHERE p.fl_disponivel = 't'
                ORDER BY p.id_produto DESC
            ");
            $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Se não encontrou produtos disponíveis, lista todos
            if (empty($ret)) {
                $stmt2 = $this->conexao->query("
                    SELECT p.*, e.nm_empresa 
                    FROM tb_produto p
                    INNER JOIN tb_empresa e ON p.id_empresa = e.id_empresa
                    ORDER BY p.id_produto DESC
                    LIMIT 50
                ");
                $ret = $stmt2->fetchAll(PDO::FETCH_ASSOC);
            }
            
            $this->banco->setMensagem(1, "Produtos recentes listados com sucesso");
            $this->banco->setDados(count($ret), $ret);
        } catch (Exception $e) {
            // Em caso de erro, tenta query mais simples sem filtro
            try {
                $stmt = $this->conexao->query("
                    SELECT p.*, e.nm_empresa 
                    FROM tb_produto p
                    LEFT JOIN tb_empresa e ON p.id_empresa = e.id_empresa
                    ORDER BY p.id_produto DESC
                    LIMIT 50
                ");
                $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);
                $this->banco->setMensagem(1, "Produtos recentes listados com sucesso");
                $this->banco->setDados(count($ret), $ret);
            } catch (Exception $e2) {
                // Se ainda falhar, retorna erro
                throw new Exception("Erro ao listar produtos: " . $e2->getMessage());
            }
        }
    }
}
