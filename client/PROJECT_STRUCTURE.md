## Documentação Completa da Estrutura do Projeto

Este documento descreve todos os diretórios e arquivos relevantes do repositório `public_html`, cobrindo tanto o back-end em PHP quanto o aplicativo Flutter no diretório `QueroDoce`. O objetivo é possibilitar que qualquer pessoa entenda rapidamente a função de cada parte do código.

---

## Visão Geral em Alto Nível

- **Back-end PHP (pastas `Controller/` e `Model/`)**  
  Camada responsável por expor endpoints HTTP para operações de CRUD, autenticação, carrinho, etc., comunicando-se diretamente com o banco PostgreSQL via PDO.

- **Front-end Flutter (`QueroDoce/`)**  
  Aplicativo cliente (Android/iOS/Web/desktop) que consome os endpoints PHP. Organizado com controllers, models, pages e services em Dart.

- **Scripts utilitários**  
  Arquivos como `phpinfo.php` para diagnóstico do ambiente.

---

## Raiz de `public_html`

| Caminho | Descrição |
| --- | --- |
| `Controller/` | Endpoints PHP expostos via HTTP. Cada `Crud*.php` recebe parâmetros da requisição, instancia o modelo correspondente e retorna JSON usando `Banco::getRetorno()`. |
| `Model/` | Implementações de acesso a dados em PHP. Cada classe `Tb_*` estende `Base.php`, usa PDO para consultar/atualizar tabelas e povoa objetos de resposta em `Banco`. |
| `phpinfo.php` | Script auxiliar que imprime as informações do PHP (`phpinfo()`), usado para diagnosticar o ambiente. |
| `QueroDoce/` | Aplicativo Flutter completo (clientes Android/iOS/Web/desktop). Contém o código Dart (`lib/`), assets, configurações de plataformas e builds. |

---

## Diretório `Controller/`

Todos os arquivos seguem um mesmo padrão:

1. Configuram CORS e cabeçalhos JSON.
2. Desligam a exibição de erros para o cliente mas mantêm `error_log`.
3. Incluem `Banco.php` e o `Model/Tb_*.php` correspondente.
4. Capturam parâmetros via `$_REQUEST`, populam o model e roteiam pela chave `oper`.
5. Retornam JSON serializado por `Banco::getRetorno()`, inclusive em erros.

| Arquivo | Responsabilidade principal |
| --- | --- |
| `CrudBanner.php` | CRUD de banners promocionais. Opera sobre `Model/Tb_Banner.php`, permitindo inserir, atualizar, remover, listar e buscar banners exibidos no app. |
| `CrudCarrinho.php` | Mantém o carrinho de compras de um usuário. Recebe itens (produto, quantidade), interage com `Tb_Carrinho` para adicionar, remover, listar e finalizar itens do carrinho. |
| `CrudCategoria.php` | CRUD de categorias de produtos, usado para filtrar doces por tipo. Chamadas “Listar”, “Inserir”, etc. |
| `CrudEmpresa.php` | Opera dados das empresas/confeitarias: cadastro, atualização, exclusão, listagens e consultas. Depende de `Tb_Empresa`. |
| `CrudProduto.php` | Principal endpoint de produtos (`Tb_Produto`). Além das operações básicas, expõe buscas por nome (`PesquisarPorNome`), por empresa, por categoria e listagens de destaque/recentes. |
| `CrudUsuario.php` | Endpoint para pessoas/usuários (`Tb_Pessoa`). Suporta inserção, alteração dos dados pessoais, consulta, login, recuperação de senha, busca de endereço e listagem. |
| `index.php` | Arquivo de conveniência que pode apresentar uma mensagem ou redirecionar para documentar os endpoints disponíveis (conteúdo simples). |

---

## Diretório `Model/`

Base comum:

- `Base.php`: classe abstrata que recebe um objeto `Banco`, guarda a conexão PDO e o nome da tabela. Fornece `setOper()` para rastrear a operação atual.
- `Banco.php`: gerencia a conexão PDO com PostgreSQL, escolhe host automaticamente (IP interno/externo), armazena mensagens/dados (`setMensagem`, `setDados`) e serializa o retorno JSON. Todos os modelos dependem dele.

Cada `Tb_*` encapsula regras de negócio e SQL da tabela correspondente. Principais responsabilidades:

