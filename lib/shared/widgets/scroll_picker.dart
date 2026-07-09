import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class ScrollPicker extends StatelessWidget {
  final List<String> items;
  final int initialIndex;
  final ValueChanged<int> onSelected;
  final double itemExtent;

  const ScrollPicker({
    super.key,
    required this.items,
    required this.onSelected,
    this.initialIndex = 0,
    this.itemExtent = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListWheelScrollView.useDelegate(
        controller: FixedExtentScrollController(initialItem: initialIndex),
        itemExtent: itemExtent,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (context, index) {
            return Center(
              child: Text(
                items[index],
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DualScrollPicker extends StatelessWidget {
  final List<String> leftItems;
  final List<String> rightItems;
  final int initialLeftIndex;
  final int initialRightIndex;
  final ValueChanged<int> onLeftChanged;
  final ValueChanged<int> onRightChanged;
  final String leftLabel;
  final String rightLabel;

  const DualScrollPicker({
    super.key,
    required this.leftItems,
    required this.rightItems,
    required this.onLeftChanged,
    required this.onRightChanged,
    this.initialLeftIndex = 0,
    this.initialRightIndex = 0,
    this.leftLabel = '',
    this.rightLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                if (leftLabel.isNotEmpty)
                  Text(leftLabel, style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: FixedExtentScrollController(initialItem: initialLeftIndex),
                    itemExtent: 40,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: onLeftChanged,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: leftItems.length,
                      builder: (context, index) => Center(
                        child: Text(leftItems[index], style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                        )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                if (rightLabel.isNotEmpty)
                  Text(rightLabel, style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: FixedExtentScrollController(initialItem: initialRightIndex),
                    itemExtent: 40,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: onRightChanged,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: rightItems.length,
                      builder: (context, index) => Center(
                        child: Text(rightItems[index], style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                        )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
