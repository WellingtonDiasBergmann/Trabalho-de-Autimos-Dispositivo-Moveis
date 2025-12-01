import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trabalhofinal/BancoDados/DataBaseHelper.dart';
import 'package:trabalhofinal/Models/Routine.dart';
import 'package:trabalhofinal/Models/RoutineStep.dart';
import 'package:trabalhofinal/Models/User.dart';
import 'package:trabalhofinal/Models/BoardItem.dart';
import 'package:trabalhofinal/Models/Diario.dart';
import 'package:trabalhofinal/Services/ApiService.dart';
import 'package:trabalhofinal/Services/ApiConstant.dart';

class SyncService {
  final ApiService _apiService = ApiService();
  final DataBaseHelper _dbHelper = DataBaseHelper.instance;

  // URL base para rotinas
  final String _routinesUrl = '${ApiConstant.baseUrl}/routines';

  // SINGLETON
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // Função de log aprimorada
  void _log(String tag, String msg, [dynamic err]) {
    final ts = DateTime.now().toIso8601String().split('T').last.substring(0, 12);
    print('[$ts] [SYNC] [$tag] $msg');
    if (err != null) print('[$ts] [SYNC ERROR] $err');
  }

  // Helper: Converte resposta da API (snake_case) para formato Flutter (camelCase)
  Future<Routine> _routineFromApiResponse(Map<String, dynamic> apiData) async {
    // A API pode retornar aninhado em 'rotina' ou diretamente
    final routineData = apiData['rotina'] ?? apiData;

    // Converte passos da API (snake_case) para formato Flutter
    List<RoutineStep>? steps;
    final passosData = routineData['passos'] as List<dynamic>?;
    if (passosData != null && passosData.isNotEmpty) {
      steps = passosData.map((passo) {
        return RoutineStep(
          id: passo['id'] as int?,
          routineId: passo['rotina_id'] as int? ?? routineData['id'] as int?,
          descricao: passo['descricao'] as String,
          duracaoSegundos: passo['duracao_segundos'] as int? ?? 0,
          ordem: passo['ordem'] as int,
          isCompleted: (passo['concluido'] as bool?) ?? false,
        );
      }).toList();
    }

    // Converte data_criacao da API para dataCriacao do Flutter
    final dataCriacaoApi = routineData['data_criacao'] as String?;
    String dataCriacao;
    if (dataCriacaoApi != null) {
      // A API retorna ISO format, mantém como string
      dataCriacao = dataCriacaoApi;
    } else {
      dataCriacao = DateTime.now().toIso8601String();
    }

    // Obtém pessoaId da resposta ou do usuário logado como fallback
    int pessoaId;
    if (routineData['pessoa_id'] != null) {
      pessoaId = routineData['pessoa_id'] as int;
    } else {
      // Fallback: busca o primeiro usuário no banco (assumindo que há apenas um usuário logado)
      final db = await _dbHelper.database;
      final users = await db.query('pessoas', limit: 1);
      if (users.isNotEmpty) {
        pessoaId = users.first['id'] as int;
      } else {
        throw Exception('Não foi possível determinar pessoaId para a rotina');
      }
    }

    return Routine(
      id: routineData['id'] as int?,
      pessoaId: pessoaId,
      titulo: routineData['titulo'] as String,
      dataCriacao: dataCriacao,
      lembrete: routineData['lembrete'] as String?,
      steps: steps,
      needsSync: false, // Rotinas vindas da API já estão sincronizadas
    );
  }

