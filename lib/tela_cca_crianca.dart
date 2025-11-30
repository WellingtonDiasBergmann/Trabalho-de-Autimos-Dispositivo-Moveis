import 'package:flutter/material.dart';
import 'package:trabalhofinal/BancoDados/DataBaseHelper.dart';
import 'package:trabalhofinal/Models/BoardItem.dart';

// Cores Temáticas
const Color primaryColor = Color(0xFFFFC107);
const Color backgroundColor = Color(0xFFFFF3E0);

class TelaCcaCrianca extends StatefulWidget {
  final void Function(String text) speakAction;
  // ⭐️ MUDANÇA 1: Adicionar o userId ao construtor
  final int userId;

  const TelaCcaCrianca({
    super.key,
    required this.speakAction,
    required this.userId, // ⭐️ OBRIGATÓRIO
  });

  @override
  State<TelaCcaCrianca> createState() => _TelaCcaCriancaState();
}

class _TelaCcaCriancaState extends State<TelaCcaCrianca> {
  // Inicialização do serviço de banco de dados
  late final DataBaseHelper _dbService = DataBaseHelper();
  List<BoardItem> _communicationItems = [];
  bool _isLoading = true;

  // ID FIXO DE TESTE (Deve ser o mesmo da tela Grande)
  static const int boardIdTeste = 1;

  @override
  void initState() {
    super.initState();
    debugPrint('TelaCcaCrianca inicializada para userId: ${widget.userId}'); // Exibir o ID
    _loadItemsFromDb();
  }

  // -----------------------------------------------------------
  // LÓGICA DE PERSISTÊNCIA (SQL) - SOMENTE LEITURA
  // -----------------------------------------------------------

  Future<void> _loadItemsFromDb() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ⭐️ FUTURO: Usar widget.userId para determinar qual board carregar.
      final items = await _dbService.getBoardItemsByBoardId(boardIdTeste);
      setState(() {
        _communicationItems = items;
      });
    } catch (e) {
      debugPrint('Erro ao carregar itens do DB: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // -----------------------------------------------------------
  // CONSTRUÇÃO DO CARD (ITEM VISUAL SIMPLIFICADO)
  // -----------------------------------------------------------

  Widget _buildKidCard(BoardItem item) {
    return Card(
      elevation: 6,
      // Usando uma cor de fundo clara para maior contraste
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Borda mais arredondada
        side: const BorderSide(color: primaryColor, width: 3), // Borda temática
      ),
      child: InkWell(
        onTap: () => widget.speakAction(item.fraseTts), // Apenas FALA
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // ÍCONE GRANDE
              Expanded(
                child: Center(
                  child: Text(
                    item.imgUrl,
                    style: const TextStyle(fontSize: 80), // Aumentar ainda mais
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // PALAVRA GRANDE
              Text(
                item.texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28, // Fonte bem maior
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        // ⭐️ MUDANÇA 2: Adicionar o userId ao título para debug
        title: Text("Comunicação (Usuário ${widget.userId})", style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        // SEM BOTÕES DE EDIÇÃO
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _communicationItems.isEmpty
          ? const Center(child: Text("Nenhum item de comunicação encontrado."))
          : GridView.builder(
        padding: const EdgeInsets.all(20.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Layout mais espaçado para criança (2 colunas)
          crossAxisSpacing: 20.0,
          mainAxisSpacing: 20.0,
          childAspectRatio: 1.0,
        ),
        itemCount: _communicationItems.length,
        itemBuilder: (context, index) => _buildKidCard(_communicationItems[index]),
      ),
    );
  }
}