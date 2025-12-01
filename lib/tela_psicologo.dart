import 'package:flutter/material.dart';
import 'package:trabalhofinal/Models/Anamnese.dart';
import 'package:trabalhofinal/tela_anamnese.dart';
import 'package:trabalhofinal/tela_mchat.dart';
import 'package:trabalhofinal/tela_relatorio_anamnese.dart';
import 'package:trabalhofinal/Services/ApiService.dart';

const Color primaryColor = Color(0xFF1976D2);

class TelaPsicologo extends StatefulWidget {
  final int userId;

  const TelaPsicologo({
    super.key,
    required this.userId,
  });

  @override
  State<TelaPsicologo> createState() => _TelaPsicologoState();
}

class _TelaPsicologoState extends State<TelaPsicologo> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<Anamnese> _assessments = [];
  bool _isLoading = true;
  int? _selectedAssessmentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAssessments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAssessments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final assessments = await _apiService.getAllAssessments();
      setState(() {
        _assessments = assessments;
        if (_assessments.isNotEmpty && _selectedAssessmentId == null) {
          _selectedAssessmentId = _assessments.first.id;
        }
      });
    } catch (e) {
      debugPrint('Erro ao carregar avaliações: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar avaliações: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _criarNovaAvaliacao() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaAnamnese(
          userId: widget.userId,
          onSave: () {
            _loadAssessments();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Psicólogo', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Anamnese', icon: Icon(Icons.description)),
            Tab(text: 'M-CHAT', icon: Icon(Icons.quiz)),
            Tab(text: 'Relatório', icon: Icon(Icons.assessment)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _criarNovaAvaliacao,
            tooltip: 'Nova Avaliação',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Aba Anamnese
                _buildAnamneseTab(),
                // Aba M-CHAT
                _buildMCHATTab(),
                // Aba Relatório
                _buildRelatorioTab(),
              ],
            ),
    );
  }

  Widget _buildAnamneseTab() {
    if (_assessments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Nenhuma avaliação encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _criarNovaAvaliacao,
              icon: const Icon(Icons.add),
              label: const Text('Criar Nova Avaliação'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _assessments.length,
      itemBuilder: (context, index) {
        final assessment = _assessments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: assessment.status == 'final' ? Colors.green : Colors.orange,
              child: Icon(
                assessment.status == 'final' ? Icons.check : Icons.edit,
                color: Colors.white,
              ),
            ),
            title: Text(assessment.pacienteNome ?? 'Sem nome'),
            subtitle: Text(
              '${assessment.dataAvaliacao ?? "Sem data"} - ${assessment.status == 'final' ? 'Finalizada' : 'Rascunho'}',
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'finalize',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(width: 8),
                      Text('Finalizar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaAnamnese(
                        userId: widget.userId,
                        anamnese: assessment,
                        onSave: () {
                          _loadAssessments();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                } else if (value == 'finalize') {
                  _finalizarAvaliacao(assessment);
                } else if (value == 'delete') {
                  _excluirAvaliacao(assessment);
                }
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TelaAnamnese(
                    userId: widget.userId,
                    anamnese: assessment,
                    onSave: () {
                      _loadAssessments();
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMCHATTab() {
    if (_assessments.isEmpty) {
      return const Center(
        child: Text('Crie uma avaliação primeiro na aba Anamnese'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione uma avaliação:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _selectedAssessmentId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Avaliação',
            ),
            items: _assessments.map((assessment) {
              return DropdownMenuItem(
                value: assessment.id,
                child: Text('${assessment.pacienteNome ?? "Sem nome"} - ${assessment.dataAvaliacao ?? ""}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAssessmentId = value;
              });
            },
          ),
          const SizedBox(height: 20),
          if (_selectedAssessmentId != null)
            Expanded(
              child: TelaMCHAT(
                assessmentId: _selectedAssessmentId!,
                userId: widget.userId,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRelatorioTab() {
    if (_assessments.isEmpty) {
      return const Center(
        child: Text('Crie uma avaliação primeiro na aba Anamnese'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione uma avaliação:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _selectedAssessmentId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Avaliação',
            ),
            items: _assessments.map((assessment) {
              return DropdownMenuItem(
                value: assessment.id,
                child: Text('${assessment.pacienteNome ?? "Sem nome"} - ${assessment.dataAvaliacao ?? ""}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAssessmentId = value;
              });
            },
          ),
          const SizedBox(height: 20),
          if (_selectedAssessmentId != null)
            Expanded(
              child: TelaRelatorioAnamnese(
                assessmentId: _selectedAssessmentId!,
                userId: widget.userId,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _finalizarAvaliacao(Anamnese assessment) async {
    try {
      final updated = Anamnese(
        id: assessment.id,
        aplicador: assessment.aplicador,
        pacienteNome: assessment.pacienteNome,
        pacienteNascimento: assessment.pacienteNascimento,
        status: 'final',
        psicologoId: assessment.psicologoId,
        dataAvaliacao: assessment.dataAvaliacao,
      );
      await _apiService.updateAssessment(assessment.id!, updated);
      _loadAssessments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação finalizada com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar: $e')),
      );
    }
  }

  Future<void> _excluirAvaliacao(Anamnese assessment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta avaliação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Em produção, chamaria _apiService.deleteAssessment(assessment.id!)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidade de exclusão em desenvolvimento')),
      );
    }
  }
}

