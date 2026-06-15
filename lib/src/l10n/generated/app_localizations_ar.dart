// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Kiosk';

  @override
  String get splashTagline => 'الدفع الذاتي · FW26';

  @override
  String get topBarSubtitle => 'الدفع الذاتي';

  @override
  String get online => 'متصل';

  @override
  String get heroEyebrow => 'مجموعة FW26';

  @override
  String get heroTitle => 'أناقة\nبلا انتظار.';

  @override
  String get heroSubtitle => 'تجربة دفع متجددة.\nبلا طوابير. بلا استعجال.';

  @override
  String get clickToStart => 'انقر للبدء';

  @override
  String get language => 'اللغة';

  @override
  String get adFw26Title => 'خصم حتى 30٪ على مجموعة FW26';

  @override
  String get adFw26Subtitle => 'ملابس خارجية ومحبوكات مختارة';

  @override
  String get adAlterationsTitle => 'تعديلات مجانية للأعضاء';

  @override
  String get adAlterationsSubtitle => 'خياطة لكل قطعة بالسعر الكامل';

  @override
  String get adSpringTitle => 'وصل حديثاً: مجموعة الربيع';

  @override
  String get adSpringSubtitle => 'اكتشف الإضافات الجديدة';

  @override
  String get yourBag => 'حقيبتك';

  @override
  String get placePieces => 'ضع كل قطعة على القارئ';

  @override
  String piecesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قطعة',
      many: '$count قطعة',
      few: '$count قطع',
      two: 'قطعتان',
      one: 'قطعة واحدة',
      zero: 'لا توجد قطع',
    );
    return '$_temp0';
  }

  @override
  String get bagEmpty => 'الصندوق فارغ';

  @override
  String get bagEmptyHint =>
      'ضع كل القطع في صندوق\nالـ RFID وسيتم إضافتها\nتلقائياً.';

  @override
  String get simulateScan => 'محاكاة مسح';

  @override
  String get total => 'المجموع';

  @override
  String get subtotal => 'السعر الأصلي';

  @override
  String youSaved(String amount) {
    return 'وفّرت $amount';
  }

  @override
  String get youSavedLabel => 'وفّرت';

  @override
  String get cancel => 'إلغاء';

  @override
  String get checkout => 'الدفع';

  @override
  String get cancelSessionTitle => 'إلغاء الجلسة؟';

  @override
  String get cancelSessionBody => 'ستُفرَّغ حقيبتك وستعود إلى شاشة الترحيب.';

  @override
  String get confirmQtyTitle => 'تأكيد عدد القطع';

  @override
  String confirmQtyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يرجى التحقق من وجود $count قطعة في الصندوق قبل الدفع.',
      many: 'يرجى التحقق من وجود $count قطعة في الصندوق قبل الدفع.',
      few: 'يرجى التحقق من وجود $count قطع في الصندوق قبل الدفع.',
      two: 'يرجى التحقق من وجود قطعتين في الصندوق قبل الدفع.',
      one: 'يرجى التحقق من وجود قطعة واحدة في الصندوق قبل الدفع.',
      zero: 'يرجى التحقق من عدم وجود قطع قبل الدفع.',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyConfirm => 'تأكيد ومتابعة الدفع';

  @override
  String get confirmQtyBack => 'العودة للمراجعة';

  @override
  String get keepShopping => 'متابعة التسوق';

  @override
  String get cancelSession => 'إلغاء الجلسة';

  @override
  String get removeFromBag => 'إزالة من الحقيبة';

  @override
  String size(String size) {
    return 'المقاس $size';
  }

  @override
  String stockCount(int count) {
    return '$count في المخزون';
  }

  @override
  String skuLabel(String sku) {
    return 'رمز $sku';
  }

  @override
  String barcodeLabel(String code) {
    return 'الباركود $code';
  }

  @override
  String get sectionMaterial => 'الخامة';

  @override
  String get sectionOrigin => 'المنشأ';

  @override
  String get sectionCare => 'العناية';

  @override
  String get genderMen => 'رجال';

  @override
  String get genderWomen => 'نساء';

  @override
  String get genderUnisex => 'للجنسين';

  @override
  String get checkoutTitle => 'الدفع';

  @override
  String get back => 'رجوع';

  @override
  String get finishDemo => 'إنهاء (تجريبي)';

  @override
  String get paymentComingSoon => 'تكامل الدفع قريباً';

  @override
  String get paymentSelectMethods => 'اختر طرق الدفع';

  @override
  String get paymentSplitHint =>
      'اضغط على طريقة لتحديد المبلغ. يمكنك الجمع بين عدة طرق.';

  @override
  String get paymentMethodCreditCard => 'بطاقة ائتمان';

  @override
  String get paymentMethodMemberCard => 'بطاقة عضوية';

  @override
  String get paymentMethodGiftCard => 'بطاقة هدية';

  @override
  String get paymentAmount => 'المبلغ';

  @override
  String get paymentRemaining => 'المتبقي';

  @override
  String get paymentAllocated => 'المخصص';

  @override
  String get paymentPayRemaining => 'دفع المتبقي';

  @override
  String get paymentClear => 'مسح';

  @override
  String get paymentApply => 'تطبيق';

  @override
  String paymentPayNow(String amount) {
    return 'دفع $amount';
  }

  @override
  String paymentEnterAmountTitle(String method) {
    return 'أدخل المبلغ لـ $method';
  }

  @override
  String paymentMaxAmount(String amount) {
    return 'الحد الأقصى $amount';
  }

  @override
  String get paymentSuccessTitle => 'تم الدفع بنجاح';

  @override
  String get paymentSuccessBody => 'شكراً للتسوق معنا.';

  @override
  String get paymentDone => 'تم';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصراً',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا توجد عناصر',
    );
    return '$_temp0';
  }

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'للمستخدمين المصرح لهم فقط';

  @override
  String get loginEmail => 'البريد الإلكتروني';

  @override
  String get loginPassword => 'كلمة المرور';

  @override
  String get loginSignIn => 'تسجيل الدخول';

  @override
  String get loginSigningIn => 'جاري تسجيل الدخول…';

  @override
  String get loginEmailRequired => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get loginPasswordRequired => 'يرجى إدخال كلمة المرور';

  @override
  String get logout => 'تسجيل الخروج';
}
