import 'package:flutter/material.dart';
// Importação presumida da classe de cores, se não estiver em outro arquivo
class AppColors {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color cardBlue = Color(0xFF42A5F5);
}

class TelaModoCrise extends StatelessWidget {
  const TelaModoCrise({super.key});

  // Função Placeholder para ligar/enviar SMS
  // Em uma aplicação real, você usaria o pacote 'url_launcher'
  void _makeAction(String action, String target) {
    // Ex: Se action for 'tel', a URL seria 'tel:999999999'
    // Ex: Se action for 'sms', a URL seria 'sms:999999999'
    print("Ação de Crise: $action para $target");
    // Lógica real de lançamento de URL seria implementada aqui
    // Ex: launchUrl(Uri.parse('$action:$target'));
  }

  // Widget para os botões de contato de emergência
  Widget _buildContactButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 30),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
        ),
      ),
    );
  }

  // Widget para a caixa de instruções
  Widget _buildInstructionsBox() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryBlue, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Meu Plano de Ação Rápida:",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          Divider(color: AppColors.primaryBlue),
          SizedBox(height: 8),
          // Instruções Personalizadas (Configuráveis pelo usuário)
          Text(
            "1. Respire fundo 5 vezes, contando até 4 em cada inspiração e expiração.",
            style: TextStyle(fontSize: 16),
          ),
          Text(
            "2. Vá para um local silencioso e escuro, se possível, ou coloque fones de ouvido.",
            style: TextStyle(fontSize: 16),
          ),
          Text(
            "3. Segure meu objeto de conforto (bola anti-stress ou cobertor macio).",
            style: TextStyle(fontSize: 16),
          ),
          Text(
            "4. Se a crise persistir, ligue para o Contato 1 ou para a Ajuda Médica.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modo Crise", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        iconTheme: const IconThemeData(color: Colors.white), // Ícone de voltar branco
      ),
      backgroundColor: Colors.red.shade50, // Fundo levemente colorido para contraste
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Mensagem de Alerta Principal
            const Center(
              child: Text(
                "ATENÇÃO: Ajuda Imediata",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            _buildInstructionsBox(),

            const Text(
              "Contatos de Emergência Rápidos:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),

            // Contato 1: Responsável/Pessoa de Confiança
            _buildContactButton(
              label: "Ligar para Contato 1 (Mãe/Pai)",
              icon: Icons.phone_in_talk,
              color: Colors.green.shade600,
              onTap: () => _makeAction('tel', '999999999'),
            ),

            // Contato 2: Terapeuta/Profissional
            _buildContactButton(
              label: "Ligar para Contato 2 (Terapeuta)",
              icon: Icons.support_agent,
              color: Colors.orange.shade600,
              onTap: () => _makeAction('tel', '888888888'),
            ),

            // Contato 3: Emergência Universal
            _buildContactButton(
              label: "Ligar para EMERGÊNCIA (911/190)",
              icon: Icons.local_hospital,
              color: Colors.red.shade700,
              onTap: () => _makeAction('tel', '190'),
            ),

            const SizedBox(height: 40),

          ],
        ),
      ),
    );
  }
}