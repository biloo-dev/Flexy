import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/cyber_button.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/authorization/app_permissions.dart';
import '../../core/authorization/permission_guard.dart';

class FlexyTransferCard extends StatefulWidget {
  final TextEditingController phoneController;
  final TextEditingController amountController;
  final FocusNode phoneFocusNode;
  final String? ghostSuggestion;
  final VoidCallback? onAcceptGhost;
  final bool isCredit;
  final ValueChanged<bool> onCreditChanged;
  final VoidCallback onSendTransfer;
  final VoidCallback? onOpenContacts;
  final String? selectedClient;
  final List<String> clientList;
  final ValueChanged<String?>? onClientSelected;

  const FlexyTransferCard({
    super.key,
    required this.phoneController,
    required this.amountController,
    required this.phoneFocusNode,
    this.ghostSuggestion,
    this.onAcceptGhost,
    required this.isCredit,
    required this.onCreditChanged,
    required this.onSendTransfer,
    this.onOpenContacts,
    this.selectedClient,
    required this.clientList,
    this.onClientSelected,
  });

  @override
  State<FlexyTransferCard> createState() => _FlexyTransferCardState();
}

class _FlexyTransferCardState extends State<FlexyTransferCard> {
  void _addKeyDigit(String digit) {
    if (widget.phoneController.text.length < 10) {
      widget.phoneController.text += digit;
    }
  }

  void _deleteKeyDigit() {
    if (widget.phoneController.text.isNotEmpty) {
      widget.phoneController.text = widget.phoneController.text.substring(
        0,
        widget.phoneController.text.length - 1,
      );
    }
  }

  void _clearKeyPad() {
    widget.phoneController.clear();
  }

  void _setAmount(String amount) {
    widget.amountController.text = amount;
  }

  // Operator Detection
  String? get _detectedOperator {
    final text = widget.phoneController.text.trim();
    if (text.startsWith('06')) return 'Mobilis';
    if (text.startsWith('07')) return 'Djezzy';
    if (text.startsWith('05')) return 'Ooredoo';
    return null;
  }

  Color get _operatorColor {
    final op = _detectedOperator;
    if (op == 'Mobilis') return AppColors.mobilisGreen;
    if (op == 'Djezzy') return AppColors.djezzyRed;
    if (op == 'Ooredoo') return AppColors.ooredooRed;
    return AppColors.textMuted;
  }

  // Validation Rules
  bool get _hasValidPrefix {
    final text = widget.phoneController.text.trim();
    if (text.length < 2) return true;
    return text.startsWith('05') || text.startsWith('06') || text.startsWith('07');
  }

