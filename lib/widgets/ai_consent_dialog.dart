import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../core/constants/colors.dart';
import '../data/services/api_sevices.dart';
import '../modules/settings/widget/webview.dart';
import '../routes/app_pages.dart';

/// Third-party AI provider that user data is shared with.
///
/// Apple Guideline 5.1.1(i) / 5.1.2(i) requires the app to name the third party
/// that personal data is sent to. If the backend provider ever changes, update
/// only this constant.
const String kAiProviderName = 'Google (Gemini)';

const String kPrivacyPolicyUrl = 'https://sleepable.ai/privacy.html';

const String _kAiConsentKey = 'ai_data_consent_given';

/// Tracks whether the user has been asked at all, so that someone who declined
/// is not prompted again on every app launch.
const String _kAiConsentAskedKey = 'ai_data_consent_asked';

/// True if the user has agreed to AI data sharing.
bool hasAiConsent() => getBoolAsync(_kAiConsentKey, defaultValue: false);

/// True once the user has answered the consent prompt, either way.
bool hasAiConsentBeenAsked() => getBoolAsync(_kAiConsentAskedKey, defaultValue: false);

/// Stores the user's choice locally and mirrors it to the backend.
///
/// The backend refuses AI requests and skips background AI processing unless
/// its own flag is true, so both sides must agree.
Future<void> setAiConsent(bool value) async {
  await setValue(_kAiConsentKey, value);
  await setValue(_kAiConsentAskedKey, true);
  await AiConsentApis.setAiConsent(value);
}

/// Revokes consent (used by the "turn off" option in Settings).
Future<void> revokeAiConsent() async => await setAiConsent(false);

/// Pulls the authoritative flag from the backend so the app matches the server
/// (e.g. after a reinstall or on a second device). Safe to call on app start.
Future<void> syncAiConsentFromServer() async {
  final remote = await AiConsentApis.getAiConsent();
  if (remote == null) return; // offline or failed - keep the local value
  await setValue(_kAiConsentKey, remote);
  if (remote) await setValue(_kAiConsentAskedKey, true);
}

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

  await setAiConsent(agreed == true);
  return agreed == true;
}

/// Shows the consent prompt once per user, on app open.
///
/// Does nothing if the user has already answered it. Call this after the first
/// frame so a Navigator is available.
Future<void> maybeShowAiConsentOnAppOpen(BuildContext context) async {
  await syncAiConsentFromServer();
  if (hasAiConsent() || hasAiConsentBeenAsked()) return;
  await ensureAiConsent(context);
}

