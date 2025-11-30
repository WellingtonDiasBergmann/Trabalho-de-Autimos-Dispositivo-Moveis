import 'package:trabalhofinal/Models/BoardItem.dart';

class Board {
  final int? id;
  final int userId;
  final String nome;
  final List<BoardItem>? items;

  Board({
    this.id,
    required this.userId,
    required this.nome,
    this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'nome': nome,
    };
  }

  factory Board.fromMap(Map<String, dynamic> map) {
    List<BoardItem>? itemsList;
    if (map.containsKey('items') && map['items'] is List) {
      itemsList = (map['items'] as List)
          .map((itemMap) => BoardItem.fromMap(itemMap))
          .toList();
    }

    return Board(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      nome: map['nome'] as String,
      items: itemsList,
    );
  }

  Board copyWith({
    int? id,
    int? userId,
    String? nome,
    List<BoardItem>? items,
  }) {
    return Board(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nome: nome ?? this.nome,
      items: items ?? this.items,
    );
  }
}
