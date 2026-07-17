import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../models/api/menu_models.dart';
import '../repositories/restaurant_repository.dart';
import '../services/mock_data.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class FssaiScreen extends ConsumerStatefulWidget {
  const FssaiScreen({super.key});

  @override
  ConsumerState<FssaiScreen> createState() => _FssaiScreenState();
}

class _FssaiScreenState extends ConsumerState<FssaiScreen> {
  List<ApiDocument>? _docs;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final rid = ref.read(authControllerProvider).restaurantId;
    if (rid == null) return;
    setState(() => _loading = true);
    try {
      final docs = await ref.read(restaurantRepositoryProvider).getDocuments(rid);
      if (mounted) setState(() => _docs = docs);
    } catch (e) {
      debugPrint('[Fssai] load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _emojiFor(String type) => switch (type.toUpperCase()) {
        'FSSAI' => '🧾',
        'GST' => '🏛️',
        'PAN' => '🪪',
        'BANK' => '🏦',
        _ => '📄',
      };

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(navigationControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final fssai = auth.restaurant?.fssaiNumber;
    final verified = fssai != null && fssai.isNotEmpty;

    final docRows = (_docs != null && _docs!.isNotEmpty)
        ? _docs!
            .map((d) => (
                  emoji: _emojiFor(d.type),
                  name: d.type.isNotEmpty ? d.type : d.filename,
                  meta: d.filename.isNotEmpty ? d.filename : d.status,
                  ok: d.isVerified,
                ))
            .toList()
        : docsList;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'FSSAI & documents', onBack: nav.back),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: verified ? const [AppColors.green, AppColors.greenDark] : const [AppColors.amber, Color(0xFFB45309)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('FSSAI status', style: AppText.body(size: 12, color: Colors.white.withValues(alpha: 0.9))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(20)),
                        child: Text(verified ? '✓ VERIFIED' : 'PENDING', style: AppText.body(size: 10, weight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      fssai ?? '13319 0110 00287',
                      style: AppText.display(size: 22, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      verified ? 'On file with Foodeez' : 'Upload your FSSAI licence',
                      style: AppText.body(size: 11.5, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
              child: Text('DOCUMENTS', style: AppText.body(size: 13, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.5)),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
              )
            else
              Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: docRows
                      .map((d) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                            child: Row(
                              children: [
                                Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.maroonTint, borderRadius: BorderRadius.circular(11)), alignment: Alignment.center, child: Text(d.emoji, style: const TextStyle(fontSize: 17))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.name, style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                                      Text(d.meta, style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(color: d.ok ? AppColors.greenPaleBg2 : AppColors.amberPaleBg, borderRadius: BorderRadius.circular(20)),
                                  child: Text(d.ok ? 'Verified' : 'Pending', style: AppText.body(size: 10, weight: FontWeight.w800, color: d.ok ? AppColors.green : AppColors.amber)),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Upload a document', style: AppText.body(size: 13.5, weight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
