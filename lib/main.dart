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
import 'package:trabalhofinal/tela_dashboard.dart';
import 'package:trabalhofinal/tela_relatorios.dart';
import 'package:trabalhofinal/tela_compartilhar.dart';
import 'package:trabalhofinal/tela_acessibilidade.dart';
import 'package:trabalhofinal/tela_psicologo.dart';
import 'package:trabalhofinal/Services/SimpleTTSService.dart';
import 'package:crypto/crypto.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spektrum',
      navigatorKey: NavigationService().navigatorKey,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      initialRoute: '/', 
      routes: {
        '/': (context) => const MyHomePage(title: 'Spektrum'), 
        '/registrar': (context) => const TelaRegistrar(),
        '/esqueci_senha': (context) => const TelaEsqueciSenha(),

        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          if (args == null ||
              !args.containsKey('userId') ||
              !args.containsKey('nomeUsuario') ||
              !args.containsKey('usuarioAutista') ||
              !args.containsKey('usuarioResponsavel') ||
              !args.containsKey('usuarioProfissional') ||
              !args.containsKey('usuarioCrianca')) {
            return const MyHomePage(title: 'Spektrum');
          }

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
          final ttsService = SimpleTTSService();
          void speakAction(String text) {
            if (text.isNotEmpty) {
              ttsService.speak(text);
            }
          }

          return TelaCcaCrianca(
            speakAction: speakAction,
            userId: userId,
          );
        },

        '/caa_grande': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final int? userId = args?['userId'] as int?;

          if (userId == null) {
            return const Scaffold(body: Center(child: Text("Erro: ID de Usuário ausente para CAA Grande.")));
          }

          final ttsService = SimpleTTSService();
          void speakAction(String text) {
            if (text.isNotEmpty) {
              ttsService.speak(text);
            }
          }

          return TelaCcaGrande(
            speakAction: speakAction,
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

        '/dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final int? userId = args?['userId'] as int?;

          if (userId == null) {
            return const Scaffold(body: Center(child: Text("Erro: ID de Usuário ausente para Dashboard.")));
          }

          return TelaDashboard(userId: userId);
        },

        '/relatorios': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final int? userId = args?['userId'] as int?;
          final bool? isProfessional = args?['isProfessional'] as bool?;

          if (userId == null) {
            return const Scaffold(body: Center(child: Text("Erro: ID de Usuário ausente para Relatórios.")));
          }

          return TelaRelatorios(
            userId: userId,
            isProfessional: isProfessional ?? false,
          );
        },

        '/compartilhar': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final int? userId = args?['userId'] as int?;

          if (userId == null) {
            return const Scaffold(body: Center(child: Text("Erro: ID de Usuário ausente para Compartilhar.")));
          }

          return TelaCompartilhar(userId: userId);
        },

        '/acessibilidade': (context) => const TelaAcessibilidade(),

        '/psicologo': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final int? userId = args?['userId'] as int?;

          if (userId == null) {
            return const Scaffold(body: Center(child: Text("Erro: ID de Usuário ausente para Psicólogo.")));
          }

          return TelaPsicologo(userId: userId);
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

  void _abrirTelaRegistrar() {
    Navigator.pushNamed(context, '/registrar');
  }

  void _abrirTelaTrocaSenha() {
    Navigator.pushNamed(context, '/esqueci_senha');
  }

  Future<void> _validaCampos() async {
    if (!_validaLogin.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    final String email = _usuarioController.text;
    final String password = _senhaController.text;

    try {
      final authResult = await _syncService.signInAndSync(email, password);

      if (authResult['success'] == true) {

        User? user;
        final dynamic userData = authResult['user'];

        if (userData is Map<String, dynamic>) {
          user = User.fromJson(userData);
        } else if (userData is User) {
          user = userData;
        }

        if (user == null || user.id == null) {
          throw Exception("Usuário ou ID não retornado pela API ou conversão de dados falhou.");
        }

        NavigationService().navigateToAndRemoveAll(
          '/home',
          arguments: {
            'userId': user.id,
            'nomeUsuario': user.nome ?? 'Usuário',
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
      debugPrint("Erro durante o processo de login: $e");
      _mostrarBalaoMensagem(
        "Erro de Conexão",
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
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Image.asset(
                  'assets/logoTudo.png',
                  height: 250,
                  width: 250,
                ),
              ),

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

              const SizedBox(height: 20),

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

              const SizedBox(height: 40),

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

              const SizedBox(height: 40),

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

              const SizedBox(height: 10),

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