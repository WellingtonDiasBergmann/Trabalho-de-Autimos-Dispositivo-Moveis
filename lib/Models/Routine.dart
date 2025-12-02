import 'dart:convert';
import 'package:trabalhofinal/Models/RoutineStep.dart';

class Routine {
  // Propriedades finais (imutáveis)
  final int? id;
  final int pessoaId;
  final String dataCriacao;
  final List<RoutineStep>? steps; // Lista de passos (aninhada)
  final bool needsSync; 

  // Propriedades mutáveis (para edição)
  String titulo;
  String? lembrete;

  Routine({
    this.id,
    required this.pessoaId,
    required this.titulo,
    required this.dataCriacao,
    this.lembrete,
    this.steps,
    bool needsSync = false 
  }) : this.needsSync = needsSync;

 
  factory Routine.fromMap(Map<String, dynamic> map, {List<RoutineStep>? steps}) {
    
    final pessoaIdValue = map['pessoaId'] ?? map['pessoa_id'];
    final dataCriacaoValue = map['dataCriacao'] ?? map['data_criacao'];

    return Routine(
      id: map['id'] as int?,
      pessoaId: (pessoaIdValue as int?) ?? (pessoaIdValue as num?)?.toInt() ?? 0,
      titulo: map['titulo'] as String? ?? '',
      dataCriacao: dataCriacaoValue as String? ?? DateTime.now().toIso8601String(),
      lembrete: map['lembrete'] as String?,
      steps: steps, 
      needsSync: (map['needsSync'] as int? ?? 0) == 1, 
    );
  }

  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pessoaId': pessoaId,
      'titulo': titulo,
      'dataCriacao': dataCriacao,
      'lembrete': lembrete,
      'needsSync': needsSync ? 1 : 0, // Converte bool para 1/0
    };
  }

  String toJson() {
    final Map<String, dynamic> map = toMap();
    // Adiciona a lista de passos serializada ao Map base para exportação JSON.
    map['steps'] = steps?.map((s) => s.toMap()).toList();
    return json.encode(map);
  }

  factory Routine.fromJson(String source) {
    final map = json.decode(source) as Map<String, dynamic>;

    // Desserializa a lista de passos (objects dentro do JSON) usando RoutineStep.fromMap
    final stepsList = (map['steps'] as List<dynamic>?)
        ?.map((stepMap) => RoutineStep.fromMap(stepMap as Map<String, dynamic>))
        .toList();

    // Chama o construtor 'fromMap' injetando a lista de passos.
    return Routine.fromMap(map, steps: stepsList);
  }

  // Método copyWith (Padrão essencial para Flutter/Dart)
  Routine copyWith({
    int? id,
    int? pessoaId,
    String? titulo,
    String? dataCriacao,
    String? lembrete,
    List<RoutineStep>? steps,
    bool? needsSync, 
  }) {
    return Routine(
      id: id ?? this.id,
      pessoaId: pessoaId ?? this.pessoaId,
      titulo: titulo ?? this.titulo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      lembrete: lembrete ?? this.lembrete,
      steps: steps ?? this.steps,
      needsSync: needsSync ?? this.needsSync, 
    );
  }
}