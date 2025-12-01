import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color cardBlue = Color(0xFF42A5F5);
}

class TelaModoCrise extends StatefulWidget {
  const TelaModoCrise({super.key});

  @override
  State<TelaModoCrise> createState() => _TelaModoCriseState();
}

class _TelaModoCriseState extends State<TelaModoCrise> {
  String _contato1Nome = 'Contato 1';
  String _contato1Telefone = '';
  String _contato2Nome = 'Contato 2';
  String _contato2Telefone = '';
  String _instrucoes = '1. Respire fundo 5 vezes\n2. Vá para um local silencioso\n3. Segure meu objeto de conforto\n4. Se persistir, ligue para ajuda';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _contato1Nome = prefs.getString('crise_contato1_nome') ?? 'Contato 1';
      _contato1Telefone = prefs.getString('crise_contato1_telefone') ?? '';
      _contato2Nome = prefs.getString('crise_contato2_nome') ?? 'Contato 2';
      _contato2Telefone = prefs.getString('crise_contato2_telefone') ?? '';
      _instrucoes = prefs.getString('crise_instrucoes') ?? _instrucoes;
    });
  }

  Future<void> _makeAction(String action, String target) async {
    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefone não configurado. Configure nas configurações.')),
      );
      return;
    }

    final uri = Uri.parse('$action:$target');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Não foi possível abrir $action:$target';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  void _editarConfiguracoes() {
    showDialog(
      context: context,
      builder: (context) => _ConfigCriseDialog(
        contato1Nome: _contato1Nome,
        contato1Telefone: _contato1Telefone,
        contato2Nome: _contato2Nome,
        contato2Telefone: _contato2Telefone,
        instrucoes: _instrucoes,
        onSave: (contato1Nome, contato1Telefone, contato2Nome, contato2Telefone, instrucoes) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('crise_contato1_nome', contato1Nome);
          await prefs.setString('crise_contato1_telefone', contato1Telefone);
          await prefs.setString('crise_contato2_nome', contato2Nome);
          await prefs.setString('crise_contato2_telefone', contato2Telefone);
          await prefs.setString('crise_instrucoes', instrucoes);
          setState(() {
            _contato1Nome = contato1Nome;
            _contato1Telefone = contato1Telefone;
            _contato2Nome = contato2Nome;
            _contato2Telefone = contato2Telefone;
            _instrucoes = instrucoes;
          });
        },
      ),
    );
  }

  // Widget para os botões de contato de emergência
  Widget _buildContactButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 30),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
        ),
      ),
    );
  }

  // Widget para a caixa de instruções
  Widget _buildInstructionsBox() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryBlue, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Meu Plano de Ação Rápida:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                onPressed: _editarConfiguracoes,
                tooltip: 'Editar configurações',
              ),
            ],
          ),
          const Divider(color: AppColors.primaryBlue),
          const SizedBox(height: 8),
          Text(
            _instrucoes,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modo Crise", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        iconTheme: const IconThemeData(color: Colors.white), // Ícone de voltar branco
      ),
      backgroundColor: Colors.red.shade50, // Fundo levemente colorido para contraste
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Mensagem de Alerta Principal
            const Center(
              child: Text(
                "ATENÇÃO: Ajuda Imediata",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            _buildInstructionsBox(),

            const Text(
              "Contatos de Emergência Rápidos:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),

            // Contato 1: Responsável/Pessoa de Confiança
            _buildContactButton(
              label: "Ligar para $_contato1Nome",
              icon: Icons.phone_in_talk,
              color: Colors.green.shade600,
              onTap: () => _makeAction('tel', _contato1Telefone),
            ),

            // Contato 2: Terapeuta/Profissional
            _buildContactButton(
              label: "Ligar para $_contato2Nome",
              icon: Icons.support_agent,
              color: Colors.orange.shade600,
              onTap: () => _makeAction('tel', _contato2Telefone),
            ),

            // Contato 3: Emergência Universal
            _buildContactButton(
              label: "Ligar para EMERGÊNCIA (911/190)",
              icon: Icons.local_hospital,
              color: Colors.red.shade700,
              onTap: () => _makeAction('tel', '190'),
            ),

            const SizedBox(height: 20),
            
            // Botão para editar configurações
            TextButton.icon(
              onPressed: _editarConfiguracoes,
              icon: const Icon(Icons.settings),
              label: const Text('Configurar Contatos e Instruções'),
            ),

            const SizedBox(height: 40),

          ],
        ),
      ),
    );
  }
}

// Dialog para configurar contatos e instruções
class _ConfigCriseDialog extends StatefulWidget {
  final String contato1Nome;
  final String contato1Telefone;
  final String contato2Nome;
  final String contato2Telefone;
  final String instrucoes;
  final Function(String, String, String, String, String) onSave;

  const _ConfigCriseDialog({
    required this.contato1Nome,
    required this.contato1Telefone,
    required this.contato2Nome,
    required this.contato2Telefone,
    required this.instrucoes,
    required this.onSave,
  });

  @override
  State<_ConfigCriseDialog> createState() => _ConfigCriseDialogState();
}

class _ConfigCriseDialogState extends State<_ConfigCriseDialog> {
  late TextEditingController _contato1NomeController;
  late TextEditingController _contato1TelefoneController;
  late TextEditingController _contato2NomeController;
  late TextEditingController _contato2TelefoneController;
  late TextEditingController _instrucoesController;

  @override
  void initState() {
    super.initState();
    _contato1NomeController = TextEditingController(text: widget.contato1Nome);
    _contato1TelefoneController = TextEditingController(text: widget.contato1Telefone);
    _contato2NomeController = TextEditingController(text: widget.contato2Nome);
    _contato2TelefoneController = TextEditingController(text: widget.contato2Telefone);
    _instrucoesController = TextEditingController(text: widget.instrucoes);
  }

  @override
  void dispose() {
    _contato1NomeController.dispose();
    _contato1TelefoneController.dispose();
    _contato2NomeController.dispose();
    _contato2TelefoneController.dispose();
    _instrucoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar Modo Crise'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Contato 1:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _contato1NomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _contato1TelefoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const Text('Contato 2:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _contato2NomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _contato2TelefoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const Text('Instruções:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _instrucoesController,
              decoration: const InputDecoration(labelText: 'Instruções de ação rápida'),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              _contato1NomeController.text,
              _contato1TelefoneController.text,
              _contato2NomeController.text,
              _contato2TelefoneController.text,
              _instrucoesController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}