  // =====================================================
  // LOGIN E SINCRONIZAÇÃO INICIAL
  // =====================================================
  Future<Map<String, dynamic>> signInAndSync(String email, String password) async {
    try {
      final authResult = await _apiService.login(email, password);

      if (authResult == null || authResult['success'] != true) {
        // Retorna a mensagem de falha da API, se disponível
        return authResult ?? {'success': false, 'message': 'Resposta vazia ou inválida da API.'};
      }

      dynamic rawUserJson = authResult['user'];
      User? user;

      // Lógica de extração de usuário: A API pode aninhar o objeto 'user'
      if (rawUserJson is Map<String, dynamic> && rawUserJson.containsKey('user')) {
        rawUserJson = rawUserJson['user'];
      }

      if (rawUserJson is Map<String, dynamic>) {
        // Certifique-se de que o construtor User.fromJson lida corretamente com a estrutura de dados
        user = User.fromJson(rawUserJson);
      } else {
        _log('LOGIN_FAIL', 'Dados de usuário ausentes ou formato JSON incorreto: ${rawUserJson.runtimeType}');
        return {'success': false, 'message': 'Dados de usuário ausentes ou formato JSON incorreto.'};
      }

      if (user!.id == null) {
        return {'success': false, 'message': 'ID de usuário nulo retornado pela API.'};
      }

      // 1. SALVAR DADOS E INICIAR SINCRONIZAÇÃO COMPLETA
      await _dbHelper.insertUser(user);
      // Passa o token para as requisições subsequentes (assumindo que ApiService cuida disso)
      await syncAllUserData(user.id!);

      return {'success': true, 'user': user, 'message': 'Login e Sincronização realizados com sucesso!'};

    } catch (e) {
      _log('LOGIN_FAIL', 'Erro na autenticação ou sincronização', e);
      return {'success': false, 'message': 'Erro durante a autenticação ou sincronização: $e'};
    }
  }

  // =====================================================
  // SINCRONIZAÇÃO GERAL (PUSH + PULL)
  // =====================================================
  Future<void> syncAll() async {
    _log('SYNC_START', 'Iniciando sincronização...');

    // --- 1. FASE PUSH (Enviar dados locais pendentes) ---
    await _pushUnsyncedRoutines();
    await _pushUnsyncedDiarioEntries();

    // --- 2. FASE PULL (Buscar novos dados do servidor) ---
    await _pullRoutinesFromServer();
    await _pullDiarioEntriesFromServer();

    _log('SYNC_END', 'Sincronização concluída.');
  }

  // =====================================================
  // PUSH: ENVIAR ROTINAS LOCAIS PARA O SERVIDOR (COM CONCORRÊNCIA)
  // =====================================================
  Future<void> _pushUnsyncedRoutines() async {
    // Busca todas as rotinas que estão marcadas com needsSync = true
    // Assumimos que getUnsyncedRoutines retorna a PK local no campo 'id'
    final unsyncedRoutines = await _dbHelper.getUnsyncedRoutines();

    if (unsyncedRoutines.isEmpty) {
      _log('PUSH_SKIP', 'Nenhuma rotina local precisa ser enviada.');
      return;
    }

    _log('PUSH_START', 'Enviando ${unsyncedRoutines.length} rotinas para o servidor em paralelo...');

    // Obtém o token de autenticação do ApiService
    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      _log('PUSH_ERROR', 'Token de autenticação não disponível. Abortando envio.');
      return;
    }

