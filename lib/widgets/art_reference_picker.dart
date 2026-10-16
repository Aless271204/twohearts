import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/art_reference_catalog.dart';
import '../core/memory_photo_reference.dart';
import '../services/memory_album_service.dart';
import '../services/supabase_service.dart';
import 'private_memory_image.dart';

class ArtReferenceChoice {
  final String title;
  final Uint8List bytes;
  const ArtReferenceChoice(this.title, this.bytes);
}

Future<ArtReferenceChoice?> showArtReferencePicker(BuildContext context) =>
    showModalBottomSheet<ArtReferenceChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFF7F5),
      builder: (_) => const _ReferencePicker(),
    );

class _ReferencePicker extends StatefulWidget {
  const _ReferencePicker();
  @override
  State<_ReferencePicker> createState() => _ReferencePickerState();
}

class _ReferencePickerState extends State<_ReferencePicker> {
  bool busy = false;
  String? error;
  int tab = 0;
  Future<List<(String, String)>>? memories, trips;
  final destination = TextEditingController();
  @override
  void dispose() {
    destination.dispose();
    super.dispose();
  }

  Future<List<(String, String)>> _memories() async {
    final albums = await MemoryAlbumService.instance.getAlbums();
    final notes = await SupabaseService.instance.getMemories();
    return [
      for (final album in albums)
        for (final photo in album.photoUrls) (album.albumName, photo),
      for (final note in notes)
        if ((note['image_url'] as String? ?? '').isNotEmpty)
          (
            note['title'] as String? ?? 'Nuestro recuerdo',
            note['image_url'] as String,
          ),
    ];
  }

  Future<List<(String, String)>> _trips() async {
    final rows = await SupabaseService.instance.getTrips();
    return [
      for (final r in rows)
        (
          r['city'] as String? ?? 'Nuestro viaje',
          r['image_url'] as String? ?? '',
        ),
    ];
  }

