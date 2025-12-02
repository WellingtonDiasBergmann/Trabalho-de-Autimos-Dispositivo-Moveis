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
const Color accentColor = Color(0xFF4CAF50);
const Color infoColor = Color(0xFF2196F3);
const Color deleteColor = Color(0xFFF44336);

class TelaCcaGrande extends StatefulWidget {
  final void Function(String text) speakAction;
  final int userId;

  const TelaCcaGrande({
    super.key,
    required this.speakAction,
    required this.userId, 
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

  // ID do board (será obtido dinamicamente)
  int? _boardId;

  @override
  void initState() {
    super.initState();
    debugPrint('TelaCcaGrande inicializada para userId: ${widget.userId}');
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
                final serverId = item.id; // Guarda o server_id antes de remover
                itemMap.remove('id'); // Remove o ID do servidor para criar novo ID local
                
                final itemId = await db.insert('board_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);
                debugPrint('Item "${item.texto}" salvo localmente com ID: $itemId');
                
                // Se o item tinha ID do servidor, salva como server_id
                if (serverId != null) {
                  try {
                    // Verifica se a coluna server_id existe, se não, adiciona
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
                    debugPrint('Server ID $serverId associado ao item local $itemId');
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

      // Se não encontrou, cria um novo
      final newBoard = Board(
        userId: widget.userId,
        nome: 'Prancha Principal',
      );
      final createdBoard = await apiService.createBoard(newBoard);
      
      if (createdBoard.id != null) {
        // Salva o board localmente
        final db = await _dbService.database;
        final boardId = await db.insert('boards', {
          'id': createdBoard.id,
          'user_id': createdBoard.userId,
          'nome': createdBoard.nome,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        debugPrint('Novo board criado e salvo localmente com ID: $boardId');
        
        // Salva os itens do board se houver
        if (createdBoard.items != null && createdBoard.items!.isNotEmpty) {
          debugPrint('Salvando ${createdBoard.items!.length} itens do novo board localmente');
          for (var item in createdBoard.items!) {
            try {
              final itemMap = item.toMap();
              itemMap['board_id'] = createdBoard.id;
              itemMap.remove('id');
              final itemId = await db.insert('board_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);
              
              if (item.id != null) {
                await db.update(
                  'board_items',
                  {'server_id': item.id},
                  where: 'id = ?',
                  whereArgs: [itemId],
                );
              }
            } catch (e) {
              debugPrint('Erro ao salvar item do novo board: $e');
            }
          }
        }
        
        return createdBoard.id;
      }
      
      return null;
    } catch (e) {
      debugPrint('Erro ao criar/obter board: $e');
      debugPrint('StackTrace: ${StackTrace.current}');
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
      debugPrint('StackTrace: ${StackTrace.current}');
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
      debugPrint('_saveOrUpdateItem: StackTrace: ${StackTrace.current}');
      rethrow;
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
      await _dbService.deleteItem(id);
      await _loadItemsFromDb(); // Recarrega os itens
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

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }


  Widget _buildCommunicationCard(BoardItem item) {
    final itemId = item.id;

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
            // Usa fraseTts se disponível, senão usa o texto
            final textToSpeak = (item.fraseTts.isNotEmpty) ? item.fraseTts : item.texto;
            debugPrint('Card tocado: "$textToSpeak"');
            if (textToSpeak.isNotEmpty) {
              debugPrint('Chamando speakAction com: "$textToSpeak"');
              widget.speakAction(textToSpeak);
            } else {
              debugPrint('Texto vazio, não é possível falar');
            }
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