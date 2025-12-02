import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class GeminiTTSService {
  
  final String _apiKey = '';
  final String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent';

  final AudioPlayer _audioPlayer = AudioPlayer();

  GeminiTTSService() {
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Uint8List _pcmToWav(Int16List pcmData, int sampleRate) {
    // Tamanho dos dados (em bytes)
    int dataLength = pcmData.length * 2;
    int totalLength = 44 + dataLength;

    ByteData buffer = ByteData(totalLength);
    int offset = 0;

    // RIFF chunk
    buffer.setUint8(offset, 0x52); offset += 1; // 'R'
    buffer.setUint8(offset, 0x49); offset += 1; // 'I'
    buffer.setUint8(offset, 0x46); offset += 1; // 'F'
    buffer.setUint8(offset, 0x46); offset += 1; // 'F'
    buffer.setUint32(offset, dataLength + 36, Endian.little); offset += 4;
    buffer.setUint8(offset, 0x57); offset += 1; // 'W'
    buffer.setUint8(offset, 0x41); offset += 1; // 'A'
    buffer.setUint8(offset, 0x56); offset += 1; // 'V'
    buffer.setUint8(offset, 0x45); offset += 1; // 'E'

    // fmt chunk
    buffer.setUint8(offset, 0x66); offset += 1; // 'f'
    buffer.setUint8(offset, 0x6d); offset += 1; // 'm'
    buffer.setUint8(offset, 0x74); offset += 1; // 't'
    buffer.setUint8(offset, 0x20); offset += 1; // ' '
    buffer.setUint32(offset, 16, Endian.little); offset += 4; // Subchunk1Size
    buffer.setUint16(offset, 1, Endian.little); offset += 2; // AudioFormat (1 = PCM)
    buffer.setUint16(offset, 1, Endian.little); offset += 2; // NumChannels (1 = Mono)
    buffer.setUint32(offset, sampleRate, Endian.little); offset += 4;
    buffer.setUint32(offset, sampleRate * 2, Endian.little); offset += 4; // ByteRate
    buffer.setUint16(offset, 2, Endian.little); offset += 2; // BlockAlign (2 bytes for 16-bit mono)
    buffer.setUint16(offset, 16, Endian.little); offset += 2; // BitsPerSample (16 bits)

    // data chunk
    buffer.setUint8(offset, 0x64); offset += 1; // 'd'
    buffer.setUint8(offset, 0x61); offset += 1; // 'a'
    buffer.setUint8(offset, 0x74); offset += 1; // 't'
    buffer.setUint8(offset, 0x61); offset += 1; // 'a'
    buffer.setUint32(offset, dataLength, Endian.little); offset += 4;

    // Escreve os dados PCM no buffer
    for (int i = 0; i < pcmData.length; i++) {
      buffer.setInt16(offset, pcmData[i], Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  /// Realiza a chamada à API do Gemini para gerar áudio TTS.
  Future<void> speak(String text) async {
    final payload = {
      "contents": [
        {
          "parts": [
            {"text": text}
          ]
        }
      ],
      "generationConfig": {
        "responseModalities": ["AUDIO"],
        "speechConfig": {
          "voiceConfig": {
            "prebuiltVoiceConfig": {"voiceName": "Puck"}
          },
          "languageCode": "pt-BR"
        }
      },
      "model": "gemini-2.5-flash-preview-tts"
    };

    try {
      final response = await http.post(
        Uri.parse("$_apiUrl?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        print("TTS Error: Status ${response.statusCode}, Body: ${response.body}");
        return;
      }

      final result = json.decode(response.body);
      final part = result['candidates']?[0]?['content']?['parts']?[0];
      final audioDataB64 = part?['inlineData']?['data'];
      final mimeType = part?['inlineData']?['mimeType'];

      if (audioDataB64 == null || mimeType == null || !mimeType.startsWith('audio/L16')) {
        print("TTS Error: Dados de áudio inválidos ou ausentes.");
        return;
      }

      // Extrai o Sample Rate do MimeType (ex: audio/L16;rate=24000)
      final rateMatch = RegExp(r'rate=(\d+)').firstMatch(mimeType);
      final sampleRate = rateMatch != null ? int.parse(rateMatch.group(1)!) : 24000;

      // Converte Base64 para Raw PCM Data
      final pcmDataBytes = base64.decode(audioDataB64);
      final pcm16 = Int16List.view(pcmDataBytes.buffer);

      final wavData = _pcmToWav(pcm16, sampleRate);

      // Cria um Blob/URI para o AudioPlayer
      await _audioPlayer.play(
          BytesSource(wavData)
      );

    } catch (e) {
      print("TTS Fatal Error: $e");
    }
  }

  // Libera o AudioPlayer quando a classe for descartada
  void dispose() {
    _audioPlayer.dispose();
  }
}