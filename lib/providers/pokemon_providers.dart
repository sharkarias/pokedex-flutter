import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/pokemon_list_notifier.dart';
import '../state/pokemon_state.dart';
import 'api_providers.dart';

/// Main provider for Pokemon list state
/// This is the primary provider that manages all Pokemon list functionality
final pokemonListProvider =
    StateNotifierProvider<PokemonListNotifier, PokemonListState>((ref) {
  final apiService = ref.watch(pokeApiServiceProvider);
  return PokemonListNotifier(apiService);
});

/// Convenience provider for active filters count (computed from main state)
final activeFiltersCountProvider = Provider<int>((ref) {
  final state = ref.watch(pokemonListProvider);
  return state.filters.activeCount;
});

/// Convenience provider for checking if in search/filter mode
final isSearchOrFilterActiveProvider = Provider<bool>((ref) {
  final state = ref.watch(pokemonListProvider);
  return state.isSearchOrFilterActive;
});

/// Convenience provider for the display list (search results or paginated list)
final displayListProvider = Provider<List<dynamic>>((ref) {
  final state = ref.watch(pokemonListProvider);
  return state.displayList;
});

/// Convenience provider for current filters
final filtersProvider = Provider<PokemonFilters>((ref) {
  final state = ref.watch(pokemonListProvider);
  return state.filters;
});

/// Convenience provider for current order
final orderProvider = Provider<PokemonOrder>((ref) {
  final state = ref.watch(pokemonListProvider);
  return state.order;
});

/// Convenience provider for loading states
final isLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(pokemonListProvider);
  return state.isSearching;
});

/// Convenience provider for loading more (pagination)
final isLoadingMoreProvider = Provider<bool>((ref) {
  final state = ref.watch(pokemonListProvider);
  return state.isLoadingMore;
});

/// Convenience provider for error state
final errorProvider = Provider<String?>((ref) {
  final state = ref.watch(pokemonListProvider);
  return state.error;
});
