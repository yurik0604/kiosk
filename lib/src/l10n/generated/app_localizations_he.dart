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
  String get bagEmpty => 'התיק ריק';

  @override
  String get bagEmptyHint =>
      'הניחו את הפריטים שבחרתם\nעל המשטח כדי להוסיף אותם.';

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
  String get cancel => 'ביטול';

  @override
  String get checkout => 'תשלום';

  @override
  String get cancelSessionTitle => 'לבטל את הקנייה?';

  @override
  String get cancelSessionBody => 'התיק יתרוקן ותחזרו למסך הפתיחה.';

  @override
  String get keepShopping => 'להמשיך בקנייה';

  @override
  String get cancelSession => 'בטלו את הקנייה';

  @override
  String get removeFromBag => 'הסירו מהתיק';

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
  String get paymentMethodMemberCard => 'כרטיס חבר';

  @override
  String get paymentMethodGiftCard => 'כרטיס מתנה';

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
}
