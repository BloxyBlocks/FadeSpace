import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('es', 'CO'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es_CO, this message translates to:
  /// **'FadeSpace Barbero'**
  String get appTitle;

  /// No description provided for @agendaTitle.
  ///
  /// In es_CO, this message translates to:
  /// **'Agenda de hoy'**
  String get agendaTitle;

  /// No description provided for @agendaSubtitle.
  ///
  /// In es_CO, this message translates to:
  /// **'Sede principal · America/Bogota'**
  String get agendaSubtitle;

  /// No description provided for @chairModeTitle.
  ///
  /// In es_CO, this message translates to:
  /// **'Modo Silla'**
  String get chairModeTitle;

  /// No description provided for @earningsTitle.
  ///
  /// In es_CO, this message translates to:
  /// **'Ganancias'**
  String get earningsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In es_CO, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @onlineStatus.
  ///
  /// In es_CO, this message translates to:
  /// **'En línea'**
  String get onlineStatus;

  /// No description provided for @offlineStatus.
  ///
  /// In es_CO, this message translates to:
  /// **'Sin conexión'**
  String get offlineStatus;

  /// No description provided for @nowServing.
  ///
  /// In es_CO, this message translates to:
  /// **'En silla'**
  String get nowServing;

  /// No description provided for @nextClient.
  ///
  /// In es_CO, this message translates to:
  /// **'Siguiente cliente'**
  String get nextClient;

  /// No description provided for @startService.
  ///
  /// In es_CO, this message translates to:
  /// **'Cliente en Silla'**
  String get startService;

  /// No description provided for @finishAndCharge.
  ///
  /// In es_CO, this message translates to:
  /// **'Finalizar y Cobrar'**
  String get finishAndCharge;

  /// No description provided for @quickBlock.
  ///
  /// In es_CO, this message translates to:
  /// **'Bloqueo rápido'**
  String get quickBlock;

  /// No description provided for @serviceHaircut.
  ///
  /// In es_CO, this message translates to:
  /// **'Corte clásico'**
  String get serviceHaircut;

  /// No description provided for @serviceBeard.
  ///
  /// In es_CO, this message translates to:
  /// **'Perfilado de barba'**
  String get serviceBeard;

  /// No description provided for @serviceCombo.
  ///
  /// In es_CO, this message translates to:
  /// **'Corte + barba'**
  String get serviceCombo;

  /// No description provided for @earningsToday.
  ///
  /// In es_CO, this message translates to:
  /// **'Hoy'**
  String get earningsToday;

  /// No description provided for @earningsWeek.
  ///
  /// In es_CO, this message translates to:
  /// **'Esta semana'**
  String get earningsWeek;

  /// No description provided for @commissionLabel.
  ///
  /// In es_CO, this message translates to:
  /// **'Comisión'**
  String get commissionLabel;

  /// No description provided for @settingsTenant.
  ///
  /// In es_CO, this message translates to:
  /// **'Barbería'**
  String get settingsTenant;

  /// No description provided for @settingsBarber.
  ///
  /// In es_CO, this message translates to:
  /// **'Barbero'**
  String get settingsBarber;

  /// No description provided for @settingsLocale.
  ///
  /// In es_CO, this message translates to:
  /// **'Idioma'**
  String get settingsLocale;

  /// No description provided for @settingsTimezone.
  ///
  /// In es_CO, this message translates to:
  /// **'Zona horaria'**
  String get settingsTimezone;

  /// No description provided for @settingsVersion.
  ///
  /// In es_CO, this message translates to:
  /// **'Versión'**
  String get settingsVersion;

  /// No description provided for @emptyAgenda.
  ///
  /// In es_CO, this message translates to:
  /// **'No hay citas para hoy'**
  String get emptyAgenda;

  /// No description provided for @retry.
  ///
  /// In es_CO, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @chairInstruction.
  ///
  /// In es_CO, this message translates to:
  /// **'Confirma el servicio y cobra en un solo toque.'**
  String get chairInstruction;

  /// No description provided for @clientArrived.
  ///
  /// In es_CO, this message translates to:
  /// **'Cliente presente'**
  String get clientArrived;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case 'CO':
            return AppLocalizationsEsCo();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
