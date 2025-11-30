/// GraphQL queries for PokeAPI Beta GraphQL API
class PokemonQueries {
  /// Lightweight query to fetch Pokemon list with minimal data (for list view)
  /// Returns only: id, name, types, and sprites
  /// 
  /// Parameters:
  /// - limit: Number of Pokemon to fetch
  /// - offset: Offset for pagination
  /// - orderList: 'asc' or 'desc' for ordering the list
  static String getPokemonList({
    int limit = 20,
    int offset = 0,
    String orderByField = 'id',
    String orderDirection = 'asc',
  }) {
    // Build the order_by clause dynamically. Expecting callers to pass a valid field
    // name (e.g. 'id' or 'name') and direction ('asc' or 'desc').
    return '''
      query GetPokemonList {
        pokemon(limit: $limit, offset: $offset, order_by: {$orderByField: $orderDirection}, where: {is_default: {_eq: true}}) {
          id
          name
          pokemontypes {
            type {
              name
            }
          }
          is_default
        }
      }
    ''';
  }

  /// Query to fetch type damage relations for calculating weaknesses/resistances
  /// 
  /// Parameters:
  /// - typeName: The name of the type (e.g., "fire", "water")
  static String getTypeDamageRelations(String typeName) {
    return '''
      query GetTypeDamageRelations {
        type(where: {name: {_eq: "$typeName"}}) {
          name
          typeefficacies {
            damage_factor
            TypeByTargetTypeId {
              name
            }
          }
          TypeefficaciesByTargetTypeId {
            damage_factor
            TypeByTargetTypeId {
              name
            }
          }
        }
      }
    ''';
  }

  /// Query to fetch a single Pokemon by ID with full details
  /// 
  /// Parameters:
  /// - id: Pokemon national dex number
  static String getPokemonById(int id) {
    return '''
      query GetPokemonById {
        pokemon(where: {id: {_eq: $id}}) {
          id
          name
          height
          weight
          pokemontypes {
            type {
              name
            }
          }
          pokemonabilities {
            is_hidden
            ability {
              name
              abilityeffecttexts(where: {language_id: {_eq: 9}}, limit: 1) {
                short_effect
              }
            }
          }
          pokemonstats {
            base_stat
            stat {
              name
            }
          }
          pokemonspecy {
            id
            is_legendary
            is_mythical
            capture_rate
            generation {
              name
            }
            pokemoncolor {
              name
            }
            pokemonegggroups {
              egggroup {
                name
              }
            }
            pokemonspeciesflavortexts(
              where: {language_id: {_eq: 9}}
              limit: 1
            ) {
              flavor_text
            }
            evolutionchain {
              id
              pokemonspecies(order_by: {order: asc}) {
                id
                name
                order
                evolves_from_species_id
                pokemonevolutions {
                  min_level
                  min_happiness
                  min_beauty
                  min_affection
                  time_of_day
                  needs_overworld_rain
                  turn_upside_down
                  evolutiontrigger {
                    name
                  }
                  item {
                    name
                  }
                  location {
                    name
                  }
                }
                pokemons(where: {is_default: {_eq: true}}, limit: 1) {
                  id
                  name
                }
              }
            }
          }
          pokemonmoves(
            where: {movelearnmethod: {name: {_eq: "level-up"}}}
            limit: 20
            order_by: {level: asc}
          ) {
            level
            move {
              name
            }
            movelearnmethod {
              name
            }
          }
        }
      }
    ''';
  }

  /// Query to get total count of Pokemon for pagination
  static const String getPokemonCount = '''
    query GetPokemonCount {
      pokemon_aggregate {
        aggregate {
          count
        }
      }
    }
  ''';

  /// Query to search Pokemon by name
  /// 
  /// Parameters:
  /// - searchTerm: Partial name to search for
  static String searchPokemonByName(String searchTerm) {
    return '''
      query SearchPokemonByName {
        pokemon(where: {name: {_ilike: "%$searchTerm%"}}, limit: 20) {
          id
          name
          pokemontypes {
            type {
              name
            }
          }
        }
      }
    ''';
  }

/// Query to search Pokemon with multiple filters
/// 
/// Parameters:
/// - searchTerm: Partial name to search for (optional)
/// - type: Pokemon type filter (optional)
/// - generation: Generation number filter (optional)
/// - isLegendary: Filter for legendary Pokemon (optional)
/// - isMythical: Filter for mythical Pokemon (optional)
/// - ability: Ability filter (optional)
/// - eggGroup: Egg group filter (optional)
static String searchPokemonWithFilters({
  String? searchTerm,
  String? type,
  int? generation,
  bool? isLegendary,
  bool? isMythical,
  String? ability,
  String? eggGroup,
}) {
  List<String> conditions = [];
  
  if (searchTerm != null && searchTerm.isNotEmpty) {
    conditions.add('name: {_ilike: "%$searchTerm%"}');
  }
  
  if (type != null) {
    conditions.add('pokemontypes: {some: {type: {name: {_eq: "$type"}}}}');
  }
  
  if (generation != null) {
    final genRoman = _getGenerationRoman(generation);
    conditions.add('pokemonspecy: {generation: {name: {_eq: "generation-$genRoman"}}}');
  }
  
  if (isLegendary == true) {
    conditions.add('pokemonspecy: {is_legendary: {_eq: true}}');
  }
  
  if (isMythical == true) {
    conditions.add('pokemonspecy: {is_mythical: {_eq: true}}');
  }
  
  if (ability != null) {
    conditions.add('pokemonabilities: {some: {ability: {name: {_eq: "$ability"}}}}');
  }
  
  if (eggGroup != null) {
    conditions.add('pokemonspecy: {pokemonegggroups: {egggroup: {name: {_eq: "$eggGroup"}}}}');
  }
  
  final whereClause = conditions.isEmpty ? '' : 'where: {${conditions.join(', ')}},';
  
  return '''
    query SearchPokemonWithFilters {
      pokemon($whereClause limit: 50, order_by: {id: asc}) {
        id
        name
        pokemontypes {
          type {
            name
          }
        }
        is_default
      }
    }
  ''';
}

// Helper method for generation conversion
static String _getGenerationRoman(int generation) {
  const romanNumerals = {
    1: 'i',
    2: 'ii',
    3: 'iii',
    4: 'iv',
    5: 'v',
    6: 'vi',
    7: 'vii',
    8: 'viii',
    9: 'ix',
  };
  return romanNumerals[generation] ?? 'i';
}

}
