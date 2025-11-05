import 'package:flutter/material.dart';

class TelaAjuda extends StatelessWidget{
  const TelaAjuda({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Suporte ao usuario"),
        backgroundColor: Colors.blueGrey,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Bem vindo ao suporte ao usuario",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                ),
              SizedBox(height: 10),
              Text("Aqui você terá suporte do nosso aplicativo"),
          ],
        ),
      ),
    );
  }
}