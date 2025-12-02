import 'package:flutter/material.dart';
import 'package:trabalhofinal/Models/BoardItem.dart';

// Cores Temáticas (Replicadas para contexto)
const Color accentColor = Color(0xFF4CAF50); // Verde para Adicionar
const Color infoColor = Color(0xFF2196F3); // Azul para Editar

class ItemFormModal extends StatefulWidget {
  final BoardItem? itemToEdit;
  final Function(BoardItem) onSave;
  final Function(String) speakAction;

  const ItemFormModal({
    super.key,
    this.itemToEdit,
    required this.onSave,
    required this.speakAction,
  });

  @override
  State<ItemFormModal> createState() => _ItemFormModalState();
}

class _ItemFormModalState extends State<ItemFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _iconController;
  late TextEditingController _wordController;
  late TextEditingController _phraseController;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _iconController = TextEditingController(text: item?.imgUrl ?? '');
    _wordController = TextEditingController(text: item?.texto ?? '');
    _phraseController = TextEditingController(text: item?.fraseTts ?? '');
  }

  @override
  void dispose() {
    _iconController.dispose();
    _wordController.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newItem = BoardItem(
        // Mantém ID se editando, ou NULL para autoincremento
        id: widget.itemToEdit?.id,
        // Mantém BoardId se editando, ou usa um valor padrão se adicionando
        boardId: widget.itemToEdit?.boardId ?? 1,
        imgUrl: _iconController.text.trim(),
        texto: _wordController.text.trim(),
        fraseTts: _phraseController.text.trim(),
      );
      widget.onSave(newItem);
    }
  }

  Future<void> _testSpeak() async {
    if (_phraseController.text.isNotEmpty && !_isSpeaking) {
      setState(() {
        _isSpeaking = true;
      });
      await widget.speakAction(_phraseController.text.trim());
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.itemToEdit == null ? 'Adicionar Novo Item' : 'Editar Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _iconController,
                decoration: const InputDecoration(labelText: 'Ícone / Símbolo', hintText: 'Ex: 🍎'),
                validator: (value) => (value == null || value.isEmpty) ? 'O ícone não pode ser vazio.' : null,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _wordController,
                decoration: const InputDecoration(labelText: 'Palavra / Nome', hintText: 'Ex: Maçã'),
                validator: (value) => (value == null || value.isEmpty) ? 'A palavra é obrigatória.' : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phraseController,
                      decoration: const InputDecoration(labelText: 'Frase para a Voz (TTS)', hintText: 'Ex: Eu quero maçã agora.'),
                      validator: (value) => (value == null || value.isEmpty) ? 'A frase é obrigatória.' : null,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSpeaking ? null : _testSpeak,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade400, foregroundColor: Colors.white),
                      child: _isSpeaking
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Icon(Icons.volume_up, size: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _saveForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.itemToEdit == null ? accentColor : infoColor,
          ),
          child: Text(widget.itemToEdit == null ? 'Adicionar' : 'Salvar', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}