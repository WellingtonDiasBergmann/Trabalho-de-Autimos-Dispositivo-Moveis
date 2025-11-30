import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:trabalhofinal/Services/SyncService.dart';
import 'package:trabalhofinal/Services/GeminiTTSService.dart';
import 'package:trabalhofinal/services/NavegacaoService.dart';
import 'package:trabalhofinal/main.dart'; // <--- NOVO: Importa MyHomePage do main.dart

// ====================================================================
// CLASSE DE CORES
// ====================================================================
class AppColors {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryOrange = Color(0xFFFF9800);
  static const Color cardBlue = Color(0xFF42A5F5);
  static const Color cardGreen = Color(0xFF66BB6A);
}

// ====================================================================
// PLACEHOLDER: CLASSE CommunicationItem
// Se CommunicationItem já existir em tela_caa_grande.dart, remova esta definição.
// ====================================================================
class CommunicationItem {
  final String id;
  final Map<String, dynamic> data;

  const CommunicationItem({required this.id, required this.data});
}


enum StatusCarregamentoAPI {carregando, sucesso, erro}

// ====================================================================
// CLASSE PRINCIPAL
// ====================================================================

class TelaPrincipal extends StatefulWidget {
  final int idUsuario;
  final bool usuarioProfissional;
  final bool usuarioResponsavel;
  final String nomeUsuario;
  final bool usuarioCrianca;
  final bool usuarioAutista;

  const TelaPrincipal({
    super.key,
    required this.idUsuario,
    required this.usuarioProfissional,
    required this.usuarioResponsavel,
    required this.usuarioCrianca,
    required this.nomeUsuario,
    required this.usuarioAutista,
  });

  @override
  State<TelaPrincipal> createState() => TelaPrincipalState();
}

class TelaPrincipalState extends State<TelaPrincipal> {
  // ATENÇÃO: A CHAVE DEVE SER MANTIDA EM SEGREDO EM PRODUÇÃO.
  final String _chaveAPI = '77932137b7964299adb200233250811';

  // Instância dos serviços
  late final GeminiTTSService _ttsService;
  final SyncService _syncService = SyncService(); // INSTÂNCIA DO SYNCSERVICE

  // ESTADOS PARA LOCALIZAÇÃO E CLIMA
  double? _latitude;
  double? _longitude;
  String _cidadeClima = "Buscando localização...";
  StatusCarregamentoAPI _statusClima = StatusCarregamentoAPI.carregando;

  //LIST DO MENU LATERAL
  late List<Map<String, dynamic>> _drawerItens;
  //RELOGIO NA TELA
  late DateTime _agora;
  Timer? _timer;
  bool _foiInicializado = false;

  //CLIMA NA TELA
  final Map<String, dynamic> _climaAtual = {
    'icon': Icons.cloud_queue,
    'descricao': "Buscando clima...",
    'temperatura': "..."
  };

