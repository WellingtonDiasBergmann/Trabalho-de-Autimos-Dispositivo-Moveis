import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trabalhofinal/Models/Board.dart';
import 'package:trabalhofinal/Models/BoardItem.dart';
import 'package:trabalhofinal/Models/Diario.dart';
import 'package:trabalhofinal/Models/Routine.dart';
import 'package:trabalhofinal/Models/User.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trabalhofinal/Services/ApiConstant.dart'; // Importa a nova classe de constantes

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  String? _jwtToken;
  bool _tokenLoaded = false;

  // =========================================================
  // LOGGING CENTRALIZADO
  // =========================================================

  /// Função auxiliar de log para maior consistência e fácil desativação.
  void _log(String level, String message, {dynamic error}) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    print('[$timestamp] [API $level] $message');
    if (error != null) {
      print('[$timestamp] [API ERROR DETAIL] $error');
    }
  }

  // =========================================================
  // TOKEN E HEADERS
  // =========================================================

  /// Carrega o token apenas uma vez do SharedPreferences ou é definido pelo login.
  Future<void> _loadToken() async {
    if (_tokenLoaded && _jwtToken != null) return;

    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('access_token');
    _tokenLoaded = true;

    if (_jwtToken == null) {
      _log('WARN', 'Nenhum token encontrado no SharedPreferences.');
    } else {
      _log('INFO',
          'Token carregado com sucesso (Tamanho: ${_jwtToken!.length}).');
    }
  }

  /// Salva o token no SharedPreferences e na variável interna.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    _jwtToken = token; // Variável interna
    _tokenLoaded = true;
    await prefs.setString('access_token', token); // Salvo no dispositivo

    _log('AUTH SUCCESS', 'Token salvo e variável interna atualizada.');
  }

  /// Retorna os cabeçalhos HTTP necessários, garantindo o carregamento do token se necessário.
  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      await _loadToken(); // Garante que o token está carregado

      if (_jwtToken == null || _jwtToken!.isEmpty) {
        _log('ERROR', 'Tentativa de requisição autenticada sem token disponível.');
      } else {
        headers['Authorization'] = 'Bearer $_jwtToken';
        _log('INFO', 'Headers de autenticação definidos.');
      }
    }

    return headers;
  }

  // =========================================================
  // HELPER PARA REQUISIÇÕES GENÉRICAS
  // =========================================================

  /// Wrapper genérico para todas as requisições HTTP para centralizar logging e tratamento de erros.
  Future<http.Response> _performRequest(
      String method,
      Uri url, {
        Object? body,
        bool requireAuth = true,
      }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    final bodyString = body != null ? jsonEncode(body) : null;

    // Log da Requisição
    _log('REQUEST', '$method ${url.path}', error: bodyString != null ? 'Body: ${bodyString.substring(0, bodyString.length.clamp(0, 150))}${bodyString.length > 150 ? '...' : ''}' : 'Sem corpo.');

    try {
      final http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: bodyString);
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: bodyString);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers, body: bodyString);
          break;
        default:
          throw Exception('Método HTTP não suportado: $method');
      }

      // Log da Resposta
      final responseBodyPreview = response.body.length > 500
          ? response.body.substring(0, 500) + '...'
          : response.body;

      if (response.statusCode == 401 && requireAuth) {
        _log('UNAUTHORIZED', 'Requisição não autorizada (401) para ${url.path}. Forçando logout.');
        await logout();
        throw Exception('Sessão expirada ou não autorizada. Faça login novamente.');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('SUCCESS', 'Status ${response.statusCode} para ${url.path}. Preview: ${responseBodyPreview.replaceAll('\n', ' ')}');
      } else {
        _log('FAIL', 'Status ${response.statusCode} para ${url.path}. Resposta: ${responseBodyPreview.replaceAll('\n', ' ')}');
      }

      return response;

    } catch (e) {
      _log('NETWORK ERROR', 'Falha na conexão com $url', error: e);
      throw Exception('Erro de conexão/rede: Verifique sua internet ou o status do servidor.');
    }
  }

  /// Helper para tratar erros HTTP e lançar exceções claras.
  Exception _handleHttpError(http.Response response) {
    String mensagem = 'Erro desconhecido no servidor';
    try {
      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      mensagem = body['mensagem'] ??
          body['message'] ??
          body['msg'] ??
          (body['detail'] is String ? body['detail'] : null) ??
          mensagem;

      _log('API ERROR', 'HTTP ${response.statusCode}: $mensagem', error: body);
      return Exception('Erro ${response.statusCode}: $mensagem');
    } catch (e) {
      _log('API ERROR', 'HTTP ${response.statusCode}: Falha ao decodificar JSON de erro.', error: response.body);
      return Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  // =========================================================
  // AUTH
  // =========================================================

  /// Trata a resposta do servidor após o signup ou login.
  Future<Map<String, dynamic>> _handleAuthResponse(http.Response response) async {
    Map<String, dynamic>? responseBody;

    try {
      responseBody = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {
      _log('AUTH ERROR', 'Corpo de resposta inválido após autenticação: ${response.body}');
      return {'success': false, 'message': 'Resposta inválida do servidor.'};
    }

    responseBody ??= {};

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic userJson = responseBody['user'];
      final String? token = responseBody['access_token'] as String?;

      if (token == null || userJson == null) {
        _log('AUTH ERROR', 'Token ou usuário ausente na resposta 2xx.');
        return {'success': false, 'message': 'Resposta inválida: token ou usuário não encontrados.'};
      }

      // 1. Salva o token
      await saveToken(token);

      // 2. Garante que userMap seja o Map<String, dynamic>
      try {
        final Map<String, dynamic> userMap = userJson is Map<String, dynamic>
            ? userJson
            : jsonDecode(jsonEncode(userJson)) as Map<String, dynamic>;

        // CORREÇÃO CRÍTICA: Retorna o Map<String, dynamic> bruto (userMap),
        // e não o objeto User já desserializado.
        return {'success': true, 'user': userMap, 'access_token': token};
      } catch (e) {
        _log('AUTH WARN', 'Erro ao processar JSON do usuário. Retornando objeto original.', error: e);
        // Fallback: retorna o JSON bruto original
        return {'success': true, 'user': userJson, 'access_token': token};
      }
    } else {
      final String errorMessage = (responseBody['mensagem'] ??
          responseBody['message'] ??
          responseBody['msg'] ??
          (responseBody['detail'] is String ? responseBody['detail'] : null) ??
          'Erro desconhecido').toString();

      _log('AUTH FAIL', 'Falha na autenticação. Status: ${response.statusCode}', error: errorMessage);

      return {'success': false, 'message': errorMessage, 'status': response.statusCode};
    }
  }

  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData, String password) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/auth/signup');
    final body = {...userData, 'senha': password};

    try {
      final response = await _performRequest('POST', url, body: body, requireAuth: false);
      return _handleAuthResponse(response);
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/auth/login');
    final body = {'email': email, 'senha': password};

    try {
      final response = await _performRequest('POST', url, body: body, requireAuth: false);
      return _handleAuthResponse(response);
    } on Exception catch (e) {
      return {'success': false, 'message': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _jwtToken = null;
    _tokenLoaded = false;
    _log('LOGOUT', 'Token de acesso removido do SharedPreferences e variável interna.');
  }

  // =========================================================
  // HELPER GENÉRICO PARA REQUISIÇÕES AUTENTICADAS
  // =========================================================

  // Refatora o request para usar o _performRequest e _handleHttpError.
  Future<Map<String, dynamic>> request(String endpoint, {
    String method = 'GET',
    dynamic body,
    String? token,
  }) async {
    try {
      final url = Uri.parse('${ApiConstant.baseUrl}$endpoint');

      final response = await _performRequest(method, url, body: body, requireAuth: true);

      // Se a requisição foi bem-sucedida, retorna o corpo decodificado
      return jsonDecode(response.body) as Map<String, dynamic>;

    } on Exception catch (e) {
      // Retorna um mapa de erro padronizado para o SyncService
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _log('ERROR', 'Falha na requisição $method $endpoint', error: errorMessage);
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Métodos de Acesso
  Future<String?> getToken() async {
    await _loadToken();
    return _jwtToken;
  }

  // =========================================================
  // ROTINAS (CRUD COMPLETO)
  // =========================================================

  Future<List<Routine>> fetchRoutines() async {
    final url = Uri.parse('${ApiConstant.baseUrl}/routines');

    try {
      final response = await _performRequest('GET', url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        // Assume que a API retorna lista de Maps
        return jsonList.map((json) => Routine.fromMap(json as Map<String, dynamic>)).toList();
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<Routine> createRoutine(Routine routine) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/routines');
    final body = routine.toJson();

    try {
      final response = await _performRequest('POST', url, body: body);

      if (response.statusCode == 201) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        // A API pode retornar o objeto diretamente ou aninhado
        final routineJson = json['rotina'] ?? json;
        return Routine.fromMap(routineJson as Map<String, dynamic>);
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<Routine> updateRoutine(int routineId, Routine routine) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/routines/$routineId');
    final body = routine.toJson(); // Assumindo que toApiJson() tem o formato correto para PUT

    try {
      final response = await _performRequest('PUT', url, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        final routineJson = json['rotina'] ?? json;
        return Routine.fromMap(routineJson as Map<String, dynamic>);
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<void> deleteRoutine(int routineId) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/routines/$routineId');

    try {
      final response = await _performRequest('DELETE', url);

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleHttpError(response);
      }
      // Status 204 (No Content) é comum para DELETEs bem-sucedidos.
    } on Exception {
      rethrow;
    }
  }

  // =========================================================
  // DIÁRIO (CRUD COMPLETO)
  // =========================================================

  Future<Diario> createEntry(Diario entry) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/entries');
    final body = entry.toMap();

    try {
      final response = await _performRequest('POST', url, body: body);

      if (response.statusCode == 201) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        // A API pode retornar o objeto diretamente ou aninhado
        final entryJson = json['diario'] ?? json['entry'] ?? json;
        return Diario.fromMap(entryJson as Map<String, dynamic>);
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<List<Diario>> fetchEntries() async {
    final url = Uri.parse('${ApiConstant.baseUrl}/entries');

    try {
      final response = await _performRequest('GET', url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList.map((json) => Diario.fromMap(json as Map<String, dynamic>)).toList();
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<Diario> updateEntry(int entryId, Diario entry) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/entries/$entryId');
    final body = entry.toMap();

    try {
      final response = await _performRequest('PUT', url, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        final entryJson = json['diario'] ?? json['entry'] ?? json;
        return Diario.fromMap(entryJson as Map<String, dynamic>);
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<void> deleteEntry(int entryId) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/entries/$entryId');

    try {
      final response = await _performRequest('DELETE', url);

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  // =========================================================
  // BOARDS (CRUD COMPLETO)
  // =========================================================

  Future<Board> createBoard(Board board) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/boards');
    final body = board.toMap();

    try {
      final response = await _performRequest('POST', url, body: body);

      if (response.statusCode == 201) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        final boardJson = json['board'] ?? json;
        return Board.fromMap(boardJson as Map<String, dynamic>);
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<List<Board>> fetchBoards() async {
    final url = Uri.parse('${ApiConstant.baseUrl}/boards');

    try {
      final response = await _performRequest('GET', url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList.map((json) => Board.fromMap(json as Map<String, dynamic>)).toList();
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<Board> updateBoard(int boardId, Board board) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/boards/$boardId');
    final body = board.toMap();

    try {
      final response = await _performRequest('PUT', url, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        final boardJson = json['board'] ?? json;
        return Board.fromMap(boardJson as Map<String, dynamic>);
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<void> deleteBoard(int boardId) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/boards/$boardId');

    try {
      final response = await _performRequest('DELETE', url);

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  // =========================================================
  // BOARD ITEMS (CRUD COMPLETO)
  // =========================================================

  Future<BoardItem> createBoardItem(int boardId, BoardItem item) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/boards/$boardId/items');
    final body = item.toMap();

    try {
      final response = await _performRequest('POST', url, body: body);

      if (response.statusCode == 201) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        final itemJson = json['item'] ?? json;
        return BoardItem.fromMap(itemJson as Map<String, dynamic>);
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<BoardItem> updateBoardItem(int itemId, BoardItem item) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/items/$itemId');
    final body = item.toMap();

    try {
      final response = await _performRequest('PUT', url, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        final itemJson = json['item'] ?? json;
        return BoardItem.fromMap(itemJson as Map<String, dynamic>);
      } else {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }

  Future<void> deleteBoardItem(int itemId) async {
    final url = Uri.parse('${ApiConstant.baseUrl}/items/$itemId');

    try {
      final response = await _performRequest('DELETE', url);

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleHttpError(response);
      }
    } on Exception {
      rethrow;
    }
  }
}