  Future<void> _choose(String title, {String? source, String? asset}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      Uint8List? bytes;
      if (asset != null)
        bytes = (await rootBundle.load(asset)).buffer.asUint8List();
      else if (source == null || source.isEmpty) {
        final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (file != null) bytes = await file.readAsBytes();
      } else {
        final path = memoryPhotoPath(source, SupabaseService.supabaseUrl);
        if (path != null)
          bytes = await SupabaseService.instance.client.storage
              .from('memory-photos')
              .download(path);
        else {
          final uri = Uri.parse(source);
          if (uri.scheme != 'https')
            throw const FormatException('Usa una foto segura');
          final client = http.Client();
          try {
            final response = await client
                .send(http.Request('GET', uri))
                .timeout(const Duration(seconds: 15));
            if (response.statusCode != 200)
              throw const FormatException('No disponible');
            final builder = BytesBuilder();
            await for (final part in response.stream.timeout(
              const Duration(seconds: 15),
            )) {
              builder.add(part);
              if (builder.length > 12000000)
                throw const FormatException('Imagen demasiado grande');
            }
            bytes = builder.takeBytes();
          } finally {
            client.close();
          }
        }
      }
      if (bytes != null && bytes.length <= 12000000 && mounted)
        Navigator.pop(context, ArtReferenceChoice(title, bytes));
    } catch (_) {
      if (mounted)
        setState(
          () => error =
              'No pudimos abrir esa foto. Puedes elegir otra o subirla desde tu galería.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .83,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Su próxima inspiración',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const Text(
            'Recuerdos de ustedes, destinos por descubrir y aventuras de sus mascotas.',
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        [
                          'Sus fotos',
                          'Sus viajes',
                          'Explorar',
                          'Próximo viaje',
                        ][i],
                      ),
                      selected: tab == i,
                      onSelected: busy
                          ? null
                          : (_) => setState(() {
                              tab = i;
                              if (i == 0) memories ??= _memories();
                              if (i == 1) trips ??= _trips();
                            }),
                    ),
                  ),
              ],
            ),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          if (busy) const LinearProgressIndicator(),
          Expanded(
            child: tab == 0 || tab == 1
                ? FutureBuilder<List<(String, String)>>(
                    future: tab == 0
                        ? (memories ??= _memories())
                        : (trips ??= _trips()),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final rows = snapshot.data!;
                      if (rows.isEmpty)
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Aún no hay fotos aquí. Pueden comenzar con una de su galería.',
                              ),
                              FilledButton(
                                onPressed: busy
                                    ? null
                                    : () => _choose('Nuestro recuerdo'),
                                child: const Text('Elegir una foto'),
                              ),
                            ],
                          ),
                        );
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: .9,
                            ),
                        itemCount: rows.length,
                        itemBuilder: (context, i) => _card(
                          rows[i].$1,
                          rows[i].$2.isEmpty
                              ? const Icon(Icons.add_photo_alternate, size: 50)
                              : PrivateMemoryImage(
                                  rows[i].$2,
                                  fit: BoxFit.cover,
                                ),
                          () => _choose(rows[i].$1, source: rows[i].$2),
                        ),
                      );
                    },
                  )
                : tab == 2
                ? GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: .92,
                    children: [
                      _card(
                        'Picnic en París · 3D',
                        Image.asset(
                          'assets/images/art_references/paris-mascots.webp',
                          fit: BoxFit.cover,
                        ),
                        () => _choose(
                          'Picnic en París · Mascotas 3D',
                          asset:
                              'assets/images/art_references/paris-mascots.webp',
                        ),
                      ),
                      _card(
                        'Guardianes · Pixel art',
                        Image.asset(
                          'assets/images/art_references/guardian-mascots.webp',
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.none,
                        ),
                        () => _choose(
                          'Guardianes del Alba · Pixel art',
                          asset:
                              'assets/images/art_references/guardian-mascots.webp',
                        ),
                      ),
                      for (final place in travelReferences)
                        _card(
                          place.$2,
                          Image.asset(
                            'assets/images/art_references/${place.$1}.webp',
                            fit: BoxFit.cover,
                          ),
                          () => _choose(
                            place.$2,
                            asset:
                                'assets/images/art_references/${place.$1}.webp',
                          ),
                        ),
                    ],
                  )
                : ListView(
                    children: [
                      const Text(
                        'Cualquier lugar del mundo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: destination,
                        maxLength: 120,
                        decoration: const InputDecoration(
                          labelText: '¿A dónde sueñan ir?',
                          hintText: 'Por ejemplo, Cartagena, Seúl o Islandia',
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => _choose(
                                destination.text.trim().isEmpty
                                    ? 'Nuestro próximo viaje'
                                    : destination.text.trim(),
                              ),
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Usar una foto de inspiración'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final query = destination.text.trim();
                          await launchUrl(
                            Uri.https(
                              'unsplash.com',
                              '/s/photos/${Uri.encodeComponent(query.isEmpty ? 'pastel travel' : query)}',
                            ),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        icon: const Icon(Icons.travel_explore),
                        label: const Text('Buscar inspiración en Unsplash'),
                      ),
                      const Text(
                        'Guarda la foto que te guste y elígela aquí. También puedes usar una foto de un viaje que ya planeaste en NIDO. Las fotos personales se comparten únicamente con la pareja de la partida.',
                        style: TextStyle(height: 1.5),
                      ),
                    ],
                  ),
          ),
          if (tab == 2)
            const Text(
              'Fotografías de Unsplash · referencias de viaje. Ilustraciones de mascotas creadas para NIDO.',
              style: TextStyle(fontSize: 10),
            ),
          if (tab != 3)
            TextButton.icon(
              onPressed: busy ? null : () => _choose('Nuestro recuerdo'),
              icon: const Icon(Icons.photo_library),
              label: const Text('Elegir desde el teléfono'),
            ),
        ],
      ),
    ),
  );
  Widget _card(String title, Widget image, VoidCallback tap) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: busy ? null : tap,
      child: Column(
        children: [
          Expanded(
            child: SizedBox(width: double.infinity, child: image),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
