import 'syllable_word_challenge.dart';

class SyllableWordChallenges {
  static const int maxLevel = 10;
  static const int completedWordsToLevelUp = 3;

  static const List<SyllableWordChallenge> all = [
    // NIVEL 1: 2 sílabas, sin distractores
    SyllableWordChallenge(
      id: 'level_1_agua',
      level: 1,
      word: 'Agua',
      pictogramId: 'agua',
      targetSyllables: ['A', 'GUA'],
    ),
    SyllableWordChallenge(
      id: 'level_1_mama',
      level: 1,
      word: 'Mamá',
      pictogramId: 'mama',
      targetSyllables: ['MA', 'MÁ'],
    ),
    SyllableWordChallenge(
      id: 'level_1_papa',
      level: 1,
      word: 'Papá',
      pictogramId: 'papa',
      targetSyllables: ['PA', 'PÁ'],
    ),
    SyllableWordChallenge(
      id: 'level_1_gato',
      level: 1,
      word: 'Gato',
      pictogramId: 'animal_gato',
      targetSyllables: ['GA', 'TO'],
    ),
    SyllableWordChallenge(
      id: 'level_1_pato',
      level: 1,
      word: 'Pato',
      pictogramId: 'animal_pato',
      targetSyllables: ['PA', 'TO'],
    ),

    // NIVEL 2: 2 sílabas, más variedad
    SyllableWordChallenge(
      id: 'level_2_perro',
      level: 2,
      word: 'Perro',
      pictogramId: 'animal_perro',
      targetSyllables: ['PE', 'RRO'],
    ),
    SyllableWordChallenge(
      id: 'level_2_bano',
      level: 2,
      word: 'Baño',
      pictogramId: 'bano',
      targetSyllables: ['BA', 'ÑO'],
    ),
    SyllableWordChallenge(
      id: 'level_2_cama',
      level: 2,
      word: 'Cama',
      pictogramId: 'casa_cama',
      targetSyllables: ['CA', 'MA'],
    ),
    SyllableWordChallenge(
      id: 'level_2_vaca',
      level: 2,
      word: 'Vaca',
      pictogramId: 'animal_vaca',
      targetSyllables: ['VA', 'CA'],
    ),
    SyllableWordChallenge(
      id: 'level_2_casa',
      level: 2,
      word: 'Casa',
      pictogramId: 'lugar_casa',
      targetSyllables: ['CA', 'SA'],
    ),

    // NIVEL 3: 3 sílabas, sin distractores
    SyllableWordChallenge(
      id: 'level_3_pelota',
      level: 3,
      word: 'Pelota',
      pictogramId: 'objeto_pelota',
      targetSyllables: ['PE', 'LO', 'TA'],
    ),
    SyllableWordChallenge(
      id: 'level_3_oveja',
      level: 3,
      word: 'Oveja',
      pictogramId: 'animal_oveja',
      targetSyllables: ['O', 'VE', 'JA'],
    ),
    SyllableWordChallenge(
      id: 'level_3_conejo',
      level: 3,
      word: 'Conejo',
      pictogramId: 'animal_conejo',
      targetSyllables: ['CO', 'NE', 'JO'],
    ),
    SyllableWordChallenge(
      id: 'level_3_jirafa',
      level: 3,
      word: 'Jirafa',
      pictogramId: 'animal_jirafa',
      targetSyllables: ['JI', 'RA', 'FA'],
    ),
    SyllableWordChallenge(
      id: 'level_3_ballena',
      level: 3,
      word: 'Ballena',
      pictogramId: 'animal_ballena',
      targetSyllables: ['BA', 'LLE', 'NA'],
    ),

    // NIVEL 4: 3 sílabas + 1 distractor
    SyllableWordChallenge(
      id: 'level_4_pelota',
      level: 4,
      word: 'Pelota',
      pictogramId: 'objeto_pelota',
      targetSyllables: ['PE', 'LO', 'TA'],
      distractorSyllables: ['MA'],
    ),
    SyllableWordChallenge(
      id: 'level_4_gallina',
      level: 4,
      word: 'Gallina',
      pictogramId: 'animal_gallina',
      targetSyllables: ['GA', 'LLI', 'NA'],
      distractorSyllables: ['TO'],
    ),
    SyllableWordChallenge(
      id: 'level_4_caballo',
      level: 4,
      word: 'Caballo',
      pictogramId: 'animal_caballo',
      targetSyllables: ['CA', 'BA', 'LLO'],
      distractorSyllables: ['PE'],
    ),
    SyllableWordChallenge(
      id: 'level_4_chaqueta',
      level: 4,
      word: 'Chaqueta',
      pictogramId: 'ropa_chaqueta',
      targetSyllables: ['CHA', 'QUE', 'TA'],
      distractorSyllables: ['LO'],
    ),

    // NIVEL 5: 3 sílabas + distractores parecidos
    SyllableWordChallenge(
      id: 'level_5_tortuga',
      level: 5,
      word: 'Tortuga',
      pictogramId: 'animal_tortuga',
      targetSyllables: ['TOR', 'TU', 'GA'],
      distractorSyllables: ['TA'],
    ),
    SyllableWordChallenge(
      id: 'level_5_serpiente',
      level: 5,
      word: 'Serpiente',
      pictogramId: 'animal_serpiente',
      targetSyllables: ['SER', 'PIEN', 'TE'],
      distractorSyllables: ['PE'],
    ),
    SyllableWordChallenge(
      id: 'level_5_pinguino',
      level: 5,
      word: 'Pingüino',
      pictogramId: 'animal_pinguino',
      targetSyllables: ['PIN', 'GÜI', 'NO'],
      distractorSyllables: ['NA'],
    ),
    SyllableWordChallenge(
      id: 'level_5_camiseta',
      level: 5,
      word: 'Camiseta',
      pictogramId: 'ropa_camiseta',
      targetSyllables: ['CA', 'MI', 'SE', 'TA'],
    ),

    // NIVEL 6: 4 sílabas, sin distractor
    SyllableWordChallenge(
      id: 'level_6_elefante',
      level: 6,
      word: 'Elefante',
      pictogramId: 'animal_elefante',
      targetSyllables: ['E', 'LE', 'FAN', 'TE'],
    ),
    SyllableWordChallenge(
      id: 'level_6_mariposa',
      level: 6,
      word: 'Mariposa',
      pictogramId: 'animal_mariposa',
      targetSyllables: ['MA', 'RI', 'PO', 'SA'],
    ),
    SyllableWordChallenge(
      id: 'level_6_camiseta',
      level: 6,
      word: 'Camiseta',
      pictogramId: 'ropa_camiseta',
      targetSyllables: ['CA', 'MI', 'SE', 'TA'],
    ),
    SyllableWordChallenge(
      id: 'level_6_cocodrilo',
      level: 6,
      word: 'Cocodrilo',
      pictogramId: 'animal_cocodrilo',
      targetSyllables: ['CO', 'CO', 'DRI', 'LO'],
    ),

    // NIVEL 7: 4 sílabas + 1 distractor
    SyllableWordChallenge(
      id: 'level_7_elefante',
      level: 7,
      word: 'Elefante',
      pictogramId: 'animal_elefante',
      targetSyllables: ['E', 'LE', 'FAN', 'TE'],
      distractorSyllables: ['FA'],
    ),
    SyllableWordChallenge(
      id: 'level_7_mariposa',
      level: 7,
      word: 'Mariposa',
      pictogramId: 'animal_mariposa',
      targetSyllables: ['MA', 'RI', 'PO', 'SA'],
      distractorSyllables: ['PA'],
    ),
    SyllableWordChallenge(
      id: 'level_7_cocodrilo',
      level: 7,
      word: 'Cocodrilo',
      pictogramId: 'animal_cocodrilo',
      targetSyllables: ['CO', 'CO', 'DRI', 'LO'],
      distractorSyllables: ['TE'],
    ),
    SyllableWordChallenge(
      id: 'level_7_escuchar',
      level: 7,
      word: 'Escuchar',
      pictogramId: 'verbo_escuchar',
      targetSyllables: ['ES', 'CU', 'CHAR'],
      distractorSyllables: ['CA', 'TE'],
    ),

    // NIVEL 8: 4 sílabas + distractores, 5 opciones
    SyllableWordChallenge(
      id: 'level_8_cocodrilo',
      level: 8,
      word: 'Cocodrilo',
      pictogramId: 'animal_cocodrilo',
      targetSyllables: ['CO', 'CO', 'DRI', 'LO'],
      distractorSyllables: ['MA'],
    ),
    SyllableWordChallenge(
      id: 'level_8_elefantete',
      level: 8,
      word: 'Elefante',
      pictogramId: 'animal_elefante',
      targetSyllables: ['E', 'LE', 'FAN', 'TE'],
      distractorSyllables: ['NE'],
    ),
    SyllableWordChallenge(
      id: 'level_8_mariposa',
      level: 8,
      word: 'Mariposa',
      pictogramId: 'animal_mariposa',
      targetSyllables: ['MA', 'RI', 'PO', 'SA'],
      distractorSyllables: ['MI'],
    ),

    // NIVEL 9: 5 opciones
    SyllableWordChallenge(
      id: 'level_9_cocodrilo',
      level: 9,
      word: 'Cocodrilo',
      pictogramId: 'animal_cocodrilo',
      targetSyllables: ['CO', 'CO', 'DRI', 'LO'],
      distractorSyllables: ['PA'],
    ),
    SyllableWordChallenge(
      id: 'level_9_escuchar',
      level: 9,
      word: 'Escuchar',
      pictogramId: 'verbo_escuchar',
      targetSyllables: ['ES', 'CU', 'CHAR'],
      distractorSyllables: ['CA', 'TE'],
    ),
    SyllableWordChallenge(
      id: 'level_9_serpiente',
      level: 9,
      word: 'Serpiente',
      pictogramId: 'animal_serpiente',
      targetSyllables: ['SER', 'PIEN', 'TE'],
      distractorSyllables: ['PE', 'TO'],
    ),

    // NIVEL 10: máximo 6 opciones
    SyllableWordChallenge(
      id: 'level_10_cocodrilo',
      level: 10,
      word: 'Cocodrilo',
      pictogramId: 'animal_cocodrilo',
      targetSyllables: ['CO', 'CO', 'DRI', 'LO'],
      distractorSyllables: ['PA', 'TE'],
    ),
    SyllableWordChallenge(
      id: 'level_10_mariposa',
      level: 10,
      word: 'Mariposa',
      pictogramId: 'animal_mariposa',
      targetSyllables: ['MA', 'RI', 'PO', 'SA'],
      distractorSyllables: ['MI', 'TO'],
    ),
    SyllableWordChallenge(
      id: 'level_10_elefante',
      level: 10,
      word: 'Elefante',
      pictogramId: 'animal_elefante',
      targetSyllables: ['E', 'LE', 'FAN', 'TE'],
      distractorSyllables: ['FA', 'NO'],
    ),
  ];

  static List<SyllableWordChallenge> getByLevel(int level) {
    return all.where((challenge) => challenge.level == level).toList();
  }
}