| Arquivo | Funções chave |
| --- | --- |
| `Tb_Banner.php` | Métodos para inserir/atualizar banners (título, imagem, links), listar banners ativos e excluir os inativos. |
| `Tb_Carrinho.php` | Manipula tabela `tb_carrinho`. Permite adicionar itens, atualizar quantidades, remover itens específicos, limpar o carrinho de um usuário e listar o carrinho atual. |
| `Tb_Categoria.php` | CRUD de categorias. Contém validação de nomes duplicados e ordenação padrão para exibição consistente. |
| `Tb_Empresa.php` | Lida com dados das confeitarias (nome, CNPJ, contato, endereço). Inclui validações de duplicidade (CNPJ/e-mail) e métodos de listagem por filtros. |
| `Tb_Pessoa.php` | Modelo mais extenso: setters higienizam entradas (limpeza de CPF, CEP, trims). Métodos incluem `Inserir` (com `password_hash`), `AlterarDadospessoa` (valida campos obrigatórios, evita duplicidades, atualiza apenas campos modificados), `Excluir`, `Consultar`, `Listar`, `Login` (usa `password_verify`), `BuscarEndereco`, `EsqueceuSenha`. |
| `Tb_Produto.php` | Controla produtos (nome, descrição, preço, estoque, disponibilidade, empresa). Implementa inserção/alteração com validações, exclusão, listagens gerais e filtros por empresa, categoria, produtos recentes e pesquisa textual. |
| `index.php` | Pode mostrar informações básicas da API ou responder com erro padrão (arquivo placeholder). |

---

## Arquivo utilitário

| Arquivo | Função |
| --- | --- |
| `phpinfo.php` | Executa `phpinfo();` para diagnosticar extensões, configurações e variáveis do PHP no servidor. Útil para suporte. |

---

## Aplicativo Flutter (`QueroDoce/`)

### Arquivos e diretórios de configuração raiz

| Caminho | Descrição |
| --- | --- |
| `analysis_options.yaml` | Regras de linting para Dart/Flutter (analisador). |
| `pubspec.yaml` | Manifesto do app: dependências, assets, fonts. |
| `pubspec.lock` | Resolução concreta das dependências. |
| `LICENSE` | Licença MIT. |
| `README.md` | Documentação do app (instalação, fluxo, diagramas). |
| `test/widget_test.dart` | Teste exemplo criado pelo template Flutter. |

### Diretório `assets/`

| Caminho | Conteúdo |
| --- | --- |
| `assets/images/logo.png` | Logo usada em splash/login. |
| `assets/images/banner.png` | Banner padrão exibido na home. |

### Diretórios de plataforma (`android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`)

Arquivos gerados pelo Flutter para cada plataforma suportada (gradle configs, Xcode projects, CMakeLists, assets de plataforma, executáveis de teste etc.). Devem ser mantidos para builds nativos, raramente editados manualmente (exceto config específicos, ícones, permissões).

### Diretório `build/` e `flutter_assets/`

Saída gerada pelo Flutter após compilações. Pode ser limpo/recriado (`flutter clean`). Não editar manualmente.

### Diretório `lib/`

Principal código Dart do aplicativo.

#### Arquivos na raiz de `lib/`

| Arquivo | Função |
| --- | --- |
| `main.dart` | Ponto de entrada. Configura tema, inicializa `AuthService.usuarioLogado`, define rotas e página inicial (provavelmente `HomePage`). |
| `register.dart` | Tela de registro/cadastro de usuário. Contém formulário, validações e chamada ao controller correspondente. |

#### `lib/controllers/`

Camada de comunicação HTTP com o back-end. Cada controller chama um endpoint PHP (veja os `baseUrl` apontando para `Controller/Crud*.php`).

| Arquivo | Descrição |
| --- | --- |
| `banner_controller.dart` | Faz requisições ao `CrudBanner.php`, obtendo banners ativos para a home. |
| `carrinho_controller.dart` | Envia operações de adicionar/remover itens ao `CrudCarrinho.php`, mantendo o estado do carrinho sincronizado com o servidor. |
| `categoria_controller.dart` | Consulta categorias registradas (`CrudCategoria.php`) para filtros e menus. |
| `empresa_controller.dart` | Busca dados de empresas para exibição (nome, avaliações) consumindo `CrudEmpresa.php`. |
| `pessoa_controller.dart` | Gerencia dados do usuário autenticado: atualizar perfil, buscar endereço formatado, fluxo de “esqueci a senha”. |
| `produto_controller.dart` | Pesquisa produtos, lista por categoria/empresa, obtém destaques e fornece dados ao catálogo usando `CrudProduto.php`. |

