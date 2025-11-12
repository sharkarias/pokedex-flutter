import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/pokemon.dart';
import 'pokemon_queries.dart';

class PokeApiGraphQLService {
  static const String _endpoint = 'https://graphql.pokeapi.co/v1beta2';

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
    String orderList = 'asc',
  }) async {
    final offset = (pageNumber - 1) * pageSize;

    final QueryOptions options = QueryOptions(
      document: gql(PokemonQueries.getPokemonList(
        limit: pageSize,
        offset: offset,
        orderList: orderList,
      )),
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception('Failed to load Pokemon list: ${result.exception}');
    }

    final List pokemonData = result.data?['pokemon'] ?? [];
    
    final List<Pokemon> pokemonList = [];
    
    for (var data in pokemonData) {
      try {
        // Only include default forms (is_default: true)
        final isDefault = data['is_default'] as bool? ?? true;
        if (isDefault) {
          final pokemon = _parsePokemonBasicFromGraphQL(data);
          pokemonList.add(pokemon);
        }
      } catch (e) {
        print('Error parsing Pokemon: ${data['name']}, Error: $e');
      }
    }

    // Get total count for pagination
    final countOptions = QueryOptions(
      document: gql(PokemonQueries.getPokemonCount),
    );
    
    final countResult = await _client.query(countOptions);
    final totalCount = countResult.data?['pokemon_aggregate']?['aggregate']?['count'] ?? 0;
    
    final hasNextPage = offset + pageSize < totalCount;
    final nextCursor = hasNextPage ? 'cursor_${offset + pageSize + 1}' : null;

    return PokemonListResponse(
      pageSize: pageSize,
      pageNumber: pageNumber,
      nextCursor: nextCursor,
      results: pokemonList,
    );
  }

  /// Fetch detailed information for a single Pokemon by ID
  Future<Pokemon> fetchPokemonById(int id) async {
    final QueryOptions options = QueryOptions(
      document: gql(PokemonQueries.getPokemonById(id)),
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      throw Exception('Failed to load Pokemon details: ${result.exception}');
    }

    final List pokemonData = result.data?['pokemon'] ?? [];
    
    if (pokemonData.isEmpty) {
      throw Exception('Pokemon with ID $id not found');
    }

    return await _parsePokemonFromGraphQL(pokemonData[0]);
  }

  /// Lightweight parser for list view - only parses: id, name, types, and sprite
  Pokemon _parsePokemonBasicFromGraphQL(Map<String, dynamic> data) {
    final id = data['id'] as int;
    final name = _capitalize(data['name'] as String);
    
    // Parse types
    final typesData = data['pokemontypes'] as List;
    final types = typesData
        .map((t) => _capitalize(t['type']['name'] as String))
        .toList();

    // Generate sprite URLs
    final spriteUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
    final officialArtworkUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

    // Generate shiny sprite URLs
    final shinySpriteeUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$id.png';
    final shinyOfficialArtworkUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/$id.png';

    // Return Pokemon with minimal data (defaults for unused fields)
    return Pokemon(
      nationalDex: id,
      name: name,
      generation: 1, // Default, not needed for list view
      types: types,
      spriteUrl: spriteUrl,
      shinySpriteeUrl: shinySpriteeUrl,
      officialArtworkUrl: officialArtworkUrl,
      shinyOfficialArtworkUrl: shinyOfficialArtworkUrl,
      heightM: null,
      weightKg: null,
      baseStats: BaseStats(
        hp: 0,
        attack: 0,
        defense: 0,
        specialAttack: 0,
        specialDefense: 0,
        speed: 0,
        total: 0,
      ),
      abilities: [],
      eggGroups: [],
      isLegendary: false,
      isMythical: false,
      forms: [],
      evolutionChain: [],
      movesSample: [],
      flavorText: null,
      captureRate: null,
      color: null,
      damageRelations: {},
      shinyAvailable: true,
      officialSources: {
        'graphql_endpoint': _endpoint,
      },
    );
  }

  /// Detailed parser for individual Pokemon view - parses all fields
  Future<Pokemon> _parsePokemonFromGraphQL(Map<String, dynamic> data) async {
    final id = data['id'] as int;
    final name = _capitalize(data['name'] as String);
    
    // Parse types
    final typesData = data['pokemontypes'] as List;
    final types = typesData
        .map((t) => _capitalize(t['type']['name'] as String))
        .toList();

    // Parse stats
    final statsData = data['pokemonstats'] as List;
    final statsMap = <String, int>{};
    for (var stat in statsData) {
      final statName = stat['stat']['name'] as String;
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
    final abilitiesData = data['pokemonabilities'] as List;
    final abilities = abilitiesData.map((abilityData) {
      final ability = abilityData['ability'];
      final isHidden = abilityData['is_hidden'] as bool;
      final abilityName = _capitalize(ability['name'] as String);
      
      String shortEffect = '';
      final effectTexts = ability['abilityeffecttexts'] as List?;
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
    final speciesData = data['pokemonspecy'];
    final isLegendary = speciesData['is_legendary'] as bool? ?? false;
    final isMythical = speciesData['is_mythical'] as bool? ?? false;
    final captureRate = speciesData['capture_rate'] as int?;

    // Parse generation
    int generation = 1;
    final generationData = speciesData['generation'];
    if (generationData != null) {
      final genName = generationData['name'] as String;
      generation = _parseGeneration(genName.replaceAll('generation-', ''));
    }

    // Parse color
    String? color;
    final colorData = speciesData['pokemoncolor'];
    if (colorData != null) {
      color = _capitalize(colorData['name'] as String);
    }

    // Parse egg groups
    final eggGroupsData = speciesData['pokemonegggroups'] as List;
    final eggGroups = eggGroupsData
        .map((eg) => _capitalize(eg['egggroup']['name'] as String))
        .toList();

    // Parse flavor text
    String? flavorText;
    final flavorTextData = speciesData['pokemonspeciesflavortexts'] as List;
    if (flavorTextData.isNotEmpty) {
      flavorText = (flavorTextData[0]['flavor_text'] as String)
          .replaceAll('\n', ' ')
          .replaceAll('\f', ' ');
      if (flavorText.length > 200) {
        flavorText = '${flavorText.substring(0, 197)}...';
      }
    }

    // Parse moves
    final movesData = data['pokemonmoves'] as List;
    final movesSample = movesData.map((moveData) {
      final moveName = _capitalize(moveData['move']['name'] as String);
      final level = moveData['level'] as int? ?? 0;
      final method = moveData['movelearnmethod']['name'] as String;

      return PokemonMove(
        name: moveName,
        method: method,
        level: level,
      );
    }).toList();

    // Parse evolution chain
    List<EvolutionStage> evolutionChain = [];
    try {
      if (speciesData['evolutionchain'] != null) {
        final evolutionChainData = speciesData['evolutionchain'];
        final speciesList = evolutionChainData['pokemonspecies'] as List?;
        
        print('Evolution chain data found: ${speciesList?.length ?? 0} species');
        
        if (speciesList != null && speciesList.isNotEmpty) {
          // Sort by order to ensure proper evolution sequence
          final sortedSpecies = List<Map<String, dynamic>>.from(speciesList);
          sortedSpecies.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
          
          for (var speciesInfo in sortedSpecies) {
            final speciesId = speciesInfo['id'] as int;
            final speciesName = _capitalize(speciesInfo['name'] as String);
            final evolvesFromId = speciesInfo['evolves_from_species_id'] as int?;
            
            // Get Pokemon ID from the default Pokemon
            int? pokemonId;
            final pokemonsList = speciesInfo['pokemons'] as List?;
            if (pokemonsList != null && pokemonsList.isNotEmpty) {
              pokemonId = pokemonsList[0]['id'] as int?;
            }
            
            // Parse evolution trigger if this Pokemon evolves from another
            EvolutionTrigger? trigger;
            if (evolvesFromId != null) {
              final evolutionsData = speciesInfo['pokemonevolutions'] as List?;
              if (evolutionsData != null && evolutionsData.isNotEmpty) {
                final evoData = evolutionsData[0];
                
                final triggerName = evoData['evolutiontrigger']?['name'] as String? ?? 'level-up';
                final minLevel = evoData['min_level'] as int?;
                final minHappiness = evoData['min_happiness'] as int?;
                final timeOfDay = evoData['time_of_day'] as String?;
                final itemName = evoData['item']?['name'] as String?;
                final locationName = evoData['location']?['name'] as String?;
                
                trigger = EvolutionTrigger(
                  trigger: triggerName,
                  minLevel: minLevel,
                  item: itemName != null ? _capitalize(itemName) : null,
                  minHappiness: minHappiness,
                  timeOfDay: timeOfDay,
                  location: locationName != null ? _capitalize(locationName) : null,
                );
              }
            }
            
            evolutionChain.add(EvolutionStage(
              name: speciesName,
              id: pokemonId ?? speciesId,
              trigger: trigger,
            ));
            
            print('Added to chain: $speciesName (ID: ${pokemonId ?? speciesId})${trigger != null ? ' with trigger' : ''}');
          }
          
          print('Total evolution chain length: ${evolutionChain.length}');
        }
      }
    } catch (e) {
      print('Error parsing evolution chain: $e');
      // Continue without evolution data rather than failing completely
    }

    // Calculate damage relations
    final damageRelations = await _calculateDamageRelations(types);

    // Generate sprite URLs (PokeAPI still hosts these)
    final spriteUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
    final shinySpriteeUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$id.png';
    final officialArtworkUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
    final shinyOfficialArtworkUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/$id.png';

    return Pokemon(
      nationalDex: id,
      name: name,
      generation: generation,
      types: types,
      spriteUrl: spriteUrl,
      shinySpriteeUrl: shinySpriteeUrl,
      officialArtworkUrl: officialArtworkUrl,
      shinyOfficialArtworkUrl: shinyOfficialArtworkUrl,
      heightM: (data['height'] as int) / 10.0,
      weightKg: (data['weight'] as int) / 10.0,
      baseStats: baseStats,
      abilities: abilities,
      eggGroups: eggGroups,
      isLegendary: isLegendary,
      isMythical: isMythical,
      forms: [],
      evolutionChain: evolutionChain,
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
          final typeData = result.data?['type'] as List?;
          if (typeData != null && typeData.isNotEmpty) {
            final efficacies = typeData[0]['typeefficaciesbytargettypeid'] as List;

            for (var efficacy in efficacies) {
              final damageFactor = efficacy['damage_factor'] as int;
              final attackingType = _capitalize(efficacy['type']['name'] as String);
              
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


/// Search Pokemon by name (partial match)
Future<List<Pokemon>> searchPokemonByName(String searchTerm) async {
  final QueryOptions options = QueryOptions(
    document: gql(PokemonQueries.searchPokemonByName(searchTerm.toLowerCase())),
  );

  final QueryResult result = await _client.query(options);

  if (result.hasException) {
    throw Exception('Failed to search Pokemon: ${result.exception}');
  }

  final List pokemonData = result.data?['pokemon'] ?? [];
  
  final List<Pokemon> pokemonList = [];
  
  for (var data in pokemonData) {
    try {
      final pokemon = _parsePokemonBasicFromGraphQL(data);
      pokemonList.add(pokemon);
    } catch (e) {
      print('Error parsing Pokemon: ${data['name']}, Error: $e');
    }
  }

  return pokemonList;
}


/// Search Pokemon with multiple filters
Future<List<Pokemon>> searchPokemonWithFilters({
  String? searchTerm,
  String? type,
  int? generation,
  bool? isLegendary,
  bool? isMythical,
}) async {
  final QueryOptions options = QueryOptions(
    document: gql(PokemonQueries.searchPokemonWithFilters(
      searchTerm: searchTerm,
      type: type,
      generation: generation,
      isLegendary: isLegendary,
      isMythical: isMythical,
    )),
  );

  final QueryResult result = await _client.query(options);

  if (result.hasException) {
    throw Exception('Failed to search Pokemon: ${result.exception}');
  }

  final List pokemonData = result.data?['pokemon'] ?? [];
  
  final List<Pokemon> pokemonList = [];
  
  // For live search / list views we should keep results lightweight.
  // Parse basic info only (no extra per-item GraphQL queries) to avoid many network calls and long waits.
  for (var data in pokemonData) {
    try {
      final pokemon = _parsePokemonBasicFromGraphQL(data);
      pokemonList.add(pokemon);
    } catch (e) {
      print('Error parsing Pokemon: ${data['name']}, Error: $e');
    }
  }

  return pokemonList;
}

}