    // Prepara os headers com autenticação
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Cria uma lista de tarefas Future, permitindo o envio em paralelo (concorrência)
    final pushTasks = unsyncedRoutines.map((routine) async {
      try {
        // Busca o server_id do banco de dados para esta rotina
        // Se server_id for NULL, é uma nova rotina (POST), senão é atualização (PUT)
        final db = await _dbHelper.database;
        final localId = routine.id;

        int? serverId;
        bool isNew = true;

        if (localId != null) {
          // Busca o server_id do banco
          final routineData = await db.query(
            'rotinas',
            columns: ['server_id'],
            where: 'id = ?',
            whereArgs: [localId],
            limit: 1,
          );

          if (routineData.isNotEmpty) {
            final serverIdValue = routineData.first['server_id'];
            if (serverIdValue != null) {
              serverId = serverIdValue as int?;
            }
          }

          // Se server_id não for nulo e for positivo, é uma atualização
          isNew = serverId == null;
        }

        final url = isNew
            ? _routinesUrl // POST para nova rotina
            : '$_routinesUrl/$serverId'; // PUT para atualizar rotina existente

        final method = isNew ? 'POST' : 'PUT';
        _log('PUSH_ITEM', 'Rotina "${routine.titulo}" - Método: $method | URL: $url');

        // Prepara o corpo da requisição no formato esperado pela API
        final bodyMap = <String, dynamic>{
          'titulo': routine.titulo,
          'lembrete': routine.lembrete,
        };

        // Converte os steps para o formato da API (passos com snake_case)
        if (routine.steps != null && routine.steps!.isNotEmpty) {
          bodyMap['passos'] = routine.steps!.map((step) {
            return {
              'id': step.id, // Pode ser nulo para novos passos
              'descricao': step.descricao,
              'duracao_segundos': step.duracaoSegundos,
              'icone': null, // A API espera este campo, mesmo que seja null
              'ordem': step.ordem,
              'concluido': step.isCompleted,
            };
          }).toList();
        } else {
          bodyMap['passos'] = [];
        }

        final bodyJson = jsonEncode(bodyMap);

        http.Response response;

        if (isNew) {
          response = await http.post(
            Uri.parse(url),
            body: bodyJson, // Passa a String JSON
            headers: headers,
          );
        } else {
          response = await http.put(
            Uri.parse(url),
            body: bodyJson, // Passa a String JSON
            headers: headers,
          );
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final serverData = jsonDecode(response.body) as Map<String, dynamic>;

          // Converte a resposta da API para o formato Flutter
          final updatedRoutine = await _routineFromApiResponse(serverData);
          final newServerId = updatedRoutine.id; // ID retornado pela API

          // Atualiza o server_id no banco de dados local
          if (localId != null && newServerId != null) {
            final db = await _dbHelper.database;
            await db.update(
              'rotinas',
              {
                'server_id': newServerId,
                'needsSync': 0, // Marca como sincronizada
              },
              where: 'id = ?',
              whereArgs: [localId],
            );

            // Atualiza os passos se necessário
            if (updatedRoutine.steps != null && updatedRoutine.steps!.isNotEmpty) {
              // Remove passos antigos e insere os novos
              await db.delete('passos_rotina', where: 'rotina_id = ?', whereArgs: [localId]);

              for (var step in updatedRoutine.steps!) {
                await db.insert('passos_rotina', {
                  'rotina_id': localId,
                  'server_id': step.id,
                  'descricao': step.descricao,
                  'duracao_segundos': step.duracaoSegundos,
                  'icone': null,
                  'ordem': step.ordem,
                  'concluido': step.isCompleted ? 1 : 0,
                });
              }
            }
          }

          _log('PUSH_SUCCESS', 'Rotina "${routine.titulo}" sincronizada. Server ID: $newServerId');

        } else {
          _log('PUSH_ERROR', 'Falha ao enviar rotina "${routine.titulo}". Status: ${response.statusCode} | Corpo: ${response.body}');
        }
      } catch (e) {
        _log('PUSH_EXCEPTION', 'Exceção ao enviar rotina "${routine.titulo}"', e);
      }
    }).toList();

