import 'package:flutter/material.dart';

class SceneStatus extends StatelessWidget {
  final String title, message;
  final bool loading;
  final VoidCallback? onRetry;
  const SceneStatus({super.key, required this.title, required this.message, this.loading = true, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 340), child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 8))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(loading ? Icons.favorite_rounded : Icons.cloud_off_rounded, color: const Color(0xFFF05280), size: 44),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Color(0xFF292633))),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.5, color: Color(0xFF716B78))),
        if (loading) const Padding(padding: EdgeInsets.only(top: 22), child: ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child: LinearProgressIndicator(minHeight: 5, color: Color(0xFFF05280), backgroundColor: Color(0xFFFBE5EC)))),
        if (onRetry != null) Padding(padding: const EdgeInsets.only(top: 16), child: FilledButton(onPressed: onRetry, child: const Text('Volver'))),
      ]),
    )),
  ));
}
