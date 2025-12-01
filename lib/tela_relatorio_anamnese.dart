import 'package:flutter/material.dart';
import 'package:trabalhofinal/Services/ApiService.dart';
import 'package:trabalhofinal/Models/Anamnese.dart';
import 'package:trabalhofinal/Models/MChat.dart';

const Color primaryColor = Color(0xFF1976D2);

class TelaRelatorioAnamnese extends StatefulWidget {
  final int assessmentId;
  final int userId;

  const TelaRelatorioAnamnese({
    super.key,
    required this.assessmentId,
    required this.userId,
  });

  @override
  State<TelaRelatorioAnamnese> createState() => _TelaRelatorioAnamneseState();
}

class _TelaRelatorioAnamneseState extends State<TelaRelatorioAnamnese> {
  final ApiService _apiService = ApiService();
  Anamnese? _anamnese;
  MCHAT? _mchat;
  Map<String, dynamic>? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final anamnese = await _apiService.getAssessment(widget.assessmentId);
      final report = await _apiService.getReport(widget.assessmentId);
      
      MCHAT? mchat;
      try {
        mchat = await _apiService.getMCHAT(widget.assessmentId);
      } catch (e) {
        debugPrint('M-CHAT não encontrado: $e');
      }

      setState(() {
        _anamnese = anamnese;
        _mchat = mchat;
        _report = report;
      });
    } catch (e) {
      debugPrint('Erro ao carregar relatório: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar relatório: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportarPDF() async {
    try {
      final url = await _apiService.exportReport(widget.assessmentId, 'pdf');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF gerado: $url')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar PDF: $e')),
      );
    }
  }

  Future<void> _exportarCSV() async {
    try {
      final url = await _apiService.exportReport(widget.assessmentId, 'csv');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV gerado: $url')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar CSV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Anamnese', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportarPDF,
            tooltip: 'Exportar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportarCSV,
            tooltip: 'Exportar CSV',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_anamnese != null) ...[
                      _buildSection('Identificação', [
                        _buildInfoRow('Paciente', _anamnese!.pacienteNome ?? 'N/A'),
                        _buildInfoRow('Data de Nascimento', _anamnese!.pacienteNascimento ?? 'N/A'),
                        _buildInfoRow('Aplicador', _anamnese!.aplicador ?? 'N/A'),
                        _buildInfoRow('Data da Avaliação', _anamnese!.dataAvaliacao ?? 'N/A'),
                        _buildInfoRow('Status', _anamnese!.status ?? 'N/A'),
                      ]),
                      const SizedBox(height: 20),
                      
                      _buildSection('Responsáveis', [
                        _buildInfoRow('Responsáveis', _anamnese!.responsaveis?.join(', ') ?? 'N/A'),
                        _buildInfoRow('Cidade', _anamnese!.cidade ?? 'N/A'),
                        _buildInfoRow('Telefone', _anamnese!.telefone ?? 'N/A'),
                      ]),
                      const SizedBox(height: 20),
                      
                      if (_anamnese!.medicoResponsavel != null)
                        _buildSection('Médico', [
                          _buildInfoRow('Médico Responsável', _anamnese!.medicoResponsavel ?? 'N/A'),
                          _buildInfoRow('Diagnóstico', _anamnese!.diagnosticoMedico ?? 'N/A'),
                          _buildInfoRow('Medicamentos', _anamnese!.medicamentos?.join(', ') ?? 'N/A'),
                        ]),
                      const SizedBox(height: 20),
                    ],

                    if (_mchat != null) ...[
                      _buildSection('M-CHAT', [
                        _buildInfoRow('Score Total', _mchat!.scoreTotal.toString()),
                        _buildInfoRow('Classificação', _mchat!.classificacao == 'risco' ? 'RISCO' : 'SEM RISCO'),
                        if (_mchat!.itensCriticosMarcados.isNotEmpty)
                          _buildInfoRow('Itens Críticos', _mchat!.itensCriticosMarcados.join(', ')),
                        if (_mchat!.recomendacao != null)
                          _buildInfoRow('Recomendação', _mchat!.recomendacao!),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    if (_report != null)
                      _buildSection('Resumo', [
                        for (var entry in _report!.entries)
                          _buildInfoRow(entry.key.toString(), entry.value.toString()),
                      ]),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

