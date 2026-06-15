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
  String get confirmQtyTitle => 'Подтвердите заказ';

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
  String get confirmQtyItemsSection => 'Товары';

  @override
  String confirmQtyItemsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товара к проверке',
      many: '$count товаров к проверке',
      few: '$count товара к проверке',
      one: '1 товар к проверке',
      zero: 'Нет товаров',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyBagsSection => 'Пакеты';

  @override
  String confirmQtyBagsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавлено $count пакета',
      many: 'Добавлено $count пакетов',
      few: 'Добавлено $count пакета',
      one: 'Добавлен 1 пакет',
    );
    return '$_temp0';
  }

  @override
  String get confirmQtyNoBagsTitle => 'Пакет не добавлен';

  @override
  String get confirmQtyNoBagsBody => 'В заказе нет пакета.';

  @override
  String get confirmQtyNoBagsYes => 'Добавить';

  @override
  String get confirmQtyNoBagsNo => 'Нет, продолжить';

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
  String get removeFromBagTitle => 'Удалить этот товар?';

  @override
  String get removeFromBagBody => 'Эта вещь будет убрана из корзины.';

  @override
  String get removeFromBagConfirm => 'Удалить товар';

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

  @override
  String get memberLookupTitle => 'Вы участник клуба?';

  @override
  String get memberLookupSubtitle =>
      'Введите номер телефона или номер участника, чтобы воспользоваться привилегиями — или пропустите и продолжите как гость.';

  @override
  String get memberInputPlaceholder => 'Телефон или номер участника';

  @override
  String get memberSkip => 'Пропустить';

  @override
  String get memberNext => 'Далее';

  @override
  String get memberLooking => 'Проверяем ваше членство…';

  @override
  String get memberNotFoundTitle => 'Участник не найден';

  @override
  String memberNotFoundBody(String query) {
    return 'Не удалось найти участника по запросу «$query». Проверьте номер или продолжите как гость.';
  }

  @override
  String get memberRetry => 'Попробовать снова';

  @override
  String memberAttachedTitle(String name) {
    return 'С возвращением, $name!';
  }

  @override
  String get memberAttachedBody =>
      'Ваша карта участника привязана к этой сессии.';

  @override
  String get memberContinue => 'Продолжить';

  @override
  String memberWelcome(String name) {
    return 'Здравствуйте, $name';
  }

  @override
  String memberTierLabel(String tier) {
    return 'Участник $tier';
  }

  @override
  String get memberTierGold => 'Gold';

  @override
  String get memberTierSilver => 'Silver';

  @override
  String get memberTierPlatinum => 'Platinum';

  @override
  String get memberTierStandard => 'Участник';

  @override
  String memberBenefitDiscountLabel(String percent) {
    return 'Скидка $percent%';
  }

  @override
  String get memberBenefitDiscountDescription =>
      'Применяется автоматически к каждому товару';

  @override
  String memberDiscountLineLabel(String percent) {
    return 'Скидка участника ($percent%)';
  }

  @override
  String get memberDiscountShort => 'Скидка участника';

  @override
  String get saleDiscountShort => 'Скидка акции';

  @override
  String get memberBenefitFreeAlterationsLabel => 'Бесплатная подгонка';

  @override
  String get memberBenefitFreeAlterationsDescription =>
      'На каждую вещь по полной цене';

  @override
  String get memberBenefitBirthdayGiftLabel => 'Подарок ко дню рождения';

  @override
  String get memberBenefitBirthdayGiftDescription =>
      'Сюрприз в месяц вашего дня рождения';

  @override
  String get memberBenefitEarlyAccessLabel => 'Ранний доступ';

  @override
  String get memberBenefitEarlyAccessDescription =>
      'Новые коллекции на 24 часа раньше публичного релиза';

  @override
  String get idleWarningTitle => 'Вы ещё здесь?';

  @override
  String get idleWarningBody =>
      'Мы не зафиксировали активности некоторое время. Нажмите кнопку ниже, чтобы продолжить покупки, иначе сессия завершится автоматически.';

  @override
  String get idleWarningCta => 'Продолжить покупки';

  @override
  String get bagTileTitle => 'Нужен пакет?';

  @override
  String get bagTileSubtitle => 'Нажмите, чтобы добавить';

  @override
  String bagTileFromPrice(String amount) {
    return 'От $amount';
  }

  @override
  String bagTileInCartBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count в корзине',
      few: '$count в корзине',
      one: '1 в корзине',
    );
    return '$_temp0';
  }

  @override
  String bagTileEach(String amount) {
    return '$amount за штуку';
  }

  @override
  String get bagTileDecrease => 'Убрать пакет';

  @override
  String get bagTileIncrease => 'Добавить пакет';

  @override
  String get bagPickerTitle => 'Выберите пакет';

  @override
  String get bagPickerSubtitle =>
      'Добавьте сколько нужно — используйте кнопки + и −.';

  @override
  String get bagPickerDone => 'Готово';

  @override
  String get bagPickerClose => 'Закрыть';

  @override
  String get bagSmallName => 'Маленький пакет';

  @override
  String get bagSmallDescription => 'Компактный пакет — для одной-двух вещей.';

  @override
  String get bagLargeName => 'Большой пакет';

  @override
  String get bagLargeDescription => 'Просторный пакет с усиленными ручками.';
}
