import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class ScrollPicker extends StatelessWidget {
  final List<String> items;
  final int initialIndex;
  final ValueChanged<int> onSelected;
  final double itemExtent;
  final String? suffix;

  const ScrollPicker({
    super.key,
    required this.items,
    required this.onSelected,
    this.initialIndex = 0,
    this.itemExtent = 48,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Selected item highlight
          Positioned(
            top: 66,
            left: 16,
            right: 16,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accent.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
          ),
          // Top/bottom fade gradients
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // The scroll picker
          ListWheelScrollView.useDelegate(
            controller: FixedExtentScrollController(initialItem: initialIndex),
            itemExtent: itemExtent,
            physics: const FixedExtentScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            onSelectedItemChanged: onSelected,
            diameterRatio: 1.5,
            perspective: 0.003,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (context, index) {
                return Center(
                  child: Text(
                    items[index],
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary.withOpacity(0.35),
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
          ),
          // Top indicator line
          Positioned(
            top: 65,
            left: 24,
            child: Icon(
              Icons.unfold_more_rounded,
              size: 16,
              color: AppTheme.accent.withOpacity(0.4),
            ),
          ),
          // Bottom indicator line
          Positioned(
            bottom: 65,
            left: 24,
            child: Icon(
              Icons.unfold_more_rounded,
              size: 16,
              color: AppTheme.accent.withOpacity(0.4),
            ),
          ),
        ],
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
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Labels
          if (leftLabel.isNotEmpty)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        leftLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Center(
                      child: Text(
                        rightLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
          // Selected item highlights
          Positioned(
            top: 66,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          // Fade gradients
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Left picker
          Positioned(
            top: 36,
            left: 12,
            width: (MediaQuery.of(context).size.width - 80) / 2,
            height: 108,
            child: ListWheelScrollView.useDelegate(
              controller: FixedExtentScrollController(initialItem: initialLeftIndex),
              itemExtent: 48,
              physics: const FixedExtentScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              onSelectedItemChanged: onLeftChanged,
              diameterRatio: 1.5,
              perspective: 0.003,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: leftItems.length,
                builder: (context, index) => Center(
                  child: Text(
                    leftItems[index],
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary.withOpacity(0.35),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Right picker
          Positioned(
            top: 36,
            right: 12,
            width: (MediaQuery.of(context).size.width - 80) / 2,
            height: 108,
            child: ListWheelScrollView.useDelegate(
              controller: FixedExtentScrollController(initialItem: initialRightIndex),
              itemExtent: 48,
              physics: const FixedExtentScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              onSelectedItemChanged: onRightChanged,
              diameterRatio: 1.5,
              perspective: 0.003,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: rightItems.length,
                builder: (context, index) => Center(
                  child: Text(
                    rightItems[index],
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary.withOpacity(0.35),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
