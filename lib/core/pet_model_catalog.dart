class PetModelCatalog {
  static const String defaultModelPath = 'assets/models/penguin_01.glb';
  static const String penguinModelPath =
      'assets/models/Meshy_AI_Pip_the_Penguin_All_Animations.glb';

  static const Map<String, String> _modelPaths = {
    'pingüino': penguinModelPath,
    'pinguino': penguinModelPath,
    'penguin': penguinModelPath,
    'penguin_01': penguinModelPath,
  };

  static String modelPathFor(String? petType) {
    final key = petType?.trim().toLowerCase();
    return _modelPaths[key] ?? defaultModelPath;
  }
}
