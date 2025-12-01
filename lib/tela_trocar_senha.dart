import 'dart:convert';

import 'package:trabalhofinal/main.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

class TelaTrocarSenha extends StatefulWidget {
  const TelaTrocarSenha({super.key});

  @override
  State<TelaTrocarSenha> createState() => _TelaTrocarSenhaState();
}

class _TelaTrocarSenhaState extends State<TelaTrocarSenha> {
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarsenhaController = TextEditingController();
  final _validaTela = GlobalKey<FormState>();

  @override
  void dispose() {
    // DISPOSE DAS VARIAVEIS PARA NÃO OCUPAR MEMORIA
    _senhaController.dispose();
    _confirmarsenhaController.dispose();
    super.dispose();
  }

  //TOAST PARA INFORMAR ERRO
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

  //CONVERSAO DA SENHA PARA HASH
  String hashSenhaSHA256(String senhaInserida) {
    final bytes = utf8.encode(senhaInserida);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  //FUNÇÃO DE VALIDAÇÕES E FUNÇÃO LOGIN
  void _validaCampos() {
    if(_validaTela.currentState!.validate()) {
      final String senhaDigitado = _senhaController.text;
      final String senhaConfirmadaDigita = _confirmarsenhaController.text;

      final String hashSenhaDigitada = hashSenhaSHA256(senhaDigitado);

      if (senhaDigitado == senhaConfirmadaDigita){
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Spektrum')),
              (Route<dynamic> route) => false,
        );
      } else{
        _mostrarBalaoMensagem("Falha Cadastro", "Senhas não são iguais, confirá antes de continuar", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova senha"),
        //COR DA BARRA DE CIMA
        //backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Form(
          key: _validaTela,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[

              Padding( padding: const EdgeInsets.symmetric(),
                  child: Center(
                    child: Text(
                      "Redefine sua senha",
                      style: TextStyle(fontSize: 20),
                    ),
                  )
              ),

              //MARGIN ENTRE OS CAMPOS
              const SizedBox(height: 20,),

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
                  decoration: InputDecoration(
                    labelText: "Informe a sua senha",
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
                  obscureText: true,
                ),
              ),

              //MARGIN ENTRE OS DOIS CAMPOS
              const SizedBox(height: 20),

              //CAMPO PRA CONFIRMAR A SENHA
              Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextFormField(
                  controller: _confirmarsenhaController,
                  validator: (value) {
                    if (value == null || value.isEmpty){
                      return 'Confirme a nova senha';
                    }
                    if (value != _senhaController.text) {
                      return 'As senhas não coincidem.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Confirme a sua senha",
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
                  obscureText: true,
                ),
              ),

              //MARGIN ENTRE OS DOIS CAMPOS
              const SizedBox(height: 20),

              //BOTAO TROCAR SENHA
              Padding( padding: const EdgeInsets.symmetric(horizontal: 70.0),
                child: ElevatedButton(
                    onPressed: _validaCampos,

                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),

                    child: const Text(
                      'Confirmar',
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
