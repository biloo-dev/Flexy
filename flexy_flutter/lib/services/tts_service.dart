import 'dart:io';

class TtsService {
  static final TtsService instance = TtsService._internal();

  TtsService._internal();

  Future<void> speak(String text) async {
    try {
      final sanitizedText = text.replaceAll("'", "''").replaceAll('"', '');
      if (Platform.isWindows) {
        final psCommand =
            'Add-Type -AssemblyName System.Speech; \$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer; \$synth.Speak(\'$sanitizedText\')';
        Process.run('powershell', ['-Command', psCommand]);
      }
    } catch (_) {}
  }

  Future<void> stop() async {
    // Stop speech synthesis if needed
  }
}
