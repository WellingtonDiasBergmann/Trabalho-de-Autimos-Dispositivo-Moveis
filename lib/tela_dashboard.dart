import 'package:flutter/material.dart';
import 'package:trabalhofinal/BancoDados/DataBaseHelper.dart';

const Color primaryColor = Color(0xFF1976D2);

class TelaDashboard extends StatefulWidget {
  final int userId;

  const TelaDashboard({
    super.key,
    required this.userId,
  });

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  final DataBaseHelper _dbHelper = DataBaseHelper();
  int _totalRotinas = 0;
  int _totalDiarios = 0;
  int _totalBoards = 0;
  int _totalBoardItems = 0;
  int _totalUsuarios = 0;
  int _rotinasConcluidas = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await _dbHelper.database;
      
      // Carrega TODAS as rotinas (de todos os usuários)
      final rotinasMaps = await db.query('rotinas');
      _totalRotinas = rotinasMaps.length;
      
      // Conta rotinas concluídas (verificando se todos os passos estão concluídos)
      int rotinasCompletas = 0;
      for (var rotinaMap in rotinasMaps) {
        final rotinaId = rotinaMap['id'] as int?;
        if (rotinaId != null) {
          final stepsMaps = await db.query(
            'passos_rotina',
            where: 'rotina_id = ?',
            whereArgs: [rotinaId],
          );
          if (stepsMaps.isNotEmpty) {
            final todosConcluidos = stepsMaps.every((step) => (step['concluido'] as int? ?? 0) == 1);
            if (todosConcluidos) rotinasCompletas++;
          }
        }
      }
      _rotinasConcluidas = rotinasCompletas;
      
      // Carrega TODOS os diários (de todos os usuários)
      final diariosMaps = await db.query('diarios');
      _totalDiarios = diariosMaps.length;
      
      // Carrega TODOS os boards (de todos os usuários)
      final boardsMaps = await db.query('boards');
      _totalBoards = boardsMaps.length;
      
      // Carrega TODOS os board items (de todos os usuários)
      final boardItemsMaps = await db.query('board_items');
      _totalBoardItems = boardItemsMaps.length;
      
      // Carrega TODOS os usuários (exceto profissionais)
      final usuariosMaps = await db.query(
        'pessoas',
        where: 'tipo_usuario != ?',
        whereArgs: [2], // Exclui profissionais (tipo 2)
      );
      _totalUsuarios = usuariosMaps.length;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados do dashboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visão Geral - Todos os Usuários',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estatísticas agregadas de todos os pacientes/clientes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Cards de Estatísticas - Primeira Linha
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Usuários',
                            _totalUsuarios.toString(),
                            Icons.people,
                            Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Rotinas',
                            _totalRotinas.toString(),
                            Icons.schedule,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Segunda Linha
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Rotinas Concluídas',
                            _rotinasConcluidas.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Taxa de Conclusão',
                            _totalRotinas > 0
                                ? '${((_rotinasConcluidas / _totalRotinas) * 100).toStringAsFixed(0)}%'
                                : '0%',
                            Icons.trending_up,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Terceira Linha
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Diários',
                            _totalDiarios.toString(),
                            Icons.book,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pranchas CCA',
                            _totalBoards.toString(),
                            Icons.grid_view,
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quarta Linha
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Itens CCA',
                            _totalBoardItems.toString(),
                            Icons.speaker_phone,
                            Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(), 
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // Seção de Ações Rápidas
                    const Text(
                      'Ações Rápidas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActionCard(
                      'Ver Rotinas',
                      'Acesse e gerencie suas rotinas',
                      Icons.schedule,
                      Colors.orange,
                      () {
                        Navigator.pushNamed(context, '/rotinas', arguments: {'userId': widget.userId});
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionCard(
                      'Ver Diários',
                      'Acesse os registros de diário',
                      Icons.book,
                      Colors.blue,
                      () {
                        Navigator.pushNamed(context, '/diario', arguments: {'userId': widget.userId});
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

