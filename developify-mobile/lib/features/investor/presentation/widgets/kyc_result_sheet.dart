import 'package:flutter/material.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_confirmation_sheet.dart';

Future<String?> showKycProgressSheet(
  BuildContext context,
) => showInvestorResult(
  context,
  success: true,
  style: InvestorResultStyle.verification,
  title: 'Verification in Progress!',
  message:
      'Your sample documents are saved. Verification is simulated in this session; no information is sent for review.',
  primary: 'Continue',
);
