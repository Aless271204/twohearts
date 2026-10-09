class PetModelCatalog {
  static const penguinModelPath = 'assets/models/Meshy_AI_Pip_the_Penguin_All_Animations.glb';
  static const defaultModelPath = penguinModelPath;
  static const models = {
    'penguin': penguinModelPath,
    'bear': 'assets/runner/play-models/bear.glb',
    'pig': 'assets/runner/play-models/pig.glb',
    'chick': 'assets/runner/play-models/chick.glb',
  };
  static const labels = {'penguin':'Pingüino','bear':'Oso','pig':'Cerdito','chick':'Pollito'};
  static const emojis = {'penguin':'🐧','bear':'🐻','pig':'🐷','chick':'🐥'};
  static String speciesFor(String? value) {
    final key=value?.trim().toLowerCase();
    return {'pingüino':'penguin','pinguino':'penguin','penguin_01':'penguin','oso':'bear','cerdito':'pig','pollito':'chick'}[key] ?? (models.containsKey(key)?key!:'penguin');
  }
  static String modelPathFor(String? species) => models[speciesFor(species)]!;
  static String speciesForPath(String path) => models.entries.firstWhere((e)=>e.value==path,orElse:()=>models.entries.first).key;
  static String stageFor(int level) => level>=10?'Adulta':level>=5?'Juvenil':'Cría';
  static double growthFor(int level) => level>=10?1:level>=5?.88:.74;
}
