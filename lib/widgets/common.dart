import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/mock_data.dart';
import '../utils/theme.dart';

/// Restaurant dish photo with a graceful fallback for blocked/slow networks.
class FoodImage extends StatelessWidget {
  final String photoKey;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const FoodImage({super.key, required this.photoKey, this.imageUrl, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final requestWidth = (width == null || !width!.isFinite) ? 300.0 : width!;
    final url = (imageUrl != null && imageUrl!.isNotEmpty)
        ? imageUrl!
        : foodImageUrl(photoKey, width: requestWidth.round() * 2);
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (c, u) => _fallback(),
      errorWidget: (c, u, e) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accentDeep, AppColors.accent]),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant, color: Colors.white38, size: 24),
    );
  }
}

/// The circular white back button used on every pushed sub-screen.
class BackCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  const BackCircleButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: AppColors.chipBorder)),
        child: const Icon(Icons.arrow_back_ios_new, size: 17, color: AppColors.ink),
      ),
    );
  }
}

/// Standard pushed-screen header: back button + title, optional trailing widget.
class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;
  const ScreenHeader({super.key, required this.title, required this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          BackCircleButton(onTap: onBack),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppText.display(size: 18))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A pill-style segmented control (Ongoing/Ready/History, Today/Week/Month, etc).
class SegmentedPills extends StatelessWidget {
  final List<String> labels;
  final List<int>? counts;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const SegmentedPills({super.key, required this.labels, required this.selectedIndex, required this.onSelect, this.counts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.neutralTint, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          final count = counts != null ? counts![i] : 0;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10)] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(labels[i], style: AppText.body(size: 13, weight: FontWeight.w800, color: selected ? AppColors.accent : AppColors.bodyGrey)),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        height: 18,
                        constraints: const BoxConstraints(minWidth: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: selected ? AppColors.accent : AppColors.lightGreyText, borderRadius: BorderRadius.circular(9)),
                        child: Text('$count', style: AppText.body(size: 11, weight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A single horizontally-scrolling filter chip (order type, menu category, review rating, etc).
class FzChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const FzChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.accent : AppColors.chipBorder, width: 1.5),
        ),
        child: Text(label, style: AppText.body(size: 12, weight: FontWeight.w800, color: selected ? Colors.white : AppColors.midGrey)),
      ),
    );
  }
}

/// The pill on/off switch used across Dashboard, Menu, Settings, and the coupon builder.
class ToggleSwitch extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  final double width;
  final double height;
  const ToggleSwitch({super.key, required this.on, required this.onTap, this.width = 44, this.height = 26});

  @override
  Widget build(BuildContext context) {
    final knob = height - 6;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        height: height,
        decoration: BoxDecoration(color: on ? AppColors.green : AppColors.lightGreyText.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(height)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: knob,
              height: knob,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2))]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small colored label chip, e.g. order status ("NEW", "PREPARING") or booking status.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  const StatusBadge({super.key, required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: AppText.body(size: 11, weight: FontWeight.w800, color: fg)),
    );
  }
}

/// A bordered "– value +" stepper pill, e.g. the menu item price control.
class InlineStepper extends StatelessWidget {
  final String valueStr;
  final VoidCallback onDec;
  final VoidCallback onInc;
  const InlineStepper({super.key, required this.valueStr, required this.onDec, required this.onInc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.chipBorder, width: 1.5), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn('–', onDec),
          SizedBox(width: 52, child: Center(child: Text(valueStr, style: AppText.body(size: 13, weight: FontWeight.w800)))),
          _btn('+', onInc),
        ],
      ),
    );
  }

  Widget _btn(String s, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: SizedBox(width: 28, height: 28, child: Center(child: Text(s, style: AppText.body(size: 16, weight: FontWeight.w800, color: AppColors.accent)))),
      );
}

/// A field row with a label/sub on the left and a "– value +" stepper on the right,
/// used throughout the New Coupon builder.
class LabeledStepperRow extends StatelessWidget {
  final String label;
  final String sub;
  final String valueStr;
  final VoidCallback onDec;
  final VoidCallback onInc;
  const LabeledStepperRow({super.key, required this.label, required this.sub, required this.valueStr, required this.onDec, required this.onInc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.chipBorder, width: 1.5), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body(size: 13, weight: FontWeight.w700)),
                Text(sub, style: AppText.body(size: 11, weight: FontWeight.w500, color: AppColors.bodyGrey)),
              ],
            ),
          ),
          Row(
            children: [
              _stepBtn('–', onDec),
              SizedBox(width: 60, child: Center(child: Text(valueStr, style: AppText.display(size: 16)))),
              _stepBtn('+', onInc),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(String s, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(border: Border.all(color: AppColors.inputBorder, width: 1.5), borderRadius: BorderRadius.circular(9)),
          child: Center(child: Text(s, style: AppText.body(size: 18, weight: FontWeight.w800, color: AppColors.accent))),
        ),
      );
}

/// Primary maroon-gradient CTA button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const PrimaryButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppText.body(size: 15.5, weight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}
