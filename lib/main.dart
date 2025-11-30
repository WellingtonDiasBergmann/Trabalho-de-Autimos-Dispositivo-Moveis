import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trabalhofinal/Models/User.dart';
import 'package:trabalhofinal/Services/ApiService.dart';
import 'package:trabalhofinal/Services/SyncService.dart';
import 'package:trabalhofinal/tela_esqueci_senha.dart';
import 'package:trabalhofinal/tela_registrar.dart';
import 'package:trabalhofinal/services/NavegacaoService.dart';
import 'package:trabalhofinal/tela_cca_grande.dart';
import 'package:trabalhofinal/tela_rotinas.dart';
import 'package:trabalhofinal/tela_cca_crianca.dart';
import 'package:trabalhofinal/tela_diario.dart';
import 'package:trabalhofinal/tela_modo_crise.dart';
import 'package:trabalhofinal/tela_principal.dart';
// Mantida para consistência com o arquivo original. Pode ser removida se não for usada.
import 'package:crypto/crypto.dart';


void main() {
  // Configuração para garantir que o Flutter binding esteja inicializado antes de rodar o app.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // O MaterialApp é o ponto central onde definimos todas as rotas do app.
    return MaterialApp(
      title: 'Spektrum',
      // PASSO CRÍTICO: Anexar a chave de navegação global para o NavigationService
      navigatorKey: NavigationService().navigatorKey,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // Definir as rotas nomeadas para todo o aplicativo
      initialRoute: '/', // Define a rota inicial como a tela de Login
      routes: {
        // ROTAS DE PRIMEIRO NÍVEL (Acessíveis do Login)
        '/': (context) => const MyHomePage(title: 'Spektrum'), // Rota de Login
        '/registrar': (context) => const TelaRegistrar(),
        '/esqueci_senha': (context) => const TelaEsqueciSenha(),

        // ROTA PRINCIPAL (DESTINO APÓS O LOGIN)
        '/home': (context) {
          // Assegura que os argumentos sejam lidos como Map<String, dynamic>
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          // Verifica se os argumentos críticos (como userId) existem
          if (args == null ||
              !args.containsKey('userId') ||
              !args.containsKey('nomeUsuario') ||
              !args.containsKey('usuarioAutista') ||
              !args.containsKey('usuarioResponsavel') ||
              !args.containsKey('usuarioProfissional') ||
              !args.containsKey('usuarioCrianca')) {
            // Se faltar algum argumento crucial (o que pode ter acontecido se o login falhou
            // ou a navegação foi incompleta), volta para a tela de login.
            return const MyHomePage(title: 'Spektrum');
          }

          // Leitura dos argumentos. Como _validaCampos agora envia booleanos não-nulos
          // (graças aos Getters), podemos usar o cast 'as bool' diretamente após o null check inicial.
          final int idUsuario = args['userId'] as int;
          final String nomeUsuario = args['nomeUsuario'] as String;

          final bool usuarioAutista = args['usuarioAutista'] as bool;
          final bool usuarioResponsavel = args['usuarioResponsavel'] as bool;
          final bool usuarioProfissional = args['usuarioProfissional'] as bool;
          final bool usuarioCrianca = args['usuarioCrianca'] as bool;

          return TelaPrincipal(
            idUsuario: idUsuario,
            nomeUsuario: nomeUsuario,
            usuarioAutista: usuarioAutista,
            usuarioResponsavel: usuarioResponsavel,
            usuarioProfissional: usuarioProfissional,
            usuarioCrianca: usuarioCrianca,
          );
        },

        // ROTAS DE SEGUNDO NÍVEL (Usadas pela TelaPrincipal e NavigationService)
        '/modo_crise': (context) => const TelaModoCrise(),

        '/rotinas': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final int? userId = args?['userId'] as int?;

          if (userId == null) {
            return const Scaffold(
              body: Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("Erro Crítico: ID do Usuário (userId) não fornecido para Rotinas.", textAlign: TextAlign.center),
              )),
            );
          }
          return TelaRotinas(userId: userId);
        },

        '/cca_crianca': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final int? userId = args?['userId'] as int?;

          if (userId == null) {
            return const Scaffold(body: Center(child: Text("Erro: ID de Usuário ausente para CCA Criança.")));
          }

          // Mock da função de fala (Ação simulada, idealmente configurada com um serviço de TTS)
          void mockSpeak(String text) {
            debugPrint("Mock Speak: $text");
          }

          return TelaCcaCrianca(
            speakAction: mockSpeak,
            userId: userId,
          );
        },

        '/caa_grande': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final int? userId = args?['userId'] as int?;

          if (userId == null) {
            return const Scaffold(body: Center(child: Text("Erro: ID de Usuário ausente para CAA Grande.")));
          }

          // Mock da função de fala
          void mockSpeak(String text) {
            debugPrint("Mock Speak: $text");
          }

          return TelaCcaGrande(
            speakAction: mockSpeak,
            userId: userId,
          );
        },

        '/diario': (context) {
          final args = ModalRoute
              .of(context)
              ?.settings
              .arguments as Map<String, dynamic>?;
          final int? userId = args?['userId'] as int?;

          if (userId == null) {
            return const Scaffold(body: Center(
                child: Text("Erro: ID de Usuário ausente para Tela Diário.")));
          }
          return TelaDiario(userId: userId);
        },
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final _validaLogin = GlobalKey<FormState>();

  final SyncService _syncService = SyncService();
  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // TOAST PARA INFORMAR ERRO
  void _mostrarBalaoMensagem(String titulo, String mensagem, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
              ),
              const SizedBox(width: 10),
              Text(titulo),
            ],
          ),
          content: Text(mensagem),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // CODIGOS DE NAVEGAÇÃO
  void _abrirTelaRegistrar() {
    // Navegação para a rota nomeada '/registrar'
    Navigator.pushNamed(context, '/registrar');
  }

  // CODIGOS DE NAVEGAÇÃO
  void _abrirTelaTrocaSenha() {
    // Navegação para a rota nomeada '/esqueci_senha'
    Navigator.pushNamed(context, '/esqueci_senha');
  }

  // FUNÇÃO DE VALIDAÇÕES E FUNÇÃO LOGIN
  Future<void> _validaCampos() async {
    // Adicionado o 'if (_isLoading) return;' para evitar múltiplos cliques
    if (!_validaLogin.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    final String email = _usuarioController.text;
    final String password = _senhaController.text;

    try {
      // 1) LOGIN COMPLETO (LOGIN + USER)
      final authResult = await _syncService.signInAndSync(email, password);

      if (authResult['success'] == true) {

        // RECUPERAÇÃO E CONVERSÃO DEFENSIVA DO USUÁRIO
        // Se 'user' vem como um Map<String, dynamic> (JSON bruto)
        // é necessário convertê-lo explicitamente.
        User? user;
        final dynamic userData = authResult['user'];

        if (userData is Map<String, dynamic>) {
          user = User.fromJson(userData);
        } else if (userData is User) {
          user = userData;
        }

        // VERIFICAÇÃO IMPORTANTE
        // Esta exceção é disparada se o user não foi convertido ou se user.id é null
        if (user == null || user.id == null) {
          throw Exception("Usuário ou ID não retornado pela API ou conversão de dados falhou.");
        }

        // CORREÇÃO: Usando os Getters booleanos (user.usuarioCrianca) em vez
        // de propriedades opcionais (user.isCrianca) para garantir que um
        // valor 'bool' (não 'bool?') seja enviado para a rota '/home'.
        NavigationService().navigateToAndRemoveAll(
          '/home',
          arguments: {
            'userId': user.id,
            'nomeUsuario': user.nome ?? 'Usuário',
            // Getters que retornam bool (false por padrão se não definido)
            'usuarioAutista': user.usuarioAutista,
            'usuarioResponsavel': user.usuarioResponsavel,
            'usuarioProfissional': user.usuarioProfissional,
            'usuarioCrianca': user.usuarioCrianca,
          },
        );

        _mostrarBalaoMensagem(
          "Login bem-sucedido!",
          "Sincronização concluída. Bem-vindo(a)!",
          isError: false,
        );

      } else {
        _mostrarBalaoMensagem(
          "Falha no Login",
          authResult['message'] ?? "Email ou senha incorretos.",
          isError: true,
        );
      }

    } catch (e) {
      // Adicionado um log para facilitar a depuração de erros de conexão/API
      debugPrint("Erro durante o processo de login: $e");
      _mostrarBalaoMensagem(
        "Erro de Conexão",
        // A mensagem da exceção lançada (se houver) aparecerá aqui.
        "Problema ao conectar com o servidor ou dados inválidos: ${e.toString()}",
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Form(
          key: _validaLogin,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              //LOGO
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Image.asset(
                  'assets/logoTudo.png',
                  height: 250,
                  width: 250,
                ),
              ),

              //CAMPO PRA INFORMAR O USUARIO (ASSUMINDO QUE É O EMAIL)
              const SizedBox(height: 30),
              Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextFormField(
                  controller: _usuarioController,
                  validator: (value) {
                    if (value == null || value.isEmpty){
                      return 'Informe o seu e-mail';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "E-mail",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                  ),
                ),
              ),

              //MARGIN ENTRE OS DOIS CAMPO QUE O USUARIO PODE ESCREVER
              const SizedBox(height: 20),

              //CAMPO PARA INFORMAR A SENHA
              Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextFormField(
                  controller: _senhaController,
                  validator: (value) {
                    if (value == null || value.isEmpty){
                      return 'Informe a sua senha';
                    }
                    return null;
                  },
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ),

              //MARGIN ENTRE O CAMPO DA SENHA E O BOTAO
              const SizedBox(height: 40),

              // BOTAO ENTRAR (com indicador de carregamento)
              Padding( padding: const EdgeInsets.symmetric(horizontal: 70.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                    onPressed: _validaCampos,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'Entrar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                ),
              ),

              //MARGIN ENTRE O BOTAO E O TEXTO PRA CADASTRAR
              const SizedBox(height: 40),

              //TEXTO PRA CADASTRAR
              Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GestureDetector(
                  onTap: _abrirTelaRegistrar,
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            const TextSpan(
                              text: 'Não tem conta? ' ,
                            ),
                            TextSpan(
                                text: 'Cadastre-se',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                )
                            )
                          ]
                      ),
                    ),
                  ),
                ),
              ),

              //MARGIN ENTRE O BOTAO E O TEXTO PRA CADASTRAR
              const SizedBox(height: 10),

              //TEXTO DE ESQUECEU A SENHA
              Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GestureDetector(
                  onTap: _abrirTelaTrocaSenha,
                  child: Center(
                    child: Text(
                      'Esqueci minha senha',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}