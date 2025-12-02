import 'package:flutter/material.dart';
import 'package:trabalhofinal/BancoDados/DataBaseHelper.dart';
import 'package:trabalhofinal/Models/BoardItem.dart';
import 'package:trabalhofinal/Models/Board.dart';
import 'package:trabalhofinal/Widgets/item_form_modal.dart';
import 'package:trabalhofinal/Services/SyncService.dart';
import 'package:trabalhofinal/Services/ApiService.dart';
import 'package:sqflite/sqflite.dart';

// Cores Temáticas
const Color primaryColor = Color(0xFFFFC107);
const Color backgroundColor = Color(0xFFFFF3E0);

class TelaCcaCrianca extends StatefulWidget {
  final void Function(String text) speakAction;
  final int userId;

  const TelaCcaCrianca({
    super.key,
    required this.speakAction,
    required this.userId, 
  });

  @override
  State<TelaCcaCrianca> createState() => _TelaCcaCriancaState();
}

class _TelaCcaCriancaState extends State<TelaCcaCrianca> {
  // Inicialização do serviço de banco de dados
  late final DataBaseHelper _dbService = DataBaseHelper();
  List<BoardItem> _communicationItems = [];
  bool _isLoading = true;

  // ID do board (será obtido dinamicamente)
  int? _boardId;

  @override
  void initState() {
    super.initState();
    debugPrint('TelaCcaCrianca inicializada para userId: ${widget.userId}');
    _initializeBoard();
  }