  // ====================================================================
  // FUNÇÃO DE LOGOUT
  // ====================================================================
  void _handleLogout() async {
    // 1. Chama o método de logout para limpar dados locais e token
    await _syncService.sair();

    // 2. Navega para a tela de login (MyHomePage no main.dart) e remove todas as
    // telas anteriores da pilha. Isso impede que o usuário volte para
    // a TelaPrincipal após o logout.
    if (mounted) {
      // Primeiro, garante que o Drawer seja fechado, caso esteja aberto.
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }

      // CORREÇÃO: Usando MyHomePage, conforme solicitado
      Navigator.of(context).pushAndRemoveUntil(
        // Passa o argumento 'title' que é obrigatório no construtor de MyHomePage
        MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Spektrum')),
            (Route<dynamic> route) => false,
      );
    }
  }

  // ====================================================================
  // FUNÇÕES PLACEHOLDER (COM TTS REAL)
  // ====================================================================

  void onSave(CommunicationItem item) {
    print("CAA Save Action Placeholder: Salvando item ID: ${item.id} com dados: ${item.data}");
  }

  void speakAction(String text) {
    print("CAA Speak Action: Falando: \"$text\"");
    _ttsService.speak(text);
  }

  void onDelete(CommunicationItem item) {
    print("CAA Delete Action Placeholder: Deletando item ID: ${item.id}");
  }

  // ====================================================================
  // FUNÇÃO PARA OBTER A LOCALIZAÇÃO E CLIMA
  // ====================================================================
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _statusClima = StatusCarregamentoAPI.erro;
          _climaAtual['descricao'] = "Localização Desativada";
          _cidadeClima = "Ative a localização para o clima";
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _statusClima = StatusCarregamentoAPI.erro;
            _climaAtual['descricao'] = "Permissão Negada";
            _cidadeClima = "Atualize as permissões nas configurações";
          });
        }
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });

        _APIClima();
      }

    } on TimeoutException {
      if (mounted) {
        setState(() {
          _statusClima = StatusCarregamentoAPI.erro;
          _climaAtual['descricao'] = "Busca Expirada";
          _cidadeClima = "Não foi possível obter a posição a tempo.";
        });
      }
      print("Erro ao obter localização: Timeout");
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusClima = StatusCarregamentoAPI.erro;
          _climaAtual['descricao'] = "Erro de Busca";
          _cidadeClima = "Não foi possível obter a posição.";
        });
      }
      print("Erro ao obter localização: $e");
    }
  }


  @override
  void initState() {
    super.initState();

    _ttsService = GeminiTTSService();

    initializeDateFormatting('pt_BR', null).then((_) {
      if (mounted) {
        Intl.defaultLocale = 'pt_BR';

        _agora = DateTime.now();
        _timer = Timer.periodic(
            const Duration(seconds: 1), (Timer t) => _updateTime());

        setState(() {
          _drawerItens = _buildDrawerItens();
          _foiInicializado = true;
        });
      }
    });

    _agora = DateTime.now();
    _drawerItens = [];

    _getCurrentLocation();
  }

  Future<void> _APIClima() async {
    if (_latitude == null || _longitude == null) {
      return;
    }

    setState(() {
      _statusClima = StatusCarregamentoAPI.carregando;
    });

    try {
      final url = Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=$_chaveAPI&q=$_latitude,$_longitude&lang=pt');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        final current = data['current'];
        final condition = current['condition'];
        final location = data['location'];

        IconData iconData = _mapConditionCodeToIcon(current['condition']['code']);

        if (mounted) {
          setState(() {
            _climaAtual['icon'] = iconData;
            _climaAtual['descricao'] = condition['text'] as String;
            _climaAtual['temperatura'] = "${current['temp_c'].toStringAsFixed(0)}ºC";
            _cidadeClima = location['name'] as String;
            _statusClima = StatusCarregamentoAPI.sucesso;
          });
        }

      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Erro desconhecido na API.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print("Erro ao buscar clima: $e");
      if (mounted) {
        setState(() {
          _climaAtual['descricao'] = "Falha no Clima.";
          _climaAtual['temperatura'] = "N/D";
          _climaAtual['icon'] = Icons.error_outline;
          _statusClima = StatusCarregamentoAPI.erro;
        });
      }
    }
  }

  IconData _mapConditionCodeToIcon(int code) {
    if (code == 1000) return Icons.wb_sunny_outlined;
    if (code == 1003 || code == 1006) return Icons.cloud_queue;
    if (code == 1009) return Icons.cloud;
    if (code >= 1063 && code <= 1072) return Icons.water_drop;
    if (code >= 1183 && code <= 1201) return Icons.shower;
    if (code >= 1087) return Icons.flash_on;
    return Icons.cloud_queue;
  }

  @override
  void dispose() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    _ttsService.dispose();
    super.dispose();
  }

  void _updateTime(){
    if (mounted && _foiInicializado) {
      setState(() {
        _agora = DateTime.now();
      });
    }
  }

  // FUNÇÃO DE NAVEGAÇÃO CENTRALIZADA
  void _navegarPara(String routeName) {
    // 1. Fecha o drawer, se estiver aberto (ainda precisa do context para pop o drawer)
    if (Navigator.of(context).canPop()){
      Navigator.pop(context);
    }

    // Adiciona o userId como argumento APENAS para a rota /rotinas
    Map<String, dynamic>? arguments;
    if (routeName == '/rotinas') {
      // A rota /rotinas espera a chave 'userId'
      arguments = {'userId': widget.idUsuario};
    }

    // 2. Chama o NavigationService para ir para a rota nomeada
    NavigationService().navigateTo(routeName, arguments: arguments);
  }

  // FUNÇÃO PARA ABRIR O MODO CRISE
  void _abrirModoCrise() {
    // Garante que o drawer esteja fechado, se estiver aberto
    if (Navigator.of(context).canPop()){
      Navigator.pop(context);
    }
    // Usa o serviço e assume que a rota é '/modo_crise'
    NavigationService().navigateTo('/modo_crise');
  }


  // ====================================================================
  // CRIAÇÃO DO MENU LATERAL (AJUSTADO PARA ROTAS NOMEADAS)
  // ====================================================================
  List<Map<String, dynamic>> _buildDrawerItens() {
    final List<Map<String, dynamic>> itens = [
      // DASHBOARD
      if(widget.usuarioProfissional || widget.usuarioAutista)
        {
          'title': 'Dashboard (WIP)',
          'icon': Icons.analytics,
          'color': Colors.indigo,
          'routeName': '/dashboard', // ROTA NOMEADA
          'type': 'navigate',
        },
      // ROTINA
      {
        'title': 'Rotina',
        'icon': Icons.schedule,
        'color': Colors.orange,
        'routeName': '/rotinas', // ROTA NOMEADA
        'type': 'navigate',
      },
      // CAA - GRANDE ou CRIANÇA
      if(widget.usuarioCrianca || widget.usuarioAutista)
        {
          'title': 'CAA - Criança',
          'icon': Icons.speaker_phone,
          'color': Colors.yellow,
          'routeName': '/caa_crianca', // ROTA NOMEADA
          'type': 'navigate',
        }
      else
        {
          'title': 'CAA - Grade (WIP)',
          'icon': Icons.grid_view,
          'color': Colors.blue,
          'routeName': '/caa_grade', // ROTA NOMEADA
          'type': 'navigate',
        },

      // DIARIO
      if(widget.usuarioResponsavel)
        {
          'title': 'Diario',
          'icon': Icons.book_outlined,
          'color': Colors.green,
          'routeName': '/diario', // ROTA NOMEADA
          'type': 'navigate',
        },

      // BOTÃO SAIR
      {
        'title': 'Sair',
        'icon': Icons.logout,
        'color': Colors.red,
        'action': _handleLogout, // FUNÇÃO DE LOGOUT REAL
        'type': 'action',
      },
    ];
    return itens;
  }

  // BANNER DO CLIMA E DO RELOGIO
  Widget _buildTempEHora(BuildContext context) {
    if (!_foiInicializado || _statusClima == StatusCarregamentoAPI.carregando) {
      // Indicador de Carregamento
      return Container(
        height: 120,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryBlue),
            const SizedBox(height: 8),
            Text(_statusClima == StatusCarregamentoAPI.carregando
                ? "Buscando dados..."
                : "Inicializando..."),
          ],
        ),
      );
    }

    final bool isError = _statusClima == StatusCarregamentoAPI.erro;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isError
              ? [Colors.red.shade400, Colors.red.shade700]
              : [AppColors.primaryBlue, AppColors.cardBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // CLIMA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: [
                    Icon(
                      _climaAtual['icon'] as IconData,
                      size: 30,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _climaAtual['temperatura'] as String,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _climaAtual['descricao'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _cidadeClima,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // RELOGIO
          Container(
            width: 1, // Separador
            color: Colors.white30,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                DateFormat('HH:mm').format(_agora),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                DateFormat('EEE, d MMM', 'pt_BR').format(_agora),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // WIDGET PRINCIPAL
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    final telaLargura = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // FLOATING ACTION BUTTON PARA O MODO CRISE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModoCrise,
        label: const Text(
          "Modo Crise",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.crisis_alert),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 120.0,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.nomeUsuario,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getRoleText(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Placeholder para a Logo
                  Image.asset(
                    'assets/logoTudo.png',
                    height: 100,
                    width: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.logo_dev,
                        size: 70,
                        color: Colors.white70,
                      );
                    },
                  ),
                ],
              ),
            ),

            ..._drawerItens.map((item) {
              return ListTile(
                leading: Icon(item['icon'] as IconData, color: item['color'] as Color),
                title: Text(item['title'] as String),
                onTap: () {
                  if (item['type'] == 'navigate') {
                    // Usa a função centralizada que chama o NavigationService
                    _navegarPara(item['routeName'] as String);
                  } else if (item['type'] == 'action') {
                    // Executa a ação (neste caso, _handleLogout)
                    (item['action'] as VoidCallback)();
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // SEÇÃO DE BOAS-VINDAS
            Text(
              "Olá,",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              widget.nomeUsuario,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),

            // CLIMA E HORA BANNER
            _buildTempEHora(context),
            const SizedBox(height: 20),

            // TÍTULO DA SEÇÃO
            const Text(
              "Acesso Rápido:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 10),

            // GRID DE BOTÕES DE NAVEGAÇÃO
            GridView.count(
              crossAxisCount: telaLargura > 600 ? 3 : 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: telaLargura > 600 ? 1.2 : 1.1,
              children: _drawerItens.where((item) => item['type'] == 'navigate').map((item) {
                return _buildFeatureCard(
                  title: item['title'] as String,
                  icon: item['icon'] as IconData,
                  color: item['color'] as Color,
                  // Usa a função centralizada que chama o NavigationService
                  onTap: () => _navegarPara(item['routeName'] as String),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Função auxiliar para determinar o texto do papel do usuário
  String _getRoleText() {
    if (widget.usuarioCrianca) {
      return "Criança Autista";
    } else if (widget.usuarioAutista) {
      return "Usuário Autista";
    } else if (widget.usuarioResponsavel) {
      return "Responsável";
    } else if (widget.usuarioProfissional) {
      return "Profissional/Terapeuta";
    }
    return "Visitante";
  }

  // WIDGET DE CARD DE FUNCIONALIDADE
  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: 5),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
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
