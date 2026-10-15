import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'profile_change_notifier.dart';

class ProfileAvatarService {
  static Future<String?> chooseAndUpload() async {
    final client = SupabaseService.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Inicia sesión');
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (photo == null) return null;
    if (await photo.length() > 10 * 1024 * 1024)
      throw StateError('Elige una foto de menos de 10 MB');
    final codec = await ui.instantiateImageCodec(
      await photo.readAsBytes(),
      targetWidth: 512,
      allowUpscaling: false,
    );
    final frame = await codec.getNextFrame();
    // Re-encode decoded pixels: no original EXIF, GPS or camera metadata is uploaded.
    final pixels = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    if (pixels == null || pixels.lengthInBytes > 3 * 1024 * 1024)
      throw StateError('No pudimos preparar esa foto');
    if (client.auth.currentUser?.id != uid)
      throw StateError('Tu sesión cambió');
    final bucket = client.storage.from('profile-avatars');
    final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.png';
    await bucket.uploadBinary(
      path,
      pixels.buffer.asUint8List(pixels.offsetInBytes, pixels.lengthInBytes),
      fileOptions: const FileOptions(contentType: 'image/png'),
    );
    final url = 'profile-avatar:$path';
    try {
      if (client.auth.currentUser?.id != uid)
        throw StateError('Tu sesión cambió');
      await SupabaseService.instance.updateProfile({'avatar_url': url});
    } catch (_) {
      await bucket.remove([path]);
      rethrow;
    }
    ProfileChangeNotifier.instance.notify();
    return url;
  }
}
