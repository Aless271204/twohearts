String? memoryPhotoPath(String source, String projectUrl) {
  if (source.startsWith('memory-photo:')) {
    final path = source.substring('memory-photo:'.length);
    return path.startsWith('albums/') && !path.split('/').contains('..') ? path : null;
  }
  final uri = Uri.tryParse(source);
  final project = Uri.tryParse(projectUrl);
  const prefix = '/storage/v1/object/public/memory-photos/';
  if (uri?.host == project?.host && uri?.scheme == 'https' && uri!.path.startsWith(prefix)) {
    return Uri.decodeComponent(uri.path.substring(prefix.length));
  }
  return null;
}

