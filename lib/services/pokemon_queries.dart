/// GraphQL queries for PokeAPI Beta GraphQL API
class PokemonQueries {
  /// Lightweight query to fetch Pokemon list with minimal data (for list view)
  /// Returns only: id, name, types, and sprites
  /// 
  /// Parameters:
  /// - limit: Number of Pokemon to fetch
  /// - offset: Offset for pagination
  static String getPokemonList({int limit = 20, int offset = 0}) {
    return '''
      query GetPokemonList {
        pokemon(limit: $limit, offset: $offset, order_by: {id: asc}) {
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

  /// Detailed query to fetch a single Pokemon with full details
  /// 
  /// Parameters:
  /// - limit: Number of Pokemon to fetch
  /// - offset: Offset for pagination
  static String getPokemonDetails({int limit = 20, int offset = 0}) {
    return '''
      query GetPokemonDetails {
        pokemon(limit: $limit, offset: $offset, order_by: {id: asc}) {
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
          }
          pokemonmoves(
            where: {movelearnmethod: {name: {_eq: "level-up"}}}
            limit: 8
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

  /// Query to fetch type damage relations for calculating weaknesses/resistances
  /// 
  /// Parameters:
  /// - typeName: The name of the type (e.g., "fire", "water")
  static String getTypeDamageRelations(String typeName) {
    return '''
      query GetTypeDamageRelations {
        type(where: {name: {_eq: "$typeName"}}) {
          name
          typeefficaciesbytargettypeid {
            damage_factor
            type {
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
          }
          pokemonmoves(
            where: {movelearnmethod: {name: {_eq: "level-up"}}}
            limit: 8
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
}
