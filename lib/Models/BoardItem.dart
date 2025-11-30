class BoardItem {
  final int? id;
  final int boardId;
  final String imgUrl;
  final String texto;
  final String fraseTts;

  BoardItem({
    this.id,
    required this.boardId,
    required this.imgUrl,
    required this.texto,
    required this.fraseTts,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'board_id': boardId,
      'img_url': imgUrl,
      'texto': texto,
      'frase_tts': fraseTts,
    };
  }

  factory BoardItem.fromMap(Map<String, dynamic> map) {
    return BoardItem(
      id: map['id'] as int?,
      boardId: map['board_id'] as int,
      imgUrl: map['img_url'] as String,
      texto: map['texto'] as String,
      fraseTts: map['frase_tts'] as String,
    );
  }

  BoardItem copyWith({
    int? id,
    int? boardId,
    String? imgUrl,
    String? texto,
    String? fraseTts,
  }) {
    return BoardItem(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      imgUrl: imgUrl ?? this.imgUrl,
      texto: texto ?? this.texto,
      fraseTts: fraseTts ?? this.fraseTts,
    );
  }
}
