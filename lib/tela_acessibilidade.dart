import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaAcessibilidade extends StatefulWidget {
  const TelaAcessibilidade({super.key});

  @override
  State<TelaAcessibilidade> createState() => _TelaAcessibilidadeState();
}

class _TelaAcessibilidadeState extends State<TelaAcessibilidade> {
  bool _altoContraste = false;
  bool _fonteGrande = false;
  bool _reduzirAnimacoes = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _altoContraste = prefs.getBool('acessibilidade_alto_contraste') ?? false;
      _fonteGrande = prefs.getBool('acessibilidade_fonte_grande') ?? false;
      _reduzirAnimacoes = prefs.getBool('acessibilidade_reduzir_animacoes') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acessibilidade_alto_contraste', _altoContraste);
    await prefs.setBool('acessibilidade_fonte_grande', _fonteGrande);
    await prefs.setBool('acessibilidade_reduzir_animacoes', _reduzirAnimacoes);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações de acessibilidade salvas'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acessibilidade', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Configurações de Acessibilidade',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalize o aplicativo para melhorar sua experiência',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          
          // Alto Contraste
          Card(
            child: SwitchListTile(
              title: const Text('Alto Contraste'),
              subtitle: const Text('Aumenta o contraste entre elementos visuais'),
              value: _altoContraste,
              onChanged: (value) {
                setState(() {
                  _altoContraste = value;
                });
                _saveSettings();
              },
              secondary: const Icon(Icons.contrast),
            ),
          ),
          const SizedBox(height: 12),
          
          // Fonte Grande
          Card(
            child: SwitchListTile(
              title: const Text('Fonte Grande'),
              subtitle: const Text('Aumenta o tamanho da fonte em todo o aplicativo'),
              value: _fonteGrande,
              onChanged: (value) {
                setState(() {
                  _fonteGrande = value;
                });
                _saveSettings();
              },
              secondary: const Icon(Icons.text_fields),
            ),
          ),
          const SizedBox(height: 12),
          
          // Reduzir Animações
          Card(
            child: SwitchListTile(
              title: const Text('Reduzir Animações'),
              subtitle: const Text('Diminui ou remove animações para reduzir distrações'),
              value: _reduzirAnimacoes,
              onChanged: (value) {
                setState(() {
                  _reduzirAnimacoes = value;
                });
                _saveSettings();
              },
              secondary: const Icon(Icons.animation),
            ),
          ),
          const SizedBox(height: 24),
          
          // Preview
          Card(
            color: _altoContraste ? Colors.black : Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: _fonteGrande ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: _altoContraste ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este é um exemplo de como o texto aparecerá com suas configurações atuais.',
                    style: TextStyle(
                      fontSize: _fonteGrande ? 18 : 14,
                      color: _altoContraste ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

