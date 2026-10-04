class PetModelCatalog {
  static const String defaultModelPath = 'assets/models/penguin_01.glb';

  static const Map<String, String> _modelPaths = {
    'pingüino': defaultModelPath,
    'penguin': defaultModelPath,
    'penguin_01': defaultModelPath,
  };

  static String modelPathFor(String? petType) {
    final key = petType?.trim().toLowerCase();
    return _modelPaths[key] ?? defaultModelPath;
  }
}
