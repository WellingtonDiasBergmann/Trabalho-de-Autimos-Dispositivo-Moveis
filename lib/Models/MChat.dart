class MCHAT {
  final int? id;
  final int assessmentId;
  final Map<String, String> respostas; // "1": "sim" ou "nao"
  final int scoreTotal;
  final List<String> itensCriticosMarcados;
  final String classificacao; // "risco" ou "sem_risco"
  final String? recomendacao;

  MCHAT({
    this.id,
    required this.assessmentId,
    required this.respostas,
    required this.scoreTotal,
    required this.itensCriticosMarcados,
    required this.classificacao,
    this.recomendacao,
  });

  // Itens que pontuam com "Não"
  static const List<int> itensPontuamNao = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 16, 17, 19, 21, 23];
  
  // Itens que pontuam com "Sim"
  static const List<int> itensPontuamSim = [11, 18, 20, 22];
  
  // Itens críticos
  static const List<int> itensCriticos = [2, 7, 9, 13, 14, 15];

  // Calcula o score baseado nas respostas
  static int calcularScore(Map<String, String> respostas) {
    int score = 0;
    
    for (var entry in respostas.entries) {
      final itemNum = int.tryParse(entry.key);
      if (itemNum == null) continue;
      
      final resposta = entry.value.toLowerCase();
      
      if (itensPontuamNao.contains(itemNum) && resposta == 'nao') {
        score++;
      } else if (itensPontuamSim.contains(itemNum) && resposta == 'sim') {
        score++;
      }
    }
    
    return score;
  }

  // Verifica itens críticos marcados
  static List<String> verificarItensCriticos(Map<String, String> respostas) {
    List<String> criticos = [];
    
    for (var itemCritico in itensCriticos) {
      final resposta = respostas[itemCritico.toString()]?.toLowerCase();
      if (resposta == 'nao') {
        criticos.add(itemCritico.toString());
      }
    }
    
    return criticos;
  }

  // Classifica o risco
  static String classificarRisco(int scoreTotal, List<String> itensCriticosMarcados) {
    if (scoreTotal > 3) {
      return 'risco';
    }
    if (itensCriticosMarcados.length >= 2) {
      return 'risco';
    }
    return 'sem_risco';
  }

  // Gera recomendação baseada na classificação
  static String gerarRecomendacao(String classificacao) {
    if (classificacao == 'risco') {
      return 'Encaminhar para avaliação especializada e acompanhamento.';
    }
    return 'Acompanhamento de rotina recomendado.';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'respostas': respostas,
      'score_total': scoreTotal,
      'itens_criticos': itensCriticosMarcados.join(','),
      'classificacao': classificacao,
      'recomendacao': recomendacao,
    };
  }

  factory MCHAT.fromMap(Map<String, dynamic> map) {
    final respostasMap = map['respostas'];
    Map<String, String> respostas = {};
    
    if (respostasMap is Map) {
      respostas = respostasMap.map((key, value) => MapEntry(key.toString(), value.toString()));
    } else if (respostasMap is String) {
      // Se vier como JSON string, precisa fazer parse
      respostas = {};
    }

    return MCHAT(
      id: map['id'] as int?,
      assessmentId: map['assessment_id'] as int? ?? map['assessmentId'] as int,
      respostas: respostas,
      scoreTotal: map['score_total'] as int? ?? map['scoreTotal'] as int? ?? 0,
      itensCriticosMarcados: (map['itens_criticos'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      classificacao: map['classificacao'] as String? ?? 'sem_risco',
      recomendacao: map['recomendacao'] as String?,
    );
  }

  MCHAT copyWith({
    int? id,
    int? assessmentId,
    Map<String, String>? respostas,
    int? scoreTotal,
    List<String>? itensCriticosMarcados,
    String? classificacao,
    String? recomendacao,
  }) {
    return MCHAT(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      respostas: respostas ?? this.respostas,
      scoreTotal: scoreTotal ?? this.scoreTotal,
      itensCriticosMarcados: itensCriticosMarcados ?? this.itensCriticosMarcados,
      classificacao: classificacao ?? this.classificacao,
      recomendacao: recomendacao ?? this.recomendacao,
    );
  }
}