    // Aguarda a conclusão de todas as tarefas de PUSH em paralelo
    await Future.wait(pushTasks);
  }

  // =====================================================
  // PULL: BUSCAR ROTINAS DO SERVIDOR
  // =====================================================
  Future<void> _pullRoutinesFromServer() async {
    _log('PULL_START', 'Buscando rotinas no servidor...');

    try {
      // Obtém o token de autenticação do ApiService
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        _log('PULL_ERROR', 'Token de autenticação não disponível. Abortando busca.');
        return;
      }

      // Prepara os headers com autenticação
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Faz a requisição diretamente para ter controle sobre a conversão
      final response = await http.get(
        Uri.parse(_routinesUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        int routinesPulled = 0;

        for (final routineJson in jsonList) {
          if (routineJson is Map<String, dynamic>) {
            try {
              // Converte da API (snake_case) para formato Flutter
              final routine = await _routineFromApiResponse(routineJson);
              final serverId = routine.id; // ID do servidor

              if (serverId == null) {
                _log('PULL_WARN', 'Rotina sem ID do servidor, ignorando...');
                continue;
              }

              // Verifica se já existe uma rotina local com este server_id
              final db = await _dbHelper.database;
              final existingRoutine = await db.query(
                'rotinas',
                columns: ['id'],
                where: 'server_id = ?',
                whereArgs: [serverId],
                limit: 1,
              );

              int? localId;
              if (existingRoutine.isNotEmpty) {
                // Rotina já existe localmente, usa o ID local para atualizar
                localId = existingRoutine.first['id'] as int;
              } else {
                // Nova rotina, será criada com novo ID local
                localId = null;
              }

              // Salva a rotina no banco usando transação para garantir consistência
              int finalLocalId;
              await db.transaction((txn) async {
                if (localId != null) {
                  // UPDATE: Rotina já existe localmente
                  finalLocalId = localId;

                  // Atualiza a rotina
                  await txn.update(
                    'rotinas',
                    {
                      'pessoa_id': routine.pessoaId,
                      'titulo': routine.titulo,
                      'data_criacao': routine.dataCriacao,
                      'lembrete': routine.lembrete,
                      'server_id': serverId,
                      'needsSync': 0,
                    },
                    where: 'id = ?',
                    whereArgs: [localId],
                  );
                } else {
                  // INSERT: Nova rotina
                  final insertedId = await txn.insert(
                    'rotinas',
                    {
                      'pessoa_id': routine.pessoaId,
                      'titulo': routine.titulo,
                      'data_criacao': routine.dataCriacao,
                      'lembrete': routine.lembrete,
                      'server_id': serverId,
                      'needsSync': 0,
                    },
                  );
                  finalLocalId = insertedId;
                }

                // Remove passos antigos
                await txn.delete('passos_rotina', where: 'rotina_id = ?', whereArgs: [finalLocalId]);

                // Insere novos passos
                if (routine.steps != null && routine.steps!.isNotEmpty) {
                  for (var step in routine.steps!) {
                    await txn.insert('passos_rotina', {
                      'rotina_id': finalLocalId,
                      'server_id': step.id,
                      'descricao': step.descricao,
                      'duracao_segundos': step.duracaoSegundos,
                      'icone': null,
                      'ordem': step.ordem,
                      'concluido': step.isCompleted ? 1 : 0,
                    });
                  }
                }
              });

              routinesPulled++;
            } catch (e) {
              _log('PULL_WARN', 'Erro ao processar rotina: $e');
            }
          } else {
            _log('PULL_WARN', 'Item de rotina em formato inesperado: ${routineJson.runtimeType}');
          }
        }

        _log('PULL_SUCCESS', 'Rotinas sincronizadas do servidor com sucesso: $routinesPulled');

      } else {
        _log('PULL_ERROR', 'Falha ao buscar rotinas. Status: ${response.statusCode}', response.body);
      }

    } catch (e) {
      _log('PULL_EXCEPTION', 'Exceção ao puxar rotinas', e);
    }
  }

  // =====================================================
  // CRIAÇÃO E ENVIO DE ROTINA (Função de suporte do ApiService)
  // =====================================================
  Future<Map<String, dynamic>> sendRoutineToServer(Routine routine) async {
    try {
      // O ApiService.createRoutine deve receber uma Routine e retornar a Routine criada
      final createdRoutine = await _apiService.createRoutine(routine);

      // Retornamos o objeto sincronizado
      return {'success': true, 'rotina': createdRoutine.toMap()};
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  // =====================================================
  // FUNÇÃO DE CRIAÇÃO: ADICIONAR NOVA ROTINA
  // =====================================================
  Future<Map<String, dynamic>> addRotina(Routine r) async {
    // 1. Salva localmente, marcando-a para sincronização
    final localRoutine = r.copyWith(needsSync: true);
    await _dbHelper.insertRoutineWithSteps(localRoutine);

    // 2. Tenta enviar a rotina para a API.
    try {
      // Usa a função de criação da ApiService, que deve retornar a rotina com o ServerId
      final createdRoutine = await _apiService.createRoutine(localRoutine);

      // 3. Se o envio for bem-sucedido, atualiza o status de sincronização no banco de dados local.
      final updatedRoutine = createdRoutine.copyWith(needsSync: false);

      // O DBHelper usa o ID local para encontrar o item local e atualizar o serverId e needsSync
      await _dbHelper.updateRoutine(updatedRoutine);

      return {'success': true, 'rotina': updatedRoutine.toMap()};

    } on Exception catch (e) {
      // Se falhar, a rotina já está no DB marcada como needsSync: true,
      // e será enviada na próxima sincronização (syncAll).
      _log('ADD_ROUTINE_FAIL', 'Falha ao adicionar rotina, será sincronizada mais tarde', e);
      return {'success': false, 'message': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  // =====================================================
  // FUNÇÃO DE ATUALIZAÇÃO: ATUALIZAR ROTINA
  // =====================================================
  Future<Map<String, dynamic>> updateRotina(Routine r) async {
    // 1. Marca para sincronização e salva localmente.
    final localRoutine = r.copyWith(needsSync: true);
    await _dbHelper.updateRoutine(localRoutine);

    // 2. Tenta enviar para a API
    try {
      // Usa a função de atualização da ApiService

      // VERIFICAÇÃO CRÍTICA: O ID não pode ser nulo para uma atualização.
      if (localRoutine.id == null) {
        throw Exception('ID da rotina não pode ser nulo para PUT/UPDATE.');
      }

      // CORREÇÃO: Passa o ID da rotina como primeiro argumento
      final updatedRoutine = await _apiService.updateRoutine(localRoutine.id!, localRoutine);

      // 3. Se o envio for bem-sucedido, atualiza o status de sincronização no banco de dados local.
      final finalRoutine = updatedRoutine.copyWith(needsSync: false);
      await _dbHelper.updateRoutine(finalRoutine);

      return {'success': true, 'rotina': finalRoutine.toMap()};

    } on Exception catch (e) {
      // Se falhar, a rotina já está no DB marcada como needsSync: true.
      _log('UPDATE_ROUTINE_FAIL', 'Falha ao atualizar rotina, será sincronizada mais tarde', e);
      return {'success': false, 'message': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  // =====================================================
  // SINCRONIZAÇÃO DE TODOS OS DADOS DO USUÁRIO
  // =====================================================
  Future<void> syncAllUserData(int userId) async {
    _log('SYNC_USER_DATA', 'Iniciando sincronização de dados do usuário $userId...');

    // A chamada a syncAll() já faz o PUSH e PULL de Rotinas
    await syncAll();

    _log('SYNC_USER_DATA', 'Sincronização de dados do usuário concluída.');
  }

  // =====================================================
  // REGISTRO DE USUÁRIO (SIGNUP)
  // =====================================================
  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData, String password) async {
    try {
      final response = await _apiService.signup(userData, password);

      if (response['success'] == true) {
        final rawUser = response['user'];
        User? newUser;

        // Lógica de extração do objeto User
        if (rawUser is Map<String, dynamic>) {
          newUser = User.fromJson(rawUser);
        } else if (rawUser is Map<String, dynamic> && rawUser.containsKey('user')) {
          newUser = User.fromJson(rawUser['user']);
        } else {
          return {'success': false, 'message': 'Formato de usuário incorreto retornado após o registro.'};
        }

        if (newUser!.id == null) {
          return {'success': false, 'message': 'ID de usuário nulo após o registro.'};
        }

        // 1. Salva o novo usuário localmente
        await _dbHelper.insertUser(newUser);

        // 2. Inicia a sincronização (principalmente PULL inicial)
        await syncAllUserData(newUser.id!);

        return {'success': true, 'message': 'Usuário cadastrado com sucesso!', 'user': newUser};
      }
      return {'success': false, 'message': response['message'] ?? 'Falha ao registrar usuário.'};

    } catch (e) {
      _log('SIGNUP_FAIL', 'Erro no SyncService.signup', e);
      return {'success': false, 'message': 'Erro no SyncService.signup: $e'};
    }
  }

  // =====================================================
  // BOARD ITEMS SYNC
  // =====================================================

  /// Sincroniza um BoardItem com a API (cria novo)
  Future<BoardItem?> syncBoardItem(BoardItem item, int boardId) async {
    try {
      // Usa o ApiService para fazer a requisição (ele já gerencia o token)
      final apiItem = await _apiService.createBoardItem(boardId, item);
      
      // Atualiza o item local com o server_id
      if (item.id != null && apiItem.id != null) {
        final db = await _dbHelper.database;
        await db.update(
          'board_items',
          {'server_id': apiItem.id},
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
      
      _log('BOARD_ITEM_SYNC', 'Item sincronizado: ${item.texto}');
      return apiItem;
    } catch (e) {
      _log('BOARD_ITEM_SYNC', 'Erro ao sincronizar item', e);
      return null;
    }
  }

  /// Atualiza um BoardItem na API
  Future<bool> updateBoardItem(BoardItem item) async {
    try {
      if (item.id == null) {
        _log('BOARD_ITEM_UPDATE', 'Item sem ID, não é possível atualizar');
        return false;
      }

      // Busca o server_id do item
      final db = await _dbHelper.database;
      final itemData = await db.query(
        'board_items',
        columns: ['server_id'],
        where: 'id = ?',
        whereArgs: [item.id],
        limit: 1,
      );

      if (itemData.isEmpty || itemData.first['server_id'] == null) {
        _log('BOARD_ITEM_UPDATE', 'Item sem server_id, sincronizando como novo');
        return await syncBoardItem(item, item.boardId) != null;
      }

      final serverId = itemData.first['server_id'] as int;
      
      // Usa o ApiService para atualizar (ele já gerencia o token)
      await _apiService.updateBoardItem(serverId, item);
      
      _log('BOARD_ITEM_UPDATE', 'Item atualizado: ${item.texto}');
      return true;
    } catch (e) {
      _log('BOARD_ITEM_UPDATE', 'Erro ao atualizar item', e);
      return false;
    }
  }

  // =====================================================
  // DIÁRIO SYNC
  // =====================================================

  /// Sincroniza uma entrada de diário com a API (cria novo)
  Future<Diario?> syncDiarioEntry(Diario entry) async {
    try {
      // Remove o ID local antes de enviar para a API
      final entryToSend = entry.copyWith(id: null);
      
      // Usa o ApiService para fazer a requisição (ele já gerencia o token)
      final apiEntry = await _apiService.createEntry(entryToSend);
      
      // Atualiza o item local com o server_id
      if (entry.id != null && apiEntry.id != null) {
        final db = await _dbHelper.database;
        await db.update(
          'diarios',
          {
            'server_id': apiEntry.id,
            'needsSync': 0, // Marca como sincronizada
          },
          where: 'id = ?',
          whereArgs: [entry.id],
        );
      }
      
      _log('DIARIO_SYNC', 'Entrada sincronizada: ${entry.dataRegistro}');
      return apiEntry;
    } catch (e) {
      _log('DIARIO_SYNC', 'Erro ao sincronizar entrada', e);
      return null;
    }
  }

  /// Atualiza uma entrada de diário na API
  Future<bool> updateDiarioEntry(Diario entry) async {
    try {
      if (entry.id == null) {
        _log('DIARIO_UPDATE', 'Entrada sem ID, não é possível atualizar');
        return false;
      }

      // Busca o server_id do item
      final db = await _dbHelper.database;
      final entryData = await db.query(
        'diarios',
        columns: ['server_id'],
        where: 'id = ?',
        whereArgs: [entry.id],
        limit: 1,
      );

      if (entryData.isEmpty || entryData.first['server_id'] == null) {
        _log('DIARIO_UPDATE', 'Entrada sem server_id, sincronizando como novo');
        return await syncDiarioEntry(entry) != null;
      }

      final serverId = entryData.first['server_id'] as int;
      
      // Usa o ApiService para atualizar (ele já gerencia o token)
      await _apiService.updateEntry(serverId, entry);
      
      // Marca como sincronizada
      await db.update(
        'diarios',
        {'needsSync': 0},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      
      _log('DIARIO_UPDATE', 'Entrada atualizada: ${entry.dataRegistro}');
      return true;
    } catch (e) {
      _log('DIARIO_UPDATE', 'Erro ao atualizar entrada', e);
      return false;
    }
  }

  // =====================================================
  // PUSH: ENVIAR ENTRIES DE DIÁRIO LOCAIS PARA O SERVIDOR
  // =====================================================
  Future<void> _pushUnsyncedDiarioEntries() async {
    try {
      final unsyncedEntries = await _dbHelper.getUnsyncedDiarioEntries();
      
      if (unsyncedEntries.isEmpty) {
        _log('PUSH_SKIP', 'Nenhuma entrada de diário local precisa ser enviada.');
        return;
      }

      _log('PUSH_START', 'Enviando ${unsyncedEntries.length} entradas de diário para o servidor...');

      for (final entry in unsyncedEntries) {
        try {
          // Verifica se já tem server_id (já foi criado no servidor, precisa atualizar)
          final db = await _dbHelper.database;
          final entryData = await db.query(
            'diarios',
            columns: ['server_id'],
            where: 'id = ?',
            whereArgs: [entry.id],
            limit: 1,
          );

          if (entryData.isNotEmpty && entryData.first['server_id'] != null) {
            // Já existe no servidor, atualiza
            await updateDiarioEntry(entry);
          } else {
            // Nova entrada, cria
            await syncDiarioEntry(entry);
          }
        } catch (e) {
          _log('PUSH_ERROR', 'Falha ao enviar entrada de diário: ${entry.dataRegistro}', e);
        }
      }

      _log('PUSH_SUCCESS', 'Entradas de diário enviadas com sucesso.');
    } catch (e) {
      _log('PUSH_ERROR', 'Erro ao enviar entradas de diário', e);
    }
  }

  // =====================================================
  // PULL: BUSCAR ENTRIES DE DIÁRIO DO SERVIDOR
  // =====================================================
  Future<void> _pullDiarioEntriesFromServer() async {
    _log('PULL_START', 'Buscando entradas de diário no servidor...');
    try {
      final apiEntries = await _apiService.fetchEntries();
      int entriesPulled = 0;
      
      for (final apiEntry in apiEntries) {
        try {
          final db = await _dbHelper.database;
          
          // Verifica se já existe uma entrada local com este server_id
          final existingEntry = await db.query(
            'diarios',
            columns: ['id'],
            where: 'server_id = ?',
            whereArgs: [apiEntry.id],
            limit: 1,
          );

          if (existingEntry.isNotEmpty) {
            // UPDATE: Entrada já existe localmente
            final localId = existingEntry.first['id'] as int;
            final entryToUpdate = apiEntry.copyWith(id: localId);
            final mapToUpdate = entryToUpdate.toMap();
            mapToUpdate['server_id'] = apiEntry.id; // Preserva server_id
            mapToUpdate['needsSync'] = 0; // Marca como sincronizada
            await db.update(
              'diarios',
              mapToUpdate,
              where: 'id = ?',
              whereArgs: [localId],
            );
          } else {
            // INSERT: Nova entrada
            final entryToInsert = apiEntry.copyWith(id: null); // Remove ID local para inserir novo
            final mapToInsert = entryToInsert.toMap();
            mapToInsert['server_id'] = apiEntry.id; // Salva server_id
            mapToInsert['needsSync'] = 0; // Marca como sincronizada
            await db.insert('diarios', mapToInsert);
          }
          
          entriesPulled++;
        } catch (e) {
          _log('PULL_WARN', 'Erro ao processar entrada de diário: $e');
        }
      }
      
      _log('PULL_SUCCESS', 'Entradas de diário sincronizadas do servidor com sucesso: $entriesPulled');
    } catch (e) {
      _log('PULL_ERROR', 'Erro ao buscar entradas de diário do servidor', e);
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  Future<void> sair() async {
    try {
      // Tenta fazer um PUSH final para não perder dados locais não sincronizados
      await _pushUnsyncedRoutines();
      await _pushUnsyncedDiarioEntries();

      // Limpa dados locais e faz logout na API
      await _dbHelper.clearAllData();
      await _apiService.logout();
    } catch (e) {
      _log('LOGOUT_FAIL', 'Erro durante o processo de logout/limpeza', e);
    }
  }
}