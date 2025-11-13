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
  final String? type;
  final String? damageClass;
  final int? power;
  final int? accuracy;
  final int? pp;

  PokemonMove({
    required this.name,
    required this.method,
    this.level,
    this.type,
    this.damageClass,
    this.power,
    this.accuracy,
    this.pp,
  });

  factory PokemonMove.fromJson(Map<String, dynamic> json) {
    return PokemonMove(
      name: json['name'] as String,
      method: json['method'] as String,
      level: json['level'] as int?,
      type: json['type'] as String?,
      damageClass: json['damage_class'] as String?,
      power: json['power'] as int?,
      accuracy: json['accuracy'] as int?,
      pp: json['pp'] as int?,
    );
  }
}

class EvolutionTrigger {
  final String trigger;
  final int? minLevel;
  final String? item;
  final String? heldItem;
  final int? minHappiness;
  final String? timeOfDay;
  final String? location;

  EvolutionTrigger({
    required this.trigger,
    this.minLevel,
    this.item,
    this.heldItem,
    this.minHappiness,
    this.timeOfDay,
    this.location,
  });

  factory EvolutionTrigger.fromJson(Map<String, dynamic> json) {
    return EvolutionTrigger(
      trigger: json['trigger'] as String,
      minLevel: json['min_level'] as int?,
      item: json['item'] as String?,
      heldItem: json['held_item'] as String?,
      minHappiness: json['min_happiness'] as int?,
      timeOfDay: json['time_of_day'] as String?,
      location: json['location'] as String?,
    );
  }

  String getDisplayText() {
    switch (trigger) {
      case 'level-up':
        if (minLevel != null) return 'Level $minLevel';
        if (minHappiness != null) return 'Friendship $minHappiness';
        if (timeOfDay != null) return 'Level up ($timeOfDay)';
        return 'Level up';
      case 'use-item':
        return item ?? 'Use item';
      case 'trade':
        if (heldItem != null) return 'Trade (holding $heldItem)';
        return 'Trade';
      case 'other':
        return 'Special';
      default:
        return trigger;
    }
  }
}

class EvolutionStage {
  final String name;
  final int id;
  final EvolutionTrigger? trigger;
  final int? evolvesFromId;

  EvolutionStage({
    required this.name,
    required this.id,
    this.trigger,
    this.evolvesFromId,
  });

  factory EvolutionStage.fromJson(Map<String, dynamic> json) {
    return EvolutionStage(
      name: json['name'] as String,
      id: json['id'] as int,
      trigger: json['trigger'] != null 
          ? EvolutionTrigger.fromJson(json['trigger'] as Map<String, dynamic>)
          : null,
      evolvesFromId: json['evolves_from_id'] as int?,
    );
  }
}

class PokemonForm {
  final String name;
  final String formName;
  final List<String> types;
  final String? spriteUrl;

  PokemonForm({
    required this.name,
    required this.formName,
    required this.types,
    this.spriteUrl,
  });

  factory PokemonForm.fromJson(Map<String, dynamic> json) {
    return PokemonForm(
      name: json['name'] as String,
      formName: json['form_name'] as String,
      types: List<String>.from(json['types']),
      spriteUrl: json['sprite_url'] as String?,
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
  final String? shinySpriteeUrl;
  final String? officialArtworkUrl;
  final String? shinyOfficialArtworkUrl;
  final double? heightM;
  final double? weightKg;
  final BaseStats baseStats;
  final List<PokemonAbility> abilities;
  final List<String> eggGroups;
  final bool isLegendary;
  final bool isMythical;
  final List<PokemonForm> forms;
  final List<EvolutionStage> evolutionChain;
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
    this.shinySpriteeUrl,
    this.officialArtworkUrl,
    this.shinyOfficialArtworkUrl,
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
      shinySpriteeUrl: json['shiny_sprite_url'] as String?,
      officialArtworkUrl: json['official_artwork_url'] as String?,
      shinyOfficialArtworkUrl: json['shiny_official_artwork_url'] as String?,
      heightM: json['height_m'] != null ? (json['height_m'] as num).toDouble() : null,
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      baseStats: BaseStats.fromJson(json['base_stats']),
      abilities: (json['abilities'] as List)
          .map((a) => PokemonAbility.fromJson(a))
          .toList(),
      eggGroups: List<String>.from(json['egg_groups']),
      isLegendary: json['is_legendary'] as bool,
      isMythical: json['is_mythical'] as bool,
      forms: (json['forms'] as List)
          .map((f) => f is String ? PokemonForm(name: f, formName: 'Normal', types: [], spriteUrl: null) : PokemonForm.fromJson(f))
          .toList(),
      evolutionChain: (json['evolution_chain'] as List)
          .map((e) => e is List ? EvolutionStage(name: e[0] as String, id: 0) : EvolutionStage.fromJson(e))
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
