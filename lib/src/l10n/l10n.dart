import 'package:flutter/widgets.dart';
import 'package:quarkdrop/l10n/generated/app_localizations.dart';

extension AppL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
