<?php

abstract Class Base
{
    protected $banco;
    protected $conexao;
    protected $nomeTabela;
    protected $Dados;
    protected $Oper;

    // Contrutor: Passar o banco que se quer utilizar

  	function __construct($p_banco)
  	{ 
  		$this->banco      = $p_banco;
  	 	$this->conexao    = $this->banco->getConexao();
  	 	$this->nomeTabela = get_class($this);
  	}

    public function setOper($p_oper)
    {
      $this->Oper = $p_oper;
    }
  }
