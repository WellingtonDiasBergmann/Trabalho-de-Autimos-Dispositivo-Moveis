class User {
  final int? id;
  final String nome;
  final String documento;
  final String email;
  final String telefone;
  // tipoUsuario: 0=Autista, 1=Responsável, 2=Profissional, 3=Admin
  final int tipoUsuario;

  final int? idade;
  final String? crp;
  final bool? isCrianca;

  User({
    this.id,
    required this.nome,
    required this.documento,
    required this.email,
    required this.telefone,
    required this.tipoUsuario,
    this.idade,
    this.crp,
    this.isCrianca,
  });

  // --- factory minimal para casos em que só temos id+nome (login/sync)
  factory User.minimal({int? id, required String nome}) {
    return User(
      id: id,
      nome: nome,
      documento: '',
      email: '',
      telefone: '',
      tipoUsuario: 1, // fallback: responsável (1)
      idade: null,
      crp: null,
      isCrianca: null,
    );
  }

  bool get usuarioAutista => tipoUsuario == 0;
  bool get usuarioResponsavel => tipoUsuario == 1;
  bool get usuarioProfissional => tipoUsuario == 2;
  bool get usuarioAdmin => tipoUsuario == 3;
  // O getter de crianca depende da flag 'isCrianca' do perfil
  bool get usuarioCrianca => isCrianca ?? false;

  /// Converte um JSON recebido da API em um objeto User.
  factory User.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return null;
    }

    // Tenta obter 'tipo_usuario' como string ou int. Fallback para 1 (Responsável)
    final tipoUsuarioValue = json['tipo_usuario'];
    int parsedTipoUsuario = 1;
    if (tipoUsuarioValue is int) {
      parsedTipoUsuario = tipoUsuarioValue;
    } else if (tipoUsuarioValue is String) {
      parsedTipoUsuario = int.tryParse(tipoUsuarioValue) ?? 1;
    }

    return User(
      id: parseId(json['id']),
      nome: json['nome'] ?? '',
      documento: json['documento'] ?? '',
      email: json['email'] ?? '',
      telefone: json['telefone'] ?? '',
      tipoUsuario: parsedTipoUsuario,
      idade: int.tryParse(json['idade']?.toString() ?? ''),
      crp: json['crp'],
      isCrianca: parseBool(json['is_crianca'] ?? json['isCrianca']),
    );
  }

  factory User.fromMap(Map<String, dynamic> map) {
    bool? mapToBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value != 0;
      return null;
    }

    // Tenta obter 'tipo_usuario' como int ou string. Fallback para 1 (Responsável)
    final tipoUsuarioValue = map['tipo_usuario'];
    int parsedTipoUsuario = 1;
    if (tipoUsuarioValue is int) {
      parsedTipoUsuario = tipoUsuarioValue;
    } else if (tipoUsuarioValue is String) {
      parsedTipoUsuario = int.tryParse(tipoUsuarioValue) ?? 1;
    }

    return User(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? ''),
      nome: map['nome']?.toString() ?? '',
      documento: map['documento']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      telefone: map['telefone']?.toString() ?? '',
      tipoUsuario: parsedTipoUsuario,
      idade: map['idade'] is int ? map['idade'] as int : int.tryParse(map['idade']?.toString() ?? ''),
      crp: map['crp']?.toString(),
      isCrianca: mapToBool(map['is_crianca']),
    );
  }

  /// Converte o objeto User para um Map para ser salvo no SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'documento': documento,
      'email': email,
      'telefone': telefone,
      'tipo_usuario': tipoUsuario,
      'idade': idade,
      'crp': crp,
      'is_crianca': isCrianca == null ? null : (isCrianca! ? 1 : 0),
    };
  }

  /// Converte o objeto User para um JSON a ser enviado para a API (ex: no Signup/Update).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'documento': documento,
      'email': email,
      'telefone': telefone,
      'tipo_usuario': tipoUsuario,
      // Usando 'isCrianca' no camelCase para consistência API/Frontend
      'isCrianca': isCrianca == null ? null : (isCrianca! ? 1 : 0),
    };
  }

  User copyWith({
    int? id,
    String? nome,
    String? documento,
    String? email,
    String? telefone,
    int? tipoUsuario,
    int? idade,
    String? crp,
    bool? isCrianca,
  }) {
    return User(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      documento: documento ?? this.documento,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      idade: idade ?? this.idade,
      crp: crp ?? this.crp,
      isCrianca: isCrianca ?? this.isCrianca,
    );
  }
}