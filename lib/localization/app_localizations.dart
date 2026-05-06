import '../core/utils/library.dart';
import 'language_es.dart';
import 'language_de.dart';
import 'language_en.dart';
import 'language_fr.dart';
import 'language_pt.dart';
import 'languages.dart';

class AppLocalizations extends LocalizationsDelegate<BaseLanguage> {
  const AppLocalizations();

  @override
  Future<BaseLanguage> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'pt':
        return LanguagePt();
      case 'es':
        return LanguageEs();
      case 'fr':
        return LanguageFr();
      case 'de':
        return LanguageDe();
      case 'en':
      default:
        return LanguageEn();
    }
  }

  @override
  bool isSupported(Locale locale) => ['en', 'de', 'fr', 'pt', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_) => false;
}
