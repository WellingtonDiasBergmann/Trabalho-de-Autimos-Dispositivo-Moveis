class Anamnese {
  final int? id;
  final String? aplicador;
  final String? pacienteNome;
  final String? pacienteNascimento;
  final List<String>? responsaveis;
  final String? cidade;
  final String? telefone;
  final List<String>? cuidadores;
  final String? composicaoFamiliar;
  final List<String>? pessoasAutorizadas;
  
  // Médico
  final String? medicoResponsavel;
  final String? medicoAssistente;
  final String? diagnosticoMedico;
  final List<String>? medicamentos;
  final String? alergias;
  final String? audicaoExame;
  final String? audicaoPercepcao;
  final String? otitesHistorico;
  
  // Gestação/Parto/Puerpério
  final bool? gestacaoPlanejada;
  final String? gestacaoIntercorrencias;
  final int? semanasGestacao;
  final String? tipoParto;
  final String? apgar;
  final String? pesoNascimento;
  final String? alturaNascimento;
  final String? partoIntercorrencias;
  final String? amamentacao;
  
  // DNPM
  final String? controleCervical;
  final String? sentarSemApoio;
  final String? engatinhar;
  final String? andar;
  final String? primeirasPalavras;
  final String? comportamentoVerbal;
  final String? motorAmplo;
  final String? motorFino;
  
  // Escola
  final bool? frequentaEscola;
  final String? escolaNome;
  final String? escolaTurno;
  final String? escolaAno;
  final String? escolaProfessora;
  final String? escolaComportamento;
  
  // Autocuidado/AVD
  final String? banheiro;
  final String? banho;
  final String? escovarDentes;
  final String? vestir;
  final String? lavarMaos;
  final String? alimentacao;
  final String? degluticao;
  final String? restricoesAlimentares;
  final String? habitosAlimentares;
  final String? sono;
  final bool? chupeta;
  final bool? mamadeira;
  
  // Sensorial
  final String? sensorialTatil;
  final String? sensorialAuditiva;
  final String? sensorialOlfativa;
  final String? sensorialVisual;
  
  // Outros
  final String? brincarPreferencias;
  final String? medos;
  final String? socializacao;
  final String? queixas;
  final String? comportamentosInadequados;
  final String? observacoes;
  
  final String? status; // rascunho, final
  final String? dataAvaliacao;
  final int? psicologoId;

  Anamnese({
    this.id,
    this.aplicador,
    this.pacienteNome,
    this.pacienteNascimento,
    this.responsaveis,
    this.cidade,
    this.telefone,
    this.cuidadores,
    this.composicaoFamiliar,
    this.pessoasAutorizadas,
    this.medicoResponsavel,
    this.medicoAssistente,
    this.diagnosticoMedico,
    this.medicamentos,
    this.alergias,
    this.audicaoExame,
    this.audicaoPercepcao,
    this.otitesHistorico,
    this.gestacaoPlanejada,
    this.gestacaoIntercorrencias,
    this.semanasGestacao,
    this.tipoParto,
    this.apgar,
    this.pesoNascimento,
    this.alturaNascimento,
    this.partoIntercorrencias,
    this.amamentacao,
    this.controleCervical,
    this.sentarSemApoio,
    this.engatinhar,
    this.andar,
    this.primeirasPalavras,
    this.comportamentoVerbal,
    this.motorAmplo,
    this.motorFino,
    this.frequentaEscola,
    this.escolaNome,
    this.escolaTurno,
    this.escolaAno,
    this.escolaProfessora,
    this.escolaComportamento,
    this.banheiro,
    this.banho,
    this.escovarDentes,
    this.vestir,
    this.lavarMaos,
    this.alimentacao,
    this.degluticao,
    this.restricoesAlimentares,
    this.habitosAlimentares,
    this.sono,
    this.chupeta,
    this.mamadeira,
    this.sensorialTatil,
    this.sensorialAuditiva,
    this.sensorialOlfativa,
    this.sensorialVisual,
    this.brincarPreferencias,
    this.medos,
    this.socializacao,
    this.queixas,
    this.comportamentosInadequados,
    this.observacoes,
    this.status,
    this.dataAvaliacao,
    this.psicologoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aplicador': aplicador,
      'paciente_nome': pacienteNome,
      'paciente_nascimento': pacienteNascimento,
      'responsaveis': responsaveis?.join(','),
      'cidade': cidade,
      'telefone': telefone,
      'cuidadores': cuidadores?.join(','),
      'composicao_familiar': composicaoFamiliar,
      'pessoas_autorizadas': pessoasAutorizadas?.join(','),
      'medico_responsavel': medicoResponsavel,
      'medico_assistente': medicoAssistente,
      'diagnostico_medico': diagnosticoMedico,
      'medicamentos': medicamentos?.join(','),
      'alergias': alergias,
      'audicao_exame': audicaoExame,
      'audicao_percepcao': audicaoPercepcao,
      'otites_historico': otitesHistorico,
      'gestacao_planejada': gestacaoPlanejada == true ? 1 : 0,
      'gestacao_intercorrencias': gestacaoIntercorrencias,
      'semanas_gestacao': semanasGestacao,
      'tipo_parto': tipoParto,
      'apgar': apgar,
      'peso_nascimento': pesoNascimento,
      'altura_nascimento': alturaNascimento,
      'parto_intercorrencias': partoIntercorrencias,
      'amamentacao': amamentacao,
      'controle_cervical': controleCervical,
      'sentar_sem_apoio': sentarSemApoio,
      'engatinhar': engatinhar,
      'andar': andar,
      'primeiras_palavras': primeirasPalavras,
      'comportamento_verbal': comportamentoVerbal,
      'motor_amplo': motorAmplo,
      'motor_fino': motorFino,
      'frequenta_escola': frequentaEscola == true ? 1 : 0,
      'escola_nome': escolaNome,
      'escola_turno': escolaTurno,
      'escola_ano': escolaAno,
      'escola_professora': escolaProfessora,
      'escola_comportamento': escolaComportamento,
      'banheiro': banheiro,
      'banho': banho,
      'escovar_dentes': escovarDentes,
      'vestir': vestir,
      'lavar_maos': lavarMaos,
      'alimentacao': alimentacao,
      'degluticao': degluticao,
      'restricoes_alimentares': restricoesAlimentares,
      'habitos_alimentares': habitosAlimentares,
      'sono': sono,
      'chupeta': chupeta == true ? 1 : 0,
      'mamadeira': mamadeira == true ? 1 : 0,
      'sensorial_tatil': sensorialTatil,
      'sensorial_auditiva': sensorialAuditiva,
      'sensorial_olfativa': sensorialOlfativa,
      'sensorial_visual': sensorialVisual,
      'brincar_preferencias': brincarPreferencias,
      'medos': medos,
      'socializacao': socializacao,
      'queixas': queixas,
      'comportamentos_inadequados': comportamentosInadequados,
      'observacoes': observacoes,
      'status': status ?? 'rascunho',
      'data_avaliacao': dataAvaliacao,
      'psicologo_id': psicologoId,
    };
  }

  factory Anamnese.fromMap(Map<String, dynamic> map) {
    return Anamnese(
      id: map['id'] as int?,
      aplicador: map['aplicador'] as String?,
      pacienteNome: map['paciente_nome'] as String? ?? map['pacienteNome'] as String?,
      pacienteNascimento: map['paciente_nascimento'] as String? ?? map['pacienteNascimento'] as String?,
      responsaveis: (map['responsaveis'] as String?)?.split(',').where((e) => e.isNotEmpty).toList(),
      cidade: map['cidade'] as String?,
      telefone: map['telefone'] as String?,
      cuidadores: (map['cuidadores'] as String?)?.split(',').where((e) => e.isNotEmpty).toList(),
      composicaoFamiliar: map['composicao_familiar'] as String?,
      pessoasAutorizadas: (map['pessoas_autorizadas'] as String?)?.split(',').where((e) => e.isNotEmpty).toList(),
      medicoResponsavel: map['medico_responsavel'] as String?,
      medicoAssistente: map['medico_assistente'] as String?,
      diagnosticoMedico: map['diagnostico_medico'] as String?,
      medicamentos: (map['medicamentos'] as String?)?.split(',').where((e) => e.isNotEmpty).toList(),
      alergias: map['alergias'] as String?,
      audicaoExame: map['audicao_exame'] as String?,
      audicaoPercepcao: map['audicao_percepcao'] as String?,
      otitesHistorico: map['otites_historico'] as String?,
      gestacaoPlanejada: (map['gestacao_planejada'] as int? ?? 0) == 1,
      gestacaoIntercorrencias: map['gestacao_intercorrencias'] as String?,
      semanasGestacao: map['semanas_gestacao'] as int?,
      tipoParto: map['tipo_parto'] as String?,
      apgar: map['apgar'] as String?,
      pesoNascimento: map['peso_nascimento'] as String?,
      alturaNascimento: map['altura_nascimento'] as String?,
      partoIntercorrencias: map['parto_intercorrencias'] as String?,
      amamentacao: map['amamentacao'] as String?,
      controleCervical: map['controle_cervical'] as String?,
      sentarSemApoio: map['sentar_sem_apoio'] as String?,
      engatinhar: map['engatinhar'] as String?,
      andar: map['andar'] as String?,
      primeirasPalavras: map['primeiras_palavras'] as String?,
      comportamentoVerbal: map['comportamento_verbal'] as String?,
      motorAmplo: map['motor_amplo'] as String?,
      motorFino: map['motor_fino'] as String?,
      frequentaEscola: (map['frequenta_escola'] as int? ?? 0) == 1,
      escolaNome: map['escola_nome'] as String?,
      escolaTurno: map['escola_turno'] as String?,
      escolaAno: map['escola_ano'] as String?,
      escolaProfessora: map['escola_professora'] as String?,
      escolaComportamento: map['escola_comportamento'] as String?,
      banheiro: map['banheiro'] as String?,
      banho: map['banho'] as String?,
      escovarDentes: map['escovar_dentes'] as String?,
      vestir: map['vestir'] as String?,
      lavarMaos: map['lavar_maos'] as String?,
      alimentacao: map['alimentacao'] as String?,
      degluticao: map['degluticao'] as String?,
      restricoesAlimentares: map['restricoes_alimentares'] as String?,
      habitosAlimentares: map['habitos_alimentares'] as String?,
      sono: map['sono'] as String?,
      chupeta: (map['chupeta'] as int? ?? 0) == 1,
      mamadeira: (map['mamadeira'] as int? ?? 0) == 1,
      sensorialTatil: map['sensorial_tatil'] as String?,
      sensorialAuditiva: map['sensorial_auditiva'] as String?,
      sensorialOlfativa: map['sensorial_olfativa'] as String?,
      sensorialVisual: map['sensorial_visual'] as String?,
      brincarPreferencias: map['brincar_preferencias'] as String?,
      medos: map['medos'] as String?,
      socializacao: map['socializacao'] as String?,
      queixas: map['queixas'] as String?,
      comportamentosInadequados: map['comportamentos_inadequados'] as String?,
      observacoes: map['observacoes'] as String?,
      status: map['status'] as String? ?? 'rascunho',
      dataAvaliacao: map['data_avaliacao'] as String? ?? map['dataAvaliacao'] as String?,
      psicologoId: map['psicologo_id'] as int? ?? map['psicologoId'] as int?,
    );
  }
}

