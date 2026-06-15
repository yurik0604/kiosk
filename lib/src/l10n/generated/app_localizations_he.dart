// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'Kiosk';

  @override
  String get splashTagline => 'קופה עצמית · FW26';

  @override
  String get topBarSubtitle => 'קופה עצמית';

  @override
  String get online => 'מחובר';

  @override
  String get heroEyebrow => 'קולקציית FW26';

  @override
  String get heroTitle => 'סטייל,\nבלי הפרעות.';

  @override
  String get heroSubtitle => 'קופה בגישה חדשה.\nבלי תורים. בלי לחץ.';

  @override
  String get clickToStart => 'לחצו להתחלה';

  @override
  String get language => 'שפה';

  @override
  String get adFw26Title => 'עד 30% הנחה על קולקציית FW26';

  @override
  String get adFw26Subtitle => 'מעילים וסריגים נבחרים';

  @override
  String get adAlterationsTitle => 'תיקונים חינם לחברי מועדון';

  @override
  String get adAlterationsSubtitle => 'תפירה על כל פריט במחיר מלא';

  @override
  String get adSpringTitle => 'חדש: קולקציית אביב';

  @override
  String get adSpringSubtitle => 'גלו את החדשים';

  @override
  String get yourBag => 'התיק שלך';

  @override
  String get placePieces => 'הניחו כל פריט על הקורא';

  @override
  String piecesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'נוספו $count פריטים',
      two: 'נוספו $count פריטים',
      one: 'נוסף פריט אחד',
    );
    return '$_temp0';
  }

  @override
  String get bagEmpty => 'הסל ריק';

  @override
  String get bagEmptyHint =>
      'הניחו את כל הפריטים בסל ה-RFID\nוהם יתווספו אוטומטית.';

  @override
  String get simulateScan => 'סריקה לדוגמה';

  @override
  String get total => 'סה״כ';

  @override
  String get subtotal => 'מחיר מקורי';

  @override
  String youSaved(String amount) {
    return 'חסכת $amount';
  }

  @override
  String get youSavedLabel => 'חסכת';

  @override
  String get cancel => 'ביטול';

  @override
  String get checkout => 'תשלום';

  @override
  String get cancelSessionTitle => 'לבטל את הקנייה?';

  @override
  String get cancelSessionBody => 'התיק יתרוקן ותחזרו למסך הפתיחה.';

  @override
  String get confirmQtyTitle => 'אישור התיק שלכם';

  @override
  String confirmQtyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ודאו שיש $count פריטים בסל לפני התשלום.',
      two: 'ודאו שיש $count פריטים בסל לפני התשלום.',
      one: 'ודאו שיש פריט אחד בסל לפני התשלום.',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyItemsSection => 'פריטים';

  @override
  String confirmQtyItemsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count פריטים לאימות',
      two: '$count פריטים לאימות',
      one: 'פריט אחד לאימות',
      zero: 'אין פריטים',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyBagsSection => 'שקיות קנייה';

  @override
  String confirmQtyBagsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שקיות נוספו',
      two: '$count שקיות נוספו',
      one: 'שקית אחת נוספה',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyNoBagsTitle => 'לא נוספה שקית';

  @override
  String get confirmQtyNoBagsBody => 'לא הוספתם שקית להזמנה.';

  @override
  String get confirmQtyNoBagsYes => 'הוסף';

  @override
  String get confirmQtyNoBagsNo => 'לא, להמשיך';

  @override
  String get confirmQtyConfirm => 'אישור והמשך לתשלום';

  @override
  String get confirmQtyBack => 'חזרה לבדיקה';

  @override
  String get keepShopping => 'להמשיך בקנייה';

  @override
  String get cancelSession => 'בטלו את הקנייה';

  @override
  String get removeFromBag => 'הסירו מהתיק';

  @override
  String get removeFromBagTitle => 'להסיר את הפריט?';

  @override
  String get removeFromBagBody => 'הפריט הזה יוסר מהתיק שלכם.';

  @override
  String get removeFromBagConfirm => 'הסר פריט';

  @override
  String size(String size) {
    return 'מידה $size';
  }

  @override
  String stockCount(int count) {
    return '$count במלאי';
  }

  @override
  String skuLabel(String sku) {
    return 'מק״ט $sku';
  }

  @override
  String barcodeLabel(String code) {
    return 'ברקוד $code';
  }

  @override
  String get sectionMaterial => 'חומר';

  @override
  String get sectionOrigin => 'מקור';

  @override
  String get sectionCare => 'טיפול';

  @override
  String get genderMen => 'גברים';

  @override
  String get genderWomen => 'נשים';

  @override
  String get genderUnisex => 'יוניסקס';

  @override
  String get checkoutTitle => 'תשלום';

  @override
  String get back => 'חזרה';

  @override
  String get finishDemo => 'סיום (הדגמה)';

  @override
  String get paymentComingSoon => 'שילוב תשלומים בקרוב';

  @override
  String get paymentSelectMethods => 'בחרו אמצעי תשלום';

  @override
  String get paymentSplitHint =>
      'הקישו על אמצעי תשלום כדי להזין סכום. ניתן לשלב מספר אמצעים.';

  @override
  String get paymentMethodCreditCard => 'כרטיס אשראי';

  @override
  String get paymentMethodGiftCard => 'כרטיס מתנה';

  @override
  String get paymentMethodCreditCardSubtitle =>
      'Visa, Mastercard, American Express · הצמדה או הכנסה';

  @override
  String get paymentMethodGiftCardSubtitle => 'מימוש כרטיס מתנה או שובר';

  @override
  String get paymentAmount => 'סכום';

  @override
  String get paymentRemaining => 'נותר לתשלום';

  @override
  String get paymentAllocated => 'הוקצה';

  @override
  String get paymentPayRemaining => 'שלמו את היתרה';

  @override
  String get paymentClear => 'ניקוי';

  @override
  String get paymentApply => 'אישור';

  @override
  String paymentPayNow(String amount) {
    return 'תשלום $amount';
  }

  @override
  String paymentEnterAmountTitle(String method) {
    return 'הזינו סכום עבור $method';
  }

  @override
  String paymentMaxAmount(String amount) {
    return 'מקסימום $amount';
  }

  @override
  String get paymentSuccessTitle => 'התשלום בוצע בהצלחה';

  @override
  String get paymentSuccessBody => 'תודה שקניתם אצלנו.';

  @override
  String get paymentDone => 'סיום';

  @override
  String get paymentTerminalTitle => 'פעלו לפי ההוראות על המסוף';

  @override
  String get paymentTerminalBody =>
      'הכניסו, הצמידו או העבירו את הכרטיס במסוף התשלום.';

  @override
  String get paymentTerminalProcessing => 'מבצע תשלום';

  @override
  String get paymentTerminalProcessingBody => 'אנא אל תוציאו את הכרטיס.';

  @override
  String get paymentTerminalAmount => 'סכום לתשלום';

  @override
  String get paymentApprovedBody => 'הכרטיס אושר.';

  @override
  String get paymentReceiptTitle => 'אנא קחו את הקבלה';

  @override
  String get paymentReceiptBody =>
      'הקבלה מודפסת. קחו אותה מהמדפסת והקישו על סיום.';

  @override
  String get paymentFinish => 'סיום';

  @override
  String get paymentDeclinedTitle => 'התשלום נדחה';

  @override
  String get paymentDeclinedBody => 'המסוף לא הצליח להשלים את העסקה. נסו שוב.';

  @override
  String get paymentRetry => 'ניסיון נוסף';

  @override
  String get thankYouTitle => 'תודה רבה!';

  @override
  String get thankYouBody => 'נשמח לראותכם שוב בקרוב.';

  @override
  String thankYouAutoClose(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'נסגר בעוד $seconds שניות…',
      two: 'נסגר בעוד $seconds שניות…',
      one: 'נסגר בעוד שנייה…',
      zero: 'סוגר…',
    );
    return '$_temp0';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count פריטים',
      two: '$count פריטים',
      one: 'פריט אחד',
    );
    return '$_temp0';
  }

  @override
  String get loginTitle => 'התחברות';

  @override
  String get loginSubtitle => 'גישה למורשים בלבד';

  @override
  String get loginEmail => 'אימייל';

  @override
  String get loginPassword => 'סיסמה';

  @override
  String get loginSignIn => 'התחברות';

  @override
  String get loginSigningIn => 'מתחבר…';

  @override
  String get loginEmailRequired => 'נא להזין אימייל';

  @override
  String get loginPasswordRequired => 'נא להזין סיסמה';

  @override
  String get logout => 'התנתקות';

  @override
  String get memberLookupTitle => 'האם אתם חברי מועדון?';

  @override
  String get memberLookupSubtitle =>
      'הזינו מספר טלפון או מספר חבר כדי ליהנות מההטבות — או דלגו והמשיכו כאורח.';

  @override
  String get memberInputPlaceholder => 'טלפון או מספר חבר';

  @override
  String get memberSkip => 'דלג';

  @override
  String get memberNext => 'הבא';

  @override
  String get memberLooking => 'בודק את חברותך…';

  @override
  String get memberNotFoundTitle => 'לא הצלחנו לאתר חבר מועדון';

  @override
  String memberNotFoundBody(String query) {
    return 'לא נמצא חבר מועדון עבור „$query”. אנא בדקו את המספר שוב, או המשיכו כאורח.';
  }

  @override
  String get memberRetry => 'נסה שוב';

  @override
  String memberAttachedTitle(String name) {
    return 'ברוך שובך, $name!';
  }

  @override
  String get memberAttachedBody => 'החברות שלך צורפה לעסקה זו בהצלחה.';

  @override
  String get memberContinue => 'המשך';

  @override
  String memberWelcome(String name) {
    return 'שלום, $name';
  }

  @override
  String memberTierLabel(String tier) {
    return 'חבר $tier';
  }

  @override
  String get memberTierGold => 'זהב';

  @override
  String get memberTierSilver => 'כסף';

  @override
  String get memberTierPlatinum => 'פלטינה';

  @override
  String get memberTierStandard => 'חבר';

  @override
  String memberBenefitDiscountLabel(String percent) {
    return 'הנחה של $percent%';
  }

  @override
  String get memberBenefitDiscountDescription => 'מוחל אוטומטית על כל פריט';

  @override
  String memberDiscountLineLabel(String percent) {
    return 'הנחת חבר ($percent%)';
  }

  @override
  String get memberDiscountShort => 'הנחת חבר';

  @override
  String get saleDiscountShort => 'הנחת מבצע';

  @override
  String get memberBenefitFreeAlterationsLabel => 'תיקוני חינם';

  @override
  String get memberBenefitFreeAlterationsDescription => 'על כל פריט במחיר מלא';

  @override
  String get memberBenefitBirthdayGiftLabel => 'מתנת יום הולדת';

  @override
  String get memberBenefitBirthdayGiftDescription =>
      'הפתעה בחודש יום ההולדת שלך';

  @override
  String get memberBenefitEarlyAccessLabel => 'גישה מוקדמת';

  @override
  String get memberBenefitEarlyAccessDescription =>
      'קולקציות חדשות 24 שעות לפני ההשקה לציבור';

  @override
  String get idleWarningTitle => 'עדיין כאן?';

  @override
  String get idleWarningBody =>
      'לא זוהתה פעילות במשך זמן מה. הקישו על הכפתור למטה כדי להמשיך לקנות, אחרת הסשן יסתיים אוטומטית.';

  @override
  String get idleWarningCta => 'המשך קניות';

  @override
  String get bagTileTitle => 'צריך שקית?';

  @override
  String get bagTileSubtitle => 'הקישו להוספה';

  @override
  String bagTileFromPrice(String amount) {
    return 'החל מ-$amount';
  }

  @override
  String bagTileInCartBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count בעגלה',
      one: '1 בעגלה',
    );
    return '$_temp0';
  }

  @override
  String bagTileEach(String amount) {
    return '$amount ליחידה';
  }

  @override
  String get bagTileDecrease => 'הסר שקית';

  @override
  String get bagTileIncrease => 'הוסף שקית';

  @override
  String get bagPickerTitle => 'בחרו שקית';

  @override
  String get bagPickerSubtitle =>
      'ניתן להוסיף כמה שצריך — הקישו על הכפתורים + ו-−.';

  @override
  String get bagPickerDone => 'סיום';

  @override
  String get bagPickerClose => 'סגור';

  @override
  String get bagSmallName => 'שקית קניות קטנה';

  @override
  String get bagSmallDescription => 'שקית קומפקטית — מושלמת לפריט או שניים.';

  @override
  String get bagLargeName => 'שקית קניות גדולה';

  @override
  String get bagLargeDescription => 'שקית מרווחת עם ידיות מחוזקות.';
}
