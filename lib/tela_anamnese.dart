import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trabalhofinal/Models/Anamnese.dart';
import 'package:trabalhofinal/Services/ApiService.dart';

const Color primaryColor = Color(0xFF1976D2);

class TelaAnamnese extends StatefulWidget {
  final int userId;
  final Anamnese? anamnese;
  final VoidCallback onSave;

  const TelaAnamnese({
    super.key,
    required this.userId,
    this.anamnese,
    required this.onSave,
  });

  @override
  State<TelaAnamnese> createState() => _TelaAnamneseState();
}

class _TelaAnamneseState extends State<TelaAnamnese> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isSaving = false;

  // Controllers para todos os campos
  late TextEditingController _aplicadorController;
  late TextEditingController _pacienteNomeController;
  late TextEditingController _pacienteNascimentoController;
  late TextEditingController _responsaveisController;
  late TextEditingController _cidadeController;
  late TextEditingController _telefoneController;
  late TextEditingController _cuidadoresController;
  late TextEditingController _composicaoFamiliarController;
  late TextEditingController _pessoasAutorizadasController;

  // Médico
  late TextEditingController _medicoResponsavelController;
  late TextEditingController _medicoAssistenteController;
  late TextEditingController _diagnosticoController;
  late TextEditingController _medicamentosController;
  late TextEditingController _alergiasController;
  late TextEditingController _audicaoExameController;
  late TextEditingController _audicaoPercepcaoController;
  late TextEditingController _otitesController;

  // Gestação
  bool _gestacaoPlanejada = false;
  late TextEditingController _gestacaoIntercorrenciasController;
  late TextEditingController _semanasGestacaoController;
  late TextEditingController _tipoPartoController;
  late TextEditingController _apgarController;
  late TextEditingController _pesoController;
  late TextEditingController _alturaController;
  late TextEditingController _partoIntercorrenciasController;
  late TextEditingController _amamentacaoController;

  // DNPM
  late TextEditingController _controleCervicalController;
  late TextEditingController _sentarController;
  late TextEditingController _engatinharController;
  late TextEditingController _andarController;
  late TextEditingController _primeirasPalavrasController;
  late TextEditingController _comportamentoVerbalController;
  late TextEditingController _motorAmploController;
  late TextEditingController _motorFinoController;

  // Escola
  bool _frequentaEscola = false;
  late TextEditingController _escolaNomeController;
  late TextEditingController _escolaTurnoController;
  late TextEditingController _escolaAnoController;
  late TextEditingController _escolaProfessoraController;
  late TextEditingController _escolaComportamentoController;

  // AVD
  late TextEditingController _banheiroController;
  late TextEditingController _banhoController;
  late TextEditingController _escovarDentesController;
  late TextEditingController _vestirController;
  late TextEditingController _lavarMaosController;
  late TextEditingController _alimentacaoController;
  late TextEditingController _degluticaoController;
  late TextEditingController _restricoesController;
  late TextEditingController _habitosController;
  late TextEditingController _sonoController;
  bool _chupeta = false;
  bool _mamadeira = false;

  // Sensorial
  late TextEditingController _sensorialTatilController;
  late TextEditingController _sensorialAuditivaController;
  late TextEditingController _sensorialOlfativaController;
  late TextEditingController _sensorialVisualController;

  // Outros
  late TextEditingController _brincarController;
  late TextEditingController _medosController;
  late TextEditingController _socializacaoController;
  late TextEditingController _queixasController;
  late TextEditingController _comportamentosController;
  late TextEditingController _observacoesController;

  String _status = 'rascunho';
  String? _dataAvaliacao;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.anamnese != null) {
      _loadAnamneseData();
    } else {
      _dataAvaliacao = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _aplicadorController.text = 'Dr(a). ${widget.userId}'; // Em produção, pegaria do usuário logado
    }
  }

  void _initializeControllers() {
    _aplicadorController = TextEditingController();
    _pacienteNomeController = TextEditingController();
    _pacienteNascimentoController = TextEditingController();
    _responsaveisController = TextEditingController();
    _cidadeController = TextEditingController();
    _telefoneController = TextEditingController();
    _cuidadoresController = TextEditingController();
    _composicaoFamiliarController = TextEditingController();
    _pessoasAutorizadasController = TextEditingController();
    _medicoResponsavelController = TextEditingController();
    _medicoAssistenteController = TextEditingController();
    _diagnosticoController = TextEditingController();
    _medicamentosController = TextEditingController();
    _alergiasController = TextEditingController();
    _audicaoExameController = TextEditingController();
    _audicaoPercepcaoController = TextEditingController();
    _otitesController = TextEditingController();
    _gestacaoIntercorrenciasController = TextEditingController();
    _semanasGestacaoController = TextEditingController();
    _tipoPartoController = TextEditingController();
    _apgarController = TextEditingController();
    _pesoController = TextEditingController();
    _alturaController = TextEditingController();
    _partoIntercorrenciasController = TextEditingController();
    _amamentacaoController = TextEditingController();
    _controleCervicalController = TextEditingController();
    _sentarController = TextEditingController();
    _engatinharController = TextEditingController();
    _andarController = TextEditingController();
    _primeirasPalavrasController = TextEditingController();
    _comportamentoVerbalController = TextEditingController();
    _motorAmploController = TextEditingController();
    _motorFinoController = TextEditingController();
    _escolaNomeController = TextEditingController();
    _escolaTurnoController = TextEditingController();
    _escolaAnoController = TextEditingController();
    _escolaProfessoraController = TextEditingController();
    _escolaComportamentoController = TextEditingController();
    _banheiroController = TextEditingController();
    _banhoController = TextEditingController();
    _escovarDentesController = TextEditingController();
    _vestirController = TextEditingController();
    _lavarMaosController = TextEditingController();
    _alimentacaoController = TextEditingController();
    _degluticaoController = TextEditingController();
    _restricoesController = TextEditingController();
    _habitosController = TextEditingController();
    _sonoController = TextEditingController();
    _sensorialTatilController = TextEditingController();
    _sensorialAuditivaController = TextEditingController();
    _sensorialOlfativaController = TextEditingController();
    _sensorialVisualController = TextEditingController();
    _brincarController = TextEditingController();
    _medosController = TextEditingController();
    _socializacaoController = TextEditingController();
    _queixasController = TextEditingController();
    _comportamentosController = TextEditingController();
    _observacoesController = TextEditingController();
  }

  void _loadAnamneseData() {
    final anamnese = widget.anamnese!;
    _aplicadorController.text = anamnese.aplicador ?? '';
    _pacienteNomeController.text = anamnese.pacienteNome ?? '';
    _pacienteNascimentoController.text = anamnese.pacienteNascimento ?? '';
    _responsaveisController.text = anamnese.responsaveis?.join(', ') ?? '';
    _cidadeController.text = anamnese.cidade ?? '';
    _telefoneController.text = anamnese.telefone ?? '';
    _cuidadoresController.text = anamnese.cuidadores?.join(', ') ?? '';
    _composicaoFamiliarController.text = anamnese.composicaoFamiliar ?? '';
    _pessoasAutorizadasController.text = anamnese.pessoasAutorizadas?.join(', ') ?? '';
    _medicoResponsavelController.text = anamnese.medicoResponsavel ?? '';
    _medicoAssistenteController.text = anamnese.medicoAssistente ?? '';
    _diagnosticoController.text = anamnese.diagnosticoMedico ?? '';
    _medicamentosController.text = anamnese.medicamentos?.join(', ') ?? '';
    _alergiasController.text = anamnese.alergias ?? '';
    _audicaoExameController.text = anamnese.audicaoExame ?? '';
    _audicaoPercepcaoController.text = anamnese.audicaoPercepcao ?? '';
    _otitesController.text = anamnese.otitesHistorico ?? '';
    _gestacaoPlanejada = anamnese.gestacaoPlanejada ?? false;
    _gestacaoIntercorrenciasController.text = anamnese.gestacaoIntercorrencias ?? '';
    _semanasGestacaoController.text = anamnese.semanasGestacao?.toString() ?? '';
    _tipoPartoController.text = anamnese.tipoParto ?? '';
    _apgarController.text = anamnese.apgar ?? '';
    _pesoController.text = anamnese.pesoNascimento ?? '';
    _alturaController.text = anamnese.alturaNascimento ?? '';
    _partoIntercorrenciasController.text = anamnese.partoIntercorrencias ?? '';
    _amamentacaoController.text = anamnese.amamentacao ?? '';
    _controleCervicalController.text = anamnese.controleCervical ?? '';
    _sentarController.text = anamnese.sentarSemApoio ?? '';
    _engatinharController.text = anamnese.engatinhar ?? '';
    _andarController.text = anamnese.andar ?? '';
    _primeirasPalavrasController.text = anamnese.primeirasPalavras ?? '';
    _comportamentoVerbalController.text = anamnese.comportamentoVerbal ?? '';
    _motorAmploController.text = anamnese.motorAmplo ?? '';
    _motorFinoController.text = anamnese.motorFino ?? '';
    _frequentaEscola = anamnese.frequentaEscola ?? false;
    _escolaNomeController.text = anamnese.escolaNome ?? '';
    _escolaTurnoController.text = anamnese.escolaTurno ?? '';
    _escolaAnoController.text = anamnese.escolaAno ?? '';
    _escolaProfessoraController.text = anamnese.escolaProfessora ?? '';
    _escolaComportamentoController.text = anamnese.escolaComportamento ?? '';
    _banheiroController.text = anamnese.banheiro ?? '';
    _banhoController.text = anamnese.banho ?? '';
    _escovarDentesController.text = anamnese.escovarDentes ?? '';
    _vestirController.text = anamnese.vestir ?? '';
    _lavarMaosController.text = anamnese.lavarMaos ?? '';
    _alimentacaoController.text = anamnese.alimentacao ?? '';
    _degluticaoController.text = anamnese.degluticao ?? '';
    _restricoesController.text = anamnese.restricoesAlimentares ?? '';
    _habitosController.text = anamnese.habitosAlimentares ?? '';
    _sonoController.text = anamnese.sono ?? '';
    _chupeta = anamnese.chupeta ?? false;
    _mamadeira = anamnese.mamadeira ?? false;
    _sensorialTatilController.text = anamnese.sensorialTatil ?? '';
    _sensorialAuditivaController.text = anamnese.sensorialAuditiva ?? '';
    _sensorialOlfativaController.text = anamnese.sensorialOlfativa ?? '';
    _sensorialVisualController.text = anamnese.sensorialVisual ?? '';
    _brincarController.text = anamnese.brincarPreferencias ?? '';
    _medosController.text = anamnese.medos ?? '';
    _socializacaoController.text = anamnese.socializacao ?? '';
    _queixasController.text = anamnese.queixas ?? '';
    _comportamentosController.text = anamnese.comportamentosInadequados ?? '';
    _observacoesController.text = anamnese.observacoes ?? '';
    _status = anamnese.status ?? 'rascunho';
    _dataAvaliacao = anamnese.dataAvaliacao;
  }

  @override
  void dispose() {
    _aplicadorController.dispose();
    _pacienteNomeController.dispose();
    _pacienteNascimentoController.dispose();
    _responsaveisController.dispose();
    _cidadeController.dispose();
    _telefoneController.dispose();
    _cuidadoresController.dispose();
    _composicaoFamiliarController.dispose();
    _pessoasAutorizadasController.dispose();
    _medicoResponsavelController.dispose();
    _medicoAssistenteController.dispose();
    _diagnosticoController.dispose();
    _medicamentosController.dispose();
    _alergiasController.dispose();
    _audicaoExameController.dispose();
    _audicaoPercepcaoController.dispose();
    _otitesController.dispose();
    _gestacaoIntercorrenciasController.dispose();
    _semanasGestacaoController.dispose();
    _tipoPartoController.dispose();
    _apgarController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _partoIntercorrenciasController.dispose();
    _amamentacaoController.dispose();
    _controleCervicalController.dispose();
    _sentarController.dispose();
    _engatinharController.dispose();
    _andarController.dispose();
    _primeirasPalavrasController.dispose();
    _comportamentoVerbalController.dispose();
    _motorAmploController.dispose();
    _motorFinoController.dispose();
    _escolaNomeController.dispose();
    _escolaTurnoController.dispose();
    _escolaAnoController.dispose();
    _escolaProfessoraController.dispose();
    _escolaComportamentoController.dispose();
    _banheiroController.dispose();
    _banhoController.dispose();
    _escovarDentesController.dispose();
    _vestirController.dispose();
    _lavarMaosController.dispose();
    _alimentacaoController.dispose();
    _degluticaoController.dispose();
    _restricoesController.dispose();
    _habitosController.dispose();
    _sonoController.dispose();
    _sensorialTatilController.dispose();
    _sensorialAuditivaController.dispose();
    _sensorialOlfativaController.dispose();
    _sensorialVisualController.dispose();
    _brincarController.dispose();
    _medosController.dispose();
    _socializacaoController.dispose();
    _queixasController.dispose();
    _comportamentosController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Anamnese _buildAnamneseFromForm() {
    return Anamnese(
      id: widget.anamnese?.id,
      aplicador: _aplicadorController.text,
      pacienteNome: _pacienteNomeController.text,
      pacienteNascimento: _pacienteNascimentoController.text,
      responsaveis: _responsaveisController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      cidade: _cidadeController.text,
      telefone: _telefoneController.text,
      cuidadores: _cuidadoresController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      composicaoFamiliar: _composicaoFamiliarController.text,
      pessoasAutorizadas: _pessoasAutorizadasController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      medicoResponsavel: _medicoResponsavelController.text,
      medicoAssistente: _medicoAssistenteController.text,
      diagnosticoMedico: _diagnosticoController.text,
      medicamentos: _medicamentosController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      alergias: _alergiasController.text,
      audicaoExame: _audicaoExameController.text,
      audicaoPercepcao: _audicaoPercepcaoController.text,
      otitesHistorico: _otitesController.text,
      gestacaoPlanejada: _gestacaoPlanejada,
      gestacaoIntercorrencias: _gestacaoIntercorrenciasController.text,
      semanasGestacao: int.tryParse(_semanasGestacaoController.text),
      tipoParto: _tipoPartoController.text,
      apgar: _apgarController.text,
      pesoNascimento: _pesoController.text,
      alturaNascimento: _alturaController.text,
      partoIntercorrencias: _partoIntercorrenciasController.text,
      amamentacao: _amamentacaoController.text,
      controleCervical: _controleCervicalController.text,
      sentarSemApoio: _sentarController.text,
      engatinhar: _engatinharController.text,
      andar: _andarController.text,
      primeirasPalavras: _primeirasPalavrasController.text,
      comportamentoVerbal: _comportamentoVerbalController.text,
      motorAmplo: _motorAmploController.text,
      motorFino: _motorFinoController.text,
      frequentaEscola: _frequentaEscola,
      escolaNome: _escolaNomeController.text,
      escolaTurno: _escolaTurnoController.text,
      escolaAno: _escolaAnoController.text,
      escolaProfessora: _escolaProfessoraController.text,
      escolaComportamento: _escolaComportamentoController.text,
      banheiro: _banheiroController.text,
      banho: _banhoController.text,
      escovarDentes: _escovarDentesController.text,
      vestir: _vestirController.text,
      lavarMaos: _lavarMaosController.text,
      alimentacao: _alimentacaoController.text,
      degluticao: _degluticaoController.text,
      restricoesAlimentares: _restricoesController.text,
      habitosAlimentares: _habitosController.text,
      sono: _sonoController.text,
      chupeta: _chupeta,
      mamadeira: _mamadeira,
      sensorialTatil: _sensorialTatilController.text,
      sensorialAuditiva: _sensorialAuditivaController.text,
      sensorialOlfativa: _sensorialOlfativaController.text,
      sensorialVisual: _sensorialVisualController.text,
      brincarPreferencias: _brincarController.text,
      medos: _medosController.text,
      socializacao: _socializacaoController.text,
      queixas: _queixasController.text,
      comportamentosInadequados: _comportamentosController.text,
      observacoes: _observacoesController.text,
      status: _status,
      dataAvaliacao: _dataAvaliacao ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      psicologoId: widget.userId,
    );
  }

  Future<void> _salvarRascunho() async {
    setState(() {
      _isSaving = true;
      _status = 'rascunho';
    });

    try {
      final anamnese = _buildAnamneseFromForm();
      if (widget.anamnese?.id != null) {
        await _apiService.updateAssessment(widget.anamnese!.id!, anamnese);
      } else {
        await _apiService.createAssessment(anamnese);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rascunho salvo com sucesso')),
      );
      widget.onSave();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _finalizar() async {
    setState(() {
      _isSaving = true;
      _status = 'final';
    });

    try {
      final anamnese = _buildAnamneseFromForm();
      if (widget.anamnese?.id != null) {
        await _apiService.updateAssessment(widget.anamnese!.id!, anamnese);
      } else {
        await _apiService.createAssessment(anamnese);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação finalizada com sucesso')),
      );
      widget.onSave();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.anamnese == null ? 'Nova Anamnese' : 'Editar Anamnese', style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _salvarRascunho,
              child: const Text('Salvar Rascunho', style: TextStyle(color: Colors.white)),
            ),
          if (!_isSaving)
            ElevatedButton(
              onPressed: _finalizar,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Identificação
              _buildSection('1. Identificação', [
                TextFormField(controller: _aplicadorController, decoration: const InputDecoration(labelText: 'Aplicador'), enabled: false),
                TextFormField(controller: _pacienteNomeController, decoration: const InputDecoration(labelText: 'Nome do Paciente *')),
                TextFormField(controller: _pacienteNascimentoController, decoration: const InputDecoration(labelText: 'Data de Nascimento'), keyboardType: TextInputType.datetime),
                TextFormField(controller: _responsaveisController, decoration: const InputDecoration(labelText: 'Responsáveis (separar por vírgula)'), maxLines: 2),
                TextFormField(controller: _cidadeController, decoration: const InputDecoration(labelText: 'Cidade')),
                TextFormField(controller: _telefoneController, decoration: const InputDecoration(labelText: 'Telefone'), keyboardType: TextInputType.phone),
                TextFormField(controller: _cuidadoresController, decoration: const InputDecoration(labelText: 'Cuidadores (separar por vírgula)'), maxLines: 2),
                TextFormField(controller: _composicaoFamiliarController, decoration: const InputDecoration(labelText: 'Composição Familiar'), maxLines: 2),
                TextFormField(controller: _pessoasAutorizadasController, decoration: const InputDecoration(labelText: 'Pessoas Autorizadas a Buscar'), maxLines: 2),
              ]),

              // Médico
              _buildSection('2. Médico', [
                TextFormField(controller: _medicoResponsavelController, decoration: const InputDecoration(labelText: 'Médico Responsável')),
                TextFormField(controller: _medicoAssistenteController, decoration: const InputDecoration(labelText: 'Médico Assistente')),
                TextFormField(controller: _diagnosticoController, decoration: const InputDecoration(labelText: 'Diagnóstico Médico'), maxLines: 3),
                TextFormField(controller: _medicamentosController, decoration: const InputDecoration(labelText: 'Medicamentos (separar por vírgula)'), maxLines: 2),
                TextFormField(controller: _alergiasController, decoration: const InputDecoration(labelText: 'Alergias')),
                TextFormField(controller: _audicaoExameController, decoration: const InputDecoration(labelText: 'Exame de Audição Recente')),
                TextFormField(controller: _audicaoPercepcaoController, decoration: const InputDecoration(labelText: 'Percepção dos Pais sobre Audição'), maxLines: 2),
                TextFormField(controller: _otitesController, decoration: const InputDecoration(labelText: 'Histórico de Otites'), maxLines: 2),
              ]),

              // Gestação/Parto/Puerpério
              _buildSection('3. Gestação, Parto e Puerpério', [
                SwitchListTile(title: const Text('Gestação Planejada'), value: _gestacaoPlanejada, onChanged: (v) => setState(() => _gestacaoPlanejada = v)),
                TextFormField(controller: _gestacaoIntercorrenciasController, decoration: const InputDecoration(labelText: 'Intercorrências na Gestação'), maxLines: 2),
                TextFormField(controller: _semanasGestacaoController, decoration: const InputDecoration(labelText: 'Semanas de Gestação'), keyboardType: TextInputType.number),
                TextFormField(controller: _tipoPartoController, decoration: const InputDecoration(labelText: 'Tipo de Parto')),
                TextFormField(controller: _apgarController, decoration: const InputDecoration(labelText: 'Apgar')),
                TextFormField(controller: _pesoController, decoration: const InputDecoration(labelText: 'Peso ao Nascer')),
                TextFormField(controller: _alturaController, decoration: const InputDecoration(labelText: 'Altura ao Nascer')),
                TextFormField(controller: _partoIntercorrenciasController, decoration: const InputDecoration(labelText: 'Intercorrências no Parto'), maxLines: 2),
                TextFormField(controller: _amamentacaoController, decoration: const InputDecoration(labelText: 'Amamentação'), maxLines: 2),
              ]),

              // DNPM
              _buildSection('4. DNPM', [
                TextFormField(controller: _controleCervicalController, decoration: const InputDecoration(labelText: 'Controle Cervical')),
                TextFormField(controller: _sentarController, decoration: const InputDecoration(labelText: 'Sentar sem Apoio')),
                TextFormField(controller: _engatinharController, decoration: const InputDecoration(labelText: 'Engatinhar')),
                TextFormField(controller: _andarController, decoration: const InputDecoration(labelText: 'Andar')),
                TextFormField(controller: _primeirasPalavrasController, decoration: const InputDecoration(labelText: 'Primeiras Palavras')),
                TextFormField(controller: _comportamentoVerbalController, decoration: const InputDecoration(labelText: 'Comportamento Verbal'), maxLines: 2),
                TextFormField(controller: _motorAmploController, decoration: const InputDecoration(labelText: 'Motor Amplo'), maxLines: 2),
                TextFormField(controller: _motorFinoController, decoration: const InputDecoration(labelText: 'Motor Fino'), maxLines: 2),
              ]),

              // Escola
              _buildSection('5. Escola', [
                SwitchListTile(title: const Text('Frequenta Escola'), value: _frequentaEscola, onChanged: (v) => setState(() => _frequentaEscola = v)),
                if (_frequentaEscola) ...[
                  TextFormField(controller: _escolaNomeController, decoration: const InputDecoration(labelText: 'Nome da Escola')),
                  TextFormField(controller: _escolaTurnoController, decoration: const InputDecoration(labelText: 'Turno')),
                  TextFormField(controller: _escolaAnoController, decoration: const InputDecoration(labelText: 'Ano')),
                  TextFormField(controller: _escolaProfessoraController, decoration: const InputDecoration(labelText: 'Nome da Professora')),
                  TextFormField(controller: _escolaComportamentoController, decoration: const InputDecoration(labelText: 'Comportamento na Escola'), maxLines: 3),
                ],
              ]),

              // Autocuidado/AVD
              _buildSection('6. Autocuidado e AVD', [
                TextFormField(controller: _banheiroController, decoration: const InputDecoration(labelText: 'Controle de Esfíncter e Uso do Banheiro'), maxLines: 2),
                TextFormField(controller: _banhoController, decoration: const InputDecoration(labelText: 'Banho'), maxLines: 2),
                TextFormField(controller: _escovarDentesController, decoration: const InputDecoration(labelText: 'Escovar os Dentes'), maxLines: 2),
                TextFormField(controller: _vestirController, decoration: const InputDecoration(labelText: 'Vestir-se e Despir-se'), maxLines: 2),
                TextFormField(controller: _lavarMaosController, decoration: const InputDecoration(labelText: 'Lavar as Mãos'), maxLines: 2),
                TextFormField(controller: _alimentacaoController, decoration: const InputDecoration(labelText: 'Alimentação'), maxLines: 2),
                TextFormField(controller: _degluticaoController, decoration: const InputDecoration(labelText: 'Dificuldade para Engolir'), maxLines: 2),
                TextFormField(controller: _restricoesController, decoration: const InputDecoration(labelText: 'Restrições Alimentares'), maxLines: 2),
                TextFormField(controller: _habitosController, decoration: const InputDecoration(labelText: 'Hábitos Alimentares'), maxLines: 2),
                TextFormField(controller: _sonoController, decoration: const InputDecoration(labelText: 'Sono'), maxLines: 2),
                SwitchListTile(title: const Text('Usa Chupeta'), value: _chupeta, onChanged: (v) => setState(() => _chupeta = v)),
                SwitchListTile(title: const Text('Usa Mamadeira'), value: _mamadeira, onChanged: (v) => setState(() => _mamadeira = v)),
              ]),

              // Sensorial
              _buildSection('7. Sensorial', [
                TextFormField(controller: _sensorialTatilController, decoration: const InputDecoration(labelText: 'Tátil'), maxLines: 2),
                TextFormField(controller: _sensorialAuditivaController, decoration: const InputDecoration(labelText: 'Auditiva'), maxLines: 2),
                TextFormField(controller: _sensorialOlfativaController, decoration: const InputDecoration(labelText: 'Olfativa'), maxLines: 2),
                TextFormField(controller: _sensorialVisualController, decoration: const InputDecoration(labelText: 'Visual'), maxLines: 2),
              ]),

              // Outros
              _buildSection('8. Outros', [
                TextFormField(controller: _brincarController, decoration: const InputDecoration(labelText: 'Brincar/Preferências/Reforçadores'), maxLines: 3),
                TextFormField(controller: _medosController, decoration: const InputDecoration(labelText: 'Medos'), maxLines: 2),
                TextFormField(controller: _socializacaoController, decoration: const InputDecoration(labelText: 'Socialização'), maxLines: 3),
                TextFormField(controller: _queixasController, decoration: const InputDecoration(labelText: 'Queixas'), maxLines: 3),
                TextFormField(controller: _comportamentosController, decoration: const InputDecoration(labelText: 'Comportamentos Inadequados'), maxLines: 3),
                TextFormField(controller: _observacoesController, decoration: const InputDecoration(labelText: 'Demais Observações'), maxLines: 5),
              ]),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

