import 'package:flutter/material.dart';
import 'package:trabalhofinal/tela_informar_codigo.dart';

class TelaEsqueciSenha extends StatefulWidget {
  const TelaEsqueciSenha({super.key});

  @override
  State<TelaEsqueciSenha> createState() => _TelaEsqueciSenhaState();
}

class _TelaEsqueciSenhaState extends State<TelaEsqueciSenha> {
  final TextEditingController _emailController = TextEditingController();
  final _validaTela = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
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

  //FUNÇÃO DE VALIDAÇÕES E FUNÇÃO LOGIN
  void _validaCampos() {
    if(_validaTela.currentState!.validate()) {
      final String emailDigitado = _emailController.text;
      if (emailDigitado == ""){
        _mostrarBalaoMensagem("Informar email", "Informe o email para recuperar a senha", isError: true);
      }else{
        Navigator.push(context,MaterialPageRoute(builder: (context) => TelaInformarCodigo()),);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Esqueci minha senha"),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Form(
          key: _validaTela,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[

              Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Center(
                  child: Text(
                    "ESQUECI MINHA SENHA",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Padding( padding: const EdgeInsets.symmetric(),
                child: Center(
                  child: Text(
                    "Digite o seu e-mail para enviarmos o código de segurança",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty){
                      return 'Informe o seu email';
                    }
                    return null;
                  },
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

              const SizedBox(height: 30),

              Padding( padding: const EdgeInsets.symmetric(horizontal: 70.0),
                child: ElevatedButton(
                    onPressed:_validaCampos,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),

                    child: const Text(
                      'Enviar código',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                ),
              ),



            ],
          ),
        ),
      ),
    );
  }
}