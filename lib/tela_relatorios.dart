import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:trabalhofinal/BancoDados/DataBaseHelper.dart';
import 'package:trabalhofinal/Models/Diario.dart';

const Color primaryColor = Color(0xFF1976D2);

class TelaRelatorios extends StatefulWidget {
  final int userId;
  final bool isProfessional; // Se true, mostra dados de todos os usuários

  const TelaRelatorios({
    super.key,
    required this.userId,
    this.isProfessional = false,
  });

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  final DataBaseHelper _dbHelper = DataBaseHelper();
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _dataFim = DateTime.now();
  bool _isLoading = true;
  
  // Dados para gráficos
  List<Diario> _diarios = [];
  Map<String, int> _humorStats = {};
  Map<String, int> _sonoStats = {};
  Map<String, int> _criseStats = {};

  @override
  void initState() {
    super.initState();
    _loadRelatorioData();
  }

  Future<void> _loadRelatorioData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await _dbHelper.database;
      
      // Busca diários no período
      final diariosMaps = await db.query(
        'diarios',
        where: widget.isProfessional 
            ? 'data_registro >= ? AND data_registro <= ?'
            : 'pessoa_id = ? AND data_registro >= ? AND data_registro <= ?',
        whereArgs: widget.isProfessional
            ? [_dataInicio.toIso8601String(), _dataFim.toIso8601String()]
            : [widget.userId, _dataInicio.toIso8601String(), _dataFim.toIso8601String()],
        orderBy: 'data_registro ASC',
      );

      _diarios = diariosMaps.map((map) => Diario.fromMap(map)).toList();

      // Calcula estatísticas
      _humorStats = {};
      _sonoStats = {};
      _criseStats = {};

      for (var diario in _diarios) {
        if (diario.humor.isNotEmpty) {
          _humorStats[diario.humor] = (_humorStats[diario.humor] ?? 0) + 1;
        }
        if (diario.sono != null && diario.sono!.isNotEmpty) {
          _sonoStats[diario.sono!] = (_sonoStats[diario.sono!] ?? 0) + 1;
        }
        if (diario.crise != null && diario.crise!.isNotEmpty) {
          _criseStats[diario.crise!] = (_criseStats[diario.crise!] ?? 0) + 1;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados do relatório: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportarCSV() async {
    try {
      final csv = StringBuffer();
      csv.writeln('Data,Humor,Sono,Alimentação,Crise,Observações');
      
      for (var diario in _diarios) {
        final data = diario.dataRegistro.split('T').first;
        csv.writeln('$data,"${diario.humor}","${diario.sono ?? ""}","${diario.alimentacao ?? ""}","${diario.crise ?? ""}","${diario.observacoes ?? ""}"');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV gerado com ${_diarios.length} registros'),
          action: SnackBarAction(
            label: 'Copiar',
            onPressed: () {
              // Copiar para clipboard
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('.')),
      );
    }
  }

  Future<void> _exportarPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportação PDF em desenvolvimento')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isProfessional ? 'Relatórios - Todos os Usuários' : 'Meus Relatórios',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportarCSV,
            tooltip: 'Exportar CSV',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportarPDF,
            tooltip: 'Exportar PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRelatorioData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seletor de Período
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Data Início:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextButton(
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _dataInicio,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _dataInicio = date;
                                        });
                                        _loadRelatorioData();
                                      }
                                    },
                                    child: Text(DateFormat('dd/MM/yyyy').format(_dataInicio)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Data Fim:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextButton(
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _dataFim,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _dataFim = date;
                                        });
                                        _loadRelatorioData();
                                      }
                                    },
                                    child: Text(DateFormat('dd/MM/yyyy').format(_dataFim)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Gráfico de Humor
                    if (_humorStats.isNotEmpty) ...[
                      const Text(
                        'Distribuição de Humor',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _humorStats.entries.map((entry) {
                              final colors = {
                                'Feliz': Colors.green,
                                'Calmo': Colors.blue,
                                'Irritado': Colors.red,
                                'Triste': Colors.grey,
                              };
                              return PieChartSectionData(
                                value: entry.value.toDouble(),
                                title: '${entry.key}\n${entry.value}',
                                color: colors[entry.key] ?? Colors.orange,
                                radius: 80,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Gráfico de Sono
                    if (_sonoStats.isNotEmpty) ...[
                      const Text(
                        'Distribuição de Sono',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            barGroups: _sonoStats.entries.map((entry) {
                              final index = _sonoStats.keys.toList().indexOf(entry.key);
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.toDouble(),
                                    color: Colors.blue,
                                    width: 20,
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < _sonoStats.length) {
                                      return Text(_sonoStats.keys.elementAt(index));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Estatísticas de Crise
                    if (_criseStats.isNotEmpty) ...[
                      const Text(
                        'Registros de Crise',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: _criseStats.entries.map((entry) {
                              return ListTile(
                                title: Text(entry.key),
                                trailing: Text(
                                  '${entry.value}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],

                    if (_diarios.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('Nenhum dado encontrado no período selecionado'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

