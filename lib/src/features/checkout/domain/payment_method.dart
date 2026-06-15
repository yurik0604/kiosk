import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

enum PaymentMethod {
  creditCard,
  giftCard;

  String label(AppLocalizations l10n) => switch (this) {
        PaymentMethod.creditCard => l10n.paymentMethodCreditCard,
        PaymentMethod.giftCard => l10n.paymentMethodGiftCard,
      };

  String subtitle(AppLocalizations l10n) => switch (this) {
        PaymentMethod.creditCard => l10n.paymentMethodCreditCardSubtitle,
        PaymentMethod.giftCard => l10n.paymentMethodGiftCardSubtitle,
      };

  IconData get icon => switch (this) {
        PaymentMethod.creditCard => Icons.credit_card_rounded,
        PaymentMethod.giftCard => Icons.card_giftcard_rounded,
      };
}
