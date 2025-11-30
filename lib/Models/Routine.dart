import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:trabalhofinal/Models/RoutineStep.dart';

class Routine {
  // Propriedades finais (imutáveis)
  final int? id;
  final int pessoaId;
  final String dataCriacao;
  final List<RoutineStep>? steps; // Lista de passos (aninhada)
  final bool needsSync; // <-- ADICIONADO!

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
    bool needsSync = false // <-- Correção: Removido 'final'
  }) : this.needsSync = needsSync; // <-- Inicializa o campo 'final'

  // --- 1. Rotina de Desserialização: Construtor de Fábrica 'fromMap' (Map -> Objeto) ---
  /// Cria uma instância de [Routine] a partir de um Map.
  /// Geralmente usado para ler a tabela 'Rotina' do SQLite.
  factory Routine.fromMap(Map<String, dynamic> map, {List<RoutineStep>? steps}) {
    // Note: A lista de 'steps' deve ser lida separadamente do DB e injetada via o parâmetro nomeado.
    return Routine(
      id: map['id'] as int?,
      pessoaId: map['pessoaId'] as int,
      titulo: map['titulo'] as String,
      dataCriacao: map['dataCriacao'] as String,
      lembrete: map['lembrete'] as String?,
      steps: steps, // Passos lidos do DB ou injetados do 'fromJson'
      needsSync: (map['needsSync'] as int? ?? 0) == 1, // Lê 1/0 e trata nulo
    );
  }

  // --- 2. Rotina de Serialização: Método 'toMap' (Objeto -> Map) ---
  /// Converte a instância para um Map.
  /// Usado para salvar a [Routine] na sua própria tabela no SQLite.
  Map<String, dynamic> toMap() {
    // 'steps' NÃO é incluído aqui, pois é salvo em uma tabela separada (RoutineStep)
    return {
      'id': id,
      'pessoaId': pessoaId,
      'titulo': titulo,
      'dataCriacao': dataCriacao,
      'lembrete': lembrete,
      'needsSync': needsSync ? 1 : 0, // Converte bool para 1/0
    };
  }

  // --- 3. Rotina de Serialização Completa: Método 'toJson' (Objeto -> JSON String) ---
  /// Converte a instância completa (incluindo passos aninhados) para uma string JSON.
  /// Usado para intercâmbio de dados (ex: APIs ou arquivos).
  String toJson() {
    final Map<String, dynamic> map = toMap();
    // Adiciona a lista de passos serializada ao Map base para exportação JSON.
    map['steps'] = steps?.map((s) => s.toMap()).toList();
    return json.encode(map);
  }

  // --- 4. Rotina de Desserialização Completa: Construtor de Fábrica 'fromJson' (JSON String -> Objeto) ---
  /// Cria uma instância de [Routine] a partir de uma string JSON (que contém a lista de passos).
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
    bool? needsSync, // <-- ADICIONADO!
  }) {
    return Routine(
      id: id ?? this.id,
      pessoaId: pessoaId ?? this.pessoaId,
      titulo: titulo ?? this.titulo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      lembrete: lembrete ?? this.lembrete,
      steps: steps ?? this.steps,
      needsSync: needsSync ?? this.needsSync, // <-- USADO!
    );
  }
}