import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Certifique-se de que este caminho está correto:
import 'package:trabalhofinal/BancoDados/DataBaseHelper.dart';
// Certifique-se de que estes imports estão corretos em seu projeto:
import 'package:trabalhofinal/Models/Routine.dart';
import 'package:trabalhofinal/Models/RoutineStep.dart';
import 'dart:math';

// ----------------------------------------------------------------------
// 2. StatefulWidget para Gerenciar Estado e Edição
// ----------------------------------------------------------------------

class TelaRotinas extends StatefulWidget {
  // Você precisará de um ID de Usuário para carregar as rotinas corretas
  final int userId;

  const TelaRotinas({super.key, required this.userId});

  @override
  State<TelaRotinas> createState() => _TelaRotinasState();
}

class _TelaRotinasState extends State<TelaRotinas> {
  // Inicialização do DB Helper
  final DataBaseHelper _dbService = DataBaseHelper();
  final Random _random = Random(); // Simulando um gerador de UUID/ID temporário

  bool _isEditing = false;
  // Agora, estas listas usam o modelo real: Routine
  List<Routine> _rotinas = [];
  List<Routine> _rotinasEditavel = [];
  bool _isLoading = true; // Novo estado de carregamento

  @override
  void initState() {
    super.initState();
    // Inicializa o carregamento, mas o setState será chamado dentro do _loadRotinas
    _loadRotinas();
  }

  // ----------------------------------------------------------------------
  // 3. Funções de Ação e Estado (AJUSTADAS PARA SQL)
  // ----------------------------------------------------------------------