  /// Inicializa ou cria o board do usuário
  Future<void> _initializeBoard() async {
    try {
      // Tenta buscar boards do usuário
      final db = await _dbService.database;
      final boards = await db.query(
        'boards',
        where: 'user_id = ?',
        whereArgs: [widget.userId],
        limit: 1,
      );

      if (boards.isNotEmpty) {
        _boardId = boards.first['id'] as int;
        debugPrint('Board encontrado: $_boardId');
      } else {
        // Cria um novo board para o usuário
        debugPrint('Criando novo board para usuário ${widget.userId}');
        _boardId = await _createOrGetBoard();
      }

      if (_boardId != null) {
        await _loadItemsFromDb();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao inicializar board: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Cria ou obtém o board do usuário
  Future<int?> _createOrGetBoard() async {
    try {
      final apiService = ApiService();
      
      // Tenta buscar boards do usuário na API
      final boards = await apiService.fetchBoards();
      if (boards.isNotEmpty) {
        final userBoard = boards.firstWhere(
          (b) => b.userId == widget.userId,
          orElse: () => boards.first,
        );
        if (userBoard.id != null) {
          // Salva o board localmente
          final db = await _dbService.database;
          await db.insert('boards', {
            'id': userBoard.id,
            'user_id': userBoard.userId,
            'nome': userBoard.nome,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          debugPrint('Board salvo localmente com ID: ${userBoard.id}');
          
          // Salva os itens do board localmente se houver
          if (userBoard.items != null && userBoard.items!.isNotEmpty) {
            debugPrint('Salvando ${userBoard.items!.length} itens do board localmente');
            for (var item in userBoard.items!) {
              try {
                final itemMap = item.toMap();
                itemMap['board_id'] = userBoard.id;
                final serverId = item.id;
                itemMap.remove('id');
                
                final itemId = await db.insert('board_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);
                debugPrint('Item "${item.texto}" salvo localmente com ID: $itemId');
                
                if (serverId != null) {
                  try {
                    final tableInfo = await db.rawQuery("PRAGMA table_info(board_items)");
                    final hasServerId = tableInfo.any((column) => column['name'] == 'server_id');
                    
                    if (!hasServerId) {
                      debugPrint('Adicionando coluna server_id em board_items');
                      await db.execute('ALTER TABLE board_items ADD COLUMN server_id INTEGER');
                    }
                    
                    await db.update(
                      'board_items',
                      {'server_id': serverId},
                      where: 'id = ?',
                      whereArgs: [itemId],
                    );
                  } catch (e) {
                    debugPrint('Erro ao salvar server_id: $e');
                  }
                }
              } catch (e) {
                debugPrint('Erro ao salvar item "${item.texto}": $e');
              }
            }
          }
          
          return userBoard.id;
        }
      }
      
      // Se não encontrou, cria um novo board na API
      final newBoard = Board(
        id: null,
        userId: widget.userId,
        nome: 'Prancha Principal',
        items: [],
      );
      final createdBoard = await apiService.createBoard(newBoard);
      
      if (createdBoard.id != null) {
        // Salva localmente
        final db = await _dbService.database;
        await db.insert('boards', {
          'id': createdBoard.id,
          'user_id': createdBoard.userId,
          'nome': createdBoard.nome,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return createdBoard.id;
      }
      
      return null;
    } catch (e) {
      debugPrint('Erro ao criar/obter board: $e');
      // Tenta criar um board local como fallback
      try {
        final db = await _dbService.database;
        final boardId = await db.insert('boards', {
          'user_id': widget.userId,
          'nome': 'Prancha Principal',
        });
        debugPrint('Board local criado como fallback com ID: $boardId');
        return boardId;
      } catch (fallbackError) {
        debugPrint('Erro ao criar board local: $fallbackError');
        return null;
      }
    }
  }

  
  Future<void> _loadItemsFromDb() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_boardId == null) {
        debugPrint('_loadItemsFromDb: _boardId é null, não é possível carregar itens');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      debugPrint('_loadItemsFromDb: Carregando itens do board $_boardId');
      final items = await _dbService.getBoardItemsByBoardId(_boardId!);
      debugPrint('_loadItemsFromDb: ${items.length} itens carregados');

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
    if (_boardId == null) {
      debugPrint('_saveOrUpdateItem: _boardId é null, não é possível salvar');
      return;
    }

    try {
      // Garante que o item tem o board_id correto
      final itemToSave = item.copyWith(boardId: _boardId!);
      
      debugPrint('_saveOrUpdateItem: Salvando item "${itemToSave.texto}" no board $_boardId');
      
      // Salva localmente
      int? savedId;
      if (itemToSave.id == null) {
        savedId = await _dbService.insertItem(itemToSave);
        debugPrint('_saveOrUpdateItem: Item inserido com ID local: $savedId');
      } else {
        await _dbService.updateItem(itemToSave);
        savedId = itemToSave.id;
        debugPrint('_saveOrUpdateItem: Item atualizado com ID: $savedId');
      }
      
      // Atualiza o item com o ID salvo para sincronização
      final itemWithId = itemToSave.copyWith(id: savedId);
      
      // Sincroniza com a API após salvar localmente
      try {
        final syncService = SyncService();
        if (itemToSave.id == null) {
          // Novo item - sincroniza imediatamente
          debugPrint('_saveOrUpdateItem: Sincronizando novo item com a API');
          await syncService.syncBoardItem(itemWithId, _boardId!);
        } else {
          // Item existente - atualiza na API
          debugPrint('_saveOrUpdateItem: Atualizando item existente na API');
          await syncService.updateBoardItem(itemWithId);
        }
      } catch (e) {
        debugPrint('_saveOrUpdateItem: Erro ao sincronizar item: $e');
        // Não bloqueia a UI, apenas loga o erro
      }
    } catch (e) {
      debugPrint('_saveOrUpdateItem: Erro ao salvar item: $e');
    }
  }

  void _openItemModal({BoardItem? item}) {
    showDialog(
      context: context,
      builder: (context) => ItemFormModal(
        itemToEdit: item,
        speakAction: widget.speakAction,
        onSave: (newItem) async {
          if (_boardId == null) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro: Board não inicializado')),
            );
            return;
          }

          // Garante o boardId no item
          final itemToSave = newItem.copyWith(boardId: newItem.boardId ?? _boardId!);

          // Salva/Atualiza e depois recarrega a UI
          await _saveOrUpdateItem(itemToSave);

          Navigator.of(context).pop(); // Fecha o modal
          await _loadItemsFromDb();
        },
      ),
    );
  }


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
        onTap: () {
          // Usa fraseTts se disponível, senão usa o texto
          final textToSpeak = (item.fraseTts.isNotEmpty) ? item.fraseTts : item.texto;
          if (textToSpeak.isNotEmpty) {
            widget.speakAction(textToSpeak);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Text(
                    item.imgUrl,
                    style: const TextStyle(fontSize: 80), // Aumentar ainda mais
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
        title: const Text("Comunicação", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _communicationItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.speaker_phone, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    "Nenhum item de comunicação encontrado.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _openItemModal(),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Primeiro Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openItemModal(),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }
}