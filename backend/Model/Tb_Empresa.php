<?php

require_once(__DIR__ . '/Base.php');

class Tb_Empresa extends Base
{
    private $id_empresa;
    private $nm_empresa;
    private $nu_cnpj;
    private $ds_email;
    private $ds_senha;
    private $nu_cep;
    private $ds_complemento;
    private $nu_endereco;
    private $nm_imagem;


    // CREATE TABLE tb_empresa (id_empresa SERIAL,
    // 		 nm_empresa VARCHAR(100) NOT NULL,
    // 		 ds_email VARCHAR(100) NOT NULL,
    // 		 ds_senha VARCHAR(20) NOT NULL,
    // 		 nu_cnpj CHAR(14) NOT NULL,
    // 		 nu_cep CHAR(8) NOT NULL,
    // 		 ds_complemento VARCHAR(50) NOT NULL,
    // 		 nu_endereco INTEGER)

    function __construct($p_banco)
    {
        parent::__construct($p_banco);
    }

    function SetIdEmpresa($id)
    {
        $this->id_empresa = $id;
    }
    function SetNmEmpresa($nome)
    {
        $this->nm_empresa = $nome;
    }
    function SetNuCNPJ($cnpj)
    {
        $this->nu_cnpj = $cnpj;
    }
    function SetDsEmail($email)
    {
        $this->ds_email = $email;
    }
    function SetDsSenha($senha)
    {
        $this->ds_senha = $senha;
    }
    function SetNuCep($cep)
    {
        $this->nu_cep = $cep;
    }
    function SetDsComplemento($complemento)
    {
        $this->ds_complemento = $complemento;
    }
    function SetNuEndereco($num_endereco)
    {
        $this->nu_endereco = $num_endereco;
    }
    function SetNmImagem($imagem)
    {
        $this->nm_imagem = $imagem;
    }


    public function verificaExistencia()
    {
        $stmt = $this->conexao->prepare("SELECT 1 FROM tb_empresa WHERE id_empresa = :id");
        $stmt->bindValue(':id', $this->id_empresa, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Empresa não localizada");
        }

        return $ret;
    }

    public function buscaEmpresa()
    {
        $stmt = $this->conexao->prepare("SELECT * FROM tb_empresa WHERE id_empresa = :id");
        $stmt->bindValue(':id', $this->id_empresa, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Empresa não localizada");
        }
        return $ret;
    }

    public function Inserir()
    {
        try {
            $this->verificaExistencia();
            $this->banco->setMensagem(0, "Empresa já cadastrada");
        } catch (Exception $e) {
            $stmt = $this->conexao->prepare("
                INSERT INTO tb_empresa (
                    nm_empresa, nu_cnpj, ds_email, ds_senha,
                    nu_cep, ds_complemento, nu_endereco, nm_imagem
                ) VALUES (
                    :nm_empresa, :nu_cnpj, :ds_email, :ds_senha,
                    :nu_cep, :ds_complemento, :nu_endereco, :nm_imagem
                )
            ");

            $stmt->bindValue(':nm_empresa', $this->nm_empresa, PDO::PARAM_STR);
            $stmt->bindValue(':nu_cnpj', $this->nu_cnpj, PDO::PARAM_STR);
            $stmt->bindValue(':ds_email', $this->ds_email, PDO::PARAM_STR);
            $stmt->bindValue(':ds_senha', $this->ds_senha, PDO::PARAM_STR);
            $stmt->bindValue(':nu_cep', $this->nu_cep, PDO::PARAM_STR);
            $stmt->bindValue(':ds_complemento', $this->ds_complemento, PDO::PARAM_STR);
            $stmt->bindValue(':nu_endereco', $this->nu_endereco, PDO::PARAM_INT);
            $stmt->bindValue(':nm_imagem', $this->nm_imagem, PDO::PARAM_STR);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Usuário incluso com sucesso");
        }
    }

    public function AlterarDadosEmpresa()
    {
        try {
            $this->buscaempresa();
            $stmt = $this->conexao->prepare("UPDATE tb_empresa set 
                                            nm_empresa = :nm_empresa,
                                            nu_cnpj = :nu_cnpj,
                                            ds_email = :ds_email,
                                            ds_senha = :ds_senha,
                                            nu_cep = :nu_cep,
                                            ds_complemento = :ds_complemento,
                                            nu_endereco = :nu_endereco,
                                            nm_imagem = :nm_imagem
                                            WHERE id_empresa = :id_empresa");
            $stmt->bindValue(':id_empresa', $this->id_empresa, PDO::PARAM_INT);
            $stmt->bindValue(':nm_empresa', $this->nm_empresa, PDO::PARAM_STR);
            $stmt->bindValue(':nu_cnpj', $this->nu_cnpj, PDO::PARAM_STR);
            $stmt->bindValue(':ds_email', $this->ds_email, PDO::PARAM_STR);
            $stmt->bindValue(':ds_senha', $this->ds_senha, PDO::PARAM_STR);
            $stmt->bindValue(':nu_cep', $this->nu_cep, PDO::PARAM_STR);
            $stmt->bindValue(':ds_complemento', $this->ds_complemento, PDO::PARAM_STR);
            $stmt->bindValue(':nu_endereco', $this->nu_endereco, PDO::PARAM_INT);
            $stmt->bindValue(':nm_imagem', $this->nm_imagem, PDO::PARAM_STR);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Dados da empresa alterados");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Excluir()
    {
        try {
            $this->buscaEmpresa();

            $stmt = $this->conexao->prepare("DELETE FROM tb_empresa WHERE id_empresa = :id_empresa");
            $stmt->bindValue(':id_empresa', $this->id_empresa, PDO::PARAM_INT);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Empresa excluída com sucesso");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Consultar()
    {
        try {
            $ret = $this->buscaEmpresa();
            $this->banco->setMensagem(1, "Consulta efetuada com sucesso");
            $this->banco->setDados(count($ret), $ret);
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Listar()
    {
        $stmt = $this->conexao->query("SELECT * FROM tb_empresa");
        $ret = $stmt->fetchAll();
        $this->banco->setMensagem(1, "Sucesso na pesquisa");
        $this->banco->setDados(count($ret), $ret);
    }

    public function Login()
    {
        try {
            $stmt = $this->conexao->prepare("
            SELECT * FROM tb_empresa 
            WHERE ds_email = :email
        ");

            $stmt->bindValue(':email', $this->ds_email, PDO::PARAM_STR);
            $stmt->execute();

            $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$usuario) {
                throw new Exception("E-mail não encontrado");
            }

            if ($this->ds_senha !== $usuario['ds_senha']) {
                throw new Exception("Senha inválida");
            }

            $this->banco->setMensagem(1, "Login permitido");
            $this->banco->setDados(1, $usuario);
        } catch (Exception $e) {
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }
    
    public function ListarPorCategoria($id_categoria)
    {
        $stmt = $this->conexao->prepare("
        SELECT e.* FROM tb_empresa e
        JOIN tb_categoria_empresa ec ON e.id_empresa = ec.id_empresa
        WHERE ec.id_categoria = :id_categoria
    ");

        $stmt->bindValue(':id_categoria', $id_categoria, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $this->banco->setMensagem(1, "Empresas da categoria listadas com sucesso");
        $this->banco->setDados(count($ret), $ret);
    }
}
