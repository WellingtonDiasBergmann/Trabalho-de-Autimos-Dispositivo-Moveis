import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:trabalhofinal/Models/Board.dart';
import 'package:trabalhofinal/Models/BoardItem.dart';
import 'package:trabalhofinal/Models/Diario.dart';
import 'package:trabalhofinal/Models/Routine.dart';
import 'package:trabalhofinal/Models/RoutineStep.dart';
import 'package:trabalhofinal/Models/User.dart';

class DataBaseHelper {
  static final DataBaseHelper instance = DataBaseHelper._internal();
  factory DataBaseHelper() => instance;
  DataBaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String documentsPath = await getDatabasesPath();
    String path = join(documentsPath, 'spektrum_app.db');

    return await openDatabase(
      path,
      version: 11, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  void _onCreate(Database db, int version) async {
    // A. PESSOAS
    await db.execute('''
      CREATE TABLE pessoas(
        id INTEGER PRIMARY KEY,
        nome TEXT,
        documento TEXT UNIQUE,
        email TEXT UNIQUE,
        telefone TEXT,
        tipo_usuario INTEGER,
        idade INTEGER, 
        crp TEXT,
        is_crianca INTEGER,
        senha_hash TEXT
      )
    ''');

    // B. ROTINAS
    await db.execute('''
      CREATE TABLE rotinas(
        id INTEGER PRIMARY KEY,
        pessoa_id INTEGER,
        server_id INTEGER, 
        titulo TEXT,
        lembrete TEXT,
        data_criacao TEXT,
        durationInMinutes INTEGER,
        localId TEXT,             
        needsSync INTEGER DEFAULT 1, -- Adicionado para controle local
        FOREIGN KEY (pessoa_id) REFERENCES pessoas(id) ON DELETE CASCADE
      )
    ''');

    // C. PASSOS DE ROTINA
    await db.execute('''
      CREATE TABLE passos_rotina(
        id INTEGER PRIMARY KEY,
        server_id INTEGER,                 
        rotina_id INTEGER, -- FK para rotinas.id (PK LOCAL)
        routine_server_id INTEGER,         
        descricao TEXT,
        duracao_segundos INTEGER,
        icone TEXT,
        ordem INTEGER,
        concluido INTEGER,
        FOREIGN KEY (rotina_id) REFERENCES rotinas(id) ON DELETE CASCADE
      )
    ''');

    // D. DIÁRIOS
    await db.execute('''
      CREATE TABLE diarios(
        id INTEGER PRIMARY KEY,
        pessoa_id INTEGER,
        server_id INTEGER,
        data_registro TEXT,
        humor TEXT,
        sono TEXT,
        alimentacao TEXT,
        crise TEXT,
        observacoes TEXT,
        needsSync INTEGER DEFAULT 1,
        FOREIGN KEY (pessoa_id) REFERENCES pessoas(id) ON DELETE CASCADE
      )
    ''');

    // E. BOARDS
    await db.execute('''
      CREATE TABLE boards(
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        nome TEXT,
        FOREIGN KEY (user_id) REFERENCES pessoas(id) ON DELETE CASCADE
      )
    ''');

    // F. ITENS DO BOARD
    await db.execute('''
      CREATE TABLE board_items(
        id INTEGER PRIMARY KEY,
        board_id INTEGER,
        server_id INTEGER,
        texto TEXT,
        img_url TEXT,
        audio_url TEXT,
        frase_tts TEXT,
        FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE
      )
    ''');


    await db.insert(
      'pessoas',
      {
        'id': 1,
        'nome': 'Sistema Local Padrão',
        'documento': '1',
        'email': 'local_default@app.com',
        'tipo_usuario': 99,
        'is_crianca': 0,
        'senha_hash': ''
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final initialPasswordHash = _hashSenhaSHA256("senha123");
    await db.insert(
      'pessoas',
      {
        'nome': 'Usuário de Teste',
        'documento': '123456789',
        'email': 'teste@email.com',
        'tipo_usuario': 1,
        'is_crianca': 0,
        'senha_hash': initialPasswordHash,
      },
    );

    await db.insert(
      'boards',
      {
        'id': 1,
        'user_id': 1,
        'nome': 'Prancha Principal'
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      debugPrint('MIGRATION: Adicionando is_crianca a pessoas.');
      await db.execute('ALTER TABLE pessoas ADD COLUMN is_crianca INTEGER');
      await db.execute("UPDATE pessoas SET is_crianca = 0 WHERE is_crianca IS NULL");
    }
    if (oldVersion < 5) {
      debugPrint('MIGRATION: Adicionando frase_tts a board_items.');
      await db.execute('ALTER TABLE board_items ADD COLUMN frase_tts TEXT');
    }
    if (oldVersion < 6) {
      debugPrint('MIGRATION: Adicionando senha_hash a pessoas e reinserindo usuário de teste.');
      await db.execute('ALTER TABLE pessoas ADD COLUMN senha_hash TEXT');
      await db.execute("UPDATE pessoas SET senha_hash = '' WHERE id = 1");
      final initialPasswordHash = _hashSenhaSHA256("senha123");
      final existingUser = await db.query('pessoas', where: 'email = ?', whereArgs: ['teste@email.com']);
      if (existingUser.isEmpty) {
        await db.insert(
          'pessoas',
          {
            'nome': 'Usuário de Teste',
            'documento': '123456789',
            'email': 'teste@email.com',
            'tipo_usuario': 1,
            'is_crianca': 0,
            'senha_hash': initialPasswordHash,
          },
        );
      }
    }
    if (oldVersion < 7) {
      debugPrint('MIGRATION: Adicionando server_id, durationInMinutes, localId e needsSync a rotinas.');
      try {
        await db.execute('ALTER TABLE rotinas ADD COLUMN server_id INTEGER');
        await db.execute('ALTER TABLE rotinas ADD COLUMN durationInMinutes INTEGER');
        await db.execute('ALTER TABLE rotinas ADD COLUMN localId TEXT');
        await db.execute('ALTER TABLE rotinas ADD COLUMN needsSync INTEGER DEFAULT 1');
      } catch (e) {
        debugPrint("AVISO DB: Erro ao adicionar colunas em rotinas (podem já existir): $e");
      }
    }

    if (oldVersion < 8) {
      debugPrint('MIGRATION: V8 - Adicionando campos de sincronização a passos_rotina.');
      try {
        await db.execute("ALTER TABLE passos_rotina ADD COLUMN server_id INTEGER;");
        await db.execute("ALTER TABLE passos_rotina ADD COLUMN routine_server_id INTEGER;");
      } catch (e) {
        debugPrint("AVISO DB: Erro ao adicionar colunas em passos_rotina (podem já existir): $e");
      }
    }

    if (oldVersion < 9) {
      debugPrint('MIGRATION: V9 - Verificando e adicionando coluna needsSync se necessário.');
      try {
        final tableInfo = await db.rawQuery("PRAGMA table_info(rotinas)");
        final hasNeedsSync = tableInfo.any((column) => column['name'] == 'needsSync');

        if (!hasNeedsSync) {
          debugPrint('MIGRATION: Adicionando coluna needsSync à tabela rotinas.');
          await db.execute('ALTER TABLE rotinas ADD COLUMN needsSync INTEGER DEFAULT 1');
          await db.execute("UPDATE rotinas SET needsSync = 1 WHERE needsSync IS NULL");
        } else {
          debugPrint('MIGRATION: Coluna needsSync já existe na tabela rotinas.');
        }
      } catch (e) {
        debugPrint("ERRO DB: Falha ao verificar/adicionar coluna needsSync: $e");
        try {
          await db.execute('ALTER TABLE rotinas ADD COLUMN needsSync INTEGER DEFAULT 1');
        } catch (e2) {
          debugPrint("AVISO DB: Coluna needsSync pode já existir: $e2");
        }
      }
    }
    
    if (oldVersion < 11) {
      debugPrint('MIGRATION: V11 - Adicionando colunas de sincronização.');
      try {
        final boardItemsInfo = await db.rawQuery("PRAGMA table_info(board_items)");
        final hasBoardItemsServerId = boardItemsInfo.any((column) => column['name'] == 'server_id');
        
        if (!hasBoardItemsServerId) {
          await db.execute('ALTER TABLE board_items ADD COLUMN server_id INTEGER');
          debugPrint('MIGRATION V11: Coluna server_id adicionada em board_items.');
        }
        
        final diariosInfo = await db.rawQuery("PRAGMA table_info(diarios)");
        final hasDiariosServerId = diariosInfo.any((column) => column['name'] == 'server_id');
        final hasDiariosNeedsSync = diariosInfo.any((column) => column['name'] == 'needsSync');
        
        if (!hasDiariosServerId) {
          await db.execute('ALTER TABLE diarios ADD COLUMN server_id INTEGER');
          debugPrint('MIGRATION V11: Coluna server_id adicionada em diarios.');
        }
        
        if (!hasDiariosNeedsSync) {
          await db.execute('ALTER TABLE diarios ADD COLUMN needsSync INTEGER DEFAULT 1');
          await db.execute("UPDATE diarios SET needsSync = 1 WHERE needsSync IS NULL");
          debugPrint('MIGRATION V11: Coluna needsSync adicionada em diarios.');
        }
      } catch (e) {
        debugPrint('MIGRATION V11 ERROR: $e');
      }
    }
  }

  String _hashSenhaSHA256(String senhaInserida) {
    final bytes = utf8.encode(senhaInserida);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final passwordHash = _hashSenhaSHA256(password);

    final List<Map<String, dynamic>> maps = await db.query(
      'pessoas',
      where: 'email = ? AND senha_hash = ?',
      whereArgs: [email, passwordHash],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<bool> updateUserPassword(String email, String newPassword) async {
    final db = await database;
    final newPasswordHash = _hashSenhaSHA256(newPassword);

    final rowsAffected = await db.update(
      'pessoas',
      {'senha_hash': newPasswordHash},
      where: 'email = ?',
      whereArgs: [email],
    );

    return rowsAffected > 0;
  }

  Future<void> clearAllData() async {
    final db = await database;
    final tableNames = [
      'passos_rotina',
      'rotinas',
      'board_items',
      'boards',
      'diarios',
      'pessoas',
    ];

    await db.transaction((txn) async {
      for (var tableName in tableNames) {
        await txn.delete(tableName);
      }

      // Reinsere dados iniciais essenciais
      await txn.insert(
        'pessoas',
        {
          'id': 1,
          'nome': 'Sistema Local Padrão',
          'documento': '1',
          'email': 'local_default@app.com',
          'tipo_usuario': 99,
          'is_crianca': 0,
          'senha_hash': ''
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final initialPasswordHash = _hashSenhaSHA256("senha123");
      await txn.insert(
        'pessoas',
        {
          'nome': 'Usuário de Teste',
          'documento': '123456789',
          'email': 'teste@email.com',
          'tipo_usuario': 1,
          'is_crianca': 0,
          'senha_hash': initialPasswordHash,
        },
      );

      await txn.insert(
        'boards',
        {
          'id': 1,
          'user_id': 1,
          'nome': 'Prancha Principal'
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> logout() async {
    await clearAllData();
  }


  Map<String, dynamic> _transformStepMapToSql(RoutineStep step) {
    return {
      'id': step.id,
      'rotina_id': step.routineId, 
      'descricao': step.descricao,
      'duracao_segundos': step.duracaoSegundos,
      'icone': null, 
      'ordem': step.ordem,
      'concluido': step.isCompleted ? 1 : 0,
      'server_id': null,
      'routine_server_id': null,
    };
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(
      'pessoas',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    if (user.id == null) return 0;
    return await db.update(
      'pessoas',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pessoas', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('pessoas', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Routine>> getUnsyncedRoutines() async {
    final db = await database;

    try {
      // Verifica se a coluna needsSync existe
      final tableInfo = await db.rawQuery("PRAGMA table_info(rotinas)");
      final hasNeedsSync = tableInfo.any((column) => column['name'] == 'needsSync');

      if (!hasNeedsSync) {
        debugPrint('AVISO: Coluna needsSync não encontrada. Tentando adicionar...');
        try {
          await db.execute('ALTER TABLE rotinas ADD COLUMN needsSync INTEGER DEFAULT 1');
          await db.execute("UPDATE rotinas SET needsSync = 1 WHERE needsSync IS NULL");
          debugPrint('SUCCESS: Coluna needsSync adicionada com sucesso.');
        } catch (e) {
          debugPrint('ERRO: Falha ao adicionar coluna needsSync: $e');
          // Se não conseguir adicionar, retorna lista vazia
          return [];
        }
      }

      // Busca rotinas onde needsSync é 1 (true)
      final rotinasMaps = await db.query(
        'rotinas',
        where: 'needsSync = 1',
      );

      List<Routine> unsynced = [];

      for (var map in rotinasMaps) {
        final rotina = Routine.fromMap(map);

        final localRoutineId = rotina.id;
        if (localRoutineId == null) continue;

        final stepsMaps = await db.query(
          'passos_rotina',
          where: 'rotina_id = ?',
          whereArgs: [localRoutineId], // Usa o ID LOCAL (int) para buscar passos
        );

        final routineWithSteps = rotina.copyWith(
          steps: stepsMaps.map((s) => RoutineStep.fromMap(s)).toList(),
        );
        unsynced.add(routineWithSteps);
      }

      return unsynced;
    } catch (e) {
      debugPrint('ERRO em getUnsyncedRoutines: $e');
      // Se houver erro, retorna lista vazia para não quebrar o fluxo
      return [];
    }
  }

  Future<void> insertRoutineWithSteps(Routine routine) async {
    final db = await database;

    await db.transaction((txn) async {
      try {
        int routineId;

        final routineMap = {
          'id': routine.id, // O id pode ser nulo (insert) ou ter valor (sincronização/update)
          'pessoa_id': routine.pessoaId,
          'titulo': routine.titulo,
          'data_criacao': routine.dataCriacao,
          'lembrete': routine.lembrete,
          'needsSync': 1, 
        };


        final localPk = routine.id;

        if (localPk != null && localPk > 0) {
          await txn.update(
            'rotinas',
            routineMap,
            where: 'id = ?',
            whereArgs: [localPk],
          );
          routineId = localPk;
        } else {
          
          routineMap.remove('id');
          final insertedId = await txn.insert(
            'rotinas',
            routineMap,
          );
          routineId = insertedId;
        }

        await txn.delete('passos_rotina', where: 'rotina_id = ?', whereArgs: [routineId]);

        if (routine.steps != null && routine.steps!.isNotEmpty) {
          for (var step in routine.steps!) {
            final stepMap = _transformStepMapToSql(step);

            final finalMap = Map<String, dynamic>.from(stepMap)
              ..['rotina_id'] = routineId
              ..remove('id'); // Remove o ID do passo para que o DB gere um novo

            await txn.insert('passos_rotina', finalMap);
          }
        }
      } catch (e) {
        debugPrint('Erro no DatabaseHelper durante a transação de rotinas: $e');
        rethrow;
      }
    });
  }

  Future<int> updateRoutine(Routine routine) async {
    final db = await database;

    final updatePk = routine.id; 
    if (updatePk == null) throw Exception('Não é possível atualizar uma Rotina sem um ID LOCAL válido.');

    return await db.transaction((txn) async {
      // 1. Prepara o mapa da rotina
      final routineMap = routine.toMap();
      routineMap.remove('steps');
      routineMap.remove('user_id');
      routineMap.remove('id'); // Remove a PK local do mapa

      final rowsAffected = await txn.update(
          'rotinas',
          routineMap,
          where: 'id = ?',
          whereArgs: [updatePk] 
      );

      await txn.delete('passos_rotina', where: 'rotina_id = ?', whereArgs: [updatePk]);

      if (routine.steps != null && routine.steps!.isNotEmpty) {
        for (var step in routine.steps!) {
          final stepMap = _transformStepMapToSql(step);

          final finalMap = Map<String, dynamic>.from(stepMap)
          // Define a FK usando o ID LOCAL da rotina (int)
            ..['rotina_id'] = updatePk
            ..remove('id'); // Remove o ID do passo para garantir novo insert

          await txn.insert('passos_rotina', finalMap, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      return rowsAffected;
    });
  }

  Future<List<Routine>> getAllRoutines(int pessoaId) async {
    final db = await database;

    final rotinasMaps = await db.query(
      'rotinas',
      where: 'pessoa_id = ?',
      whereArgs: [pessoaId],
    );

    List<Routine> rotinas = [];

    for (var map in rotinasMaps) {
      final rotina = Routine.fromMap(map);

      final routineId = rotina.id;

      if (routineId != null) {
        final stepsMaps = await db.query(
            'passos_rotina',
            where: 'rotina_id = ?',
            whereArgs: [routineId], 
            orderBy: 'ordem ASC'
        );

        rotinas.add(rotina.copyWith(
          steps: stepsMaps.map((s) => RoutineStep.fromMap(s)).toList(),
        ));
      } else {
        debugPrint('AVISO DB: Rotina sem ID local encontrada e ignorada: ${rotina.titulo}');
      }
    }

    return rotinas;
  }

  Future<int> updateRoutineStepStatus(int stepId, bool isCompleted) async {
    final db = await database;
    return await db.update('passos_rotina', {'concluido': isCompleted ? 1 : 0}, where: 'id = ?', whereArgs: [stepId]);
  }

  Future<int> resetRoutineSteps(int routineId) async {
    final db = await database;
    return await db.update('passos_rotina', {'concluido': 0}, where: 'rotina_id = ?', whereArgs: [routineId]);
  }

  Future<int> resetAllRoutinesStepsForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> routineIds = await db.query('rotinas', columns: ['id'], where: 'pessoa_id = ?', whereArgs: [userId]);

    if (routineIds.isEmpty) return 0;
    final ids = routineIds.map((map) => map['id'] as int).toList();
    final idsPlaceholder = List.generate(ids.length, (_) => '?').join(',');

    return await db.update('passos_rotina', {'concluido': 0}, where: 'rotina_id IN ($idsPlaceholder)', whereArgs: ids.cast<Object?>().toList());
  }

  Future<int> deleteRoutine(int id) async {
    final db = await database;
    return await db.delete('rotinas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertOrUpdateDiarioEntry(Diario entry) async {
    final db = await database;
    final map = entry.toMap();
    
    if (!map.containsKey('needsSync')) {
      map['needsSync'] = 1;
    }
    
    if (entry.id != null) {
      final rowsAffected = await db.update('diarios', map, where: 'id = ?', whereArgs: [entry.id]);
      return rowsAffected > 0 ? entry.id! : 0;
    } else {
      final newId = await db.insert('diarios', map, conflictAlgorithm: ConflictAlgorithm.replace);
      return newId;
    }
  }
  
  /// Busca todas as entradas de diário que precisam ser sincronizadas
  Future<List<Diario>> getUnsyncedDiarioEntries() async {
    final db = await database;
    
    try {
      final tableInfo = await db.rawQuery("PRAGMA table_info(diarios)");
      final hasNeedsSync = tableInfo.any((column) => column['name'] == 'needsSync');

      if (!hasNeedsSync) {
        debugPrint('AVISO: Coluna needsSync não encontrada em diarios. Tentando adicionar...');
        try {
          await db.execute('ALTER TABLE diarios ADD COLUMN needsSync INTEGER DEFAULT 1');
          await db.execute("UPDATE diarios SET needsSync = 1 WHERE needsSync IS NULL");
          debugPrint('SUCCESS: Coluna needsSync adicionada em diarios.');
        } catch (e) {
          debugPrint('ERRO: Falha ao adicionar coluna needsSync em diarios: $e');
          return [];
        }
      }

      final diariosMaps = await db.query(
        'diarios',
        where: 'needsSync = 1',
        orderBy: 'data_registro DESC',
      );

      return diariosMaps.map((map) => Diario.fromMap(map)).toList();
    } catch (e) {
      debugPrint('ERRO em getUnsyncedDiarioEntries: $e');
      return [];
    }
  }

  Future<List<Diario>> getDiarioEntriesByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('diarios', where: 'pessoa_id = ?', whereArgs: [userId], orderBy: 'data_registro DESC');
    return maps.map((map) => Diario.fromMap(map)).toList();
  }

  Future<Diario?> getTodayDiarioEntry(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('diarios', where: 'pessoa_id = ?', whereArgs: [userId], orderBy: 'data_registro DESC', limit: 1);
    if (maps.isNotEmpty) return Diario.fromMap(maps.first);
    return null;
  }

  Future<int> deleteDiarioEntry(int id) async {
    final db = await database;
    return await db.delete('diarios', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBoardWithItems(Board board) async {
    final db = await database;
    final boardId = await db.insert('boards', Map<String, dynamic>.from(board.toMap())..remove('id'), conflictAlgorithm: ConflictAlgorithm.replace);

    final batch = db.batch();
    if (board.items != null) {
      for (var item in board.items!) {
        final itemMap = Map<String, dynamic>.from(item.toMap())
          ..['board_id'] = boardId
          ..remove('id');
        batch.insert('board_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
    return boardId;
  }

  Future<int> updateBoard(Board board) async {
    final db = await database;
    if (board.id == null) throw Exception('Não é possível atualizar um Board sem um ID.');

    return await db.transaction((txn) async {
      final rowsAffected = await txn.update('boards', board.toMap(), where: 'id = ?', whereArgs: [board.id]);

      await txn.delete('board_items', where: 'board_id = ?', whereArgs: [board.id]);

      if (board.items != null) {
        for (var item in board.items!) {
          final itemMap = Map<String, dynamic>.from(item.toMap())
            ..['board_id'] = board.id
            ..remove('id');
          await txn.insert('board_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      return rowsAffected;
    });
  }

  Future<int> insertItem(BoardItem item) async {
    final db = await database;
    final itemMap = Map<String, dynamic>.from(item.toMap())..remove('id');
    return await db.insert('board_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateItem(BoardItem item) async {
    final db = await database;
    if (item.id == null) throw Exception('Não é possível atualizar um BoardItem sem um ID.');
    return await db.update('board_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<List<Board>> getAllBoards(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> boardMaps = await db.query('boards', where: 'user_id = ?', whereArgs: [userId]);

    List<Board> boards = [];
    for (var boardMap in boardMaps) {
      final board = Board.fromMap(boardMap);
      final List<Map<String, dynamic>> itemMaps = await db.query('board_items', where: 'board_id = ?', whereArgs: [board.id]);
      List<BoardItem> items = itemMaps.map((map) => BoardItem.fromMap(map)).toList();
      boards.add(board.copyWith(items: items));
    }
    return boards;
  }

  Future<List<BoardItem>> getBoardItemsByBoardId(int boardId) async {
    final db = await database;
    final List<Map<String, dynamic>> itemMaps = await db.query('board_items', where: 'board_id = ?', whereArgs: [boardId]);
    return itemMaps.map((map) => BoardItem.fromMap(map)).toList();
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('board_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBoard(int id) async {
    final db = await database;
    return await db.delete('boards', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getRoutineCompletionStats(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(pr.id) AS total_steps,
        SUM(CASE WHEN pr.concluido = 1 THEN 1 ELSE 0 END) AS completed_steps
      FROM passos_rotina pr
      INNER JOIN rotinas r ON pr.rotina_id = r.id
      WHERE r.pessoa_id = ?
    ''', [userId]);

    if (result.isNotEmpty) {
      final data = result.first;
      final totalSteps = (data['total_steps'] as num?)?.toInt() ?? 0;
      final completedSteps = (data['completed_steps'] as num?)?.toInt() ?? 0;
      return {'total_steps': totalSteps, 'completed_steps': completedSteps};
    }
    return {'total_steps': 0, 'completed_steps': 0};
  }

  Future<Map<String, int>> getDiarioCrisisCounts(int userId, {int days = 30}) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final startDateString = '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')} 00:00:00';

    final result = await db.rawQuery('''
      SELECT
        crise,
        COUNT(id) AS count
      FROM diarios
      WHERE pessoa_id = ? AND data_registro >= ?
      GROUP BY crise
      HAVING crise IS NOT NULL AND crise != ''
    ''', [userId, startDateString]);

    Map<String, int> counts = {};
    for (var row in result) {
      final crisisType = row['crise'] as String;
      final count = (row['count'] as num).toInt();
      counts[crisisType] = count;
    }
    return counts;
  }
}