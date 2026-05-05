import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ru.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('he'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kiosk'**
  String get appName;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'SELF-CHECKOUT · FW26'**
  String get splashTagline;

  /// No description provided for @topBarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SELF-CHECKOUT'**
  String get topBarSubtitle;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @heroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'FW26 COLLECTION'**
  String get heroEyebrow;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Style,\nuninterrupted.'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout, reimagined.\nNo queues. No rush.'**
  String get heroSubtitle;

  /// No description provided for @clickToStart.
  ///
  /// In en, this message translates to:
  /// **'Click To Start'**
  String get clickToStart;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @adFw26Title.
  ///
  /// In en, this message translates to:
  /// **'Up to 30% off the FW26 edit'**
  String get adFw26Title;

  /// No description provided for @adFw26Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Selected outerwear & knitwear'**
  String get adFw26Subtitle;

  /// No description provided for @adAlterationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Free alterations for members'**
  String get adAlterationsTitle;

  /// No description provided for @adAlterationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tailoring on every full-price piece'**
  String get adAlterationsSubtitle;

  /// No description provided for @adSpringTitle.
  ///
  /// In en, this message translates to:
  /// **'Just landed: Spring resort'**
  String get adSpringTitle;

  /// No description provided for @adSpringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover the new arrivals'**
  String get adSpringSubtitle;

  /// No description provided for @yourBag.
  ///
  /// In en, this message translates to:
  /// **'Your Bag'**
  String get yourBag;

  /// No description provided for @placePieces.
  ///
  /// In en, this message translates to:
  /// **'Place each piece on the reader'**
  String get placePieces;

  /// No description provided for @piecesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 piece added} other{{count} pieces added}}'**
  String piecesAdded(int count);

  /// No description provided for @bagEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your bag is empty'**
  String get bagEmpty;

  /// No description provided for @bagEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Place your selected pieces on\nthe reader pad to add them.'**
  String get bagEmptyHint;

  /// No description provided for @simulateScan.
  ///
  /// In en, this message translates to:
  /// **'Simulate Scan'**
  String get simulateScan;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @youSaved.
  ///
  /// In en, this message translates to:
  /// **'You saved {amount}'**
  String youSaved(String amount);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @cancelSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel session?'**
  String get cancelSessionTitle;

  /// No description provided for @cancelSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Your bag will be emptied and you will return to the welcome screen.'**
  String get cancelSessionBody;

  /// No description provided for @keepShopping.
  ///
  /// In en, this message translates to:
  /// **'Keep shopping'**
  String get keepShopping;

  /// No description provided for @cancelSession.
  ///
  /// In en, this message translates to:
  /// **'Cancel session'**
  String get cancelSession;

  /// No description provided for @removeFromBag.
  ///
  /// In en, this message translates to:
  /// **'Remove from bag'**
  String get removeFromBag;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size {size}'**
  String size(String size);

  /// No description provided for @stockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String stockCount(int count);

  /// No description provided for @skuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU {sku}'**
  String skuLabel(String sku);

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode {code}'**
  String barcodeLabel(String code);

  /// No description provided for @sectionMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get sectionMaterial;

  /// No description provided for @sectionOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get sectionOrigin;

  /// No description provided for @sectionCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get sectionCare;

  /// No description provided for @genderMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get genderMen;

  /// No description provided for @genderWomen.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get genderWomen;

  /// No description provided for @genderUnisex.
  ///
  /// In en, this message translates to:
  /// **'Unisex'**
  String get genderUnisex;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @finishDemo.
  ///
  /// In en, this message translates to:
  /// **'Finish (demo)'**
  String get finishDemo;

  /// No description provided for @paymentComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Payment integration coming next'**
  String get paymentComingSoon;

  /// No description provided for @paymentSelectMethods.
  ///
  /// In en, this message translates to:
  /// **'Select payment methods'**
  String get paymentSelectMethods;

  /// No description provided for @paymentSplitHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a method to assign an amount. You can combine several.'**
  String get paymentSplitHint;

  /// No description provided for @paymentMethodCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get paymentMethodCreditCard;

  /// No description provided for @paymentMethodMemberCard.
  ///
  /// In en, this message translates to:
  /// **'Member card'**
  String get paymentMethodMemberCard;

  /// No description provided for @paymentMethodGiftCard.
  ///
  /// In en, this message translates to:
  /// **'Gift card'**
  String get paymentMethodGiftCard;

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get paymentAmount;

  /// No description provided for @paymentRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get paymentRemaining;

  /// No description provided for @paymentAllocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get paymentAllocated;

  /// No description provided for @paymentPayRemaining.
  ///
  /// In en, this message translates to:
  /// **'Pay remaining'**
  String get paymentPayRemaining;

  /// No description provided for @paymentClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get paymentClear;

  /// No description provided for @paymentApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get paymentApply;

  /// No description provided for @paymentPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String paymentPayNow(String amount);

  /// No description provided for @paymentEnterAmountTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter amount for {method}'**
  String paymentEnterAmountTitle(String method);

  /// No description provided for @paymentMaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Max {amount}'**
  String paymentMaxAmount(String amount);

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you for shopping with us.'**
  String get paymentSuccessBody;

  /// No description provided for @paymentDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get paymentDone;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authorized staff access only'**
  String get loginSubtitle;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get loginSignIn;

  /// No description provided for @loginSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get loginSigningIn;

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get loginEmailRequired;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get loginPasswordRequired;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;
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
      <String>['ar', 'en', 'he', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
