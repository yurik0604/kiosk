// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kiosk';

  @override
  String get splashTagline => 'SELF-CHECKOUT · FW26';

  @override
  String get topBarSubtitle => 'SELF-CHECKOUT';

  @override
  String get online => 'Online';

  @override
  String get heroEyebrow => 'FW26 COLLECTION';

  @override
  String get heroTitle => 'Style,\nuninterrupted.';

  @override
  String get heroSubtitle => 'Checkout, reimagined.\nNo queues. No rush.';

  @override
  String get clickToStart => 'Click To Start';

  @override
  String get language => 'Language';

  @override
  String get adFw26Title => 'Up to 30% off the FW26 edit';

  @override
  String get adFw26Subtitle => 'Selected outerwear & knitwear';

  @override
  String get adAlterationsTitle => 'Free alterations for members';

  @override
  String get adAlterationsSubtitle => 'Tailoring on every full-price piece';

  @override
  String get adSpringTitle => 'Just landed: Spring resort';

  @override
  String get adSpringSubtitle => 'Discover the new arrivals';

  @override
  String get yourBag => 'Your Bag';

  @override
  String get placePieces => 'Place each piece on the reader';

  @override
  String piecesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieces added',
      one: '1 piece added',
    );
    return '$_temp0';
  }

  @override
  String get bagEmpty => 'The bin is empty';

  @override
  String get bagEmptyHint =>
      'Place all your items in the\nRFID bin and they will be\nadded automatically.';

  @override
  String get simulateScan => 'Simulate Scan';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String youSaved(String amount) {
    return 'You saved $amount';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get checkout => 'Checkout';

  @override
  String get cancelSessionTitle => 'Cancel session?';

  @override
  String get cancelSessionBody =>
      'Your bag will be emptied and you will return to the welcome screen.';

  @override
  String get keepShopping => 'Keep shopping';

  @override
  String get cancelSession => 'Cancel session';

  @override
  String get removeFromBag => 'Remove from bag';

  @override
  String size(String size) {
    return 'Size $size';
  }

  @override
  String stockCount(int count) {
    return '$count in stock';
  }

  @override
  String skuLabel(String sku) {
    return 'SKU $sku';
  }

  @override
  String barcodeLabel(String code) {
    return 'Barcode $code';
  }

  @override
  String get sectionMaterial => 'Material';

  @override
  String get sectionOrigin => 'Origin';

  @override
  String get sectionCare => 'Care';

  @override
  String get genderMen => 'Men';

  @override
  String get genderWomen => 'Women';

  @override
  String get genderUnisex => 'Unisex';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get back => 'Back';

  @override
  String get finishDemo => 'Finish (demo)';

  @override
  String get paymentComingSoon => 'Payment integration coming next';

  @override
  String get paymentSelectMethods => 'Select payment methods';

  @override
  String get paymentSplitHint =>
      'Tap a method to assign an amount. You can combine several.';

  @override
  String get paymentMethodCreditCard => 'Credit card';

  @override
  String get paymentMethodMemberCard => 'Member card';

  @override
  String get paymentMethodGiftCard => 'Gift card';

  @override
  String get paymentAmount => 'Amount';

  @override
  String get paymentRemaining => 'Remaining';

  @override
  String get paymentAllocated => 'Allocated';

  @override
  String get paymentPayRemaining => 'Pay remaining';

  @override
  String get paymentClear => 'Clear';

  @override
  String get paymentApply => 'Apply';

  @override
  String paymentPayNow(String amount) {
    return 'Pay $amount';
  }

  @override
  String paymentEnterAmountTitle(String method) {
    return 'Enter amount for $method';
  }

  @override
  String paymentMaxAmount(String amount) {
    return 'Max $amount';
  }

  @override
  String get paymentSuccessTitle => 'Payment successful';

  @override
  String get paymentSuccessBody => 'Thank you for shopping with us.';

  @override
  String get paymentDone => 'Done';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Authorized staff access only';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSignIn => 'SIGN IN';

  @override
  String get loginSigningIn => 'Signing in…';

  @override
  String get loginEmailRequired => 'Please enter your email';

  @override
  String get loginPasswordRequired => 'Please enter your password';

  @override
  String get logout => 'Sign out';
}