  bool get _isPhoneValid {
    final text = widget.phoneController.text.trim();
    return text.length == 10 && _hasValidPrefix;
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoneText = widget.phoneController.text;
    final String? ghostTail = (widget.ghostSuggestion != null &&
            widget.ghostSuggestion!.startsWith(currentPhoneText) &&
            widget.ghostSuggestion!.length > currentPhoneText.length)
        ? widget.ghostSuggestion!.substring(currentPhoneText.length)
        : null;

    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Title + Icon
          // Row(
          //   children: [
          //     Container(
          //       width: 36,
          //       height: 36,
          //       decoration: BoxDecoration(
          //         color: AppColors.primaryTeal.withValues(alpha: 0.15),
          //         borderRadius: BorderRadius.circular(10),
          //         border: Border.all(
          //           color: AppColors.primaryTeal.withValues(alpha: 0.3),
          //         ),
          //       ),
          //       child: const Icon(
          //         Icons.send_rounded,
          //         color: AppColors.primaryTeal,
          //         size: 18,
          //       ),
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       context.tr('new_flexy_transfer'),
          //       style: const TextStyle(
          //         color: AppColors.textPrimary,
          //         fontSize: 16,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ],
          // ),
          //
          // const SizedBox(height: 22),

          // Label: Phone Number + Auto-Detected Operator Badge
          Row(
            children: [
              Text(
                context.tr('phone_number'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_detectedOperator != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _operatorColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _operatorColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sim_card_rounded, size: 12, color: _operatorColor),
                      const SizedBox(width: 4),
                      Text(
                        _detectedOperator!,
                        style: TextStyle(
                          color: _operatorColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Phone Number Input Box with Ghost Suggestion Overlay
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Actual Phone TextField (Large & Prominent for clear distant visibility)
              TextField(
                focusNode: widget.phoneFocusNode,
                controller: widget.phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.phone_android_rounded,
                      size: 24,
                      color: _hasValidPrefix ? AppColors.primaryTeal : AppColors.danger,
                    ),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ghostTail != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: widget.onAcceptGhost,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.5)),
                              ),
                              child: const Text(
                                'TAB ↹',
                                style: TextStyle(
                                  color: AppColors.primaryTeal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.contacts_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: widget.onOpenContacts,
                        tooltip: 'Sélectionner depuis les contacts',
                      ),
                    ],
                  ),
                  hintText: '06 XX XX XX XX',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    fontSize: 22,
                    fontWeight: FontWeight.normal,
                    letterSpacing: 1.5,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _hasValidPrefix ? AppColors.border : AppColors.danger,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _hasValidPrefix ? AppColors.primaryTeal : AppColors.danger,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // 2. Ghost completion tail overlay layer (ON TOP of TextField)
              if (ghostTail != null)
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: currentPhoneText,
                            style: const TextStyle(
                              color: Colors.transparent,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          TextSpan(
                            text: ghostTail,
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.6),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Error Helper Text for Invalid Prefix
          if (!_hasValidPrefix) ...[
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 14),
                SizedBox(width: 6),
                Text(
                  'Numéro invalide (doit commencer par 05, 06 ou 07)',
                  style: TextStyle(color: AppColors.danger, fontSize: 11),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Amount Label & Quick Selector Chips
          Row(
            children: [
              Text(
                context.tr('amount_da'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _QuickAmountChip(amount: '100', onTap: () => _setAmount('100')),
              _QuickAmountChip(amount: '200', onTap: () => _setAmount('200')),
              _QuickAmountChip(amount: '500', onTap: () => _setAmount('500')),
              _QuickAmountChip(amount: '1000', onTap: () => _setAmount('1000')),
            ],
          ),

          const SizedBox(height: 8),

          // Amount Input Box
          TextField(
            controller: widget.amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Client Dropdown & Credit Checkbox Row
          Text(
            context.tr('optional_client'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: (widget.selectedClient != null && widget.clientList.contains(widget.selectedClient))
                          ? widget.selectedClient
                          : (widget.clientList.isNotEmpty ? widget.clientList.first : null),
                      dropdownColor: AppColors.cardHover,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      onChanged: widget.onClientSelected,
                      items: widget.clientList.map((client) {
                        return DropdownMenuItem<String>(
                          value: client,
                          child: Text(client),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Checkbox: À crédit
              InkWell(
                onTap: () => widget.onCreditChanged(!widget.isCredit),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Checkbox(
                      value: widget.isCredit,
                      onChanged: (val) => widget.onCreditChanged(val ?? false),
                      activeColor: AppColors.primaryTeal,
                      checkColor: Colors.black,
                      side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                    ),
                    Text(
                      context.tr('on_credit'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Main Action Button: Envoyer Flexy (Guarded by transactions.create)
          PermissionGuard(
            permission: AppPermissions.transactionsCreate,
            fallback: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.cardHover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('transfer_permission_required'),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            child: CyberButton(
              label: context.tr('send_flexy'),
              icon: Icons.send_rounded,
              height: 52,
              onPressed: _isPhoneValid ? widget.onSendTransfer : null,
            ),
          ),

          const SizedBox(height: 22),

          // Keypad Section Title
          Text(
            context.tr('quick_keypad'),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          // 3x4 Onscreen Numeric Keypad Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _KeypadButton(text: '7', onTap: () => _addKeyDigit('7')),
              _KeypadButton(text: '8', onTap: () => _addKeyDigit('8')),
              _KeypadButton(text: '9', onTap: () => _addKeyDigit('9')),
              _KeypadButton(text: '4', onTap: () => _addKeyDigit('4')),
              _KeypadButton(text: '5', onTap: () => _addKeyDigit('5')),
              _KeypadButton(text: '6', onTap: () => _addKeyDigit('6')),
              _KeypadButton(text: '1', onTap: () => _addKeyDigit('1')),
              _KeypadButton(text: '2', onTap: () => _addKeyDigit('2')),
              _KeypadButton(text: '3', onTap: () => _addKeyDigit('3')),
              _KeypadButton(
                text: 'C',
                backgroundColor: AppColors.keyClear,
                textColor: Colors.white,
                onTap: _clearKeyPad,
              ),
              _KeypadButton(text: '0', onTap: () => _addKeyDigit('0')),
              _KeypadButton(
                icon: Icons.backspace_outlined,
                backgroundColor: AppColors.keyBackspace,
                textColor: Colors.white,
                onTap: _deleteKeyDigit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String amount;
  final VoidCallback onTap;

  const _QuickAmountChip({
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              amount,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const _KeypadButton({
    this.text,
    this.icon,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.keyBg;
    final effectiveTextColor = textColor ?? AppColors.textPrimary;

    return Material(
      color: effectiveBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: icon != null
              ? Icon(icon, color: effectiveTextColor, size: 18)
              : Text(
                  text ?? '',
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
