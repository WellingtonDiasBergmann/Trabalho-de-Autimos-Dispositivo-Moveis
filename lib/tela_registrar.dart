import 'package:flutter/material.dart';
import 'package:trabalhofinal/Services/SyncService.dart';
import 'package:trabalhofinal/main.dart';

class TipoUsuario {
  final int id;
  final String nome;

  TipoUsuario(this.id, this.nome);
}

class TelaRegistrar extends StatefulWidget {
  const TelaRegistrar({super.key});

  @override
  State<TelaRegistrar> createState() => _TelaRegistrarState();
}

class _TelaRegistrarState extends State<TelaRegistrar> {
  final _validaRegistro = GlobalKey<FormState>();

  // Controllers para os campos de texto
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmasenhaController = TextEditingController();

  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _crpController = TextEditingController();

  final List<TipoUsuario> _tiposUsuario = [
    TipoUsuario(0, 'Autista (Usuário Principal)'),
    TipoUsuario(1, 'Responsável/Familiar'),
    TipoUsuario(2, 'Profissional (Psicólogo/Terapeuta)')
  ];

  TipoUsuario? _tipoSelecionado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = _tiposUsuario.first;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmasenhaController.dispose();
    _idadeController.dispose();
    _crpController.dispose();
    super.dispose();
  }

  void _mostrarBalaoMensagem(String titulo, String mensagem, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : Colors.green),
            const SizedBox(width: 10),
            Text(titulo),
          ],
        ),
        content: Text(mensagem),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // CHAMADA API  - CORRIGIDO!!!
  // ------------------------------
  Future<void> _validaCamposEChamaAPI() async {
    if (_validaRegistro.currentState!.validate()) {
      if (_senhaController.text != _confirmasenhaController.text) {
        _mostrarBalaoMensagem("Falha Cadastro",
            "As senhas não coincidem. Confirme antes de continuar.",
            isError: true);
        return;
      }

      setState(() => _isLoading = true);

      Map<String, dynamic> data = {
        'nome': _nomeController.text,
        'documento': _documentoController.text,
        'email': _emailController.text,
        'telefone': _telefoneController.text,
        'senha': _senhaController.text,
        'tipo_usuario': _tipoSelecionado!.id,
      };

      if (_tipoSelecionado!.id == 0) {
        data['idade'] = _idadeController.text;
      } else if (_tipoSelecionado!.id == 2) {
        data['crp'] = _crpController.text;
      }

      try {
        final response = await SyncService().signup(data, _senhaController.text);

        if (response['success'] == true) {
          _mostrarBalaoMensagem("Sucesso!", "Usuário cadastrado com sucesso!");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MyHomePage(title: 'Spektrum')),
          );
        } else {
          _mostrarBalaoMensagem("Falha Cadastro",
              response['message'] ?? "Erro desconhecido ao cadastrar.",
              isError: true);
        }
      } catch (e) {
        _mostrarBalaoMensagem("Erro",
            "Falha ao conectar ao servidor. Erro: $e",
            isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }  // 👉 AGORA FECHOU CERTINHO!

  // ------------------------------
  // WIDGET PARA CAMPOS DE TEXTO
  // ------------------------------
  Widget _buildTextFormField(
      TextEditingController controller,
      String label, {
        TextInputType keyboardType = TextInputType.text,
        bool isObscure = false,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isObscure,
      validator: validator ??
              (value) => (value == null || value.isEmpty) ? 'Este campo é obrigatório.' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar-se")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _validaRegistro,
          child: Column(
            children: [
              Image.asset('assets/logoTudo.png', height: 120),

              const SizedBox(height: 20),
              _buildTextFormField(_nomeController, "Nome completo"),

              const SizedBox(height: 20),
              _buildTextFormField(_documentoController, "Documento"),

              const SizedBox(height: 20),
              _buildTextFormField(_emailController, "E-mail",
                  keyboardType: TextInputType.emailAddress),

              const SizedBox(height: 20),
              _buildTextFormField(_telefoneController, "Telefone",
                  keyboardType: TextInputType.phone),

              const SizedBox(height: 20),
              DropdownButtonFormField<TipoUsuario>(
                value: _tipoSelecionado,
                items: _tiposUsuario.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.nome))).toList(),
                onChanged: (value) => setState(() => _tipoSelecionado = value),
                decoration: InputDecoration(
                  labelText: "Tipo de Usuário",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),

              if (_tipoSelecionado?.id == 0) ...[
                const SizedBox(height: 20),
                _buildTextFormField(_idadeController, "Idade",
                    keyboardType: TextInputType.number),
              ],

              if (_tipoSelecionado?.id == 2) ...[
                const SizedBox(height: 20),
                _buildTextFormField(_crpController, "CRP"),
              ],

              const SizedBox(height: 20),
              _buildTextFormField(_senhaController, "Senha", isObscure: true),

              const SizedBox(height: 20),
              _buildTextFormField(_confirmasenhaController, "Confirmar senha",
                  isObscure: true),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _validaCamposEChamaAPI,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Registrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
