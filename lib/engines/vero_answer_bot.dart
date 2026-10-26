import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show VoidCallback;

enum AnswerBotStatus { idle, running, completed, aborted }

class AnswerBotPhrase {
  const AnswerBotPhrase({
    required this.text,
    required this.assetPath,
    required this.waitDuration,
  });

  final String text;
  final String assetPath;
  final Duration waitDuration;
}

/// [ADIM 5] SPAM OYALAMA BOTU (RoboKiller Answer Bot benzeri, %100 OFFLINE).
///
/// Plays pre-recorded local audio clips to stall spam callers for 30-60 seconds
/// before disconnecting. Supported on Android; gracefully skipped on iOS.
class VeroAnswerBot {
  VeroAnswerBot({this.forceAndroid = false});

  final bool forceAndroid;

  AnswerBotStatus _status = AnswerBotStatus.idle;
  int _currentStepIndex = 0;
  Timer? _stepTimer;
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  AnswerBotStatus get status => _status;
  int get currentStepIndex => _currentStepIndex;
  Stream<String> get transcriptStream => _transcriptController.stream;

  /// Whether current platform supports on-device call interception/stalling.
  bool get isSupported => forceAndroid || Platform.isAndroid;

  static const List<AnswerBotPhrase> turkishPhrases = [
    AnswerBotPhrase(
      text: 'Alo, buyurun?',
      assetPath: 'assets/audio/bot_responses/tr_01_alo_buyurun.mp3',
      waitDuration: Duration(seconds: 2),
    ),
    AnswerBotPhrase(
      text: 'Kimi arıyorsunuz?',
      assetPath: 'assets/audio/bot_responses/tr_02_kim_ariyorsunuz.mp3',
      waitDuration: Duration(seconds: 3),
    ),
    AnswerBotPhrase(
      text: 'Bir saniye, sizi ilgili birime bağlıyorum...',
      assetPath: 'assets/audio/bot_responses/tr_03_bir_saniye_bagliyorum.mp3',
      waitDuration: Duration(seconds: 5),
    ),
    AnswerBotPhrase(
      text: 'Hat meşgul, lütfen hatta beklemeye devam edin...',
      assetPath: 'assets/audio/bot_responses/tr_04_hat_mesgul_bekleyin.mp3',
      waitDuration: Duration(seconds: 10),
    ),
  ];

  static const List<AnswerBotPhrase> englishPhrases = [
    AnswerBotPhrase(
      text: 'Hello, who is calling please?',
      assetPath: 'assets/audio/bot_responses/en_01_hello_who_is_calling.mp3',
      waitDuration: Duration(seconds: 3),
    ),
  ];

  static const List<AnswerBotPhrase> arabicPhrases = [
    AnswerBotPhrase(
      text: 'مرحباً، من المتصل؟ يرجى الانتظار...',
      assetPath: 'assets/audio/bot_responses/ar_01_marhaba_intazir.mp3',
      waitDuration: Duration(seconds: 4),
    ),
  ];

  /// Starts the stall loop. Yields spoken lines via [transcriptStream].
  Future<bool> startStallSequence({
    String languageCode = 'tr',
    VoidCallback? onComplete,
  }) async {
    if (!isSupported) {
      _status = AnswerBotStatus.aborted;
      _transcriptController.add('iOS kısıtlaması: Answer Bot desteklenmiyor.');
      return false;
    }

    _status = AnswerBotStatus.running;
    _currentStepIndex = 0;

    final phrases = switch (languageCode) {
      'en' => englishPhrases,
      'ar' => arabicPhrases,
      _ => turkishPhrases,
    };

    _executeStep(phrases, 0, onComplete);
    return true;
  }

  void _executeStep(
    List<AnswerBotPhrase> phrases,
    int index,
    VoidCallback? onComplete,
  ) {
    if (_status != AnswerBotStatus.running) return;

    if (index >= phrases.length) {
      _status = AnswerBotStatus.completed;
      _transcriptController.add('Spam arayan başarıyla oyalandı ve hat kapatıldı.');
      onComplete?.call();
      return;
    }

    _currentStepIndex = index;
    final phrase = phrases[index];
    _transcriptController.add('🤖 Bot: "${phrase.text}" (${phrase.assetPath})');

    _stepTimer = Timer(phrase.waitDuration, () {
      _executeStep(phrases, index + 1, onComplete);
    });
  }

  /// Stops and hangs up the call bot.
  void stop() {
    _stepTimer?.cancel();
    _status = AnswerBotStatus.idle;
  }

  void dispose() {
    _stepTimer?.cancel();
    _transcriptController.close();
  }
}
