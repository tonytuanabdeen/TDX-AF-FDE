import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mortgage_question.dart';
import '../../../theme/app_theme.dart';

class QuestionInput extends StatefulWidget {
  const QuestionInput({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.onChanged,
  });

  final MortgageQuestion question;
  final String currentAnswer;
  final ValueChanged<String> onChanged;

  @override
  State<QuestionInput> createState() => _QuestionInputState();
}

class _QuestionInputState extends State<QuestionInput> {
  late final TextEditingController _textController;
  late final TextEditingController _detailController;
  bool _yesSelected = false;

  @override
  void initState() {
    super.initState();
    final ans = widget.currentAnswer;

    if (widget.question.inputType == InputType.yesNo ||
        widget.question.inputType == InputType.yesNoWithDetail) {
      if (ans.startsWith('Yes')) {
        _yesSelected = true;
        _textController = TextEditingController();
        _detailController =
            TextEditingController(text: ans.length > 4 ? ans.substring(5) : '');
      } else {
        _yesSelected = ans == 'Yes';
        _textController = TextEditingController();
        _detailController = TextEditingController();
      }
    } else {
      _textController = TextEditingController(text: ans);
      _detailController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _emitYesNo(bool yes) {
    setState(() => _yesSelected = yes);
    if (!yes) {
      _detailController.clear();
      widget.onChanged('No');
    } else {
      final detail = _detailController.text.trim();
      widget.onChanged(detail.isEmpty ? 'Yes' : 'Yes: $detail');
    }
  }

  void _emitDetail(String val) {
    widget.onChanged(_yesSelected
        ? (val.trim().isEmpty ? 'Yes' : 'Yes: ${val.trim()}')
        : 'No');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = widget.question;

    switch (q.inputType) {
      case InputType.picklist:
        return Column(
          children: q.options.map((opt) {
            final selected = widget.currentAnswer == opt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => widget.onChanged(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.brandRed.withValues(alpha: 0.08)
                        : scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppTheme.brandRed
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppTheme.brandRed
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.brandRed, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case InputType.currency:
        return TextField(
          controller: _textController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.dmSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: GoogleFonts.dmSans(
                fontSize: 15, color: AppTheme.secondaryLabel),
            prefixText: '\$ ',
          ),
          onChanged: (v) => widget.onChanged(v.trim()),
        );

      case InputType.yesNo:
      case InputType.yesNoWithDetail:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ToggleOption(
                  label: 'Yes',
                  selected: _yesSelected,
                  onTap: () => _emitYesNo(true),
                ),
                const SizedBox(width: 12),
                _ToggleOption(
                  label: 'No',
                  selected: !_yesSelected,
                  onTap: () => _emitYesNo(false),
                ),
              ],
            ),
            if (_yesSelected &&
                q.inputType == InputType.yesNoWithDetail) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _detailController,
                style: GoogleFonts.dmSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText: q.detailHint ?? 'Please provide details',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 15, color: AppTheme.secondaryLabel),
                ),
                onChanged: _emitDetail,
              ),
            ],
          ],
        );

      case InputType.text:
        return TextField(
          controller: _textController,
          style: GoogleFonts.dmSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Type your answer',
            hintStyle: GoogleFonts.dmSans(
                fontSize: 15, color: AppTheme.secondaryLabel),
          ),
          onChanged: (v) => widget.onChanged(v.trim()),
        );
    }
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.brandRed.withValues(alpha: 0.08)
                : scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.brandRed : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color:
                    selected ? AppTheme.brandRed : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
