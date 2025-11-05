import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trabalhofinal/telaajuda.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spektrum',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Spektrum'),
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

  void _abrirTelaAjuda() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TelaAjuda(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        //COR DA BARRA DE CIMA
        //backgroundColor: Colors.blueGrey,

        title: Text(widget.title),
      ),
      body: Center(
          
        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            
            //LOGO
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Image.asset(
              'assets/logoTudo.png',
            height: 250,
            width: 250,
            ),
            ),

            //TITULO
            /*Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "SPEKTRUM",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            ),*/

            //MARGIN PRA NAO FICAR MUITO JUNTO O NOME DO APP COM O CAMPO
            //const SizedBox(height: 30),

            //CAMPO PRA INFORMAR O USUARIO
            Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Informe o seu usuario",
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
            child: TextField(
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

            //MARGIN ENTRE O CAMPO DA SENHA E O BOTAO
            const SizedBox(height: 40),

            //BOTAO ENTRAR
            Padding( padding: const EdgeInsets.symmetric(horizontal: 70.0),
            child: ElevatedButton(
                onPressed: (){
                  print("Entrou");
                },

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
              onTap: (){
                print('Usuario clicou pra se cadastrar');
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaCadastro()));
              },
              child: RichText(
                text: TextSpan(
                  //SETANDO UM ESTILO BASICO PRA TODO O TEXTO
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    //PRIMEIRA PARTE DO TEXTO (NORMAL)
                    const TextSpan(
                      text: 'Não tem conta? ' ,
                    ),
                    TextSpan(
                      //SEGUNDA PARTE DO TEXTO, ONDE PODE CLICAR
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

            //MARGIN ENTRE O BOTAO E O TEXTO PRA CADASTRAR
            const SizedBox(height: 10),

            //TEXTO DE ESQUECEU A SENHA
            Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GestureDetector(
              onTap: (){
               print('Usuario esqueceu a senha');
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaEsqueceuSenha()));
              },
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
          ],
        ),
      ),

/*
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirTelaAjuda,
        tooltip: 'Ajuda',
        child: const Icon(Icons.help),
      )
      */
    );
  }
}
