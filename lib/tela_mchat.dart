import 'package:flutter/material.dart';
import 'package:trabalhofinal/Models/MChat.dart';
import 'package:trabalhofinal/Services/ApiService.dart';

const Color primaryColor = Color(0xFF1976D2);

class TelaMCHAT extends StatefulWidget {
  final int assessmentId;
  final int userId;

  const TelaMCHAT({
    super.key,
    required this.assessmentId,
    required this.userId,
  });

  @override
  State<TelaMCHAT> createState() => _TelaMCHATState();
}

class _TelaMCHATState extends State<TelaMCHAT> {
  final ApiService _apiService = ApiService();
  Map<String, String> _respostas = {};
  bool _isLoading = true;
  bool _isSaving = false;
  MCHAT? _mchatResult;

  // Perguntas do M-CHAT
  static const List<Map<String, String>> _perguntas = [
    {'num': '1', 'texto': 'A criança gosta de se balançar, de pular no seu joelho, etc.?'},
    {'num': '2', 'texto': 'Tem interesse por outras crianças?'},
    {'num': '3', 'texto': 'Gosta de subir em coisas, como escadas ou móveis?'},
    {'num': '4', 'texto': 'Gosta de brincar de esconder e mostrar o rosto ou esconde-esconde?'},
    {'num': '5', 'texto': 'Já brincou de faz-de-conta, como, por exemplo, fazer de conta que está falando no telefone ou que está cuidando da boneca, ou qualquer outra brincadeira de faz-de-conta?'},
    {'num': '6', 'texto': 'Já usou o dedo indicador para apontar, para pedir alguma coisa?'},
    {'num': '7', 'texto': 'Já usou o dedo indicador para apontar, para indicar interesse em algo?'},
    {'num': '8', 'texto': 'Consegue brincar de forma correta com brinquedos pequenos (ex.: carros ou blocos) sem apenas colocar na boca, remexer no brinquedo ou deixar o brinquedo cair?'},
    {'num': '9', 'texto': 'Alguma vez trouxe objetos para você (pais) para mostrá-los?'},
    {'num': '10', 'texto': 'Olha para você nos olhos por mais de um segundo ou dois?'},
    {'num': '11', 'texto': 'Já pareceu muito sensível ao barulho (ex.: tapando os ouvidos)?'},
    {'num': '12', 'texto': 'Sorri como resposta às suas expressões faciais ou ao seu sorriso?'},
    {'num': '13', 'texto': 'Imita você (ex.: você faz expressões/caretas e ela o imita)?'},
    {'num': '14', 'texto': 'Responde/olha quando você a chama pelo nome?'},
    {'num': '15', 'texto': 'Se você apontar para um brinquedo do outro lado da sala, a criança acompanha com o olhar?'},
    {'num': '16', 'texto': 'Já sabe andar?'},
    {'num': '17', 'texto': 'Olha para coisas que você está olhando?'},
    {'num': '18', 'texto': 'Faz movimentos estranhos perto do rosto dele?'},
    {'num': '19', 'texto': 'Tenta atrair a sua atenção para a atividade dele?'},
    {'num': '20', 'texto': 'Você alguma vez já se perguntou se a sua criança é surda?'},
    {'num': '21', 'texto': 'Entende o que as pessoas dizem?'},
    {'num': '22', 'texto': 'Às vezes fica aérea, "olhando para o nada" ou caminhando sem direção definida?'},
    {'num': '23', 'texto': 'Olha para o seu rosto para conferir a sua reação quando vê algo estranho?'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMCHAT();
  }

  Future<void> _loadMCHAT() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mchat = await _apiService.getMCHAT(widget.assessmentId);
      setState(() {
        _respostas = Map<String, String>.from(mchat.respostas);
        _mchatResult = mchat;
      });
    } catch (e) {
      // Se não existir, inicia vazio
      debugPrint('M-CHAT não encontrado, iniciando novo: $e');
      for (var i = 1; i <= 23; i++) {
        _respostas[i.toString()] = '';
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calcularScore() {
    final score = MCHAT.calcularScore(_respostas);
    final itensCriticos = MCHAT.verificarItensCriticos(_respostas);
    final classificacao = MCHAT.classificarRisco(score, itensCriticos);
    final recomendacao = MCHAT.gerarRecomendacao(classificacao);

    setState(() {
      _mchatResult = MCHAT(
        assessmentId: widget.assessmentId,
        respostas: _respostas,
        scoreTotal: score,
        itensCriticosMarcados: itensCriticos,
        classificacao: classificacao,
        recomendacao: recomendacao,
      );
    });
  }

  Future<void> _salvar() async {
    if (_respostas.values.any((v) => v.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, responda todas as questões')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      _calcularScore();
      await _apiService.saveMCHAT(widget.assessmentId, _respostas);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('M-CHAT salvo com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _perguntas.length,
            itemBuilder: (context, index) {
              final pergunta = _perguntas[index];
              final num = pergunta['num']!;
              final texto = pergunta['texto']!;
              final resposta = _respostas[num] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pergunta['num']}. $texto',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Sim'),
                              value: 'sim',
                              groupValue: resposta,
                              onChanged: (value) {
                                setState(() {
                                  _respostas[num] = value!;
                                });
                                _calcularScore();
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Não'),
                              value: 'nao',
                              groupValue: resposta,
                              onChanged: (value) {
                                setState(() {
                                  _respostas[num] = value!;
                                });
                                _calcularScore();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Resultado do Score
        if (_mchatResult != null)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _mchatResult!.classificacao == 'risco' ? Colors.red.shade50 : Colors.green.shade50,
              border: Border(
                top: BorderSide(
                  color: _mchatResult!.classificacao == 'risco' ? Colors.red : Colors.green,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score Total: ${_mchatResult!.scoreTotal}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _mchatResult!.classificacao == 'risco' ? Colors.red : Colors.green,
                      ),
                    ),
                    Chip(
                      label: Text(
                        _mchatResult!.classificacao == 'risco' ? 'RISCO' : 'SEM RISCO',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: _mchatResult!.classificacao == 'risco' ? Colors.red : Colors.green,
                    ),
                  ],
                ),
                if (_mchatResult!.itensCriticosMarcados.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Itens Críticos: ${_mchatResult!.itensCriticosMarcados.join(", ")}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                if (_mchatResult!.recomendacao != null) ...[
                  const SizedBox(height: 8),
                  Text(_mchatResult!.recomendacao!),
                ],
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Salvar M-CHAT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}

