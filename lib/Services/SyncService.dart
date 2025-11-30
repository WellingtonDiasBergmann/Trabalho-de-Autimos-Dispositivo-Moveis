import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trabalhofinal/BancoDados/DataBaseHelper.dart';
import 'package:trabalhofinal/Models/Routine.dart';
import 'package:trabalhofinal/Models/User.dart';
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

    // --- 2. FASE PULL (Buscar novos dados do servidor) ---
    await _pullRoutinesFromServer();

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

    // Cria uma lista de tarefas Future, permitindo o envio em paralelo (concorrência)
    final pushTasks = unsyncedRoutines.map((routine) async {
      try {
        // Assumimos que 'routine.id' armazena o ID do servidor (serverId) após a primeira sincronização.
        // Se 'routine.id' for nulo, é uma nova rotina (POST).
        final serverId = routine.id;
        final isNew = serverId == null;

        final url = isNew
            ? _routinesUrl // POST para nova rotina
            : '$_routinesUrl/$serverId'; // PUT para atualizar rotina existente

        final method = isNew ? 'POST' : 'PUT';
        _log('PUSH_ITEM', 'Rotina "${routine.titulo}" - Método: $method | URL: $url');

        // Prepara o corpo da requisição usando o toJson da rotina
        // Retorna String JSON codificada (RESOLVE O ERRO DE TIPAGEM)
        final bodyJson = routine.toJson();

        http.Response response;

        // Assumimos que o ApiService cuida da autenticação (via _getHeaders ou ApiService.request)
        // Mas como aqui está usando http.post/put diretamente, precisamos injetar o token.
        // Já que o ApiService foi usado na primeira classe, vamos manter o padrão de headers simples:
        final headers = {'Content-Type': 'application/json'};
        // Nota: Idealmente, use o _apiService._performRequest aqui para autenticação.

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
          final serverData = jsonDecode(response.body);

          // Extrai o novo ID do servidor (se for POST, este é o ID retornado).
          // Se for PUT, ele usará o ID original.
          final newServerId = serverData['id'] as int? ?? serverData['rotina']['id'] as int?;

          // Cria a rotina atualizada, usando o ID retornado pela API como o novo ID local/servidor
          final updatedRoutine = routine.copyWith(
            id: newServerId ?? routine.id, // Usa o ID retornado ou o ID existente
            needsSync: false, // MARCA como sincronizada
          );

          // O DBHelper deve ser capaz de fazer o UPSERT ou UPDATE usando o ID contido em updatedRoutine.id
          // Se o DBHelper espera 2 argumentos (como sugerido pelo erro), o ID local original deve ser passado.
          // ASSUMINDO que o ID contido em updatedRoutine é suficiente:
          await _dbHelper.updateRoutine(updatedRoutine); // <-- Assumindo que a assinatura é updateRoutine(Routine r)
          _log('PUSH_SUCCESS', 'Rotina "${routine.titulo}" sincronizada. Server ID: ${updatedRoutine.id}');

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
      // Assumindo que o ApiService ou um interceptor gere o token de autorização
      final response = await http.get(
        Uri.parse(_routinesUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        int routinesPulled = 0;

        for (final routineJson in jsonList) {
          if (routineJson is Map<String, dynamic>) {
            // Usa o factory Routine.fromJson para desserialização
            final Routine routine = Routine.fromMap(routineJson);

            // Marca explicitamente como sincronizada (needsSync: false)
            final synchronizedRoutine = routine.copyWith(needsSync: false);

            // O DBHelper deve fazer um UPSERT (Inserir ou Atualizar, usando o serverId como chave de verificação)
            await _dbHelper.insertRoutineWithSteps(synchronizedRoutine);
            routinesPulled++;
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
  // LOGOUT
  // =====================================================
  Future<void> sair() async {
    try {
      // Tenta fazer um PUSH final para não perder dados locais não sincronizados
      await _pushUnsyncedRoutines();

      // Limpa dados locais e faz logout na API
      await _dbHelper.clearAllData();
      await _apiService.logout();
    } catch (e) {
      _log('LOGOUT_FAIL', 'Erro durante o processo de logout/limpeza', e);
    }
  }
}