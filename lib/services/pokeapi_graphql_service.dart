import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/pokemon.dart';
import 'pokemon_queries.dart';

class PokeApiGraphQLService {
  static const String _endpoint = 'https://beta.pokeapi.co/graphql/v1beta2';

  late GraphQLClient _client;

  PokeApiGraphQLService() {
    final HttpLink httpLink = HttpLink(_endpoint);

    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
  }

  Future<PokemonListResponse> fetchPokemonList({
    int pageSize = 20,
    int pageNumber = 1,
  }) async {
    final offset = (pageNumber - 1) * pageSize;

    final QueryOptions options = QueryOptions(
      document: gql(PokemonQueries.getPokemonList(
        limit: pageSize,
        offset: offset,
      )),
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception('Failed to load Pokemon list: ${result.exception}');
    }

    final List pokemonData = result.data?['pokemon_v2_pokemon'] ?? [];
    
    final List<Pokemon> pokemonList = [];
    
    for (var data in pokemonData) {
      try {
        final pokemon = await _parsePokemonFromGraphQL(data);
        pokemonList.add(pokemon);
      } catch (e) {
        print('Error parsing Pokemon: ${data['name']}, Error: $e');
      }
    }

    // Get total count for pagination
    final countOptions = QueryOptions(
      document: gql(PokemonQueries.getPokemonCount),
    );
    
    final countResult = await _client.query(countOptions);
    final totalCount = countResult.data?['pokemon_v2_pokemon_aggregate']?['aggregate']?['count'] ?? 0;
    
    final hasNextPage = offset + pageSize < totalCount;
    final nextCursor = hasNextPage ? 'cursor_${offset + pageSize + 1}' : null;

    return PokemonListResponse(
      pageSize: pageSize,
      pageNumber: pageNumber,
      nextCursor: nextCursor,
      results: pokemonList,
    );
  }

