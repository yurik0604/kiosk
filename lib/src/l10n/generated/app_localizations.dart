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
  /// **'The bin is empty'**
  String get bagEmpty;

  /// No description provided for @bagEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Place all your items in the\nRFID bin and they will be\nadded automatically.'**
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

  /// No description provided for @youSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'You saved'**
  String get youSavedLabel;

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

  /// No description provided for @confirmQtyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your bag'**
  String get confirmQtyTitle;

  /// No description provided for @confirmQtyBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Please verify 1 item is in the bin before paying.} other{Please verify {count} items are in the bin before paying.}}'**
  String confirmQtyBody(int count);

  /// No description provided for @confirmQtyItemsSection.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get confirmQtyItemsSection;

  /// No description provided for @confirmQtyItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item to verify} other{{count} items to verify}}'**
  String confirmQtyItemsLabel(int count);

  /// No description provided for @confirmQtyBagsSection.
  ///
  /// In en, this message translates to:
  /// **'Shopping bags'**
  String get confirmQtyBagsSection;

  /// No description provided for @confirmQtyBagsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bag added} other{{count} bags added}}'**
  String confirmQtyBagsLabel(int count);

  /// No description provided for @confirmQtyNoBagsTitle.
  ///
  /// In en, this message translates to:
  /// **'No bag added'**
  String get confirmQtyNoBagsTitle;

  /// No description provided for @confirmQtyNoBagsBody.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added a bag to your order.'**
  String get confirmQtyNoBagsBody;

  /// No description provided for @confirmQtyNoBagsYes.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get confirmQtyNoBagsYes;

  /// No description provided for @confirmQtyNoBagsNo.
  ///
  /// In en, this message translates to:
  /// **'No, continue'**
  String get confirmQtyNoBagsNo;

  /// No description provided for @confirmQtyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm and pay'**
  String get confirmQtyConfirm;

  /// No description provided for @confirmQtyBack.
  ///
  /// In en, this message translates to:
  /// **'Back to review'**
  String get confirmQtyBack;

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

  /// No description provided for @removeFromBagTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this item?'**
  String get removeFromBagTitle;

  /// No description provided for @removeFromBagBody.
  ///
  /// In en, this message translates to:
  /// **'This piece will be taken out of your bag.'**
  String get removeFromBagBody;

  /// No description provided for @removeFromBagConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removeFromBagConfirm;

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

  /// No description provided for @paymentMethodGiftCard.
  ///
  /// In en, this message translates to:
  /// **'Gift card'**
  String get paymentMethodGiftCard;

  /// No description provided for @paymentMethodCreditCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visa, Mastercard, American Express · Tap or insert'**
  String get paymentMethodCreditCardSubtitle;

  /// No description provided for @paymentMethodGiftCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Redeem a gift card or voucher'**
  String get paymentMethodGiftCardSubtitle;

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

  /// No description provided for @paymentTerminalTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow instructions on the terminal'**
  String get paymentTerminalTitle;

  /// No description provided for @paymentTerminalBody.
  ///
  /// In en, this message translates to:
  /// **'Insert, tap, or swipe your card on the payment terminal.'**
  String get paymentTerminalBody;

  /// No description provided for @paymentTerminalProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing payment'**
  String get paymentTerminalProcessing;

  /// No description provided for @paymentTerminalProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'Please don\'t remove your card.'**
  String get paymentTerminalProcessingBody;

  /// No description provided for @paymentTerminalAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get paymentTerminalAmount;

  /// No description provided for @paymentApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'Your card was approved.'**
  String get paymentApprovedBody;

  /// No description provided for @paymentReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Please take your receipt'**
  String get paymentReceiptTitle;

  /// No description provided for @paymentReceiptBody.
  ///
  /// In en, this message translates to:
  /// **'Your receipt is printing. Take it from the printer and tap Finish.'**
  String get paymentReceiptBody;

  /// No description provided for @paymentFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get paymentFinish;

  /// No description provided for @paymentDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment declined'**
  String get paymentDeclinedTitle;

  /// No description provided for @paymentDeclinedBody.
  ///
  /// In en, this message translates to:
  /// **'The terminal could not complete the transaction. Please try again.'**
  String get paymentDeclinedBody;

  /// No description provided for @paymentRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get paymentRetry;

  /// No description provided for @thankYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get thankYouTitle;

  /// No description provided for @thankYouBody.
  ///
  /// In en, this message translates to:
  /// **'We hope to see you again soon.'**
  String get thankYouBody;

  /// No description provided for @thankYouAutoClose.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =0{Closing…} =1{Closing in 1 second…} other{Closing in {seconds} seconds…}}'**
  String thankYouAutoClose(int seconds);

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

  /// No description provided for @memberLookupTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you a club member?'**
  String get memberLookupTitle;

  /// No description provided for @memberLookupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number or member ID to enjoy your benefits — or skip and continue as a guest.'**
  String get memberLookupSubtitle;

  /// No description provided for @memberInputPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Phone or member ID'**
  String get memberInputPlaceholder;

  /// No description provided for @memberSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get memberSkip;

  /// No description provided for @memberNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get memberNext;

  /// No description provided for @memberLooking.
  ///
  /// In en, this message translates to:
  /// **'Checking your membership…'**
  String get memberLooking;

  /// No description provided for @memberNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that member'**
  String get memberNotFoundTitle;

  /// No description provided for @memberNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'No club member matched “{query}”. Please double-check the number, or continue as a guest.'**
  String memberNotFoundBody(String query);

  /// No description provided for @memberRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get memberRetry;

  /// No description provided for @memberAttachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String memberAttachedTitle(String name);

  /// No description provided for @memberAttachedBody.
  ///
  /// In en, this message translates to:
  /// **'Your membership has been attached to this session.'**
  String get memberAttachedBody;

  /// No description provided for @memberContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get memberContinue;

  /// No description provided for @memberWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String memberWelcome(String name);

  /// No description provided for @memberTierLabel.
  ///
  /// In en, this message translates to:
  /// **'{tier} member'**
  String memberTierLabel(String tier);

  /// No description provided for @memberTierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get memberTierGold;

  /// No description provided for @memberTierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get memberTierSilver;

  /// No description provided for @memberTierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get memberTierPlatinum;

  /// No description provided for @memberTierStandard.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberTierStandard;

  /// No description provided for @memberBenefitDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% discount'**
  String memberBenefitDiscountLabel(String percent);

  /// No description provided for @memberBenefitDiscountDescription.
  ///
  /// In en, this message translates to:
  /// **'Applied automatically to every item'**
  String get memberBenefitDiscountDescription;

  /// No description provided for @memberDiscountLineLabel.
  ///
  /// In en, this message translates to:
  /// **'Member discount ({percent}%)'**
  String memberDiscountLineLabel(String percent);

  /// No description provided for @memberDiscountShort.
  ///
  /// In en, this message translates to:
  /// **'Member discount'**
  String get memberDiscountShort;

  /// No description provided for @saleDiscountShort.
  ///
  /// In en, this message translates to:
  /// **'Sale discount'**
  String get saleDiscountShort;

  /// No description provided for @memberBenefitFreeAlterationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Free alterations'**
  String get memberBenefitFreeAlterationsLabel;

  /// No description provided for @memberBenefitFreeAlterationsDescription.
  ///
  /// In en, this message translates to:
  /// **'On every full-price piece'**
  String get memberBenefitFreeAlterationsDescription;

  /// No description provided for @memberBenefitBirthdayGiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Birthday gift'**
  String get memberBenefitBirthdayGiftLabel;

  /// No description provided for @memberBenefitBirthdayGiftDescription.
  ///
  /// In en, this message translates to:
  /// **'A surprise during your birthday month'**
  String get memberBenefitBirthdayGiftDescription;

  /// No description provided for @memberBenefitEarlyAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Early access'**
  String get memberBenefitEarlyAccessLabel;

  /// No description provided for @memberBenefitEarlyAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'New collections 24h before public release'**
  String get memberBenefitEarlyAccessDescription;

  /// No description provided for @idleWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you still there?'**
  String get idleWarningTitle;

  /// No description provided for @idleWarningBody.
  ///
  /// In en, this message translates to:
  /// **'We haven\'t detected any activity for a while. Press the button below to continue shopping, otherwise the session will end automatically.'**
  String get idleWarningBody;

  /// No description provided for @idleWarningCta.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get idleWarningCta;

  /// No description provided for @bagTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Need a bag?'**
  String get bagTileTitle;

  /// No description provided for @bagTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get bagTileSubtitle;

  /// No description provided for @bagTileFromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {amount}'**
  String bagTileFromPrice(String amount);

  /// No description provided for @bagTileInCartBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 in cart} other{{count} in cart}}'**
  String bagTileInCartBadge(int count);

  /// No description provided for @bagTileEach.
  ///
  /// In en, this message translates to:
  /// **'{amount} each'**
  String bagTileEach(String amount);

  /// No description provided for @bagTileDecrease.
  ///
  /// In en, this message translates to:
  /// **'Remove one bag'**
  String get bagTileDecrease;

  /// No description provided for @bagTileIncrease.
  ///
  /// In en, this message translates to:
  /// **'Add one bag'**
  String get bagTileIncrease;

  /// No description provided for @bagPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a bag'**
  String get bagPickerTitle;

  /// No description provided for @bagPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add as many as you like — tap the + and − buttons.'**
  String get bagPickerSubtitle;

  /// No description provided for @bagPickerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get bagPickerDone;

  /// No description provided for @bagPickerClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get bagPickerClose;

  /// No description provided for @bagSmallName.
  ///
  /// In en, this message translates to:
  /// **'Small Shopping Bag'**
  String get bagSmallName;

  /// No description provided for @bagSmallDescription.
  ///
  /// In en, this message translates to:
  /// **'Compact reusable bag — perfect for one or two pieces.'**
  String get bagSmallDescription;

  /// No description provided for @bagLargeName.
  ///
  /// In en, this message translates to:
  /// **'Large Shopping Bag'**
  String get bagLargeName;

  /// No description provided for @bagLargeDescription.
  ///
  /// In en, this message translates to:
  /// **'Roomy reusable bag with reinforced handles.'**
  String get bagLargeDescription;
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
