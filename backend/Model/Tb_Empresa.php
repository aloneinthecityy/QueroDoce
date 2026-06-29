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
    private $ids_categoria = [];

    function __construct($p_banco)
    {
        parent::__construct($p_banco);
    }

    function SetIdEmpresa($id)
    {
        $this->id_empresa = intval($id);
    }

    function SetNmEmpresa($nome)
    {
        $this->nm_empresa = substr(trim($nome), 0, 100);
    }

    function SetNuCNPJ($cnpj)
    {
        $this->nu_cnpj = substr(preg_replace('/\D/', '', $cnpj), 0, 14);
    }

    function SetDsEmail($email)
    {
        $this->ds_email = substr(trim($email), 0, 100);
    }

    function SetDsSenha($senha)
    {
        $this->ds_senha = trim($senha);
    }

    function SetNuCep($cep)
    {
        $this->nu_cep = substr(preg_replace('/\D/', '', $cep), 0, 8);
    }

    function SetDsComplemento($complemento)
    {
        $this->ds_complemento = substr(trim($complemento), 0, 50);
    }

    function SetNuEndereco($num_endereco)
    {
        $this->nu_endereco = intval($num_endereco);
    }

    function SetNmImagem($imagem)
    {
        $this->nm_imagem = substr(trim($imagem), 0, 255);
    }

    function SetIdCategoria($id_categoria)
    {
        $valores = is_array($id_categoria)
            ? $id_categoria
            : preg_split('/[,;|]/', strval($id_categoria));

        $ids = [];
        foreach ($valores as $valor) {
            $id = intval($valor);
            if ($id > 0 && !in_array($id, $ids)) {
                $ids[] = $id;
            }
        }

        $this->ids_categoria = $ids;
    }

    private function validarCadastro()
    {
        if (empty($this->nm_empresa)) {
            throw new Exception("Informe o nome da empresa para continuar.");
        }

        if (empty($this->nu_cnpj) || strlen($this->nu_cnpj) != 14) {
            throw new Exception("Informe um CNPJ valido com 14 digitos.");
        }

        if (empty($this->ds_email) || !filter_var($this->ds_email, FILTER_VALIDATE_EMAIL)) {
            throw new Exception("Informe um e-mail valido para a empresa.");
        }

        if (empty($this->ds_senha) || strlen($this->ds_senha) < 6) {
            throw new Exception("Crie uma senha com pelo menos 6 caracteres.");
        }

        if (empty($this->nu_cep) || strlen($this->nu_cep) != 8) {
            throw new Exception("Informe um CEP valido com 8 digitos.");
        }

        if (empty($this->nu_endereco) || $this->nu_endereco <= 0) {
            throw new Exception("Informe o numero do endereco da empresa.");
        }

        if (empty($this->ids_categoria)) {
            throw new Exception("Escolha pelo menos uma categoria da empresa.");
        }
    }

    private function verificaDuplicidadeCadastro()
    {
        $stmt = $this->conexao->prepare("
            SELECT nu_cnpj, ds_email
            FROM tb_empresa
            WHERE nu_cnpj = :nu_cnpj OR ds_email = :ds_email
            LIMIT 1
        ");
        $stmt->bindValue(':nu_cnpj', $this->nu_cnpj, PDO::PARAM_STR);
        $stmt->bindValue(':ds_email', $this->ds_email, PDO::PARAM_STR);
        $stmt->execute();

        $ret = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$ret) {
            return;
        }

        if (isset($ret['ds_email']) && $ret['ds_email'] === $this->ds_email) {
            throw new Exception("Ja existe uma empresa cadastrada com esse e-mail.");
        }

        if (isset($ret['nu_cnpj']) && $ret['nu_cnpj'] === $this->nu_cnpj) {
            throw new Exception("Ja existe uma empresa cadastrada com esse CNPJ.");
        }

        throw new Exception("Ja existe uma empresa com esses dados cadastrados.");
    }

    private function salvarCategoriaEmpresa($id_empresa)
    {
        if (empty($id_empresa) || intval($id_empresa) <= 0) {
            throw new Exception("Nao foi possivel vincular a categoria da empresa.");
        }

        if (empty($this->ids_categoria)) {
            throw new Exception("Escolha pelo menos uma categoria da empresa.");
        }

        $stmtDelete = $this->conexao->prepare("
            DELETE FROM tb_categoria_empresa
            WHERE id_empresa = :id_empresa
        ");
        $stmtDelete->bindValue(':id_empresa', $id_empresa, PDO::PARAM_INT);
        $stmtDelete->execute();

        $stmtInsert = $this->conexao->prepare("
            INSERT INTO tb_categoria_empresa (id_empresa, id_categoria)
            VALUES (:id_empresa, :id_categoria)
        ");
        foreach ($this->ids_categoria as $id_categoria) {
            $stmtInsert->bindValue(':id_empresa', $id_empresa, PDO::PARAM_INT);
            $stmtInsert->bindValue(':id_categoria', $id_categoria, PDO::PARAM_INT);
            $stmtInsert->execute();
        }
    }

    private function consultaEmpresaSql($where)
    {
        return "
            SELECT
                e.*,
                cat.id_categoria,
                cat.nm_categoria,
                cat.id_categorias,
                cat.nm_categorias
            FROM tb_empresa e
            LEFT JOIN (
                SELECT
                    ec.id_empresa,
                    MIN(ec.id_categoria) AS id_categoria,
                    MIN(c.nm_categoria) AS nm_categoria,
                    string_agg(ec.id_categoria::text, ',' ORDER BY ec.id_categoria) AS id_categorias,
                    string_agg(c.nm_categoria, ', ' ORDER BY c.nm_categoria) AS nm_categorias
                FROM tb_categoria_empresa ec
                LEFT JOIN tb_categoria c ON c.id_categoria = ec.id_categoria
                GROUP BY ec.id_empresa
            ) cat ON cat.id_empresa = e.id_empresa
            $where
        ";
    }

    private function consultaEmpresaPorId($id_empresa)
    {
        $stmt = $this->conexao->prepare($this->consultaEmpresaSql("
            WHERE e.id_empresa = :id
            LIMIT 1
        "));
        $stmt->bindValue(':id', $id_empresa, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    private function consultaEmpresaPorEmail($email)
    {
        $stmt = $this->conexao->prepare($this->consultaEmpresaSql("
            WHERE e.ds_email = :email
            LIMIT 1
        "));
        $stmt->bindValue(':email', $email, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function verificaExistencia()
    {
        $stmt = $this->conexao->prepare("SELECT 1 FROM tb_empresa WHERE id_empresa = :id");
        $stmt->bindValue(':id', $this->id_empresa, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Empresa nao localizada");
        }

        return $ret;
    }

    public function buscaEmpresa()
    {
        $ret = $this->consultaEmpresaPorId($this->id_empresa);

        if (!$ret) {
            throw new Exception("Empresa nao localizada");
        }

        return $ret;
    }

    public function Inserir()
    {
        try {
            $this->validarCadastro();
            $this->verificaDuplicidadeCadastro();

            $stmt = $this->conexao->prepare("
                INSERT INTO tb_empresa (
                    nm_empresa, nu_cnpj, ds_email, ds_senha,
                    nu_cep, ds_complemento, nu_endereco, nm_imagem
                ) VALUES (
                    :nm_empresa, :nu_cnpj, :ds_email, :ds_senha,
                    :nu_cep, :ds_complemento, :nu_endereco, :nm_imagem
                )
                RETURNING id_empresa
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
            $id_empresa = intval($stmt->fetchColumn());
            $this->salvarCategoriaEmpresa($id_empresa);
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Cadastro da empresa realizado com sucesso.");
            $this->banco->setDados(1, $this->consultaEmpresaPorId($id_empresa));
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    public function AlterarDadosEmpresa()
    {
        try {
            $this->buscaEmpresa();

            $stmt = $this->conexao->prepare("UPDATE tb_empresa SET
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
            $this->salvarCategoriaEmpresa($this->id_empresa);
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Dados da empresa alterados");
            $this->banco->setDados(1, $this->consultaEmpresaPorId($this->id_empresa));
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            throw new Exception($e->getMessage());
        }
    }

    public function Excluir()
    {
        try {
            $this->buscaEmpresa();

            $this->conexao->beginTransaction();

            $stmtCategoria = $this->conexao->prepare("
                DELETE FROM tb_categoria_empresa
                WHERE id_empresa = :id_empresa
            ");
            $stmtCategoria->bindValue(':id_empresa', $this->id_empresa, PDO::PARAM_INT);
            $stmtCategoria->execute();

            $stmt = $this->conexao->prepare("DELETE FROM tb_empresa WHERE id_empresa = :id_empresa");
            $stmt->bindValue(':id_empresa', $this->id_empresa, PDO::PARAM_INT);
            $stmt->execute();

            $this->conexao->commit();

            $this->banco->setMensagem(1, "Empresa excluida com sucesso");
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
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
        $stmt = $this->conexao->query($this->consultaEmpresaSql("
            ORDER BY e.nm_empresa
        "));
        $ret = $stmt->fetchAll();
        $this->banco->setMensagem(1, "Sucesso na pesquisa");
        $this->banco->setDados(count($ret), $ret);
    }

    public function Login()
    {
        try {
            $usuario = $this->consultaEmpresaPorEmail($this->ds_email);

            if (!$usuario) {
                throw new Exception("E-mail nao encontrado");
            }

            if ($this->ds_senha !== $usuario['ds_senha']) {
                throw new Exception("Senha invalida");
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
            SELECT e.*, ec.id_categoria, c.nm_categoria
            FROM tb_empresa e
            JOIN tb_categoria_empresa ec ON e.id_empresa = ec.id_empresa
            LEFT JOIN tb_categoria c ON c.id_categoria = ec.id_categoria
            WHERE ec.id_categoria = :id_categoria
        ");

        $stmt->bindValue(':id_categoria', $id_categoria, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $this->banco->setMensagem(1, "Empresas da categoria listadas com sucesso");
        $this->banco->setDados(count($ret), $ret);
    }
}
