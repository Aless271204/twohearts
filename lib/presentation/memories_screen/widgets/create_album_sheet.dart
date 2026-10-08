import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/memory_album_service.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';

class CreateAlbumSheet extends StatefulWidget {
  final VoidCallback? onAlbumCreated;

  const CreateAlbumSheet({super.key, this.onAlbumCreated});

  @override
  State<CreateAlbumSheet> createState() => _CreateAlbumSheetState();
}

class _CreateAlbumSheetState extends State<CreateAlbumSheet> {
  final _albumNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<_PickedPhoto> _pickedPhotos = [];
  bool _saving = false;
  bool _pickingPhotos = false;
  final Map<_PickedPhoto, String> _uploadedUrls = {};
  bool _uploadingPhotos = false;
  String? _errorMessage;

  // Category
  String _selectedCategory = 'general';

  static const int _maxPhotos = 5;

  static const _categories = [
    ('general', '🗂️', 'General'),
    ('lugar', '📍', 'Lugar'),
    ('fecha', '📅', 'Fecha'),
    ('especial', '⭐', 'Especial'),
    ('viaje', '✈️', 'Viaje'),
    ('cita', '💑', 'Cita'),
  ];

  @override
  void dispose() {
    _albumNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_saving || _pickingPhotos) return;
    if (_pickedPhotos.length >= _maxPhotos) {
      _showError('Máximo $_maxPhotos fotos por álbum');
      return;
    }

    try {
      _pickingPhotos = true;
      final picker = ImagePicker();
      final remaining = _maxPhotos - _pickedPhotos.length;

      if (kIsWeb) {
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (image != null) {
          final bytes = await image.readAsBytes();
          if (mounted) {
            setState(() {
              _pickedPhotos.add(
                _PickedPhoto(xFile: image, bytes: bytes, name: image.name),
              );
            });
          }
        }
      } else {
        final images = await picker.pickMultiImage(imageQuality: 80);
        if (images.isNotEmpty && mounted) {
          final toAdd = images.take(remaining).toList();
          final picked = <_PickedPhoto>[];
          for (final img in toAdd) {
            final bytes = await img.readAsBytes();
            picked.add(_PickedPhoto(xFile: img, bytes: bytes, name: img.name));
          }
          if (mounted) setState(() => _pickedPhotos.addAll(picked));
        }
      }
    } catch (e) {
      _showError('No se pudo abrir la galería. Vuelve a intentarlo.');
    } finally {
      _pickingPhotos = false;
    }
  }

  void _removePhoto(int index) {
    if (!_saving) setState(() => _pickedPhotos.removeAt(index));
  }

  void _showError(String msg) {
    if (mounted) setState(() => _errorMessage = msg);
  }

  Future<List<String>> _uploadPhotos() async {
    final client = SupabaseService.instance.client;
    final uid = SupabaseService.instance.currentUser?.id;
    if (uid == null) throw StateError('Inicia sesión para guardar tu álbum');
    final urls = <String>[];

    for (int i = 0; i < _pickedPhotos.length; i++) {
      final photo = _pickedPhotos[i];
      if (_uploadedUrls.containsKey(photo)) {
        urls.add(_uploadedUrls[photo]!);
        continue;
      }
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final ext = photo.name.contains('.')
          ? photo.name.split('.').last.toLowerCase()
          : 'jpg';
      final mime = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/$ext';
      if (photo.bytes.length > 10 * 1024 * 1024)
        throw StateError('Cada foto debe pesar menos de 10 MB');
      final path = 'albums/$uid/${timestamp}_$i.$ext';

      try {
        await client.storage
            .from('memory-photos')
            .uploadBinary(
              path,
              photo.bytes,
              fileOptions: FileOptions(contentType: mime, upsert: false),
            );
        final url = 'memory-photo:$path';
        urls.add(url);
        _uploadedUrls[photo] = url;
      } catch (e) {
        debugPrint('Photo upload failed: $e');
        rethrow;
      }
    }
    return urls;
  }

  Future<void> _onSave() async {
    if (_saving || _pickingPhotos) return;
    final name = _albumNameController.text.trim();
    if (name.isEmpty) {
      _showError('Por favor ingresa un nombre para el álbum');
      return;
    }
    if (_pickedPhotos.isEmpty) {
      _showError('Agrega al menos una foto al álbum');
      return;
    }

    setState(() {
      _saving = true;
      _uploadingPhotos = true;
      _errorMessage = null;
    });

    List<String> photoUrls;
    try {
      photoUrls = await _uploadPhotos();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _uploadingPhotos = false;
        _errorMessage = 'Error al subir las fotos';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _uploadingPhotos = false);

    final error = await MemoryAlbumService.instance.createAlbum(
      albumName: name,
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      photoUrls: photoUrls,
    );

    if (mounted) {
      setState(() => _saving = false);
      if (error != null) {
        _showError(error);
      } else {
        widget.onAlbumCreated?.call();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  children: [
                    Text(
                      'Nuevo álbum 📸',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: const Color(0xFF9E9E9E),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withAlpha(60)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Category selector
                      _SectionLabel(label: 'Tipo de álbum'),
                      const SizedBox(height: 10),
                      _buildCategorySelector(),
                      const SizedBox(height: 16),

                      // Album name
                      _SectionLabel(label: 'Nombre del álbum *'),
                      const SizedBox(height: 8),
                      _StyledTextField(
                        controller: _albumNameController,
                        hintText: _getCategoryHint(),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _SectionLabel(label: 'Descripción'),
                      const SizedBox(height: 8),
                      _StyledTextField(
                        controller: _descriptionController,
                        hintText: 'Cuéntanos sobre este recuerdo...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      // Photos section
                      Row(
                        children: [
                          _SectionLabel(label: 'Fotos'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_pickedPhotos.length}/$_maxPhotos',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Máximo 5 fotos por álbum',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPhotoGrid(),
                      const SizedBox(height: 20),

                      // Spotify section
                      const SizedBox(height: 28),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _saving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _uploadingPhotos
                                          ? 'Subiendo fotos...'
                                          : 'Guardando...',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Crear álbum 💝',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getCategoryHint() {
    switch (_selectedCategory) {
      case 'lugar':
        return 'Ej: Barcelona, España 🌊';
      case 'fecha':
        return 'Ej: Verano 2026 ☀️';
      case 'especial':
        return 'Ej: Nuestro primer aniversario 💍';
      case 'viaje':
        return 'Ej: Viaje a París ✈️';
      case 'cita':
        return 'Ej: Cita en el parque 🌸';
      default:
        return 'Ej: Recuerdos de agosto 📸';
    }
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final (id, emoji, label) = cat;
        final isSelected = _selectedCategory == id;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primary : const Color(0xFFEEEEEE),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF5A5A5A),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._pickedPhotos.asMap().entries.map((entry) {
          final i = entry.key;
          final photo = entry.value;
          return _PhotoThumbnail(
            bytes: photo.bytes,
            onRemove: () => _removePhoto(i),
          );
        }),
        if (_pickedPhotos.length < _maxPhotos)
          GestureDetector(
            onTap: _pickPhotos,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primary.withAlpha(80),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Galería',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PickedPhoto {
  final XFile xFile;
  final Uint8List bytes;
  final String name;

  const _PickedPhoto({
    required this.xFile,
    required this.bytes,
    required this.name,
  });
}

class _PhotoThumbnail extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const _PhotoThumbnail({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(bytes, width: 90, height: 90, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.dmSans(
          fontSize: 13,
          color: const Color(0xFFBBBBBB),
        ),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