/// Called when the backend rejects a request with AI_CONSENT_REQUIRED (403).
///
/// The server is the source of truth, so the local flag is cleared and the user
/// is offered a shortcut to the Settings screen to turn AI features on.
void handleAiConsentRequired([String? message]) {
  setValue(_kAiConsentKey, false);

  if (Get.isSnackbarOpen == true) return;
  Get.snackbar(
    _manage('label'),
    (message == null || message.isEmpty) ? _manage('required') : message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.background,
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 6),
    mainButton: TextButton(
      onPressed: () {
        if (Get.isSnackbarOpen == true) Get.closeCurrentSnackbar();
        Get.toNamed(Routes.settings);
      },
      child: Text(
        _manage('openSettings'),
        style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
      ),
    ),
  );
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
    'required': 'AI features require your consent. Please enable AI features in Settings.',
    'openSettings': 'Settings',
  },
  'de': {
    'label': 'KI & Datenfreigabe',
    'body': 'KI-Funktionen sind aktiviert. Ihre Traumbeschreibungen und Schlafstatistiken werden an '
        '$kAiProviderName gesendet, um Deutungen und Erkenntnisse zu erstellen.\n\nSie können dies jederzeit '
        'deaktivieren. KI-Funktionen werden dann nicht mehr arbeiten, die übrige App funktioniert normal weiter.',
    'keep': 'Aktiviert lassen',
    'off': 'Deaktivieren',
    'required': 'KI-Funktionen erfordern Ihre Zustimmung. Bitte aktivieren Sie sie in den Einstellungen.',
    'openSettings': 'Einstellungen',
  },
  'fr': {
    'label': 'IA et partage de données',
    'body': "Les fonctionnalités d'IA sont activées. Vos descriptions de rêves et statistiques de sommeil sont "
        "envoyées à $kAiProviderName pour générer des interprétations et des analyses.\n\nVous pouvez désactiver "
        "cela à tout moment. Les fonctionnalités d'IA cesseront, mais le reste de l'application continuera normalement.",
    'keep': 'Garder activé',
    'off': 'Désactiver',
    'required': "Les fonctionnalités d'IA nécessitent votre consentement. Activez-les dans les Réglages.",
    'openSettings': 'Réglages',
  },
  'es': {
    'label': 'IA y uso de datos',
    'body': 'Las funciones de IA están activadas. Tus descripciones de sueños y estadísticas de sueño se envían a '
        '$kAiProviderName para generar interpretaciones y análisis.\n\nPuedes desactivarlo cuando quieras. Las '
        'funciones de IA dejarán de funcionar, pero el resto de la app seguirá igual.',
    'keep': 'Mantener activado',
    'off': 'Desactivar',
    'required': 'Las funciones de IA requieren tu consentimiento. Actívalas en Ajustes.',
    'openSettings': 'Ajustes',
  },
  'pt': {
    'label': 'IA e Compartilhamento de Dados',
    'body': 'Os recursos de IA estão ativados. Suas descrições de sonhos e estatísticas de sono são enviadas para '
        '$kAiProviderName para gerar interpretações e análises.\n\nVocê pode desativar a qualquer momento. Os '
        'recursos de IA vão parar, mas o restante do app continuará normal.',
    'keep': 'Manter ativado',
    'off': 'Desativar',
    'required': 'Os recursos de IA exigem seu consentimento. Ative-os em Configurações.',
    'openSettings': 'Configurações',
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
        '•  Any sleep notes you type\n'
        '•  Your sleep statistics (duration, quality, patterns)\n\n'
        'Who it is sent to:\n'
        '•  $kAiProviderName, our third-party AI provider\n\n'
        'Why:\n'
        '•  To generate your dream interpretation, insights and personalised recommendations\n\n'
        'Some of this analysis runs automatically in the background after a sleep session.\n\n'
        'We never send your name, email, phone number or payment details. Your data is not sold. '
        'You can decline and still use the rest of the app, and change this later in Settings.',
    policyLink: 'Read our Privacy Policy',
    accept: 'Agree',
    decline: 'Decline',
  ),
  'de': const _ConsentStrings(
    title: 'KI-gestützte Funktionen',
    body: 'Sleepable nutzt KI, um Ihre Träume zu deuten und Ihren Schlaf zu analysieren.\n\n'
        'Was gesendet wird:\n'
        '•  Die Traumbeschreibungen und Chat-Nachrichten, die Sie schreiben\n'
        '•  Alle Schlafnotizen, die Sie eingeben\n'
        '•  Ihre Schlafstatistiken (Dauer, Qualität, Muster)\n\n'
        'An wen es gesendet wird:\n'
        '•  $kAiProviderName, unser externer KI-Anbieter\n\n'
        'Warum:\n'
        '•  Um Ihre Traumdeutung, Erkenntnisse und personalisierten Empfehlungen zu erstellen\n\n'
        'Ein Teil dieser Analyse läuft nach einer Schlafsitzung automatisch im Hintergrund.\n\n'
        'Wir senden niemals Ihren Namen, Ihre E-Mail-Adresse, Telefonnummer oder Zahlungsdaten. '
        'Ihre Daten werden nicht verkauft. Sie können ablehnen und die übrige App weiterhin nutzen '
        'und dies später in den Einstellungen ändern.',
    policyLink: 'Datenschutzrichtlinie lesen',
    accept: 'Zustimmen',
    decline: 'Ablehnen',
  ),
  'fr': const _ConsentStrings(
    title: 'Fonctionnalités basées sur l\'IA',
    body: 'Sleepable utilise l\'IA pour interpréter vos rêves et analyser votre sommeil.\n\n'
        'Ce qui est envoyé :\n'
        '•  Les descriptions de rêves et les messages que vous écrivez\n'
        '•  Les notes de sommeil que vous saisissez\n'
        '•  Vos statistiques de sommeil (durée, qualité, habitudes)\n\n'
        'À qui c\'est envoyé :\n'
        '•  $kAiProviderName, notre fournisseur d\'IA tiers\n\n'
        'Pourquoi :\n'
        '•  Pour générer votre interprétation des rêves, vos analyses et vos recommandations personnalisées\n\n'
        'Une partie de cette analyse s\'exécute automatiquement en arrière-plan après une session de sommeil.\n\n'
        'Nous n\'envoyons jamais votre nom, e-mail, numéro de téléphone ou données de paiement. '
        'Vos données ne sont pas vendues. Vous pouvez refuser et continuer à utiliser le reste de '
        'l\'application, et modifier ce choix plus tard dans les Réglages.',
    policyLink: 'Lire notre politique de confidentialité',
    accept: 'Accepter',
    decline: 'Refuser',
  ),
  'es': const _ConsentStrings(
    title: 'Funciones con IA',
    body: 'Sleepable usa IA para interpretar tus sueños y analizar tu descanso.\n\n'
        'Qué se envía:\n'
        '•  Las descripciones de sueños y los mensajes que escribes\n'
        '•  Las notas de sueño que escribas\n'
        '•  Tus estadísticas de sueño (duración, calidad, patrones)\n\n'
        'A quién se envía:\n'
        '•  $kAiProviderName, nuestro proveedor de IA externo\n\n'
        'Por qué:\n'
        '•  Para generar la interpretación de tus sueños, análisis y recomendaciones personalizadas\n\n'
        'Parte de este análisis se ejecuta automáticamente en segundo plano tras una sesión de sueño.\n\n'
        'Nunca enviamos tu nombre, correo electrónico, teléfono ni datos de pago. Tus datos no se '
        'venden. Puedes rechazarlo y seguir usando el resto de la app, y cambiarlo luego en Ajustes.',
    policyLink: 'Leer nuestra Política de Privacidad',
    accept: 'Aceptar',
    decline: 'Rechazar',
  ),
  'pt': const _ConsentStrings(
    title: 'Recursos com IA',
    body: 'O Sleepable usa IA para interpretar seus sonhos e analisar seu sono.\n\n'
        'O que é enviado:\n'
        '•  As descrições de sonhos e as mensagens que você escreve\n'
        '•  As notas de sono que você digitar\n'
        '•  Suas estatísticas de sono (duração, qualidade, padrões)\n\n'
        'Para quem é enviado:\n'
        '•  $kAiProviderName, nosso provedor de IA terceirizado\n\n'
        'Por quê:\n'
        '•  Para gerar a interpretação dos seus sonhos, análises e recomendações personalizadas\n\n'
        'Parte dessa análise é executada automaticamente em segundo plano após uma sessão de sono.\n\n'
        'Nunca enviamos seu nome, e-mail, telefone ou dados de pagamento. Seus dados não são vendidos. '
        'Você pode recusar e continuar usando o restante do app, e alterar isso depois em Configurações.',
    policyLink: 'Ler nossa Política de Privacidade',
    accept: 'Concordar',
    decline: 'Recusar',
  ),
};
