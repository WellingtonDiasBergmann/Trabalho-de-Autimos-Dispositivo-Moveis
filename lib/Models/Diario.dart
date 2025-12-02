import 'package:intl/intl.dart';



const List<String> CATEGORIES = ['SONO', 'HUMOR', 'ALIMENTAÇÃO', 'CRISE'];

const Map<String, List<String>> OPTIONS = {
  'SONO': ['Dormiu bem', 'Dormiu mal', 'Insônia', 'Interrompido'],
  'HUMOR': ['Feliz', 'Calmo', 'Irritado', 'Ansioso', 'Triste'],
  'ALIMENTAÇÃO': ['Normal', 'Exagerada', 'Restrita', 'Seletiva'],
  'CRISE': ['Nenhuma', 'Leve', 'Moderada', 'Grave'],
};



class Diario {
  final int? id; // ID da entrada no DB (pode ser null se for nova)
  final int pessoaId; // ID do usuário/pessoa (FK)
  final String dataRegistro; // Timestamp ou String 'YYYY-MM-DD HH:MM:SS'
  final String humor;
  final String? sono;
  final String? alimentacao;
  final String? crise;
  final String? observacoes;

  Diario({
    this.id,
    required this.pessoaId,
    required this.dataRegistro,
    required this.humor,
    this.sono,
    this.alimentacao,
    this.crise,
    this.observacoes,
  });

  // Converte o objeto para um Map (para salvar no DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pessoa_id': pessoaId,
      'data_registro': dataRegistro,
      'humor': humor,
      'sono': sono,
      'alimentacao': alimentacao,
      'crise': crise,
      'observacoes': observacoes,
    };
  }

  // Cria um objeto a partir de um Map (lido do DB)
  factory Diario.fromMap(Map<String, dynamic> map) {
    return Diario(
      id: map['id'] as int?,
      pessoaId: (map['pessoa_id'] as int?) ?? (map['pessoa_id'] as num?)?.toInt() ?? 0,
      dataRegistro: map['data_registro'] as String? ?? DateTime.now().toIso8601String(),
      humor: map['humor'] as String? ?? '',
      sono: map['sono'] as String?,
      alimentacao: map['alimentacao'] as String?,
      crise: map['crise'] as String?,
      observacoes: map['observacoes'] as String?,
    );
  }
  
  // Método copyWith para criar cópias modificadas
  Diario copyWith({
    int? id,
    int? pessoaId,
    String? dataRegistro,
    String? humor,
    String? sono,
    String? alimentacao,
    String? crise,
    String? observacoes,
  }) {
    return Diario(
      id: id ?? this.id,
      pessoaId: pessoaId ?? this.pessoaId,
      dataRegistro: dataRegistro ?? this.dataRegistro,
      humor: humor ?? this.humor,
      sono: sono ?? this.sono,
      alimentacao: alimentacao ?? this.alimentacao,
      crise: crise ?? this.crise,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}

class EntradaDiario {
  int? id; // ID da entrada no DB (null se for nova)
  DateTime data;

  // Status estruturados para cada categoria
  String sonoStatus;
  String humorStatus;
  String alimentacaoStatus;
  String criseStatus;

  String observacoes;

  EntradaDiario({
    this.id, // O ID pode ser null para novas entradas
    required this.data,
    this.sonoStatus = 'Dormiu bem',
    this.humorStatus = 'Feliz',
    this.alimentacaoStatus = 'Normal',
    this.criseStatus = 'Nenhuma',
    this.observacoes = '',
  });

  EntradaDiario copyWith({
    int? id,
    DateTime? data,
    String? sonoStatus,
    String? humorStatus,
    String? alimentacaoStatus,
    String? criseStatus,
    String? observacoes,
  }) {
    return EntradaDiario(
      id: id ?? this.id,
      data: data ?? this.data,
      sonoStatus: sonoStatus ?? this.sonoStatus,
      humorStatus: humorStatus ?? this.humorStatus,
      alimentacaoStatus: alimentacaoStatus ?? this.alimentacaoStatus,
      criseStatus: criseStatus ?? this.criseStatus,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  factory EntradaDiario.fromDiario(Diario diario) {
    // Tenta parsear a data em diferentes formatos
    DateTime dataParsed;
    try {
      // Tenta primeiro como ISO8601 (pode ter microssegundos)
      dataParsed = DateTime.parse(diario.dataRegistro);
    } catch (e) {
      try {
        // Tenta como formato "yyyy-MM-dd HH:mm:ss"
        final dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
        dataParsed = dateFormat.parse(diario.dataRegistro);
      } catch (e2) {
        // Fallback: usa data atual
        dataParsed = DateTime.now();
      }
    }
    
    return EntradaDiario(
      id: diario.id,
      data: dataParsed,
      sonoStatus: diario.sono ?? OPTIONS['SONO']!.first,
      humorStatus: diario.humor, // 'humor' é obrigatório no modelo Diario
      alimentacaoStatus: diario.alimentacao ?? OPTIONS['ALIMENTAÇÃO']!.first,
      criseStatus: diario.crise ?? OPTIONS['CRISE']!.first,
      observacoes: diario.observacoes ?? '',
    );
  }

  // Converte o modelo de UI (EntradaDiario) para o modelo de DB (Diario)
  Diario toDiario(int userId) {
    return Diario(
      id: id,
      pessoaId: userId,
      dataRegistro: data.toIso8601String(), // Salva a data em formato ISO
      humor: humorStatus,
      sono: sonoStatus,
      alimentacao: alimentacaoStatus,
      crise: criseStatus,
      observacoes: observacoes,
    );
  }
}