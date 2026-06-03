<?php

require_once(__DIR__ . '/Base.php');

class Tb_Pessoa extends Base
{
    private $id_pessoa;
    private $nm_pessoa;
    private $nu_cpf;
    private $nu_cel;
    private $ds_email;
    private $ds_senha;
    private $nu_cep;
    private $ds_complemento;
    private $nu_endereco;


    // CREATE TABLE tb_pessoa (id_pessoa SERIAL,
    // 		nm_pessoa VARCHAR(50) NOT NULL,
    // 		nu_cpf CHAR(11) NOT NULL,
    // 		nu_cel CHAR(13) NOT NULL,
    // 		ds_email VARCHAR(100) NOT NULL,
    // 		ds_senha VARCHAR(20) NOT NULL,
    // 		nu_cep CHAR(8) NOT NULL,
    // 		ds_complemento VARCHAR(50) NOT NULL,
    // 		nu_endereco INTEGER)

    function __construct($p_banco)
    {
        parent::__construct($p_banco);
    }

    function SetIdpessoa($id)
    {
        $this->id_pessoa = $id;
    }
    function SetNmPessoa($nome)
    {
        // Banco espera VARCHAR(50) - limita a 50 caracteres
        $this->nm_pessoa = substr(trim($nome), 0, 50);
    }
    function SetNuCPF($cpf)
    {
        // Remove pontos, hífens e espaços do CPF (banco espera apenas 11 dígitos)
        $cpfLimpo = preg_replace('/\D/', '', $cpf);
        // Limita a 11 caracteres
        $this->nu_cpf = substr($cpfLimpo, 0, 11);
    }
    function SetNuCel($cel)
    {
        // Remove formatação do telefone (pontos, hífens, parênteses, espaços)
        // Banco espera CHAR(13) - máximo 13 caracteres numéricos
        $celLimpo = preg_replace('/\D/', '', $cel);
        // Limita a 13 caracteres
        $this->nu_cel = substr($celLimpo, 0, 13);
    }
    function SetDsEmail($email)
    {
        // Banco espera VARCHAR(100) - limita a 100 caracteres e remove espaços
        $emailLimpo = trim($email);
        $this->ds_email = substr($emailLimpo, 0, 100);
    }
    function SetDsSenha($senha)
    {
        $this->ds_senha = $senha;
    }
    function SetNuCep($cep)
    {
        // Remove hífen e caracteres não numéricos do CEP (banco espera apenas 8 dígitos)
        $cepLimpo = preg_replace('/\D/', '', $cep);
        // Limita a 8 caracteres
        $this->nu_cep = substr($cepLimpo, 0, 8);
    }
    function SetDsComplemento($complemento)
    {
        // Banco espera VARCHAR(50) - limita a 50 caracteres
        $this->ds_complemento = substr(trim($complemento), 0, 50);
    }
    function SetNuEndereco($num_endereco)
    {
        $this->nu_endereco = $num_endereco;
    }


