import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../core/constants/colors.dart';
import '../modules/settings/widget/webview.dart';

/// Third-party AI provider that user data is shared with.
///
/// Apple Guideline 5.1.1(i) / 5.1.2(i) requires the app to name the third party
/// that personal data is sent to. If the backend provider ever changes, update
/// only this constant.
const String kAiProviderName = 'Google (Gemini)';

const String kPrivacyPolicyUrl = 'https://sleepable.ai/privacy.html';

const String _kAiConsentKey = 'ai_data_consent_given';

/// True if the user has already agreed to AI data sharing.
bool hasAiConsent() => getBoolAsync(_kAiConsentKey, defaultValue: false);

/// Revokes consent (used by the "turn off" option in Settings).
Future<void> revokeAiConsent() async => await setValue(_kAiConsentKey, false);

/// Shows the AI consent dialog if the user has not granted permission yet.
/// Returns true once the user has consented (either now or previously).
///
/// ⚠️ Await this BEFORE sending any personal data to an AI endpoint.
Future<bool> ensureAiConsent(BuildContext context) async {
  if (hasAiConsent()) return true;

  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AiConsentDialog(),
  );

  if (agreed == true) {
    await setValue(_kAiConsentKey, true);
    return true;
  }
  return false;
}

class AiConsentDialog extends StatelessWidget {
  const AiConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = _stringsFor(Get.locale?.languageCode ?? 'en');

    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.title,
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    s.body,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => Get.to(() => WebViewScreen(title: s.policyLink, url: kPrivacyPolicyUrl)),
                child: Text(
                  s.policyLink,
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.lightBlueAccent,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    s.accept,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    s.decline,
                    style: const TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog strings are kept self-contained here to avoid adding new getters to the
/// BaseLanguage abstract class - that would require updating every language file,
/// and missing a single one would break the build.
class _ConsentStrings {
  final String title;
  final String body;
  final String policyLink;
  final String accept;
  final String decline;

  const _ConsentStrings({
    required this.title,
    required this.body,
    required this.policyLink,
    required this.accept,
    required this.decline,
  });
}

_ConsentStrings _stringsFor(String code) => _consentStrings[code] ?? _consentStrings['en']!;

/// Entry point for managing AI data sharing from Settings.
/// Opens the consent dialog when consent is missing; otherwise offers to turn it off.
Future<void> showAiDataSettings(BuildContext context) async {
  if (!hasAiConsent()) {
    await ensureAiConsent(context);
    return;
  }

  final revoke = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        _manage('label'),
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Text(
        _manage('body'),
        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(_manage('keep'), style: const TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(_manage('off'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (revoke == true) await revokeAiConsent();
}

/// Label shown on the Settings screen.
String aiDataSettingsLabel() => _manage('label');

String _manage(String key) {
  final map = _manageStrings[Get.locale?.languageCode ?? 'en'] ?? _manageStrings['en']!;
  return map[key] ?? _manageStrings['en']![key]!;
}

const Map<String, Map<String, String>> _manageStrings = {
  'en': {
    'label': 'AI & Data Sharing',
    'body': 'AI features are enabled. Your dream descriptions and sleep statistics are sent to '
        '$kAiProviderName to generate interpretations and insights.\n\nYou can turn this off at any time. '
        'AI features will stop working, but the rest of the app will continue as normal.',
    'keep': 'Keep enabled',
    'off': 'Turn off',
  },
  'de': {
    'label': 'KI & Datenfreigabe',
    'body': 'KI-Funktionen sind aktiviert. Ihre Traumbeschreibungen und Schlafstatistiken werden an '
        '$kAiProviderName gesendet, um Deutungen und Erkenntnisse zu erstellen.\n\nSie können dies jederzeit '
        'deaktivieren. KI-Funktionen werden dann nicht mehr arbeiten, die übrige App funktioniert normal weiter.',
    'keep': 'Aktiviert lassen',
    'off': 'Deaktivieren',
  },
  'fr': {
    'label': 'IA et partage de données',
    'body': "Les fonctionnalités d'IA sont activées. Vos descriptions de rêves et statistiques de sommeil sont "
        "envoyées à $kAiProviderName pour générer des interprétations et des analyses.\n\nVous pouvez désactiver "
        "cela à tout moment. Les fonctionnalités d'IA cesseront, mais le reste de l'application continuera normalement.",
    'keep': 'Garder activé',
    'off': 'Désactiver',
  },
  'es': {
    'label': 'IA y uso de datos',
    'body': 'Las funciones de IA están activadas. Tus descripciones de sueños y estadísticas de sueño se envían a '
        '$kAiProviderName para generar interpretaciones y análisis.\n\nPuedes desactivarlo cuando quieras. Las '
        'funciones de IA dejarán de funcionar, pero el resto de la app seguirá igual.',
    'keep': 'Mantener activado',
    'off': 'Desactivar',
  },
  'pt': {
    'label': 'IA e Compartilhamento de Dados',
    'body': 'Os recursos de IA estão ativados. Suas descrições de sonhos e estatísticas de sono são enviadas para '
        '$kAiProviderName para gerar interpretações e análises.\n\nVocê pode desativar a qualquer momento. Os '
        'recursos de IA vão parar, mas o restante do app continuará normal.',
    'keep': 'Manter ativado',
    'off': 'Desativar',
  },
};

/// Message shown when the user has declined AI consent.
String aiConsentDeclinedMessage() {
  const messages = <String, String>{
    'en': 'AI features need your permission before your data can be analysed. Tap to try again.',
    'de': 'KI-Funktionen benötigen Ihre Erlaubnis, bevor Ihre Daten analysiert werden können. Tippen Sie, um es erneut zu versuchen.',
    'fr': "Les fonctionnalités d'IA nécessitent votre autorisation avant l'analyse de vos données. Appuyez pour réessayer.",
    'es': 'Las funciones de IA necesitan tu permiso antes de analizar tus datos. Toca para intentarlo de nuevo.',
    'pt': 'Os recursos de IA precisam da sua permissão antes de analisar seus dados. Toque para tentar novamente.',
  };
  return messages[Get.locale?.languageCode ?? 'en'] ?? messages['en']!;
}

final Map<String, _ConsentStrings> _consentStrings = {
  'en': const _ConsentStrings(
    title: 'AI-powered features',
    body: 'Sleepable uses AI to interpret your dreams and analyse your sleep.\n\n'
        'What is sent:\n'
        '•  The dream descriptions and chat messages you write\n'
        '•  Your sleep statistics (duration, quality, patterns)\n\n'
        'Who it is sent to:\n'
        '•  $kAiProviderName, our third-party AI provider\n\n'
        'Why:\n'
        '•  To generate your dream interpretation, insights and personalised recommendations\n\n'
        'Your data is sent securely and is never sold. You can decline and still use the rest of the app.',
    policyLink: 'Read our Privacy Policy',
    accept: 'Agree & Continue',
    decline: 'Not now',
  ),
  'de': const _ConsentStrings(
    title: 'KI-gestützte Funktionen',
    body: 'Sleepable nutzt KI, um Ihre Träume zu deuten und Ihren Schlaf zu analysieren.\n\n'
        'Was gesendet wird:\n'
        '•  Die Traumbeschreibungen und Chat-Nachrichten, die Sie schreiben\n'
        '•  Ihre Schlafstatistiken (Dauer, Qualität, Muster)\n\n'
        'An wen es gesendet wird:\n'
        '•  $kAiProviderName, unser externer KI-Anbieter\n\n'
        'Warum:\n'
        '•  Um Ihre Traumdeutung, Erkenntnisse und personalisierten Empfehlungen zu erstellen\n\n'
        'Ihre Daten werden sicher übertragen und niemals verkauft. Sie können ablehnen und die übrige App weiterhin nutzen.',
    policyLink: 'Datenschutzrichtlinie lesen',
    accept: 'Zustimmen & fortfahren',
    decline: 'Jetzt nicht',
  ),
  'fr': const _ConsentStrings(
    title: 'Fonctionnalités basées sur l\'IA',
    body: 'Sleepable utilise l\'IA pour interpréter vos rêves et analyser votre sommeil.\n\n'
        'Ce qui est envoyé :\n'
        '•  Les descriptions de rêves et les messages que vous écrivez\n'
        '•  Vos statistiques de sommeil (durée, qualité, habitudes)\n\n'
        'À qui c\'est envoyé :\n'
        '•  $kAiProviderName, notre fournisseur d\'IA tiers\n\n'
        'Pourquoi :\n'
        '•  Pour générer votre interprétation des rêves, vos analyses et vos recommandations personnalisées\n\n'
        'Vos données sont transmises de façon sécurisée et ne sont jamais vendues. Vous pouvez refuser et continuer à utiliser le reste de l\'application.',
    policyLink: 'Lire notre politique de confidentialité',
    accept: 'Accepter et continuer',
    decline: 'Pas maintenant',
  ),
  'es': const _ConsentStrings(
    title: 'Funciones con IA',
    body: 'Sleepable usa IA para interpretar tus sueños y analizar tu descanso.\n\n'
        'Qué se envía:\n'
        '•  Las descripciones de sueños y los mensajes que escribes\n'
        '•  Tus estadísticas de sueño (duración, calidad, patrones)\n\n'
        'A quién se envía:\n'
        '•  $kAiProviderName, nuestro proveedor de IA externo\n\n'
        'Por qué:\n'
        '•  Para generar la interpretación de tus sueños, análisis y recomendaciones personalizadas\n\n'
        'Tus datos se envían de forma segura y nunca se venden. Puedes rechazarlo y seguir usando el resto de la app.',
    policyLink: 'Leer nuestra Política de Privacidad',
    accept: 'Aceptar y continuar',
    decline: 'Ahora no',
  ),
  'pt': const _ConsentStrings(
    title: 'Recursos com IA',
    body: 'O Sleepable usa IA para interpretar seus sonhos e analisar seu sono.\n\n'
        'O que é enviado:\n'
        '•  As descrições de sonhos e as mensagens que você escreve\n'
        '•  Suas estatísticas de sono (duração, qualidade, padrões)\n\n'
        'Para quem é enviado:\n'
        '•  $kAiProviderName, nosso provedor de IA terceirizado\n\n'
        'Por quê:\n'
        '•  Para gerar a interpretação dos seus sonhos, análises e recomendações personalizadas\n\n'
        'Seus dados são enviados com segurança e nunca são vendidos. Você pode recusar e continuar usando o restante do app.',
    policyLink: 'Ler nossa Política de Privacidade',
    accept: 'Concordar e continuar',
    decline: 'Agora não',
  ),
};
