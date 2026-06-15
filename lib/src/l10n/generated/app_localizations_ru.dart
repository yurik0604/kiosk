// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Kiosk';

  @override
  String get splashTagline => 'САМООБСЛУЖИВАНИЕ · FW26';

  @override
  String get topBarSubtitle => 'САМООБСЛУЖИВАНИЕ';

  @override
  String get online => 'В сети';

  @override
  String get heroEyebrow => 'КОЛЛЕКЦИЯ FW26';

  @override
  String get heroTitle => 'Стиль\nбез ожидания.';

  @override
  String get heroSubtitle => 'Оплата по-новому.\nБез очередей и спешки.';

  @override
  String get clickToStart => 'Нажмите для начала';

  @override
  String get language => 'Язык';

  @override
  String get adFw26Title => 'До 30% на коллекцию FW26';

  @override
  String get adFw26Subtitle => 'Избранная верхняя одежда и трикотаж';

  @override
  String get adAlterationsTitle => 'Бесплатная подгонка для участников';

  @override
  String get adAlterationsSubtitle => 'На каждую вещь без скидки';

  @override
  String get adSpringTitle => 'Только что: весенний резорт';

  @override
  String get adSpringSubtitle => 'Новые поступления';

  @override
  String get yourBag => 'Ваша корзина';

  @override
  String get placePieces => 'Поместите каждую вещь на считыватель';

  @override
  String piecesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'добавлено $count вещи',
      many: 'добавлено $count вещей',
      few: 'добавлено $count вещи',
      one: 'добавлена 1 вещь',
    );
    return '$_temp0';
  }

  @override
  String get bagEmpty => 'Лоток пуст';

  @override
  String get bagEmptyHint =>
      'Положите все товары в\nRFID-лоток — они добавятся\nавтоматически.';

  @override
  String get simulateScan => 'Имитация сканирования';

  @override
  String get total => 'Итого';

  @override
  String get subtotal => 'Без скидки';

  @override
  String youSaved(String amount) {
    return 'Вы экономите $amount';
  }

  @override
  String get youSavedLabel => 'Вы экономите';

  @override
  String get cancel => 'Отмена';

  @override
  String get checkout => 'К оплате';

  @override
  String get cancelSessionTitle => 'Отменить сессию?';

  @override
  String get cancelSessionBody =>
      'Корзина будет очищена, и вы вернётесь на главный экран.';

  @override
  String get confirmQtyTitle => 'Подтвердите количество';

  @override
  String confirmQtyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Убедитесь, что в лотке $count товара, прежде чем оплатить.',
      many: 'Убедитесь, что в лотке $count товаров, прежде чем оплатить.',
      few: 'Убедитесь, что в лотке $count товара, прежде чем оплатить.',
      one: 'Убедитесь, что в лотке 1 товар, прежде чем оплатить.',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyConfirm => 'Подтвердить и оплатить';

  @override
  String get confirmQtyBack => 'Назад к проверке';

  @override
  String get keepShopping => 'Продолжить';

  @override
  String get cancelSession => 'Отменить сессию';

  @override
  String get removeFromBag => 'Удалить из корзины';

  @override
  String size(String size) {
    return 'Размер $size';
  }

  @override
  String stockCount(int count) {
    return '$count в наличии';
  }

  @override
  String skuLabel(String sku) {
    return 'Артикул $sku';
  }

  @override
  String barcodeLabel(String code) {
    return 'Штрих-код $code';
  }

  @override
  String get sectionMaterial => 'Материал';

  @override
  String get sectionOrigin => 'Происхождение';

  @override
  String get sectionCare => 'Уход';

  @override
  String get genderMen => 'Мужское';

  @override
  String get genderWomen => 'Женское';

  @override
  String get genderUnisex => 'Унисекс';

  @override
  String get checkoutTitle => 'Оплата';

  @override
  String get back => 'Назад';

  @override
  String get finishDemo => 'Завершить (демо)';

  @override
  String get paymentComingSoon => 'Интеграция оплаты скоро';

  @override
  String get paymentSelectMethods => 'Выберите способы оплаты';

  @override
  String get paymentSplitHint =>
      'Нажмите на способ, чтобы указать сумму. Можно комбинировать.';

  @override
  String get paymentMethodCreditCard => 'Кредитная карта';

  @override
  String get paymentMethodGiftCard => 'Подарочная карта';

  @override
  String get paymentMethodCreditCardSubtitle =>
      'Visa, Mastercard, American Express · бесконтактно или чип';

  @override
  String get paymentMethodGiftCardSubtitle =>
      'Погасить подарочную карту или ваучер';

  @override
  String get paymentAmount => 'Сумма';

  @override
  String get paymentRemaining => 'Остаток';

  @override
  String get paymentAllocated => 'Назначено';

  @override
  String get paymentPayRemaining => 'Оплатить остаток';

  @override
  String get paymentClear => 'Очистить';

  @override
  String get paymentApply => 'Применить';

  @override
  String paymentPayNow(String amount) {
    return 'Оплатить $amount';
  }

  @override
  String paymentEnterAmountTitle(String method) {
    return 'Введите сумму для $method';
  }

  @override
  String paymentMaxAmount(String amount) {
    return 'Макс. $amount';
  }

  @override
  String get paymentSuccessTitle => 'Оплата прошла успешно';

  @override
  String get paymentSuccessBody => 'Спасибо за покупку.';

  @override
  String get paymentDone => 'Готово';

  @override
  String get paymentTerminalTitle => 'Следуйте инструкциям на терминале';

  @override
  String get paymentTerminalBody =>
      'Вставьте, приложите или проведите картой по платёжному терминалу.';

  @override
  String get paymentTerminalProcessing => 'Обработка платежа';

  @override
  String get paymentTerminalProcessingBody =>
      'Пожалуйста, не извлекайте карту.';

  @override
  String get paymentTerminalAmount => 'Сумма к оплате';

  @override
  String get paymentApprovedBody => 'Карта подтверждена.';

  @override
  String get paymentReceiptTitle => 'Заберите чек';

  @override
  String get paymentReceiptBody =>
      'Чек печатается. Возьмите его из принтера и нажмите «Готово».';

  @override
  String get paymentFinish => 'Готово';

  @override
  String get paymentDeclinedTitle => 'Платёж отклонён';

  @override
  String get paymentDeclinedBody =>
      'Терминал не смог завершить операцию. Попробуйте ещё раз.';

  @override
  String get paymentRetry => 'Повторить';

  @override
  String get thankYouTitle => 'Спасибо!';

  @override
  String get thankYouBody => 'Будем рады видеть вас снова.';

  @override
  String thankYouAutoClose(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Закрытие через $seconds секунды…',
      many: 'Закрытие через $seconds секунд…',
      few: 'Закрытие через $seconds секунды…',
      one: 'Закрытие через 1 секунду…',
      zero: 'Закрывается…',
    );
    return '$_temp0';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товара',
      many: '$count товаров',
      few: '$count товара',
      one: '1 товар',
    );
    return '$_temp0';
  }

  @override
  String get loginTitle => 'Вход';

  @override
  String get loginSubtitle => 'Доступ только для авторизованных сотрудников';

  @override
  String get loginEmail => 'Эл. почта';

  @override
  String get loginPassword => 'Пароль';

  @override
  String get loginSignIn => 'ВОЙТИ';

  @override
  String get loginSigningIn => 'Вход…';

  @override
  String get loginEmailRequired => 'Введите эл. почту';

  @override
  String get loginPasswordRequired => 'Введите пароль';

  @override
  String get logout => 'Выйти';
}
