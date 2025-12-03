import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pokemon.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pokedex.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    
    if (kIsWeb) {
      // For web
      path = filePath;
    } else {
      // For Mobile/Desktop uses file system
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorite_pokemon (
        id INTEGER PRIMARY KEY,
        national_dex INTEGER NOT NULL,
        name TEXT NOT NULL,
        generation INTEGER NOT NULL,
        types TEXT NOT NULL,
        sprite_url TEXT,
        shiny_sprite_url TEXT,
        official_artwork_url TEXT,
        shiny_official_artwork_url TEXT,
        height_m REAL,
        weight_kg REAL,
        base_stats TEXT NOT NULL,
        abilities TEXT NOT NULL,
        egg_groups TEXT NOT NULL,
        is_legendary INTEGER NOT NULL,
        is_mythical INTEGER NOT NULL,
        forms TEXT NOT NULL,
        evolution_chain TEXT NOT NULL,
        moves_sample TEXT NOT NULL,
        flavor_text TEXT,
        capture_rate INTEGER,
        color TEXT,
        damage_relations TEXT NOT NULL,
        offensive_damage_relations TEXT NOT NULL,
        shiny_available INTEGER NOT NULL,
        official_sources TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
  }

  // Save a favorite Pokemon to the database
  Future<void> saveFavoritePokemon(Pokemon pokemon) async {
    if (kIsWeb) return; // Skip database operations on web
    
    final db = await database;
    
    final data = {
      'national_dex': pokemon.nationalDex,
      'name': pokemon.name,
      'generation': pokemon.generation,
      'types': jsonEncode(pokemon.types),
      'sprite_url': pokemon.spriteUrl,
      'shiny_sprite_url': pokemon.shinySpriteeUrl,
      'official_artwork_url': pokemon.officialArtworkUrl,
      'shiny_official_artwork_url': pokemon.shinyOfficialArtworkUrl,
      'height_m': pokemon.heightM,
      'weight_kg': pokemon.weightKg,
      'base_stats': jsonEncode(pokemon.baseStats.toJson()),
      'abilities': jsonEncode(pokemon.abilities.map((a) => a.toJson()).toList()),
      'egg_groups': jsonEncode(pokemon.eggGroups),
      'is_legendary': pokemon.isLegendary ? 1 : 0,
      'is_mythical': pokemon.isMythical ? 1 : 0,
      'forms': jsonEncode(pokemon.forms.map((f) => f.toJson()).toList()),
      'evolution_chain': jsonEncode(pokemon.evolutionChain.map((e) => e.toJson()).toList()),
      'moves_sample': jsonEncode(pokemon.movesSample.map((m) => m.toJson()).toList()),
      'flavor_text': pokemon.flavorText,
      'capture_rate': pokemon.captureRate,
      'color': pokemon.color,
      'damage_relations': jsonEncode(pokemon.damageRelations),
      'offensive_damage_relations': jsonEncode(pokemon.offensiveDamageRelations),
      'shiny_available': pokemon.shinyAvailable ? 1 : 0,
      'official_sources': jsonEncode(pokemon.officialSources),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };

    await db.insert(
      'favorite_pokemon',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get a favorite Pokemon by national dex number
  Future<Pokemon?> getFavoritePokemon(int nationalDex) async {
    if (kIsWeb) return null; // Skip database operations on web
    
    final db = await database;
    
    final results = await db.query(
      'favorite_pokemon',
      where: 'national_dex = ?',
      whereArgs: [nationalDex],
    );

    if (results.isEmpty) return null;

    return _pokemonFromMap(results.first);
  }

  // Get all favorite Pokemon
  Future<List<Pokemon>> getAllFavoritePokemon() async {
    if (kIsWeb) return []; // Skip database operations on web
    
    final db = await database;
    
    final results = await db.query(
      'favorite_pokemon',
      orderBy: 'national_dex ASC',
    );

    return results.map((map) => _pokemonFromMap(map)).toList();
  }

  // Delete a favorite Pokemon
  Future<void> deleteFavoritePokemon(int nationalDex) async {
    if (kIsWeb) return; // Skip database operations on web
    
    final db = await database;
    
    await db.delete(
      'favorite_pokemon',
      where: 'national_dex = ?',
      whereArgs: [nationalDex],
    );
  }

  // Check if a Pokemon is favorited
  Future<bool> isFavorite(int nationalDex) async {
    if (kIsWeb) return false; // Skip database operations on web
    
    final db = await database;
    
    final results = await db.query(
      'favorite_pokemon',
      where: 'national_dex = ?',
      whereArgs: [nationalDex],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  // Convert database data to Pokemon object
  Pokemon _pokemonFromMap(Map<String, dynamic> map) {
    return Pokemon(
      nationalDex: map['national_dex'] as int,
      name: map['name'] as String,
      generation: map['generation'] as int,
      types: List<String>.from(jsonDecode(map['types'] as String)),
      spriteUrl: map['sprite_url'] as String?,
      shinySpriteeUrl: map['shiny_sprite_url'] as String?,
      officialArtworkUrl: map['official_artwork_url'] as String?,
      shinyOfficialArtworkUrl: map['shiny_official_artwork_url'] as String?,
      heightM: map['height_m'] as double?,
      weightKg: map['weight_kg'] as double?,
      baseStats: BaseStats.fromJson(jsonDecode(map['base_stats'] as String)),
      abilities: (jsonDecode(map['abilities'] as String) as List)
          .map((a) => PokemonAbility.fromJson(a))
          .toList(),
      eggGroups: List<String>.from(jsonDecode(map['egg_groups'] as String)),
      isLegendary: map['is_legendary'] == 1,
      isMythical: map['is_mythical'] == 1,
      forms: (jsonDecode(map['forms'] as String) as List)
          .map((f) => PokemonForm.fromJson(f))
          .toList(),
      evolutionChain: (jsonDecode(map['evolution_chain'] as String) as List)
          .map((e) => EvolutionStage.fromJson(e))
          .toList(),
      movesSample: (jsonDecode(map['moves_sample'] as String) as List)
          .map((m) => PokemonMove.fromJson(m))
          .toList(),
      flavorText: map['flavor_text'] as String?,
      captureRate: map['capture_rate'] as int?,
      color: map['color'] as String?,
      damageRelations: (jsonDecode(map['damage_relations'] as String) as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      offensiveDamageRelations: (jsonDecode(map['offensive_damage_relations'] as String) as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      shinyAvailable: map['shiny_available'] == 1,
      officialSources: Map<String, String>.from(jsonDecode(map['official_sources'] as String)),
    );
  }

  
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
