
class RoutineStep {
  final int? id;
  final int? routineId;

  String descricao; // Mutável para edição
  int duracaoSegundos; // Mutável para edição
  int ordem; // Mutável para edição e reordenação
  final bool isCompleted;

  RoutineStep({
    this.id,
    this.routineId,
    required this.descricao,
    required this.duracaoSegundos,
    required this.ordem,
    required this.isCompleted,
  });

  factory RoutineStep.fromMap(Map<String, dynamic> map) {
    final routineIdValue = map['routineId'] ?? map['rotina_id'];
    final duracaoSegundosValue = map['duracaoSegundos'] ?? map['duracao_segundos'];
    final isCompletedValue = map['isCompleted'] ?? map['concluido'];

    return RoutineStep(
      id: map['id'] as int?,
      routineId: routineIdValue as int?,
      descricao: map['descricao'] as String? ?? '',
      duracaoSegundos: (duracaoSegundosValue as int?) ?? (duracaoSegundosValue as num?)?.toInt() ?? 0,
      ordem: (map['ordem'] as int?) ?? (map['ordem'] as num?)?.toInt() ?? 0,
      isCompleted: (isCompletedValue is int ? isCompletedValue == 1 : (isCompletedValue as bool?) ?? false),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'descricao': descricao,
      'duracaoSegundos': duracaoSegundos,
      'ordem': ordem,
      'isCompleted': isCompleted ? 1 : 0, 
    };
  }

  RoutineStep copyWith({
    int? id,
    int? routineId,
    String? descricao,
    int? duracaoSegundos,
    int? ordem,
    bool? isCompleted,
  }) {
    return RoutineStep(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      descricao: descricao ?? this.descricao,
      duracaoSegundos: duracaoSegundos ?? this.duracaoSegundos,
      ordem: ordem ?? this.ordem,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}