import '../../../core/utils/library.dart';
import '../../../widgets/cached_image_widget.dart';
import '../model/sounds_mixed_list_model.dart';

class ApiMixCard extends StatelessWidget {
  final Map<String, dynamic> mix;
  final VoidCallback onTap;

  const ApiMixCard({required this.mix, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> rawSounds = mix['rawSounds'] ?? [];
    final String name = mix['name'] ?? 'Mix';
    final String description = (mix['sounds'] as List).join(", ");

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Visual Grid Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C2130),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Take first 4 sounds to show in the grid
                  final displaySounds = rawSounds.take(4).toList();
                  final double itemSize = (constraints.maxWidth - 20) / 2;

                  return Center(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: displaySounds.map((sound) {
                        // 'sound' is a MixedSoundItem object
                        return Container(
                          width: itemSize,
                          height: itemSize,
                          decoration: const BoxDecoration(
                            color: Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: CachedImageWidget(
                              url: sound.image, // Using image from API
                              fit: BoxFit.cover,
                              usePlaceholderIfUrlEmpty: true,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 🔹 Name and Info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.white54, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
void showMixOptions(BuildContext context, MixedSoundRecord mix, String name) {
  Get.bottomSheet(
    Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101A3D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 38),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 40), // spacer
              ],
            ),
            const SizedBox(height: 20),
            _buildOption(context,
                icon: Icons.favorite,
                label: "Unlike",
                color: Colors.pinkAccent,
                onTap: () {
                  Get.back();
                  // 2. Updated to use mix.id instead of mix['id']
                  // controller.unlikeMix(mix.id);
                }),
            const Divider(color: Colors.white10),
            _buildOption(context, icon: Icons.edit_outlined, label: "Rename", onTap: () {}),
            const Divider(color: Colors.white10),
            _buildOption(context, icon: Icons.share_outlined, label: "Share", onTap: () {}),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}
/// 🔸 Helper Widget
Widget _buildOption(BuildContext context, {required IconData icon, required String label, VoidCallback? onTap, Color? color}) {
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 24),
          const SizedBox(width: 16),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 14 * SizeConfigs.textScale, fontWeight: FontWeight.w600),
          ),
          // style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    ),
  );
}
