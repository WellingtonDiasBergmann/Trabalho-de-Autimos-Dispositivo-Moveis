import 'package:flutter/material.dart';
import 'package:trabalhofinal/tela_trocar_senha.dart';

class TelaInformarCodigo extends StatefulWidget {
  const TelaInformarCodigo({super.key});

  @override
  State<TelaInformarCodigo> createState() => _TelaInformarCodigoState();
}

class _TelaInformarCodigoState extends State<TelaInformarCodigo> {
  final TextEditingController _codigoController = TextEditingController();
  final _validaTela = GlobalKey<FormState>();

  @override
  void dispose() {
    // DISPOSE DAS VARIAVEIS PARA NÃO OCUPAR MEMORIA
    _codigoController.dispose();
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

  //FUNÇÃO DE VALIDAÇÕES E FUNÇÃO LOGIN
  void _validaCampos() {
    if(_validaTela.currentState!.validate()) {
      final String emailDigitado = _codigoController.text;
      if (emailDigitado == ""){
        _mostrarBalaoMensagem("Informar email", "Informe o email para recuperar a senha", isError: true);
      }else{
        Navigator.push(context,MaterialPageRoute(builder: (context) => TelaTrocarSenha()),);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmar email"),
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

              //MARGIN ENTRE OS CAMPOS
              const SizedBox(height: 40,),

              //TEXTO INFORMATIVO 1
              Padding( padding: const EdgeInsets.symmetric(),
                child: Center(
                  child: Text(
                    "Digite o código de segurança que foi enviado ao seu e-mail",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              //MARGIN ENTRE OS CAMPOS
              const SizedBox(height: 30,),

              //CAMPO PARA INFORMAR A SENHA
              Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextFormField(
                  controller: _codigoController,
                  validator: (value) {
                    if (value == null || value.isEmpty){
                      return 'Informe o código';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Informe o código",
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

              //MARGIN ENTRE OS CAMPOS
              const SizedBox(height: 30,),

              //BOTAO CONFIRMAR CODIGO
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
                      'Redefinir Senha',
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