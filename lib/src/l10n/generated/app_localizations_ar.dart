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
  String get confirmQtyTitle => 'تأكيد طلبك';

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
  String get confirmQtyItemsSection => 'القطع';

  @override
  String confirmQtyItemsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قطعة للتحقق',
      many: '$count قطعة للتحقق',
      few: '$count قطع للتحقق',
      two: 'قطعتان للتحقق',
      one: 'قطعة واحدة للتحقق',
      zero: 'لا توجد قطع',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyBagsSection => 'أكياس التسوق';

  @override
  String confirmQtyBagsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count كيس أُضيف',
      many: '$count كيسًا أُضيف',
      few: '$count أكياس أُضيفت',
      two: 'كيسان أُضيفا',
      one: 'كيس واحد أُضيف',
      zero: 'لا توجد أكياس',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyNoBagsTitle => 'لم يُضَف كيس';

  @override
  String get confirmQtyNoBagsBody => 'لم تضف كيسًا إلى طلبك.';

  @override
  String get confirmQtyNoBagsYes => 'إضافة';

  @override
  String get confirmQtyNoBagsNo => 'لا، متابعة';

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
  String get removeFromBagTitle => 'هل تريد إزالة هذا العنصر؟';

  @override
  String get removeFromBagBody => 'ستتم إزالة هذه القطعة من حقيبتك.';

  @override
  String get removeFromBagConfirm => 'إزالة العنصر';

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
  String get paymentMethodGiftCard => 'بطاقة هدية';

  @override
  String get paymentMethodCreditCardSubtitle =>
      'Visa, Mastercard, American Express · تقريب أو إدخال';

  @override
  String get paymentMethodGiftCardSubtitle => 'استرداد بطاقة هدية أو قسيمة';

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
  String get paymentTerminalTitle => 'اتبع التعليمات على الجهاز';

  @override
  String get paymentTerminalBody =>
      'أدخل البطاقة أو مررها أو قربها من جهاز الدفع.';

  @override
  String get paymentTerminalProcessing => 'جارٍ معالجة الدفع';

  @override
  String get paymentTerminalProcessingBody => 'يرجى عدم إزالة البطاقة.';

  @override
  String get paymentTerminalAmount => 'المبلغ المستحق';

  @override
  String get paymentApprovedBody => 'تمت الموافقة على البطاقة.';

  @override
  String get paymentSuccessReceiptPrompt => 'تمت الموافقة على الدفع.';

  @override
  String get receiptSectionTitle => 'كيف تريد استلام إيصالك؟';

  @override
  String get paymentReceiptTitle => 'يرجى أخذ الإيصال';

  @override
  String get paymentReceiptBody =>
      'تتم طباعة الإيصال. خذه من الطابعة ثم اضغط إنهاء.';

  @override
  String get paymentFinish => 'إنهاء';

  @override
  String get receiptChoiceTitle => 'إيصالك';

  @override
  String get receiptChoiceBody => 'اختر ما تريد تضمينه وكيفية استلامه.';

  @override
  String get exchangeSlipTitle => 'إضافة إيصال استبدال؟';

  @override
  String get exchangeSlipBody =>
      'يتيح إيصال الاستبدال إرجاع المنتجات أو استبدالها دون إظهار السعر.';

  @override
  String get exchangeSlipSectionLabel => 'يشمل';

  @override
  String get exchangeSlipYes => 'تضمين إيصال استبدال';

  @override
  String get exchangeSlipNo => 'لا، شكرًا';

  @override
  String get receiptDeliverySectionLabel => 'الإرسال عبر';

  @override
  String get receiptDeliveryTitle => 'كيف تريد استلام إيصالك؟';

  @override
  String get receiptDeliveryBody =>
      'اختر طريقة استلام الإيصال وإيصال الاستبدال.';

  @override
  String get receiptDeliveryPrint => 'طباعة';

  @override
  String get receiptDeliverySms => 'أرسِله كرسالة';

  @override
  String get phoneEntryTitle => 'أدخل رقم هاتفك';

  @override
  String get phoneEntrySubtitle => 'سنرسل إيصالك برسالة نصية إلى هذا الرقم.';

  @override
  String get phoneEntryPlaceholder => 'رقم الهاتف';

  @override
  String get phoneEntrySend => 'إرسال';

  @override
  String get paymentPrintingTitle => 'جارٍ طباعة مستنداتك';

  @override
  String get paymentPrintingBody => 'يرجى أخذ إيصالك من الطابعة.';

  @override
  String get paymentSendingSmsTitle => 'جارٍ إرسال إيصالك';

  @override
  String paymentSendingSmsBody(String phone) {
    return 'نرسل إيصالك برسالة نصية إلى $phone.';
  }

  @override
  String get paymentDeclinedTitle => 'تم رفض الدفع';

  @override
  String get paymentDeclinedBody =>
      'تعذّر على الجهاز إتمام المعاملة. يرجى المحاولة مرة أخرى.';

  @override
  String get paymentRetry => 'حاول مجدداً';

  @override
  String get thankYouTitle => 'شكراً لك!';

  @override
  String get thankYouBody => 'نأمل أن نراك مجدداً قريباً.';

  @override
  String thankYouAutoClose(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'الإغلاق خلال $seconds ثانية…',
      many: 'الإغلاق خلال $seconds ثانية…',
      few: 'الإغلاق خلال $seconds ثوانٍ…',
      two: 'الإغلاق خلال ثانيتين…',
      one: 'الإغلاق خلال ثانية…',
      zero: 'جارٍ الإغلاق…',
    );
    return '$_temp0';
  }

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

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get logoutConfirmBody =>
      'ستحتاج إلى تسجيل الدخول مرة أخرى لاستخدام الجهاز.';

  @override
  String get logoutConfirm => 'تسجيل الخروج';

  @override
  String get menu => 'القائمة';

  @override
  String get menuTitle => 'قائمة الجهاز';

  @override
  String get menuCatalog => 'الكتالوج';

  @override
  String get menuReaderSettings => 'إعدادات القارئ';

  @override
  String get catalogTitle => 'الكتالوج';

  @override
  String get catalogLoading => 'جارٍ تحميل المنتجات…';

  @override
  String get catalogEmpty => 'لا توجد منتجات في الكتالوج بعد';

  @override
  String get catalogSearchHint => 'ابحث بالاسم أو الباركود';

  @override
  String get catalogNoResults => 'لا توجد منتجات مطابقة لبحثك';

  @override
  String get catalogSyncing => 'جارٍ مزامنة الكتالوج…';

  @override
  String get catalogRetry => 'أعد المحاولة';

  @override
  String get catalogInfo => 'مزامنة';

  @override
  String get catalogSyncTitle => 'مزامنة الكتالوج';

  @override
  String get catalogStatus => 'الحالة';

  @override
  String get catalogLastSync => 'آخر مزامنة';

  @override
  String get catalogServerUpdated => 'تحديث الخادم';

  @override
  String get catalogHoursFromSync => 'منذ آخر مزامنة';

  @override
  String get catalogItemsLabel => 'عناصر الكتالوج';

  @override
  String get catalogValidity => 'الصلاحية';

  @override
  String get catalogValidityNeverExpires => 'لا تنتهي';

  @override
  String catalogValidityDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days أيام',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get catalogNever => 'أبداً';

  @override
  String get catalogJustNow => 'الآن';

  @override
  String get catalogStatusSyncing => 'جارٍ المزامنة…';

  @override
  String get catalogStatusFailed => 'فشلت المزامنة';

  @override
  String get catalogStatusUpdateAvailable => 'يتوفر تحديث';

  @override
  String get catalogStatusUpToDate => 'محدَّث';

  @override
  String get catalogStatusNoUpdate => 'لا يوجد تحديث';

  @override
  String get catalogProgress => 'التقدم';

  @override
  String get catalogPressSyncToStart => 'اضغط مزامنة للبدء';

  @override
  String get catalogNoNewData => 'لا يتوفر كتالوج جديد';

  @override
  String get catalogSyncNow => 'زامن الآن';

  @override
  String get catalogRetrySync => 'أعد المزامنة';

  @override
  String get catalogCheckForUpdates => 'التحقق من التحديثات';

  @override
  String get catalogNotAvailable => 'لا يوجد كتالوج متاح لهذه المجموعة';

  @override
  String get memberLookupTitle => 'هل أنت عضو في النادي؟';

  @override
  String get memberLookupSubtitle =>
      'أدخل رقم هاتفك أو رقم العضوية للاستفادة من المزايا — أو تخطَّ وتابع كزائر.';

  @override
  String get memberInputPlaceholder => 'الهاتف أو رقم العضوية';

  @override
  String get memberSkip => 'تخطّي';

  @override
  String get memberNext => 'التالي';

  @override
  String get memberLooking => 'جارٍ التحقق من عضويتك…';

  @override
  String get memberNotFoundTitle => 'تعذّر العثور على هذا العضو';

  @override
  String memberNotFoundBody(String query) {
    return 'لم نعثر على أي عضو مطابق لـ ”$query“. يرجى التحقق من الرقم، أو المتابعة كزائر.';
  }

  @override
  String get memberRetry => 'حاول مرة أخرى';

  @override
  String memberAttachedTitle(String name) {
    return 'مرحبًا بعودتك يا $name!';
  }

  @override
  String get memberAttachedBody => 'تم ربط عضويتك بهذه الجلسة بنجاح.';

  @override
  String get memberContinue => 'متابعة';

  @override
  String memberWelcome(String name) {
    return 'أهلاً، $name';
  }

  @override
  String memberTierLabel(String tier) {
    return 'عضو $tier';
  }

  @override
  String get memberTierGold => 'ذهبي';

  @override
  String get memberTierSilver => 'فضي';

  @override
  String get memberTierPlatinum => 'بلاتيني';

  @override
  String get memberTierStandard => 'عضو';

  @override
  String memberBenefitDiscountLabel(String percent) {
    return 'خصم $percent%';
  }

  @override
  String get memberBenefitDiscountDescription => 'يُطبَّق تلقائيًا على كل قطعة';

  @override
  String memberDiscountLineLabel(String percent) {
    return 'خصم العضوية ($percent%)';
  }

  @override
  String get memberDiscountShort => 'خصم العضوية';

  @override
  String get saleDiscountShort => 'خصم العرض';

  @override
  String get memberBenefitFreeAlterationsLabel => 'تعديلات مجانية';

  @override
  String get memberBenefitFreeAlterationsDescription =>
      'على كل قطعة بالسعر الكامل';

  @override
  String get memberBenefitBirthdayGiftLabel => 'هدية عيد الميلاد';

  @override
  String get memberBenefitBirthdayGiftDescription =>
      'مفاجأة خلال شهر عيد ميلادك';

  @override
  String get memberBenefitEarlyAccessLabel => 'وصول مبكر';

  @override
  String get memberBenefitEarlyAccessDescription =>
      'تشكيلات جديدة قبل 24 ساعة من الإصدار العام';

  @override
  String get idleWarningTitle => 'هل ما زلت هنا؟';

  @override
  String get idleWarningBody =>
      'لم نلاحظ أي نشاط منذ فترة. اضغط على الزر أدناه لمتابعة التسوّق، وإلا ستنتهي الجلسة تلقائيًا.';

  @override
  String get idleWarningCta => 'متابعة التسوّق';

  @override
  String get bagTileTitle => 'هل تحتاج إلى كيس؟';

  @override
  String get bagTileSubtitle => 'اضغط للإضافة';

  @override
  String bagTileFromPrice(String amount) {
    return 'ابتداءً من $amount';
  }

  @override
  String bagTileInCartBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count في السلة',
      one: '1 في السلة',
    );
    return '$_temp0';
  }

  @override
  String bagTileEach(String amount) {
    return '$amount للقطعة';
  }

  @override
  String get bagTileDecrease => 'إزالة كيس';

  @override
  String get bagTileIncrease => 'إضافة كيس';

  @override
  String get bagPickerTitle => 'اختَر كيسًا';

  @override
  String get bagPickerSubtitle => 'أضف بقدر ما تشاء — اضغط على زرّي + و−.';

  @override
  String get bagPickerDone => 'تم';

  @override
  String get bagPickerClose => 'إغلاق';

  @override
  String get bagSmallName => 'كيس تسوّق صغير';

  @override
  String get bagSmallDescription => 'كيس مدمج — مثالي لقطعة أو قطعتين.';

  @override
  String get bagLargeName => 'كيس تسوّق كبير';

  @override
  String get bagLargeDescription => 'كيس واسع مع مقابض مقوّاة.';
}
