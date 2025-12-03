import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pokeapi_graphql_service.dart';
import '../database/database_helper.dart';

/// Provider for the PokeAPI GraphQL service
/// This is a singleton that can be injected into notifiers
final pokeApiServiceProvider = Provider<PokeApiGraphQLService>((ref) {
  return PokeApiGraphQLService();
});

/// Provider for the Database helper (for favorites)
/// DatabaseHelper is already a singleton, this just exposes it to Riverpod
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});
