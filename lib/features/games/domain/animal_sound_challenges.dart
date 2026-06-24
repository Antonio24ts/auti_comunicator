import 'animal_sound_challenge.dart';

class AnimalSoundChallenges {
  static const int maxLevel = 8;
  static const int correctAnswersToLevelUp = 3;

  static const List<AnimalSoundChallenge> all = [
    // NIVEL 1: más fáciles y cotidianos
    AnimalSoundChallenge(
      id: 'animal_sound_perro',
      level: 1,
      animalName: 'Perro',
      pictogramId: 'animal_perro',
      soundAssetPath: 'assets/audio/animales/perro.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_gato',
      level: 1,
      animalName: 'Gato',
      pictogramId: 'animal_gato',
      soundAssetPath: 'assets/audio/animales/gato.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_pajaro',
      level: 1,
      animalName: 'Pájaro',
      pictogramId: 'animal_pajaro',
      soundAssetPath: 'assets/audio/animales/pajaro.mp3',
    ),

    // NIVEL 2: granja muy clara
    AnimalSoundChallenge(
      id: 'animal_sound_vaca',
      level: 2,
      animalName: 'Vaca',
      pictogramId: 'animal_vaca',
      soundAssetPath: 'assets/audio/animales/vaca.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_cerdo',
      level: 2,
      animalName: 'Cerdo',
      pictogramId: 'animal_cerdo',
      soundAssetPath: 'assets/audio/animales/cerdo.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_oveja',
      level: 2,
      animalName: 'Oveja',
      pictogramId: 'animal_oveja',
      soundAssetPath: 'assets/audio/animales/oveja.mp3',
    ),

    // NIVEL 3: granja y sonidos conocidos
    AnimalSoundChallenge(
      id: 'animal_sound_gallina',
      level: 3,
      animalName: 'Gallina',
      pictogramId: 'animal_gallina',
      soundAssetPath: 'assets/audio/animales/gallina.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_pato',
      level: 3,
      animalName: 'Pato',
      pictogramId: 'animal_pato',
      soundAssetPath: 'assets/audio/animales/pato.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_caballo',
      level: 3,
      animalName: 'Caballo',
      pictogramId: 'animal_caballo',
      soundAssetPath: 'assets/audio/animales/caballo.mp3',
    ),

    // NIVEL 4: granja algo más difícil
    AnimalSoundChallenge(
      id: 'animal_sound_burro',
      level: 4,
      animalName: 'Burro',
      pictogramId: 'animal_burro',
      soundAssetPath: 'assets/audio/animales/burro.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_cabra',
      level: 4,
      animalName: 'Cabra',
      pictogramId: 'animal_cabra',
      soundAssetPath: 'assets/audio/animales/cabra.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_rana',
      level: 4,
      animalName: 'Rana',
      pictogramId: 'animal_rana',
      soundAssetPath: 'assets/audio/animales/rana.mp3',
    ),

    // NIVEL 5: salvajes muy reconocibles
    AnimalSoundChallenge(
      id: 'animal_sound_leon',
      level: 5,
      animalName: 'León',
      pictogramId: 'animal_leon',
      soundAssetPath: 'assets/audio/animales/leon.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_tigre',
      level: 5,
      animalName: 'Tigre',
      pictogramId: 'animal_tigre',
      soundAssetPath: 'assets/audio/animales/tigre.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_elefante',
      level: 5,
      animalName: 'Elefante',
      pictogramId: 'animal_elefante',
      soundAssetPath: 'assets/audio/animales/elefante.mp3',
    ),

    // NIVEL 6: salvajes y pequeños
    AnimalSoundChallenge(
      id: 'animal_sound_mono',
      level: 6,
      animalName: 'Mono',
      pictogramId: 'animal_mono',
      soundAssetPath: 'assets/audio/animales/mono.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_oso',
      level: 6,
      animalName: 'Oso',
      pictogramId: 'animal_oso',
      soundAssetPath: 'assets/audio/animales/oso.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_raton',
      level: 6,
      animalName: 'Ratón',
      pictogramId: 'animal_raton',
      soundAssetPath: 'assets/audio/animales/raton.mp3',
    ),

    // NIVEL 7: reptiles y sonidos más concretos
    AnimalSoundChallenge(
      id: 'animal_sound_serpiente',
      level: 7,
      animalName: 'Serpiente',
      pictogramId: 'animal_serpiente',
      soundAssetPath: 'assets/audio/animales/serpiente.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_cocodrilo',
      level: 7,
      animalName: 'Cocodrilo',
      pictogramId: 'animal_cocodrilo',
      soundAssetPath: 'assets/audio/animales/cocodrilo.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_pinguino',
      level: 7,
      animalName: 'Pingüino',
      pictogramId: 'animal_pinguino',
      soundAssetPath: 'assets/audio/animales/pinguino.mp3',
    ),

    // NIVEL 8: marinos e insectos
    AnimalSoundChallenge(
      id: 'animal_sound_delfin',
      level: 8,
      animalName: 'Delfín',
      pictogramId: 'animal_delfin',
      soundAssetPath: 'assets/audio/animales/delfin.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_ballena',
      level: 8,
      animalName: 'Ballena',
      pictogramId: 'animal_ballena',
      soundAssetPath: 'assets/audio/animales/ballena.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_abeja',
      level: 8,
      animalName: 'Abeja',
      pictogramId: 'animal_abeja',
      soundAssetPath: 'assets/audio/animales/abeja.mp3',
    ),
    AnimalSoundChallenge(
      id: 'animal_sound_mosca',
      level: 8,
      animalName: 'Mosca',
      pictogramId: 'animal_mosca',
      soundAssetPath: 'assets/audio/animales/mosca.mp3',
    ),
  ];

  static List<AnimalSoundChallenge> getByLevel(int level) {
    return all.where((challenge) => challenge.level == level).toList();
  }

  static List<AnimalSoundChallenge> getPreviousLevels(int level) {
    return all.where((challenge) => challenge.level < level).toList();
  }
}