  // Novo: Carrega as rotinas do banco de dados
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
        // Mapeamos para garantir que a lista de passos (steps) nunca seja nula,
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
        // Ao entrar no modo de edição, copia a lista principal para a lista temporária
        // USANDO DEEP COPY com copyWith para não modificar a lista persistida.
        // É essencial usar .toList() após o map para criar uma nova lista.
        _rotinasEditavel = _rotinas.map((r) => r.copyWith(
            steps: r.steps?.map((p) => p.copyWith()).toList()
        )).toList();
      } else {
        // Se cancelou, limpamos e voltamos aos dados persistidos.
        _rotinasEditavel = [];
      }
    });
    // Adiciona rotina inicial se a lista estiver vazia e entramos em modo de edição
    if (_isEditing && _rotinasEditavel.isEmpty) { // Usamos _rotinasEditavel para verificar a lista de edição
      _adicionarRotina();
    }
  }

  // Adiciona uma nova rotina (SÓ FUNCIONA NO MODO EDIÇÃO)
  void _adicionarRotina() {
    if (!_isEditing) return;
    setState(() {
      // Cria um ID temporário negativo para rotinas novas.
      final temporaryId = -(_random.nextInt(1000000) + 1);

      // Aqui os nomes dos campos estão corrigidos para o modelo Routine
      final newRoutine = Routine(
        id: temporaryId,
        pessoaId: widget.userId,
        titulo: "Nova Rotina",
        dataCriacao: DateTime.now().toIso8601String().substring(0, 10),
        lembrete: "00:00",
        steps: [
          // Aqui os nomes dos campos estão corrigidos para o modelo RoutineStep
          RoutineStep(
              id: null,
              routineId: null, // Será ajustado pelo DB Helper
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

  // Função de salvamento (AGORA REAL)
  void _salvarRotinas() async {
    // 1. Validar se há rotinas com título vazio
    final rotinaInvalida = _rotinasEditavel.any((r) => r.titulo.trim().isEmpty);
    if (rotinaInvalida) {
      _showMessage(context, "Todas as rotinas devem ter um título.");
      return;
    }

    debugPrint('[FLUXO DB - INÍCIO] Rotinas a serem processadas: ${_rotinasEditavel.length}');
    // Mostrar feedback visual imediato
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salvando Rotinas..."), duration: Duration(seconds: 1)));

    try {
      // 2. Itera sobre a lista editável e salva/atualiza
      for (var rotina in _rotinasEditavel) {
        debugPrint('[FLUXO DB - PROCESSANDO] Tentando salvar Rotina ID: ${rotina.id}, Título: ${rotina.titulo}');

        // O DB Helper deve ser robusto o suficiente para:
        // - Inserir se ID for negativo (novo) e retornar o novo ID
        // - Atualizar se ID for positivo (existente)
        await _dbService.insertRoutineWithSteps(rotina);

        debugPrint('[FLUXO DB - SUCESSO PARCIAL] Rotina salva/atualizada com sucesso: ${rotina.titulo}');
      }

      // 3. Após salvar todos, recarrega a lista do banco de dados (obtendo os novos IDs)
      await _loadRotinas();

      // 4. Conclui a edição
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

  // Adiciona um passo a uma rotina específica (SÓ FUNCIONA NO MODO EDIÇÃO)
  void _adicionarPasso(Routine rotina) {
    if (!_isEditing) return;
    setState(() {
      // Encontra o index da rotina na lista _rotinasEditavel
      final index = _rotinasEditavel.indexWhere((r) => r.id == rotina.id);
      if (index != -1) {
        final rotinaEditada = _rotinasEditavel[index];
        final newOrder = rotinaEditada.steps != null ? rotinaEditada.steps!.length : 0;

        // Cria o novo passo com o próximo número de ordem
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

  // Alterna o estado de conclusão de um passo (SÓ FUNCIONA FORA DO MODO EDIÇÃO)
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
    // Verifica se o widget está montado antes de mostrar o SnackBar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ----------------------------------------------------------------------
  // 4. Widgets de Construção da UI
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Usa o getter 'titulo' e outras propriedades corrigidas no modelo Routine
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
          // Título da Seção Nome da Rotina
          const Text(
            "Nome da rotina",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Campo de Nome e Horário
          Row(
            children: [
              Expanded(
                child: _isEditing
                    ? _buildEditableField(
                  initialValue: rotina.titulo,
                  hintText: "Nome da rotina",
                  onChanged: (newValue) => rotina.titulo = newValue, // Correto: campo 'titulo' é mutável
                )
                    : _buildDisplayBox(rotina.titulo, isTitle: true),
              ),
              const SizedBox(width: 10),

              // O campo de Horário (Lembrete)
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
                  onChanged: (newValue) => rotina.lembrete = newValue, // Correto: campo 'lembrete' é mutável
                )
                    : _buildDisplayBox(rotina.lembrete ?? '00:00', isTitle: false, width: 70),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Título da Seção Passos
          const Text(
            "Passos",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Lista de Passos
          ...(rotina.steps ?? []).asMap().entries.map((entry) {
            final RoutineStep passo = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  // Ícone de Conclusão (interativo fora do modo de edição)
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
                    // O campo de Descrição do Passo (com strikethrough se completo)
                    child: _isEditing
                        ? _buildEditableField(
                      initialValue: passo.descricao, // Usa 'descricao' do modelo RoutineStep
                      hintText: "Descrição do passo",
                      onChanged: (newValue) => passo.descricao = newValue, // Correto: campo 'descricao' é mutável no RoutineStep
                    )
                        : _buildDisplayBox(passo.descricao, isTitle: false, isComplete: passo.isCompleted),
                  ),
                  const SizedBox(width: 10),

                  // O campo de Duração do Passo
                  SizedBox(
                    width: 70,
                    child: _isEditing
                        ? _buildEditableField(
                      // Exibe em minutos
                      initialValue: "${(passo.duracaoSegundos) ~/ 60}", // Usa 'duracaoSegundos'
                      hintText: "X min",
                      keyboardType: TextInputType.number, // Apenas números
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Garante que só há dígitos
                        LengthLimitingTextInputFormatter(3), // Limita para não ter números absurdos
                      ],
                      onChanged: (newValue) {
                        // Tenta converter o valor para um inteiro e salva em segundos
                        final minutes = int.tryParse(newValue) ?? 1;
                        // Correto: campo 'duracaoSegundos' é mutável no RoutineStep
                        passo.duracaoSegundos = minutes * 60;
                      },
                    )
                    // Exibe em minutos
                        : _buildDisplayBox("${(passo.duracaoSegundos) ~/ 60} min", isTitle: false, width: 70, isComplete: passo.isCompleted),
                  ),

                  // Botão de Excluir Passo (apenas em modo de edição)
                  if (_isEditing) ...[
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        // Encontra a rotina atual na lista editável
                        final rotinaAtualIndex = _rotinasEditavel.indexWhere((r) => r.id == rotina.id);

                        if (rotinaAtualIndex != -1) {
                          final rotinaAtual = _rotinasEditavel[rotinaAtualIndex];
                          final indexParaRemover = rotinaAtual.steps!.indexOf(passo);

                          if (indexParaRemover != -1) {
                            setState(() {
                              rotinaAtual.steps!.removeAt(indexParaRemover);

                              // >>> CORREÇÃO APLICADA AQUI:
                              // Após remover um passo, reordenamos todos os passos restantes
                              // para que o campo `ordem` seja sequencial (0, 1, 2...)
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

          // Botão Adicionar passo (apenas em modo de edição)
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

          // Botão de Excluir Rotina (apenas em modo de edição)
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text("Excluir Rotina", style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    // CORREÇÃO: Usar 'rotina' (o argumento) em vez de 'rotinas' (escopo incorreto)
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
                      // O ideal é recarregar só se houver mais rotinas a salvar, mas vamos manter o _loadRotinas por segurança.
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

  // Componente para a CAIXA DE VISUALIZAÇÃO (Modo não-edição, com isComplete)
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
          decoration: isComplete ? TextDecoration.lineThrough : TextDecoration.none, // RISCO NO TEXTO!
          decorationColor: Colors.black54,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Componente para o CAMPO DE TEXTO EDITÁVEL (Modo edição)
  Widget _buildEditableField({
    required String initialValue,
    String? hintText,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    // Usamos um Builder para criar um TextEditingController temporário,
    // garantindo que ele não seja recriado a cada setState.
    // Como estamos usando initialValue e onChanged (que modifica o objeto Routine/RoutineStep diretamente),
    // vamos usar o TextFormField simples, que já está configurado para o estado mutável do objeto.
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

  // A função agora retorna o(s) botão(ões) flutuante(s) diretamente.
  Widget _buildFloatingActionButtons(BuildContext context) {
    // Se estiver no modo de edição, exibe a barra com os 3 botões.
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
            // Botão ADICIONAR
            _buildActionButton(
              context: context,
              icon: Icons.add,
              color: Colors.blue,
              tooltip: 'Adicionar Rotina',
              onPressed: _adicionarRotina,
            ),
            const SizedBox(width: 15),

            // Botão CANCELAR (Substitui o Editar no modo de edição)
            _buildActionButton(
              context: context,
              icon: Icons.cancel_outlined,
              color: Colors.red.shade400,
              tooltip: 'Cancelar Edição',
              onPressed: _toggleEditing,
            ),
            const SizedBox(width: 15),

            // Botão SALVAR
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

    // Se NÃO estiver no modo de edição (estado inicial), exibe apenas o botão EDITAR (lápis)
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

  // Componente para um botão flutuante
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