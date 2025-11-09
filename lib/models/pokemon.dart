class PokemonAbility {
  final String name;
  final bool isHidden;
  final String shortEffect;

  PokemonAbility({
    required this.name,
    required this.isHidden,
    required this.shortEffect,
  });

  factory PokemonAbility.fromJson(Map<String, dynamic> json) {
    return PokemonAbility(
      name: json['name'] as String,
      isHidden: json['is_hidden'] as bool,
      shortEffect: json['short_effect'] as String,
    );
  }
}

class PokemonMove {
  final String name;
  final String method;
  final int? level;

  PokemonMove({
    required this.name,
    required this.method,
    this.level,
  });

  factory PokemonMove.fromJson(Map<String, dynamic> json) {
    return PokemonMove(
      name: json['name'] as String,
      method: json['method'] as String,
      level: json['level'] as int?,
    );
  }
}

class BaseStats {
  final int hp;
  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;
  final int total;

  BaseStats({
    required this.hp,
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
    required this.total,
  });

  factory BaseStats.fromJson(Map<String, dynamic> json) {
    return BaseStats(
      hp: json['hp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      specialAttack: json['special_attack'] as int,
      specialDefense: json['special_defense'] as int,
      speed: json['speed'] as int,
      total: json['total'] as int,
    );
  }
}

class Pokemon {
  final int nationalDex;
  final String name;
  final int generation;
  final List<String> types;
  final String? spriteUrl;
  final String? officialArtworkUrl;
  final double? heightM;
  final double? weightKg;
  final BaseStats baseStats;
  final List<PokemonAbility> abilities;
  final List<String> eggGroups;
  final bool isLegendary;
  final bool isMythical;
  final List<String> forms;
  final List<List<String>> evolutionChain;
  final List<PokemonMove> movesSample;
  final String? flavorText;
  final int? captureRate;
  final String? color;
  final Map<String, double> damageRelations;
  final bool shinyAvailable;
  final Map<String, String> officialSources;

  Pokemon({
    required this.nationalDex,
    required this.name,
    required this.generation,
    required this.types,
    this.spriteUrl,
    this.officialArtworkUrl,
    this.heightM,
    this.weightKg,
    required this.baseStats,
    required this.abilities,
    required this.eggGroups,
    required this.isLegendary,
    required this.isMythical,
    required this.forms,
    required this.evolutionChain,
    required this.movesSample,
    this.flavorText,
    this.captureRate,
    this.color,
    required this.damageRelations,
    required this.shinyAvailable,
    required this.officialSources,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      nationalDex: json['national_dex'] as int,
      name: json['name'] as String,
      generation: json['generation'] as int,
      types: List<String>.from(json['types']),
      spriteUrl: json['sprite_url'] as String?,
      officialArtworkUrl: json['official_artwork_url'] as String?,
      heightM: json['height_m'] != null ? (json['height_m'] as num).toDouble() : null,
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      baseStats: BaseStats.fromJson(json['base_stats']),
      abilities: (json['abilities'] as List)
          .map((a) => PokemonAbility.fromJson(a))
          .toList(),
      eggGroups: List<String>.from(json['egg_groups']),
      isLegendary: json['is_legendary'] as bool,
      isMythical: json['is_mythical'] as bool,
      forms: List<String>.from(json['forms']),
      evolutionChain: (json['evolution_chain'] as List)
          .map((chain) => List<String>.from(chain))
          .toList(),
      movesSample: (json['moves_sample'] as List)
          .map((m) => PokemonMove.fromJson(m))
          .toList(),
      flavorText: json['flavor_text'] as String?,
      captureRate: json['capture_rate'] as int?,
      color: json['color'] as String?,
      damageRelations: (json['damage_relations'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      shinyAvailable: json['shiny_available'] as bool,
      officialSources: Map<String, String>.from(json['official_sources']),
    );
  }
}

class PokemonListResponse {
  final int pageSize;
  final int pageNumber;
  final String? nextCursor;
  final List<Pokemon> results;

  PokemonListResponse({
    required this.pageSize,
    required this.pageNumber,
    this.nextCursor,
    required this.results,
  });

  factory PokemonListResponse.fromJson(Map<String, dynamic> json) {
    return PokemonListResponse(
      pageSize: json['page_size'] as int,
      pageNumber: json['page_number'] as int,
      nextCursor: json['next_cursor'] as String?,
      results: (json['results'] as List)
          .map((p) => Pokemon.fromJson(p))
          .toList(),
    );
  }
}
