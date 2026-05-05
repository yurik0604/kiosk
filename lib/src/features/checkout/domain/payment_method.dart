import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

enum PaymentMethod {
  creditCard,
  memberCard,
  giftCard;

  String label(AppLocalizations l10n) => switch (this) {
        PaymentMethod.creditCard => l10n.paymentMethodCreditCard,
        PaymentMethod.memberCard => l10n.paymentMethodMemberCard,
        PaymentMethod.giftCard => l10n.paymentMethodGiftCard,
      };

  IconData get icon => switch (this) {
        PaymentMethod.creditCard => Icons.credit_card_rounded,
        PaymentMethod.memberCard => Icons.card_membership_rounded,
        PaymentMethod.giftCard => Icons.card_giftcard_rounded,
      };
}
