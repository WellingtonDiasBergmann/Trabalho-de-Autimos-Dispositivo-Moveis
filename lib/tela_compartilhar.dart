import 'package:flutter/material.dart';
import 'package:trabalhofinal/Services/ApiService.dart';
import 'package:intl/intl.dart';

const Color primaryColor = Color(0xFF1976D2);

class TelaCompartilhar extends StatefulWidget {
  final int userId;

  const TelaCompartilhar({
    super.key,
    required this.userId,
  });

  @override
  State<TelaCompartilhar> createState() => _TelaCompartilharState();
}

class _TelaCompartilharState extends State<TelaCompartilhar> {
  final _emailController = TextEditingController();
  DateTime? _dataExpiracao;
  String _escopo = 'rotinas'; // rotinas, diarios, todos
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _compartilhar() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o e-mail do profissional')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Convite enviado para ${_emailController.text}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Limpa o formulário
      _emailController.clear();
      _dataExpiracao = null;
      setState(() {
        _escopo = 'rotinas';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao compartilhar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartilhar Dados', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Convidar Profissional',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Compartilhe seus dados com um profissional para acompanhamento e relatórios.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            
            // Campo de E-mail
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail do Profissional',
                hintText: 'profissional@exemplo.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            
            // Seletor de Escopo
            const Text(
              'Dados a Compartilhar:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('Apenas Rotinas'),
              value: 'rotinas',
              groupValue: _escopo,
              onChanged: (value) => setState(() => _escopo = value!),
            ),
            RadioListTile<String>(
              title: const Text('Apenas Diários'),
              value: 'diarios',
              groupValue: _escopo,
              onChanged: (value) => setState(() => _escopo = value!),
            ),
            RadioListTile<String>(
              title: const Text('Todos os Dados'),
              value: 'todos',
              groupValue: _escopo,
              onChanged: (value) => setState(() => _escopo = value!),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              title: const Text('Data de Expiração (Opcional)'),
              subtitle: Text(
                _dataExpiracao != null
                    ? DateFormat('dd/MM/yyyy').format(_dataExpiracao!)
                    : 'Sem expiração',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _dataExpiracao = date;
                  });
                }
              },
            ),
            const SizedBox(height: 30),
            
            // Botão de Compartilhar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _compartilhar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Enviar Convite',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Lista de Compartilhamentos Ativos
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Compartilhamentos Ativos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('profissional@exemplo.com'),
                subtitle: Text('Todos os dados • Expira em 30 dias'),
                trailing: Icon(Icons.delete, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

