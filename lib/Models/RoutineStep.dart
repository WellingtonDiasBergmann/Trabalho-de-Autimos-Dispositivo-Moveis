import 'package:flutter/foundation.dart';

// O modelo foi mantido como 'immutable' para as propriedades finais
// (id, routineId, isCompleted), mas as propriedades editáveis
// (descricao, duracaoSegundos, ordem) foram tornadas mutáveis (non-final)
// para suportar a lógica de edição direta na TelaRotinas.dart.

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

  // --- Rotina de Desserialização (Map -> Objeto) ---
  factory RoutineStep.fromMap(Map<String, dynamic> map) {
    return RoutineStep(
      id: map['id'] as int?,
      routineId: map['routineId'] as int?,
      descricao: map['descricao'] as String,
      duracaoSegundos: map['duracaoSegundos'] as int,
      ordem: map['ordem'] as int,
      isCompleted: (map['isCompleted'] as int) == 1, // SQLite armazena booleanos como 0/1
    );
  }

  // --- Rotina de Serialização (Objeto -> Map) ---
  Map<String, dynamic> toMap() {
    return {
      // O 'id' é incluído na atualização, mas pode ser nulo para inserção
      'id': id,
      'routineId': routineId,
      'descricao': descricao,
      'duracaoSegundos': duracaoSegundos,
      'ordem': ordem,
      'isCompleted': isCompleted ? 1 : 0, // Converte booleano para 1/0 para DB
    };
  }

  // Método copyWith (já existia e é essencial para manipulação de listas)
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