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
  String get youSavedLabel => 'You saved';

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
  String get confirmQtyTitle => 'Confirm your bag';

  @override
  String confirmQtyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Please verify $count items are in the bin before paying.',
      one: 'Please verify 1 item is in the bin before paying.',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyItemsSection => 'Items';

  @override
  String confirmQtyItemsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items to verify',
      one: '1 item to verify',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyBagsSection => 'Shopping bags';

  @override
  String confirmQtyBagsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bags added',
      one: '1 bag added',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyNoBagsTitle => 'No bag added';

  @override
  String get confirmQtyNoBagsBody => 'You haven\'t added a bag to your order.';

  @override
  String get confirmQtyNoBagsYes => 'Add';

  @override
  String get confirmQtyNoBagsNo => 'No, continue';

  @override
  String get confirmQtyConfirm => 'Confirm and pay';

  @override
  String get confirmQtyBack => 'Back to review';

  @override
  String get keepShopping => 'Keep shopping';

  @override
  String get cancelSession => 'Cancel session';

  @override
  String get removeFromBag => 'Remove from bag';

  @override
  String get removeFromBagTitle => 'Remove this item?';

  @override
  String get removeFromBagBody => 'This piece will be taken out of your bag.';

  @override
  String get removeFromBagConfirm => 'Remove item';

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
  String get paymentMethodGiftCard => 'Gift card';

  @override
  String get paymentMethodCreditCardSubtitle =>
      'Visa, Mastercard, American Express · Tap or insert';

  @override
  String get paymentMethodGiftCardSubtitle => 'Redeem a gift card or voucher';

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
  String get paymentTerminalTitle => 'Follow instructions on the terminal';

  @override
  String get paymentTerminalBody =>
      'Insert, tap, or swipe your card on the payment terminal.';

  @override
  String get paymentTerminalProcessing => 'Processing payment';

  @override
  String get paymentTerminalProcessingBody => 'Please don\'t remove your card.';

  @override
  String get paymentTerminalAmount => 'Amount due';

  @override
  String get paymentApprovedBody => 'Your card was approved.';

  @override
  String get paymentSuccessReceiptPrompt => 'Your payment has been approved.';

  @override
  String get receiptSectionTitle => 'How would you like your receipt?';

  @override
  String get paymentReceiptTitle => 'Please take your receipt';

  @override
  String get paymentReceiptBody =>
      'Your receipt is printing. Take it from the printer and tap Finish.';

  @override
  String get paymentFinish => 'Finish';

  @override
  String get receiptChoiceTitle => 'Your receipt';

  @override
  String get receiptChoiceBody =>
      'Choose what to include and how to receive it.';

  @override
  String get exchangeSlipTitle => 'Add an exchange slip?';

  @override
  String get exchangeSlipBody =>
      'An exchange slip lets someone return or exchange items without seeing the price.';

  @override
  String get exchangeSlipSectionLabel => 'Include';

  @override
  String get exchangeSlipYes => 'Include an exchange slip';

  @override
  String get exchangeSlipNo => 'No, thanks';

  @override
  String get receiptDeliverySectionLabel => 'Send by';

  @override
  String get receiptDeliveryTitle => 'How would you like your receipt?';

  @override
  String get receiptDeliveryBody =>
      'Choose how to receive your receipt and any exchange slip.';

  @override
  String get receiptDeliveryPrint => 'Print';

  @override
  String get receiptDeliverySms => 'Text me';

  @override
  String get phoneEntryTitle => 'Enter your phone number';

  @override
  String get phoneEntrySubtitle => 'We\'ll text your receipt to this number.';

  @override
  String get phoneEntryPlaceholder => 'Phone number';

  @override
  String get phoneEntrySend => 'Send';

  @override
  String get paymentPrintingTitle => 'Printing your documents';

  @override
  String get paymentPrintingBody =>
      'Please take your receipt from the printer.';

  @override
  String get paymentSendingSmsTitle => 'Sending your receipt';

  @override
  String paymentSendingSmsBody(String phone) {
    return 'We\'re texting your receipt to $phone.';
  }

  @override
  String get paymentDeclinedTitle => 'Payment declined';

  @override
  String get paymentDeclinedBody =>
      'The terminal could not complete the transaction. Please try again.';

  @override
  String get paymentRetry => 'Try again';

  @override
  String get thankYouTitle => 'Thank you!';

  @override
  String get thankYouBody => 'We hope to see you again soon.';

  @override
  String thankYouAutoClose(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Closing in $seconds seconds…',
      one: 'Closing in 1 second…',
      zero: 'Closing…',
    );
    return '$_temp0';
  }

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

  @override
  String get logoutConfirmTitle => 'Sign out?';

  @override
  String get logoutConfirmBody =>
      'You will need to sign in again to use the kiosk.';

  @override
  String get logoutConfirm => 'Sign out';

  @override
  String get menu => 'Menu';

  @override
  String get menuTitle => 'Kiosk Menu';

  @override
  String get menuCatalog => 'Catalog';

  @override
  String get menuReaderSettings => 'Reader Settings';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get catalogLoading => 'Loading products…';

  @override
  String get catalogEmpty => 'No products in the catalog yet';

  @override
  String get catalogSearchHint => 'Search by name or barcode';

  @override
  String get catalogNoResults => 'No products match your search';

  @override
  String get catalogSyncing => 'Syncing catalog…';

  @override
  String get catalogRetry => 'Try again';

  @override
  String get catalogInfo => 'Sync';

  @override
  String get catalogSyncTitle => 'Catalog Sync';

  @override
  String get catalogStatus => 'Status';

  @override
  String get catalogLastSync => 'Last Sync';

  @override
  String get catalogServerUpdated => 'Server Updated';

  @override
  String get catalogHoursFromSync => 'Since Last Sync';

  @override
  String get catalogItemsLabel => 'Catalog Items';

  @override
  String get catalogValidity => 'Validity';

  @override
  String get catalogValidityNeverExpires => 'Never expires';

  @override
  String catalogValidityDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get catalogNever => 'Never';

  @override
  String get catalogJustNow => 'Just now';

  @override
  String get catalogStatusSyncing => 'Syncing…';

  @override
  String get catalogStatusFailed => 'Sync failed';

  @override
  String get catalogStatusUpdateAvailable => 'Update available';

  @override
  String get catalogStatusUpToDate => 'Up to date';

  @override
  String get catalogStatusNoUpdate => 'No update available';

  @override
  String get catalogProgress => 'Progress';

  @override
  String get catalogPressSyncToStart => 'Press Sync to start';

  @override
  String get catalogNoNewData => 'No new catalog available';

  @override
  String get catalogSyncNow => 'Sync Now';

  @override
  String get catalogRetrySync => 'Retry Sync';

  @override
  String get catalogCheckForUpdates => 'Check for updates';

  @override
  String get catalogNotAvailable => 'No catalog available for this group';

  @override
  String get memberLookupTitle => 'Are you a club member?';

  @override
  String get memberLookupSubtitle =>
      'Enter your phone number or member ID to enjoy your benefits — or skip and continue as a guest.';

  @override
  String get memberInputPlaceholder => 'Phone or member ID';

  @override
  String get memberSkip => 'Skip';

  @override
  String get memberNext => 'Next';

  @override
  String get memberLooking => 'Checking your membership…';

  @override
  String get memberNotFoundTitle => 'We couldn\'t find that member';

  @override
  String memberNotFoundBody(String query) {
    return 'No club member matched “$query”. Please double-check the number, or continue as a guest.';
  }

  @override
  String get memberRetry => 'Try again';

  @override
  String memberAttachedTitle(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get memberAttachedBody =>
      'Your membership has been attached to this session.';

  @override
  String get memberContinue => 'Continue';

  @override
  String memberWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String memberTierLabel(String tier) {
    return '$tier member';
  }

  @override
  String get memberTierGold => 'Gold';

  @override
  String get memberTierSilver => 'Silver';

  @override
  String get memberTierPlatinum => 'Platinum';

  @override
  String get memberTierStandard => 'Member';

  @override
  String memberBenefitDiscountLabel(String percent) {
    return '$percent% discount';
  }

  @override
  String get memberBenefitDiscountDescription =>
      'Applied automatically to every item';

  @override
  String memberDiscountLineLabel(String percent) {
    return 'Member discount ($percent%)';
  }

  @override
  String get memberDiscountShort => 'Member discount';

  @override
  String get saleDiscountShort => 'Sale discount';

  @override
  String get memberBenefitFreeAlterationsLabel => 'Free alterations';

  @override
  String get memberBenefitFreeAlterationsDescription =>
      'On every full-price piece';

  @override
  String get memberBenefitBirthdayGiftLabel => 'Birthday gift';

  @override
  String get memberBenefitBirthdayGiftDescription =>
      'A surprise during your birthday month';

  @override
  String get memberBenefitEarlyAccessLabel => 'Early access';

  @override
  String get memberBenefitEarlyAccessDescription =>
      'New collections 24h before public release';

  @override
  String get idleWarningTitle => 'Are you still there?';

  @override
  String get idleWarningBody =>
      'We haven\'t detected any activity for a while. Press the button below to continue shopping, otherwise the session will end automatically.';

  @override
  String get idleWarningCta => 'Continue shopping';

  @override
  String get bagTileTitle => 'Need a bag?';

  @override
  String get bagTileSubtitle => 'Tap to add';

  @override
  String bagTileFromPrice(String amount) {
    return 'From $amount';
  }

  @override
  String bagTileInCartBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in cart',
      one: '1 in cart',
    );
    return '$_temp0';
  }

  @override
  String bagTileEach(String amount) {
    return '$amount each';
  }

  @override
  String get bagTileDecrease => 'Remove one bag';

  @override
  String get bagTileIncrease => 'Add one bag';

  @override
  String get bagPickerTitle => 'Choose a bag';

  @override
  String get bagPickerSubtitle =>
      'Add as many as you like — tap the + and − buttons.';

  @override
  String get bagPickerDone => 'Done';

  @override
  String get bagPickerClose => 'Close';

  @override
  String get bagSmallName => 'Small Shopping Bag';

  @override
  String get bagSmallDescription =>
      'Compact reusable bag — perfect for one or two pieces.';

  @override
  String get bagLargeName => 'Large Shopping Bag';

  @override
  String get bagLargeDescription =>
      'Roomy reusable bag with reinforced handles.';
}