  Future<Pokemon> _parsePokemonFromGraphQL(Map<String, dynamic> data) async {
    final id = data['id'] as int;
    final name = _capitalize(data['name'] as String);
    
    // Parse types
    final typesData = data['pokemon_v2_pokemontypes'] as List;
    final types = typesData
        .map((t) => _capitalize(t['pokemon_v2_type']['name'] as String))
        .toList();

    // Parse stats
    final statsData = data['pokemon_v2_pokemonstats'] as List;
    final statsMap = <String, int>{};
    for (var stat in statsData) {
      final statName = stat['pokemon_v2_stat']['name'] as String;
      final baseStat = stat['base_stat'] as int;
      statsMap[statName] = baseStat;
    }

    final baseStats = BaseStats(
      hp: statsMap['hp'] ?? 0,
      attack: statsMap['attack'] ?? 0,
      defense: statsMap['defense'] ?? 0,
      specialAttack: statsMap['special-attack'] ?? 0,
      specialDefense: statsMap['special-defense'] ?? 0,
      speed: statsMap['speed'] ?? 0,
      total: statsMap.values.fold<int>(0, (sum, stat) => sum + stat),
    );

    // Parse abilities
    final abilitiesData = data['pokemon_v2_pokemonabilities'] as List;
    final abilities = abilitiesData.map((abilityData) {
      final ability = abilityData['pokemon_v2_ability'];
      final isHidden = abilityData['is_hidden'] as bool;
      final abilityName = _capitalize(ability['name'] as String);
      
      String shortEffect = '';
      final effectTexts = ability['pokemon_v2_abilityeffecttexts'] as List?;
      if (effectTexts != null && effectTexts.isNotEmpty) {
        shortEffect = effectTexts[0]['short_effect'] as String? ?? '';
        if (shortEffect.length > 140) {
          shortEffect = '${shortEffect.substring(0, 137)}...';
        }
      }

      return PokemonAbility(
        name: abilityName,
        isHidden: isHidden,
        shortEffect: shortEffect,
      );
    }).toList();

    // Parse species data
    final speciesData = data['pokemon_v2_pokemonspecy'];
    final isLegendary = speciesData['is_legendary'] as bool? ?? false;
    final isMythical = speciesData['is_mythical'] as bool? ?? false;
    final captureRate = speciesData['capture_rate'] as int?;

    // Parse generation
    int generation = 1;
    final generationData = speciesData['pokemon_v2_generation'];
    if (generationData != null) {
      final genName = generationData['name'] as String;
      generation = _parseGeneration(genName.replaceAll('generation-', ''));
    }

    // Parse color
    String? color;
    final colorData = speciesData['pokemon_v2_pokemoncolor'];
    if (colorData != null) {
      color = _capitalize(colorData['name'] as String);
    }

    // Parse egg groups
    final eggGroupsData = speciesData['pokemon_v2_pokemonegggroups'] as List;
    final eggGroups = eggGroupsData
        .map((eg) => _capitalize(eg['pokemon_v2_egggroup']['name'] as String))
        .toList();

    // Parse flavor text
    String? flavorText;
    final flavorTextData = speciesData['pokemon_v2_pokemonspeciesflavortexts'] as List;
    if (flavorTextData.isNotEmpty) {
      flavorText = (flavorTextData[0]['flavor_text'] as String)
          .replaceAll('\n', ' ')
          .replaceAll('\f', ' ');
      if (flavorText.length > 200) {
        flavorText = '${flavorText.substring(0, 197)}...';
      }
    }

    // Parse moves
    final movesData = data['pokemon_v2_pokemonmoves'] as List;
    final movesSample = movesData.map((moveData) {
      final moveName = _capitalize(moveData['pokemon_v2_move']['name'] as String);
      final level = moveData['level'] as int? ?? 0;
      final method = moveData['pokemon_v2_movelearnmethod']['name'] as String;

      return PokemonMove(
        name: moveName,
        method: method,
        level: level,
      );
    }).toList();

    // Calculate damage relations
    final damageRelations = await _calculateDamageRelations(types);

    // Generate sprite URLs (PokeAPI still hosts these)
    final spriteUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
    final officialArtworkUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

    return Pokemon(
      nationalDex: id,
      name: name,
      generation: generation,
      types: types,
      spriteUrl: spriteUrl,
      officialArtworkUrl: officialArtworkUrl,
      heightM: (data['height'] as int) / 10.0,
      weightKg: (data['weight'] as int) / 10.0,
      baseStats: baseStats,
      abilities: abilities,
      eggGroups: eggGroups,
      isLegendary: isLegendary,
      isMythical: isMythical,
      forms: ['Normal'],
      evolutionChain: [],
      movesSample: movesSample,
      flavorText: flavorText,
      captureRate: captureRate,
      color: color,
      damageRelations: damageRelations,
      shinyAvailable: true,
      officialSources: {
        'graphql_endpoint': _endpoint,
      },
    );
  }

  Future<Map<String, double>> _calculateDamageRelations(List<String> types) async {
    Map<String, double> damageRelations = {};

    for (var typeName in types) {
      try {
        final QueryOptions options = QueryOptions(
          document: gql(PokemonQueries.getTypeDamageRelations(typeName.toLowerCase())),
        );

        final QueryResult result = await _client.query(options);

        if (!result.hasException && result.data != null) {
          final typeData = result.data?['pokemon_v2_type'] as List?;
          if (typeData != null && typeData.isNotEmpty) {
            final efficacies = typeData[0]['pokemonV2TypeefficaciesByTargetTypeId'] as List;

            for (var efficacy in efficacies) {
              final damageFactor = efficacy['damage_factor'] as int;
              final attackingType = _capitalize(efficacy['pokemon_v2_type']['name'] as String);
              
              // damage_factor is in percentage (e.g., 200 = 2x, 50 = 0.5x, 0 = 0x)
              final multiplier = damageFactor / 100.0;
              
              if (multiplier != 1.0) {
                damageRelations[attackingType] = (damageRelations[attackingType] ?? 1.0) * multiplier;
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching type damage relations: $e');
      }
    }

    damageRelations.removeWhere((key, value) => value == 1.0);

    return damageRelations;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split('-').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  int _parseGeneration(String genString) {
    const romanToInt = {
      'i': 1,
      'ii': 2,
      'iii': 3,
      'iv': 4,
      'v': 5,
      'vi': 6,
      'vii': 7,
      'viii': 8,
      'ix': 9,
    };

    final lowerGen = genString.toLowerCase();

    if (romanToInt.containsKey(lowerGen)) {
      return romanToInt[lowerGen]!;
    }

    try {
      return int.parse(genString);
    } catch (e) {
      print('Could not parse generation: $genString');
      return 1;
    }
  }
}
