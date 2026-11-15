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
  /// **'FadeSpace'**
  String get appTitle;

  /// No description provided for @bookingTitle.
  ///
  /// In es_CO, this message translates to:
  /// **'Reserva tu cita'**
  String get bookingTitle;

  /// No description provided for @bookingSubtitle.
  ///
  /// In es_CO, this message translates to:
  /// **'Barbería El Roble · Sede principal'**
  String get bookingSubtitle;

  /// No description provided for @stepService.
  ///
  /// In es_CO, this message translates to:
  /// **'Servicio'**
  String get stepService;

  /// No description provided for @stepBarber.
  ///
  /// In es_CO, this message translates to:
  /// **'Barbero'**
  String get stepBarber;

  /// No description provided for @stepSlot.
  ///
  /// In es_CO, this message translates to:
  /// **'Franja'**
  String get stepSlot;

  /// No description provided for @stepData.
  ///
  /// In es_CO, this message translates to:
  /// **'Tus datos'**
  String get stepData;

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

  /// No description provided for @barberAndres.
  ///
  /// In es_CO, this message translates to:
  /// **'Andrés'**
  String get barberAndres;

  /// No description provided for @barberCamilo.
  ///
  /// In es_CO, this message translates to:
  /// **'Camilo'**
  String get barberCamilo;

  /// No description provided for @slotMorning.
  ///
  /// In es_CO, this message translates to:
  /// **'10:00 a. m.'**
  String get slotMorning;

  /// No description provided for @slotMidday.
  ///
  /// In es_CO, this message translates to:
  /// **'12:30 p. m.'**
  String get slotMidday;

  /// No description provided for @slotAfternoon.
  ///
  /// In es_CO, this message translates to:
  /// **'4:00 p. m.'**
  String get slotAfternoon;

  /// No description provided for @continueLabel.
  ///
  /// In es_CO, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// No description provided for @confirmBooking.
  ///
  /// In es_CO, this message translates to:
  /// **'Confirmar reserva'**
  String get confirmBooking;

  /// No description provided for @bookingConfirmedTitle.
  ///
  /// In es_CO, this message translates to:
  /// **'¡Cita confirmada!'**
  String get bookingConfirmedTitle;

  /// No description provided for @bookingConfirmedBody.
  ///
  /// In es_CO, this message translates to:
  /// **'Te enviamos el detalle por WhatsApp.'**
  String get bookingConfirmedBody;

  /// No description provided for @myAppointmentTitle.
  ///
  /// In es_CO, this message translates to:
  /// **'Mi cita'**
  String get myAppointmentTitle;

  /// No description provided for @queueStatusTitle.
  ///
  /// In es_CO, this message translates to:
  /// **'Estado de la fila'**
  String get queueStatusTitle;

  /// No description provided for @estimatedWait.
  ///
  /// In es_CO, this message translates to:
  /// **'Espera estimada'**
  String get estimatedWait;

  /// No description provided for @cancelAppointment.
  ///
  /// In es_CO, this message translates to:
  /// **'Cancelar cita'**
  String get cancelAppointment;

  /// No description provided for @rescheduleAppointment.
  ///
  /// In es_CO, this message translates to:
  /// **'Reprogramar'**
  String get rescheduleAppointment;

  /// No description provided for @phoneLabel.
  ///
  /// In es_CO, this message translates to:
  /// **'Teléfono'**
  String get phoneLabel;

  /// No description provided for @otpLabel.
  ///
  /// In es_CO, this message translates to:
  /// **'Código de verificación'**
  String get otpLabel;

  /// No description provided for @otpSent.
  ///
  /// In es_CO, this message translates to:
  /// **'Enviamos un código de 6 dígitos por SMS.'**
  String get otpSent;

  /// No description provided for @privacyNotice.
  ///
  /// In es_CO, this message translates to:
  /// **'Usamos tus datos solo para gestionar la cita.'**
  String get privacyNotice;

  /// No description provided for @backLabel.
  ///
  /// In es_CO, this message translates to:
  /// **'Volver'**
  String get backLabel;

  /// No description provided for @oneTapBooking.
  ///
  /// In es_CO, this message translates to:
  /// **'Reserva en menos de 15 segundos'**
  String get oneTapBooking;

  /// No description provided for @offlineNotice.
  ///
  /// In es_CO, this message translates to:
  /// **'Sin conexión: reintentaremos automáticamente.'**
  String get offlineNotice;
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
