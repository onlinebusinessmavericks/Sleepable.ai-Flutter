import 'package:flutter/widgets.dart';
import 'languages.dart';

extension LangExtension on BuildContext {
  BaseLanguage get lang => BaseLanguage.of(this)!;
}