    public function verificaExistencia()
    {
        $stmt = $this->conexao->prepare("
        SELECT 1 FROM tb_pessoa 
        WHERE nu_cpf = :nu_cpf 
           OR ds_email = :ds_email
           OR nu_cel = :nu_cel
    ");
        $stmt->bindValue(':nu_cpf', $this->nu_cpf, PDO::PARAM_STR);
        $stmt->bindValue(':ds_email', $this->ds_email, PDO::PARAM_STR);
        $stmt->bindValue(':nu_cel', $this->nu_cel, PDO::PARAM_STR);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($ret) {
            throw new Exception("CPF, e-mail ou telefone já cadastrado");
        }
    }

    public function verificaExistenciaAlteracao()
    {
        // Verifica se CPF, email ou celular já existem em OUTROS usuários (excluindo o próprio)
        $stmt = $this->conexao->prepare("
        SELECT 1 FROM tb_pessoa 
        WHERE id_pessoa != :id_pessoa
          AND (nu_cpf = :nu_cpf 
           OR ds_email = :ds_email
           OR nu_cel = :nu_cel)
    ");
        $stmt->bindValue(':id_pessoa', $this->id_pessoa, PDO::PARAM_INT);
        $stmt->bindValue(':nu_cpf', $this->nu_cpf, PDO::PARAM_STR);
        $stmt->bindValue(':ds_email', $this->ds_email, PDO::PARAM_STR);
        $stmt->bindValue(':nu_cel', $this->nu_cel, PDO::PARAM_STR);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($ret) {
            throw new Exception("CPF, e-mail ou telefone já cadastrado para outro usuário");
        }
    }

    public function buscaPessoa()
    {
        $stmt = $this->conexao->prepare("SELECT * FROM tb_pessoa WHERE id_pessoa = :id");
        $stmt->bindValue(':id', $this->id_pessoa, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Usuário não Localizado");
        }
        return $ret;
    }

    public function Inserir()
    {
        try {
            $this->verificaExistencia();
            $this->conexao->beginTransaction();
            $stmt = $this->conexao->prepare("
                INSERT INTO tb_pessoa (
                    nm_pessoa, nu_cpf, nu_cel, ds_email, ds_senha,
                    nu_cep, ds_complemento, nu_endereco
                ) VALUES (
                    :nm_pessoa, :nu_cpf, :nu_cel, :ds_email, :ds_senha,
                    :nu_cep, :ds_complemento, :nu_endereco
                )
            ");

            $stmt->bindValue(':nm_pessoa', $this->nm_pessoa, PDO::PARAM_STR);
            $stmt->bindValue(':nu_cpf', $this->nu_cpf, PDO::PARAM_STR);
            $stmt->bindValue(':nu_cel', $this->nu_cel, PDO::PARAM_STR);
            $stmt->bindValue(':ds_email', $this->ds_email, PDO::PARAM_STR);
            $this->ds_senha = password_hash($this->ds_senha, PASSWORD_DEFAULT);
            $stmt->bindValue(':ds_senha', $this->ds_senha, PDO::PARAM_STR);
            $stmt->bindValue(':nu_cep', $this->nu_cep, PDO::PARAM_STR);
            $stmt->bindValue(':ds_complemento', $this->ds_complemento, PDO::PARAM_STR);
            $stmt->bindValue(':nu_endereco', $this->nu_endereco, PDO::PARAM_INT);

            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Usuario adicionado com sucesso");
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    public function AlterarDadospessoa()
    {
        try {
            // Valida campos obrigatórios
            if (empty($this->nm_pessoa)) {
                throw new Exception("Nome é obrigatório");
            }
            if (empty($this->nu_cpf) || strlen($this->nu_cpf) != 11) {
                throw new Exception("CPF inválido (deve conter 11 dígitos)");
            }
            if (empty($this->nu_cel)) {
                throw new Exception("Celular é obrigatório");
            }
            if (empty($this->ds_email) || !filter_var($this->ds_email, FILTER_VALIDATE_EMAIL)) {
                throw new Exception("E-mail inválido");
            }
            if (empty($this->nu_cep) || strlen($this->nu_cep) != 8) {
                throw new Exception("CEP inválido (deve conter 8 dígitos)");
            }
            
            // Busca os dados atuais do usuário
            $dadosAtuais = $this->buscaPessoa();
            
            // Verifica se os dados não estão duplicados em outros usuários
            $this->verificaExistenciaAlteracao();
            
            // Monta o SQL apenas com os campos que foram alterados
            $camposUpdate = array();
            $valoresBind = array(':id_pessoa' => $this->id_pessoa);
            
            // Compara cada campo e adiciona apenas se foi alterado
            if (trim($this->nm_pessoa) !== trim($dadosAtuais['nm_pessoa'])) {
                $camposUpdate[] = "nm_pessoa = :nm_pessoa";
                $valoresBind[':nm_pessoa'] = $this->nm_pessoa;
            }
            
            if ($this->nu_cpf !== $dadosAtuais['nu_cpf']) {
                $camposUpdate[] = "nu_cpf = :nu_cpf";
                $valoresBind[':nu_cpf'] = $this->nu_cpf;
            }
            
            if ($this->nu_cel !== $dadosAtuais['nu_cel']) {
                $camposUpdate[] = "nu_cel = :nu_cel";
                $valoresBind[':nu_cel'] = $this->nu_cel;
            }
            
            if (trim($this->ds_email) !== trim($dadosAtuais['ds_email'])) {
                $camposUpdate[] = "ds_email = :ds_email";
                $valoresBind[':ds_email'] = $this->ds_email;
            }
            
            if ($this->nu_cep !== $dadosAtuais['nu_cep']) {
                $camposUpdate[] = "nu_cep = :nu_cep";
                $valoresBind[':nu_cep'] = $this->nu_cep;
            }
            
            if ($this->nu_endereco != $dadosAtuais['nu_endereco']) {
                $camposUpdate[] = "nu_endereco = :nu_endereco";
                $valoresBind[':nu_endereco'] = $this->nu_endereco;
            }
            
            // Só atualiza ds_complemento se não estiver vazio E for diferente do atual
            if (!empty(trim($this->ds_complemento)) && trim($this->ds_complemento) !== trim($dadosAtuais['ds_complemento'])) {
                $camposUpdate[] = "ds_complemento = :ds_complemento";
                $valoresBind[':ds_complemento'] = $this->ds_complemento;
            }
            
            // Se senha foi fornecida, adiciona ao UPDATE
            if (!empty($this->ds_senha)) {
                $camposUpdate[] = "ds_senha = :ds_senha";
                $senhaHash = password_hash($this->ds_senha, PASSWORD_DEFAULT);
                $valoresBind[':ds_senha'] = $senhaHash;
            }
            
            // Se não há campos para atualizar, retorna sucesso sem fazer UPDATE
            if (empty($camposUpdate)) {
                $this->banco->setMensagem(1, "Nenhum dado foi alterado");
                $this->banco->setDados(1, $dadosAtuais);
                return;
            }
            
            // Monta o SQL final
            $sql = "UPDATE tb_pessoa SET " . implode(", ", $camposUpdate) . " WHERE id_pessoa = :id_pessoa";
            
            $stmt = $this->conexao->prepare($sql);
            
            // Faz bind de todos os valores
            foreach ($valoresBind as $param => $valor) {
                if (strpos($param, ':nu_endereco') !== false || strpos($param, ':id_pessoa') !== false) {
                    $stmt->bindValue($param, $valor, PDO::PARAM_INT);
                } else {
                    $stmt->bindValue($param, $valor, PDO::PARAM_STR);
                }
            }

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            // Busca os dados atualizados para retornar usando query direta
            $stmtBusca = $this->conexao->prepare("SELECT * FROM tb_pessoa WHERE id_pessoa = :id");
            $stmtBusca->bindValue(':id', $this->id_pessoa, PDO::PARAM_INT);
            $stmtBusca->execute();
            $dadosAtualizados = $stmtBusca->fetch(PDO::FETCH_ASSOC);
            
            if (!$dadosAtualizados) {
                throw new Exception("Erro ao buscar dados atualizados");
            }
            
            $this->banco->setMensagem(1, "Dados do usuário Alterados");
            $this->banco->setDados(1, $dadosAtualizados);
        } catch (PDOException $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            error_log("AlterarDadospessoa PDOException: " . $e->getMessage());
            throw new Exception("Erro ao atualizar dados: " . $e->getMessage());
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            error_log("AlterarDadospessoa Exception: " . $e->getMessage());
            throw new Exception($e->getMessage());
        }
    }

    public function Excluir()
    {
        try {
            $this->buscaPessoa();

            $stmt = $this->conexao->prepare("DELETE FROM tb_pessoa WHERE id_pessoa = :id_pessoa");
            $stmt->bindValue(':id_pessoa', $this->id_pessoa, PDO::PARAM_INT);

            $this->conexao->beginTransaction();
            $stmt->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Usuário excluído com sucesso");
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Consultar()
    {
        try {
            $ret = $this->buscaPessoa();
            $this->banco->setMensagem(1, "Consulta efetuada com sucesso");
            $this->banco->setDados(count($ret), $ret);
        } catch (Exception $e) {
            throw new Exception($e->getMessage());
        }
    }

    public function Listar()
    {
        $stmt = $this->conexao->query("SELECT * FROM tb_pessoa");
        $ret = $stmt->fetchAll();
        $this->banco->setMensagem(1, "Sucesso na pesquisa");
        $this->banco->setDados(count($ret), $ret);
    }

    public function Login()
    {
        try {
            $stmt = $this->conexao->prepare("SELECT * FROM tb_pessoa WHERE ds_email = :email");
            $stmt->bindValue(':email', $this->ds_email, PDO::PARAM_STR);
            $stmt->execute();

            $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$usuario) {
                throw new Exception("Usuário incorreto");
            }

            if (!password_verify($this->ds_senha, $usuario['ds_senha'])) {
                throw new Exception("senha incorreto");
            }

            $this->banco->setMensagem(1, "Login permitido");
            $this->banco->setDados(1, $usuario);
        } catch (Exception $e) {
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }

    public function BuscarEndereco($id_pessoa)
    {
        $stmt = $this->conexao->prepare("SELECT nu_cep, ds_complemento, nu_endereco FROM tb_pessoa WHERE id_pessoa = :id");
        $stmt->bindValue(':id', $id_pessoa, PDO::PARAM_INT);
        $stmt->execute();
        $ret = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ret) {
            throw new Exception("Usuário não localizado");
        }

        // Formatar endereço (exemplo: "R. Goiabeira, 208")
        $endereco = "";
        if (!empty($ret['ds_complemento'])) {
            $endereco = $ret['ds_complemento'];
        }
        if (!empty($ret['nu_endereco'])) {
            if (!empty($endereco)) {
                $endereco .= ", " . $ret['nu_endereco'];
            } else {
                $endereco = $ret['nu_endereco'];
            }
        }

        $this->banco->setMensagem(1, "Endereço encontrado");
        $this->banco->setDados(1, array('endereco' => $endereco, 'cep' => $ret['nu_cep']));
    }

    public function EsqueceuSenha()
    {
        try {
            $stmt = $this->conexao->prepare("SELECT id_pessoa, nm_pessoa FROM tb_pessoa WHERE ds_email = :email");
            $stmt->bindValue(':email', $this->ds_email, PDO::PARAM_STR);
            $stmt->execute();

            $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$usuario) {
                throw new Exception("E-mail não encontrado");
            }

            // Gera uma nova senha temporária
            $novaSenha = substr(md5(uniqid(rand(), true)), 0, 8);
            $senhaHash = password_hash($novaSenha, PASSWORD_DEFAULT);

            // Atualiza a senha no banco
            $stmtUpdate = $this->conexao->prepare("UPDATE tb_pessoa SET ds_senha = :senha WHERE id_pessoa = :id");
            $stmtUpdate->bindValue(':senha', $senhaHash, PDO::PARAM_STR);
            $stmtUpdate->bindValue(':id', $usuario['id_pessoa'], PDO::PARAM_INT);
            
            $this->conexao->beginTransaction();
            $stmtUpdate->execute();
            $this->conexao->commit();

            $this->banco->setMensagem(1, "Nova senha gerada com sucesso");
            $this->banco->setDados(1, array(
                'id_pessoa' => $usuario['id_pessoa'],
                'nm_pessoa' => $usuario['nm_pessoa'],
                'nova_senha' => $novaSenha
            ));
        } catch (Exception $e) {
            if ($this->conexao->inTransaction()) {
                $this->conexao->rollBack();
            }
            $this->banco->setMensagem(0, $e->getMessage());
        }
    }
}
