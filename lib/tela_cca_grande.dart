import 'package:flutter/material.dart';
import 'package:trabalhofinal/BancoDados/DataBaseHelper.dart';
import 'package:trabalhofinal/Models/BoardItem.dart';
import 'package:trabalhofinal/Widgets/item_form_modal.dart';

// Cores Temáticas
const Color primaryColor = Color(0xFFFFC107);
const Color backgroundColor = Color(0xFFFFF3E0);
const Color accentColor = Color(0xFF4CAF50);
const Color infoColor = Color(0xFF2196F3);
const Color deleteColor = Color(0xFFF44336);

class TelaCcaGrande extends StatefulWidget {
  final void Function(String text) speakAction;
  // ⭐️ MUDANÇA 1: Adicionar o userId ao construtor
  final int userId;

  const TelaCcaGrande({
    super.key,
    required this.speakAction,
    required this.userId, // ⭐️ OBRIGATÓRIO
  });

  @override
  State<TelaCcaGrande> createState() => _TelaCcaGrandeState();
}

class _TelaCcaGrandeState extends State<TelaCcaGrande> {
  // Inicialização do serviço de banco de dados
  late final DataBaseHelper _dbService = DataBaseHelper();
  List<BoardItem> _communicationItems = [];
  bool _isEditMode = false;
  bool _isLoading = true;

  // ID FIXO DE TESTE (Altere para usar um Board ID dinâmico, se necessário)
  // Por enquanto, usaremos este ID fixo para a prancha, mas o userId está disponível.
  static const int boardIdTeste = 1;

  @override
  void initState() {
    super.initState();
    debugPrint('TelaCcaGrande inicializada para userId: ${widget.userId}'); // Exibir o ID
    _loadItemsFromDb();
  }

  // -----------------------------------------------------------
  // LÓGICA DE PERSISTÊNCIA (SQL)
  // -----------------------------------------------------------

  Future<void> _loadItemsFromDb() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ⭐️ Chama o método do seu DB Helper para carregar itens
      // FUTURO: Aqui você poderia usar o widget.userId para buscar a prancha
      // principal vinculada a esse usuário.
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

  Future<void> _saveOrUpdateItem(BoardItem item) async {
    // ⭐️ Chamada SQL correta (usando os métodos de Insert/Update do seu Helper)
    if (item.id == null) {
      await _dbService.insertItem(item);
    } else {
      await _dbService.updateItem(item);
    }
  }

  void _deleteItem(int id) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja deletar este item?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: deleteColor),
            child: const Text('Deletar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      // ⭐️ Chamada SQL correta
      await _dbService.deleteItem(id);
      await _loadItemsFromDb(); // Recarrega os itens
    }
  }

  // -----------------------------------------------------------
  // AÇÕES DE UI E MODAL
  // -----------------------------------------------------------

  void _openItemModal({BoardItem? item}) {
    showDialog(
      context: context,
      builder: (context) => ItemFormModal(
        itemToEdit: item,
        speakAction: widget.speakAction,
        onSave: (newItem) async {
          // Garante o boardId no item
          final itemToSave = newItem.copyWith(boardId: newItem.boardId ?? boardIdTeste);

          // Salva/Atualiza e depois recarrega a UI
          await _saveOrUpdateItem(itemToSave);

          Navigator.of(context).pop(); // Fecha o modal
          await _loadItemsFromDb();
        },
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  // -----------------------------------------------------------
  // CONSTRUÇÃO DO CARD (ITEM VISUAL)
  // -----------------------------------------------------------

  Widget _buildCommunicationCard(BoardItem item) {
    final itemId = item.id;

    // ⭐️ MUDANÇA 2: Melhorar o visual do Card.
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: primaryColor, width: 2),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (_isEditMode) {
            _openItemModal(item: item);
          } else {
            widget.speakAction(item.fraseTts); // Ação principal: Falar a frase
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // O emoji/ícone como texto grande
              Expanded(
                child: Center(
                  child: Text(
                    item.imgUrl,
                    style: const TextStyle(fontSize: 60), // Aumentar o tamanho do ícone/emoji
                  ),
                ),
              ),

              // O texto/rótulo
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  item.texto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),

              // Botões de Ação (somente em modo de edição)
              if (_isEditMode && itemId != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_forever, size: 24),
                      color: deleteColor,
                      onPressed: () => _deleteItem(itemId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 24),
                      color: infoColor,
                      onPressed: () => _openItemModal(item: item),
                    ),
                  ],
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
        // ⭐️ MUDANÇA 3: Adicionar o userId ao título para debug
        title: Text("Prancha CAA (Usuário ${widget.userId})", style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.add_box, color: Colors.white),
              onPressed: () => _openItemModal(),
              tooltip: 'Adicionar Novo Cartão',
            ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.done : Icons.edit, color: Colors.white),
            onPressed: _toggleEditMode,
            tooltip: _isEditMode ? 'Sair do Modo de Edição' : 'Entrar no Modo de Edição',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _communicationItems.isEmpty && !_isEditMode
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.speaker_phone, size: 80, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              "Nenhum cartão nesta prancha.",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Text(
              "Clique em 'Editar' (o lápis) para começar.",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(12.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 1.0 / 1.3,
        ),
        itemCount: _communicationItems.length,
        itemBuilder: (context, index) => _buildCommunicationCard(_communicationItems[index]),
      ),
    );
  }
}