Todos seguem o mesmo padrão: montar URL com query parameters, chamar `http.get`, decodificar JSON e converter para models.

#### `lib/models/`

Representações locais (Dart) das entidades retornadas pelo back-end. Cada model possui `fromJson`/`toJson`.

| Arquivo | Campos principais |
| --- | --- |
| `banner.dart` | id, título, descrição, link/imagem para banners promocionais. |
| `carrinho_item.dart` | id do item, produto associado, quantidade, preço total. |
| `categoria.dart` | id, descrição, ícone/cor usados na UI. |
| `empresa.dart` | id, nome fantasia, contatos, endereço e possivelmente avaliação. |
| `pessoa.dart` | id, nome, CPF, celular, email, CEP, complemento, número; inclui getter `enderecoFormatado`. |
| `produto.dart` | id, nome, descrição, valor, estoque, imagem, flags de disponibilidade e relacionamento com empresa/categoria. |

#### `lib/pages/`

Telas completas do app, compostas por widgets, formulários e chamadas a controllers.

| Arquivo | Responsabilidade |
| --- | --- |
| `address_page.dart` | Tela para cadastrar/atualizar CEP, número e complemento. Integra com consulta de CEP e controllers para salvar endereço. |
| `cart_page.dart` | Mostra itens no carrinho, permite alterar quantidades e navegar ao checkout. |
| `checkout_page.dart` | Resumo final do pedido, escolha de pagamento, disparo da conclusão de compra. |
| `forgot_password_page.dart` | Formulário de recuperação (solicita email, aciona `PessoaController.esqueceuSenha`). |
| `home_page.dart` | Landing page com banner, lista de categorias, produtos, destaques e ícones de navegação. Consome `banner_controller`, `produto_controller`, etc. |
| `product_page.dart` | Detalhe de um produto específico; mostra descrição, fotos, preço e botão “Adicionar ao carrinho”. |
| `profile_page.dart` | Permite visualizar e editar dados pessoais (nome, CPF, celular, email, CEP) e redefinir senha. Usa `AuthService.usuarioLogado` e `PessoaController`. |
| `search_page.dart` | Tela de busca com campo texto e resultados filtrados via `produto_controller`. |

#### `lib/services/`

| Arquivo | Função |
| --- | --- |
| `auth_service.dart` | Mantém o usuário autenticado em memória (`Pessoa? usuarioLogado`), executa login/logout via `CrudUsuario.php` e reutiliza os dados em todo o app. |

#### `lib/widgets/`

Atualmente vazio; reservado para componentes reutilizáveis (cards, botões, etc.). Ao criar novos widgets comuns, eles devem ser adicionados aqui.

---

## Conexão entre Back-end e Front-end

- Os controllers PHP acessam endpoins via HTTP (o backend está hospedado no servidor de aplicação da faculdade).
- Os controllers Dart montam URLs apontando para esses scripts e interpretam o JSON retornado (chaves `Mensagem`, `NumMens`, `dados`, `registros`).
- Models PHP garantem consistência e validação antes de tocar o banco; models Dart fornecem tipagem e conveniências de UI.

---

## Como usar este documento

1. **Para entender o fluxo completo**: comece pela visão geral e localize a seção do componente desejado (por exemplo, “Atualizar perfil” passa por `lib/pages/profile_page.dart` → `lib/controllers/pessoa_controller.dart` → `Controller/CrudUsuario.php` → `Model/Tb_Pessoa.php`).
2. **Para manutenção**: encontre o arquivo na tabela correspondente e leia sua descrição para saber se a alteração deve acontecer nele ou em um arquivo relacionado.
3. **Para novos contribuidores**: siga a ordem “Raiz → Back-end → Front-end” para montar o mapa mental do projeto.

---

Documento mantido manualmente. Atualize-o sempre que criar novos arquivos ou alterar responsabilidades para preservar a rastreabilidade do sistema.

