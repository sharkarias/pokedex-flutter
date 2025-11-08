/// GraphQL queries for PokeAPI Beta GraphQL API
class PokemonQueries {
  /// Query to fetch a list of Pokemon with details
  /// 
  /// Parameters:
  /// - limit: Number of Pokemon to fetch
  /// - offset: Offset for pagination
  static String getPokemonList({int limit = 20, int offset = 0}) {
    return '''
      query GetPokemonList {
        pokemon_v2_pokemon(limit: $limit, offset: $offset, order_by: {id: asc}) {
          id
          name
          height
          weight
          pokemon_v2_pokemontypes {
            pokemon_v2_type {
              name
            }
          }
          pokemon_v2_pokemonabilities {
            is_hidden
            pokemon_v2_ability {
              name
              pokemon_v2_abilityeffecttexts(where: {language_id: {_eq: 9}}, limit: 1) {
                short_effect
              }
            }
          }
          pokemon_v2_pokemonstats {
            base_stat
            pokemon_v2_stat {
              name
            }
          }
          pokemon_v2_pokemonspecy {
            is_legendary
            is_mythical
            capture_rate
            pokemon_v2_generation {
              name
            }
            pokemon_v2_pokemoncolor {
              name
            }
            pokemon_v2_pokemonegggroups {
              pokemon_v2_egggroup {
                name
              }
            }
            pokemon_v2_pokemonspeciesflavortexts(
              where: {language_id: {_eq: 9}}
              limit: 1
            ) {
              flavor_text
            }
          }
          pokemon_v2_pokemonmoves(
            where: {pokemon_v2_movelearnmethod: {name: {_eq: "level-up"}}}
            limit: 8
            order_by: {level: asc}
          ) {
            level
            pokemon_v2_move {
              name
            }
            pokemon_v2_movelearnmethod {
              name
            }
          }
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
        pokemon_v2_type(where: {name: {_eq: "$typeName"}}) {
          name
          pokemonV2TypeefficaciesByTargetTypeId {
            damage_factor
            pokemon_v2_type {
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
        pokemon_v2_pokemon(where: {id: {_eq: $id}}) {
          id
          name
          height
          weight
          pokemon_v2_pokemontypes {
            pokemon_v2_type {
              name
            }
          }
          pokemon_v2_pokemonabilities {
            is_hidden
            pokemon_v2_ability {
              name
              pokemon_v2_abilityeffecttexts(where: {language_id: {_eq: 9}}, limit: 1) {
                short_effect
              }
            }
          }
          pokemon_v2_pokemonstats {
            base_stat
            pokemon_v2_stat {
              name
            }
          }
          pokemon_v2_pokemonspecy {
            is_legendary
            is_mythical
            capture_rate
            pokemon_v2_generation {
              name
            }
            pokemon_v2_pokemoncolor {
              name
            }
            pokemon_v2_pokemonegggroups {
              pokemon_v2_egggroup {
                name
              }
            }
            pokemon_v2_pokemonspeciesflavortexts(
              where: {language_id: {_eq: 9}}
              limit: 1
            ) {
              flavor_text
            }
          }
          pokemon_v2_pokemonmoves(
            where: {pokemon_v2_movelearnmethod: {name: {_eq: "level-up"}}}
            limit: 8
            order_by: {level: asc}
          ) {
            level
            pokemon_v2_move {
              name
            }
            pokemon_v2_movelearnmethod {
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
      pokemon_v2_pokemon_aggregate {
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
        pokemon_v2_pokemon(where: {name: {_ilike: "%$searchTerm%"}}, limit: 20) {
          id
          name
          pokemon_v2_pokemontypes {
            pokemon_v2_type {
              name
            }
          }
        }
      }
    ''';
  }
}
