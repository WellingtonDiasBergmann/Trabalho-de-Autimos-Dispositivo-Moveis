import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trabalhofinal/BancoDados/DataBaseHelper.dart';
import 'package:trabalhofinal/Models/Diario.dart';

// Cores Temáticas
const Color primaryColor = Colors.blue;

// ----------------------------------------------------------------------
// 1. StatefulWidget Principal (TelaDiario)
// ----------------------------------------------------------------------

class TelaDiario extends StatefulWidget {
  // ⭐️ Adicionando userId ao construtor
  final int userId;

  const TelaDiario({super.key, required this.userId});

  @override
  State<TelaDiario> createState() => _TelaDiarioState();
}

class _TelaDiarioState extends State<TelaDiario> {
  // ⭐️ Inicialização do serviço de banco de dados e estados de carregamento
  late final DataBaseHelper _dbService = DataBaseHelper();
  List<EntradaDiario> _entradas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItemsFromDb();
  }

  // ----------------------------------------------------------------------
  // 2. Lógica de Persistência (SQL)
  // ----------------------------------------------------------------------

  Future<void> _loadItemsFromDb() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ⭐️ Chama o DB Helper para carregar itens filtrando pelo userId
      final List<Diario> diarioMaps = await _dbService.getDiarioEntriesByUserId(widget.userId);

      setState(() {
        // Converte os modelos de DB para modelos de UI
        _entradas = diarioMaps.map((d) => EntradaDiario.fromDiario(d)).toList();
        // Ordena pela data (mais recente primeiro)
        _entradas.sort((a, b) => b.data.compareTo(a.data));
      });
    } catch (e) {
      debugPrint('Erro ao carregar entradas do Diário: $e');
      _showMessage(context, "Erro ao carregar dados.", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Lógica para salvar/atualizar a entrada no DB
  Future<void> _salvarEntrada(EntradaDiario entradaSalva) async {
    try {
      // Converte o modelo de UI para o modelo de DB
      final Diario diario = entradaSalva.toDiario(widget.userId);

      // ⭐️ Insere ou atualiza no banco de dados
      final int newId = await _dbService.insertOrUpdateDiarioEntry(diario);

      // Atualiza o modelo de UI com o ID permanente retornado pelo DB
      entradaSalva.id = newId;

      // Recarrega a lista completa para refletir as mudanças e ordenação
      await _loadItemsFromDb();

      _showMessage(context, entradaSalva.id == diario.id ? "Entrada atualizada com sucesso!" : "Nova entrada adicionada!");
    } catch (e) {
      debugPrint('Erro ao salvar/atualizar entrada: $e');
      _showMessage(context, "Erro ao salvar a entrada. Tente novamente.", isError: true);
    }
  }

  // Lógica para excluir a entrada do DB
  Future<void> _excluirEntrada(EntradaDiario entrada) async {
    if (entrada.id == null) return; // Não exclui se não tem ID de DB

    try {
      // ⭐️ Exclui no banco de dados
      await _dbService.deleteDiarioEntry(entrada.id!);

      // Recarrega a lista
      await _loadItemsFromDb();
      _showMessage(context, "Entrada excluída.");

    } catch (e) {
      debugPrint('Erro ao excluir entrada: $e');
      _showMessage(context, "Erro ao excluir a entrada.", isError: true);
    }
  }

  // ----------------------------------------------------------------------
  // 3. Funções de Ação e UI
  // ----------------------------------------------------------------------

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryColor,
      ),
    );
  }

  // Abre o modal para adicionar ou editar uma entrada
  void _abrirModalEdicao([EntradaDiario? entrada]) {
    // Cria uma cópia da entrada para edição no modal
    EntradaDiario entradaEmEdicao = entrada != null
        ? entrada.copyWith()
        : EntradaDiario(
      data: DateTime.now(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ModalEdicaoDiario(
          entradaOriginal: entrada,
          entradaEmEdicao: entradaEmEdicao,
          onSave: (salva) {
            _salvarEntrada(salva);
            Navigator.pop(context);
          },
        );
      },
    );
  }


  // ----------------------------------------------------------------------
  // 4. Widgets de Construção da UI
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ⭐️ Atualizando o título com o userId
        title: Text("Diário (Usuário ${widget.userId})"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _buildBody(context),
          _buildFloatingActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DIÁRIO",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 50.0),
                child: CircularProgressIndicator(color: primaryColor),
              ),
            )
          else if (_entradas.isEmpty)
            _buildEmptyState()
          else
            ..._entradas.map((entrada) => Padding(
              padding: const EdgeInsets.only(bottom: 25.0),
              child: _EntradaDiarioCard(
                entrada: entrada,
                onEdit: () => _abrirModalEdicao(entrada),
                onDelete: () => _excluirEntrada(entrada),
              ),
            )).toList(),
        ],
      ),
    );
  }

  // Estado Vazio
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
            Icon(Icons.auto_stories, size: 80, color: primaryColor),
            const SizedBox(height: 10),
            Text(
              "Nenhum registro no diário ainda.",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FloatingActionButton.extended(
              onPressed: () => _abrirModalEdicao(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Novo Registro'),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            )
          ],
        ),
      ),
    );
  }

  // Botões flutuantes na parte inferior (Figma)
  Widget _buildFloatingActionButtons(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
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
              // Botão ADICIONAR (+)
              _buildActionButton(
                context,
                Icons.add,
                primaryColor,
                'Adicionar Entrada',
                    () => _abrirModalEdicao(),
              ),
              const SizedBox(width: 15),

              // Botão EXPORTAR/DOCUMENTO (Documento) - Ação Placeholder
              _buildActionButton(
                context,
                Icons.description,
                Colors.green,
                'Exportar Diário',
                    () => _showMessage(context, "Ação: Exportar Diário"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Componente auxiliar para o botão flutuante
  Widget _buildActionButton(
      BuildContext context,
      IconData icon,
      Color color,
      String tooltip,
      VoidCallback onPressed,
      ) {
    return FloatingActionButton(
      heroTag: tooltip,
      onPressed: onPressed,
      backgroundColor: color,
      foregroundColor: Colors.white,
      mini: false,
      child: Icon(icon, size: 30),
    );
  }
}

// ----------------------------------------------------------------------
// 5. Componente Stateful para o Card Individual (Visualização)
// ----------------------------------------------------------------------

class _EntradaDiarioCard extends StatefulWidget {
  final EntradaDiario entrada;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntradaDiarioCard({
    required this.entrada,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EntradaDiarioCard> createState() => _EntradaDiarioCardState();
}

class _EntradaDiarioCardState extends State<_EntradaDiarioCard> {
  String _activeTab = CATEGORIES.first;

  @override
  void initState() {
    super.initState();
    _activeTab = CATEGORIES.first;
  }

  String _getStatusForTab(String tab) {
    switch (tab) {
      case 'SONO': return widget.entrada.sonoStatus;
      case 'HUMOR': return widget.entrada.humorStatus;
      case 'ALIMENTAÇÃO': return widget.entrada.alimentacaoStatus;
      case 'CRISE': return widget.entrada.criseStatus;
      default: return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Data e Botões de Ação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Data: ${DateFormat('dd/MM/yyyy').format(widget.entrada.data)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: const Icon(Icons.edit, size: 20, color: primaryColor),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: const Icon(Icons.delete, size: 20, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Chips de Categoria
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: CATEGORIES.map((tab) {
              final isSelected = _activeTab == tab;
              return ActionChip(
                label: Text(tab, style: TextStyle(color: isSelected ? Colors.white : primaryColor)),
                backgroundColor: isSelected ? primaryColor : primaryColor,
                side: BorderSide(color: isSelected ? Colors.transparent : primaryColor),
                onPressed: () {
                  setState(() {
                    _activeTab = tab;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Título Dinâmico (Nome da Categoria)
          Text(
            _activeTab,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),

          // Campo de Status Dinâmico (Apenas Texto de Visualização)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            width: double.infinity,
            child: Text(
              _getStatusForTab(_activeTab),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Observações
          const Text(
            "Observações",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(15),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              widget.entrada.observacoes.isEmpty ? "Sem observações." : widget.entrada.observacoes,
              style: TextStyle(
                fontSize: 14,
                fontStyle: widget.entrada.observacoes.isEmpty ? FontStyle.italic : FontStyle.normal,
                color: widget.entrada.observacoes.isEmpty ? Colors.grey.shade500 : Colors.grey.shade700,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 6. Componente Stateful para o Modal de Edição/Criação
// ----------------------------------------------------------------------

class _ModalEdicaoDiario extends StatefulWidget {
  final EntradaDiario? entradaOriginal;
  final EntradaDiario entradaEmEdicao;
  final ValueChanged<EntradaDiario> onSave;

  const _ModalEdicaoDiario({
    required this.entradaOriginal,
    required this.entradaEmEdicao,
    required this.onSave,
  });

  @override
  State<_ModalEdicaoDiario> createState() => _ModalEdicaoDiarioState();
}

class _ModalEdicaoDiarioState extends State<_ModalEdicaoDiario> {
  String _activeTab = CATEGORIES.first;

  @override
  void initState() {
    super.initState();
    _activeTab = CATEGORIES.first;
  }

  String _getCurrentStatus(String tab) {
    switch (tab) {
      case 'SONO': return widget.entradaEmEdicao.sonoStatus;
      case 'HUMOR': return widget.entradaEmEdicao.humorStatus;
      case 'ALIMENTAÇÃO': return widget.entradaEmEdicao.alimentacaoStatus;
      case 'CRISE': return widget.entradaEmEdicao.criseStatus;
      default: return OPTIONS[tab]!.first;
    }
  }

  void _updateStatus(String tab, String newValue) {
    setState(() {
      switch (tab) {
        case 'SONO': widget.entradaEmEdicao.sonoStatus = newValue; break;
        case 'HUMOR': widget.entradaEmEdicao.humorStatus = newValue; break;
        case 'ALIMENTAÇÃO': widget.entradaEmEdicao.alimentacaoStatus = newValue; break;
        case 'CRISE': widget.entradaEmEdicao.criseStatus = newValue; break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromWindowPadding(
        WidgetsBinding.instance.window.viewInsets,
        WidgetsBinding.instance.window.devicePixelRatio,
      ).copyWith(top: 20, left: 20, right: 20, bottom: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.entradaOriginal == null ? "Nova Entrada" : "Editar Entrada",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Seletor de Data
            _buildDataSelector(),
            const SizedBox(height: 20),

            // Chips de Categoria
            _buildCategoryChips(),
            const SizedBox(height: 20),

            // Título Dinâmico (Nome da Categoria)
            Text(
              _activeTab,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            // Dropdown Dinâmico
            _buildDynamicDropdown(_activeTab),
            const SizedBox(height: 20),

            // Campo de Observações
            const Text(
              "Observações",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            _buildObservationsField(),
            const SizedBox(height: 20),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Salvar Entrada", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => widget.onSave(widget.entradaEmEdicao),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget para o Seletor de Data
  Widget _buildDataSelector() {
    return ListTile(
      leading: const Icon(Icons.calendar_today, color: primaryColor),
      title: Text(
        "Data: ${DateFormat('dd/MM/yyyy').format(widget.entradaEmEdicao.data)}",
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.edit),
      onTap: () async {
        DateTime? dataSelecionada = await showDatePicker(
          context: context,
          initialDate: widget.entradaEmEdicao.data,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (dataSelecionada != null) {
          setState(() {
            // Preserva a hora atual, mas muda a data
            widget.entradaEmEdicao.data = DateTime(
              dataSelecionada.year,
              dataSelecionada.month,
              dataSelecionada.day,
              widget.entradaEmEdicao.data.hour,
              widget.entradaEmEdicao.data.minute,
            );
          });
        }
      },
    );
  }

  // Widget para os Chips de Categoria
  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: CATEGORIES.map((tab) {
        final isSelected = _activeTab == tab;
        return ActionChip(
          label: Text(tab, style: TextStyle(color: isSelected ? Colors.white : primaryColor)),
          backgroundColor: isSelected ? primaryColor : primaryColor,
          side: BorderSide(color: isSelected ? Colors.transparent : primaryColor),
          onPressed: () {
            setState(() {
              _activeTab = tab;
            });
          },
        );
      }).toList(),
    );
  }

  // Widget para o Dropdown Dinâmico
  Widget _buildDynamicDropdown(String tab) {
    List<String> items = OPTIONS[tab] ?? ['Erro: Sem Opções'];
    String currentValue = _getCurrentStatus(tab);

    if (!items.contains(currentValue)) {
      currentValue = items.first;
      _updateStatus(tab, currentValue);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              _updateStatus(tab, newValue);
            }
          },
        ),
      ),
    );
  }

  // Widget para o Campo de Observações
  Widget _buildObservationsField() {
    return TextFormField(
      initialValue: widget.entradaEmEdicao.observacoes,
      decoration: InputDecoration(
        hintText: "Escreva uma observação...",
        contentPadding: const EdgeInsets.all(15),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      maxLines: 5,
      onChanged: (value) {
        widget.entradaEmEdicao.observacoes = value;
      },
    );
  }
}