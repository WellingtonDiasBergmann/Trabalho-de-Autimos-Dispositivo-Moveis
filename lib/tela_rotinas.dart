import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trabalhofinal/BancoDados/DataBaseHelper.dart';
import 'package:trabalhofinal/Models/Routine.dart';
import 'package:trabalhofinal/Models/RoutineStep.dart';
import 'dart:math';



class TelaRotinas extends StatefulWidget {
  final int userId;

  const TelaRotinas({super.key, required this.userId});

  @override
  State<TelaRotinas> createState() => _TelaRotinasState();
}

class _TelaRotinasState extends State<TelaRotinas> {
  // Inicialização do DB Helper
  final DataBaseHelper _dbService = DataBaseHelper();
  final Random _random = Random(); 

  bool _isEditing = false;
  List<Routine> _rotinas = [];
  List<Routine> _rotinasEditavel = [];
  bool _isLoading = true; 
  @override
  void initState() {
    super.initState();
    // Inicializa o carregamento, mas o setState será chamado dentro do _loadRotinas
    _loadRotinas();
  }

  

  Future<void> _loadRotinas() async {
    // Evita múltiplas chamadas simultâneas, mas permite o carregamento inicial
    if (_isLoading && _rotinas.isNotEmpty) {
      // Se já está carregando E já tem rotinas, não recarrega
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      // Usando a função correta que retorna todas as rotinas do usuário
      final loadedRoutines = await _dbService.getAllRoutines(widget.userId);

      setState(() {
        _rotinas = loadedRoutines.map((r) => r.copyWith(steps: r.steps ?? [])).toList();
      });
    } catch (e) {
      debugPrint('Erro CRÍTICO ao carregar rotinas: $e');
      _showMessage(context, "Erro ao carregar rotinas. Verifique o console para detalhes.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Ativa/Desativa o modo de edição
  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
    
        _rotinasEditavel = _rotinas.map((r) => r.copyWith(
            steps: r.steps?.map((p) => p.copyWith()).toList()
        )).toList();
      } else {
        _rotinasEditavel = [];
      }
    });
    if (_isEditing && _rotinasEditavel.isEmpty) { 
      _adicionarRotina();
    }
  }

  void _adicionarRotina() {
    if (!_isEditing) return;
    setState(() {
      final temporaryId = -(_random.nextInt(1000000) + 1);

      final newRoutine = Routine(
        id: temporaryId,
        pessoaId: widget.userId,
        titulo: "Nova Rotina",
        dataCriacao: DateTime.now().toIso8601String().substring(0, 10),
        lembrete: "00:00",
        steps: [
          RoutineStep(
              id: null,
              routineId: null, 
              descricao: "Novo Passo",
              duracaoSegundos: 60,
              ordem: 0,
              isCompleted: false
          ),
        ],
      );
      _rotinasEditavel.add(newRoutine);
    });
  }

  void _salvarRotinas() async {
    final rotinaInvalida = _rotinasEditavel.any((r) => r.titulo.trim().isEmpty);
    if (rotinaInvalida) {
      _showMessage(context, "Todas as rotinas devem ter um título.");
      return;
    }

    debugPrint('[FLUXO DB - INÍCIO] Rotinas a serem processadas: ${_rotinasEditavel.length}');
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salvando Rotinas..."), duration: Duration(seconds: 1)));

    try {
      for (var rotina in _rotinasEditavel) {
        debugPrint('[FLUXO DB - PROCESSANDO] Tentando salvar Rotina ID: ${rotina.id}, Título: ${rotina.titulo}');

     
        await _dbService.insertRoutineWithSteps(rotina);

        debugPrint('[FLUXO DB - SUCESSO PARCIAL] Rotina salva/atualizada com sucesso: ${rotina.titulo}');
      }

      await _loadRotinas();

      setState(() {
        _isEditing = false;
        _rotinasEditavel = [];
      });
      _showMessage(context, "Rotinas salvas com sucesso!");
      debugPrint('[FLUXO DB - FIM] Todas as rotinas processadas com sucesso.');

    } catch (e) {
      debugPrint('Erro CRÍTICO ao salvar rotinas (Catch externo): $e');
      _showMessage(context, "Erro ao salvar rotinas. Verifique o console para detalhes.");
    }
  }

  void _adicionarPasso(Routine rotina) {
    if (!_isEditing) return;
    setState(() {
      final index = _rotinasEditavel.indexWhere((r) => r.id == rotina.id);
      if (index != -1) {
        final rotinaEditada = _rotinasEditavel[index];
        final newOrder = rotinaEditada.steps != null ? rotinaEditada.steps!.length : 0;

        rotinaEditada.steps!.add(RoutineStep(
            id: null,
            routineId: rotinaEditada.id,
            descricao: "Novo Passo",
            duracaoSegundos: 60,
            ordem: newOrder,
            isCompleted: false
        ));
      }
    });
  }

  void _toggleStepCompletion(Routine rotina, RoutineStep passo) async {
    if (_isEditing) {
      _showMessage(context, "Saia do modo de edição para marcar a rotina.");
      return;
    }

    final stepId = passo.id;
    if (stepId != null) {
      final currentCompletionStatus = passo.isCompleted;
      final newCompletionStatus = !currentCompletionStatus;

      try {
        // Atualiza no banco de dados primeiro
        await _dbService.updateRoutineStepStatus(stepId, newCompletionStatus);

        // Atualiza o estado local de forma imutável após sucesso no DB
        final rotinaIndex = _rotinas.indexWhere((r) => r.id == rotina.id);
        if (rotinaIndex == -1) return;

        final stepIndex = rotina.steps!.indexWhere((p) => p.id == stepId);
        if (stepIndex == -1) return;

        // 1. Cria cópia do passo atualizado
        final updatedStep = passo.copyWith(isCompleted: newCompletionStatus);

        // 2. Cria nova lista de passos
        final updatedSteps = List<RoutineStep>.from(_rotinas[rotinaIndex].steps!);
        updatedSteps[stepIndex] = updatedStep;

        // 3. Cria nova rotina e atualiza a lista principal
        setState(() {
          final updatedRoutine = _rotinas[rotinaIndex].copyWith(steps: updatedSteps);
          final updatedRoutinesList = List<Routine>.from(_rotinas);
          updatedRoutinesList[rotinaIndex] = updatedRoutine;
          _rotinas = updatedRoutinesList;
        });

        _showMessage(context, "Passo marcado como ${newCompletionStatus ? 'concluído' : 'pendente'}!");
      } catch (e) {
        debugPrint('Erro ao atualizar status do passo: $e');
        _showMessage(context, "Falha ao atualizar o status do passo no banco de dados.");
      }

    } else {
      _showMessage(context, "Erro: Passo não possui ID para atualização. Salve a rotina primeiro.");
    }
  }

  // Função auxiliar para exibir mensagens
  void _showMessage(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

 

  @override
  Widget build(BuildContext context) {
    final List<Routine> rotinasParaExibir = _isEditing ? _rotinasEditavel : _rotinas;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rotinas"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            if (rotinasParaExibir.isEmpty && !_isEditing)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: Column(
                    children: [
                      const Icon(Icons.list_alt, size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(
                        "Nenhuma rotina cadastrada.",
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Clique no lápis para editar e adicionar uma.",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...rotinasParaExibir.map((rotina) => Padding(
                padding: const EdgeInsets.only(bottom: 25.0),
                child: _buildRotinaCard(context, rotina),
              )).toList(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingActionButtons(context),
    );
  }

  // Widget para construir o Card de uma Rotina individual
  Widget _buildRotinaCard(BuildContext context, Routine rotina) {
    const double borderRadius = 20.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nome da rotina",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? _buildEditableField(
                  initialValue: rotina.titulo,
                  hintText: "Nome da rotina",
                  onChanged: (newValue) => rotina.titulo = newValue, 
                )
                    : _buildDisplayBox(rotina.titulo, isTitle: true),
              ),
              const SizedBox(width: 10),

              SizedBox(
                width: 70,
                child: _isEditing
                    ? _buildEditableField(
                  initialValue: rotina.lembrete ?? '00:00',
                  hintText: "HH:mm",
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  onChanged: (newValue) => rotina.lembrete = newValue, 
                )
                    : _buildDisplayBox(rotina.lembrete ?? '00:00', isTitle: false, width: 70),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            "Passos",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          ...(rotina.steps ?? []).asMap().entries.map((entry) {
            final RoutineStep passo = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleStepCompletion(rotina, passo),
                    child: Icon(
                      passo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: passo.isCompleted ? Colors.green : Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: _isEditing
                        ? _buildEditableField(
                      initialValue: passo.descricao, 
                      hintText: "Descrição do passo",
                      onChanged: (newValue) => passo.descricao = newValue, 
                    )
                        : _buildDisplayBox(passo.descricao, isTitle: false, isComplete: passo.isCompleted),
                  ),
                  const SizedBox(width: 10),

                  SizedBox(
                    width: 70,
                    child: _isEditing
                        ? _buildEditableField(
                      initialValue: "${(passo.duracaoSegundos) ~/ 60}", 
                      hintText: "X min",
                      keyboardType: TextInputType.number, 
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, 
                        LengthLimitingTextInputFormatter(3), 
                      ],
                      onChanged: (newValue) {
                        final minutes = int.tryParse(newValue) ?? 1;
                        passo.duracaoSegundos = minutes * 60;
                      },
                    )
                        : _buildDisplayBox("${(passo.duracaoSegundos) ~/ 60} min", isTitle: false, width: 70, isComplete: passo.isCompleted),
                  ),

                  if (_isEditing) ...[
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        final rotinaAtualIndex = _rotinasEditavel.indexWhere((r) => r.id == rotina.id);

                        if (rotinaAtualIndex != -1) {
                          final rotinaAtual = _rotinasEditavel[rotinaAtualIndex];
                          final indexParaRemover = rotinaAtual.steps!.indexOf(passo);

                          if (indexParaRemover != -1) {
                            setState(() {
                              rotinaAtual.steps!.removeAt(indexParaRemover);

                              for (int i = 0; i < rotinaAtual.steps!.length; i++) {
                                // Assume que o campo `ordem` é mutável no modelo RoutineStep
                                rotinaAtual.steps![i].ordem = i;
                              }
                            });
                            _showMessage(context, "Passo removido e reordenado.");
                          } else {
                            _showMessage(context, "Erro ao encontrar passo para remover.");
                          }
                        }
                      },
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 15),

          if (_isEditing)
            Center(
              child: InkWell(
                onTap: () => _adicionarPasso(rotina),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                      const SizedBox(width: 8),
                      Text(
                        "Adicionar passo",
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text("Excluir Rotina", style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final rotinaRemovida = rotina.id != null && rotina.id! > 0
                        ? _rotinasEditavel.firstWhere((r) => r.id == rotina.id)
                        : null;

                    setState(() {
                      _rotinasEditavel.removeWhere((r) => r.id == rotina.id); // Usando where para IDs temporários
                    });

                    if (rotinaRemovida != null) {
                      // Se tem um ID real do DB (positivo), exclui permanentemente
                      await _dbService.deleteRoutine(rotina.id!);
                      _showMessage(context, "Rotina '${rotina.titulo}' excluída permanentemente.");
                      // Recarrega a lista principal após exclusão (se necessário)
                      await _loadRotinas();
                    } else {
                      _showMessage(context, "Rotina '${rotina.titulo}' removida da edição (ainda não estava salva).");
                    }
                  },
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildDisplayBox(String text, {required bool isTitle, double? width, bool isComplete = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTitle ? 16 : 14,
          fontWeight: isTitle ? FontWeight.w500 : FontWeight.normal,
          color: isComplete ? Colors.grey.shade500 : Colors.grey.shade700,
          decoration: isComplete ? TextDecoration.lineThrough : TextDecoration.none, 
          decorationColor: Colors.black54,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEditableField({
    required String initialValue,
    String? hintText,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: 16,
        color: Colors.blue.shade900,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    if (_isEditing) {
      return Container(
        margin: const EdgeInsets.only(bottom: 25.0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              context: context,
              icon: Icons.add,
              color: Colors.blue,
              tooltip: 'Adicionar Rotina',
              onPressed: _adicionarRotina,
            ),
            const SizedBox(width: 15),

            _buildActionButton(
              context: context,
              icon: Icons.cancel_outlined,
              color: Colors.red.shade400,
              tooltip: 'Cancelar Edição',
              onPressed: _toggleEditing,
            ),
            const SizedBox(width: 15),

            _buildActionButton(
              context: context,
              icon: Icons.save,
              color: Colors.green,
              tooltip: 'Salvar Rotinas',
              onPressed: _salvarRotinas,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 25.0),
      child: _buildActionButton(
        context: context,
        icon: Icons.edit,
        color: Colors.orange,
        tooltip: 'Editar',
        onPressed: _toggleEditing,
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    bool isMini = false,
  }) {
    return FloatingActionButton(
      heroTag: tooltip,
      onPressed: onPressed,
      backgroundColor: color,
      foregroundColor: Colors.white,
      mini: isMini,
      child: Icon(icon, size: 28),
    );
  }
}