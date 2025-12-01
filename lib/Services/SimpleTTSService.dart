import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';

/// Serviço simples de TTS usando flutter_tts (não precisa de API key)
class SimpleTTSService {
  static final SimpleTTSService _instance = SimpleTTSService._internal();
  factory SimpleTTSService() => _instance;
  SimpleTTSService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  Future<void> speak(String text) async {
    if (text.isEmpty) {
      print("TTS: Texto vazio, ignorando");
      return;
    }

    try {
      print("TTS: Iniciando fala: $text");
      
      // Tenta inicializar
      if (!_isInitialized) {
        try {
          _flutterTts = FlutterTts();
          await _flutterTts?.setLanguage("pt-BR");
          await _flutterTts?.setSpeechRate(0.5);
          await _flutterTts?.setVolume(1.0);
          await _flutterTts?.setPitch(1.0);
          _isInitialized = true;
        } catch (initError) {
          print("TTS Init Error: $initError");
          print("⚠️ AVISO CRÍTICO: Plugin flutter_tts não está registrado!");
          print("📋 SOLUÇÃO: Execute os seguintes comandos no terminal:");
          print("   1. flutter clean");
          print("   2. flutter pub get");
          print("   3. flutter run");
          print("   Isso recompilará o app e registrará o plugin corretamente.");
          return;
        }
      }
      
      if (_flutterTts == null) {
        print("TTS Error: FlutterTts é null");
        return;
      }
      
      await _flutterTts!.speak(text);
      print("TTS: Fala iniciada com sucesso");
    } on MissingPluginException catch (e) {
      print("TTS MissingPluginException: $e");
      print("⚠️ AVISO CRÍTICO: Plugin flutter_tts não está registrado!");
      print("📋 SOLUÇÃO: Execute os seguintes comandos no terminal:");
      print("   1. flutter clean");
      print("   2. flutter pub get");
      print("   3. flutter run");
      print("   Isso recompilará o app e registrará o plugin corretamente.");
    } catch (e) {
      print("TTS Error: $e");
      print("⚠️ AVISO: TTS requer rebuild completo do app.");
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts?.stop();
    } catch (e) {
      print("TTS Stop Error: $e");
    }
  }

  void dispose() {
    _flutterTts?.stop();
  }
}

