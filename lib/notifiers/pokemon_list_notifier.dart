import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_graphql_service.dart';
import '../state/pokemon_state.dart';

/// StateNotifier for managing the Pokemon list state
/// Handles pagination, search, filters, and ordering
class PokemonListNotifier extends StateNotifier<PokemonListState> {
  final PokeApiGraphQLService _apiService;
  Timer? _debounceTimer;

  PokemonListNotifier(this._apiService) : super(const PokemonListState()) {
    // Load initial Pokemon list on creation
    loadPokemon();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Loads the first page of Pokemon (resets pagination)
  Future<void> loadPokemon() async {
    if (state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final response = await _apiService.fetchPokemonList(
        pageSize: 20,
        pageNumber: 1,
        orderByField: state.order.field,
        orderDirection: state.order.direction,
      );

      state = state.copyWith(
        pokemonList: response.results,
        currentPage: 1,
        hasMore: response.nextCursor != null,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'You are offline. Please check your internet connection.',
        isLoadingMore: false,
      );
    }
  }

  /// Loads the next page of Pokemon (appends to list)
  Future<void> loadMorePokemon() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _apiService.fetchPokemonList(
        pageSize: 20,
        pageNumber: state.currentPage + 1,
        orderByField: state.order.field,
        orderDirection: state.order.direction,
      );

      state = state.copyWith(
        pokemonList: [...state.pokemonList, ...response.results],
        currentPage: state.currentPage + 1,
        hasMore: response.nextCursor != null,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'You are offline. Cannot load more Pokémon.',
      );
    }
  }

  /// Updates the search term with debouncing
  void updateSearchTerm(String term) {
    state = state.copyWith(searchTerm: term);
    _debounceSearch();
  }

  /// Debounces search - waits 1 second of inactivity before performing search
  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      performSearch();
    });
  }

  /// Performs the search with current search term and filters
  Future<void> performSearch() async {
    final searchTerm = state.searchTerm.trim();

    // If no search term and no filters, clear search results
    if (searchTerm.isEmpty && !state.filters.hasActiveFilters) {
      state = state.copyWith(searchResults: [], clearError: true);
      return;
    }

    state = state.copyWith(isSearching: true, clearError: true);

    try {
      final results = await _apiService.searchPokemonWithFilters(
        searchTerm: searchTerm.isEmpty ? null : searchTerm,
        type: state.filters.type,
        generation: state.filters.generation,
        isLegendary: state.filters.isLegendary ? true : null,
        isMythical: state.filters.isMythical ? true : null,
        ability: state.filters.ability,
        eggGroup: state.filters.eggGroup,
      );

      // Apply client-side sorting to search results
      final sortedResults = _sortResults(results);

      state = state.copyWith(
        searchResults: sortedResults,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Search unavailable offline. Please check your internet connection.',
        isSearching: false,
        searchResults: [],
      );
    }
  }

  /// Sorts results based on current order settings
  List<Pokemon> _sortResults(List<Pokemon> results) {
    final sorted = List<Pokemon>.from(results);
    sorted.sort((a, b) {
      final int cmp;
      switch (state.order.field) {
        case 'name':
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'id':
        default:
          cmp = a.nationalDex.compareTo(b.nationalDex);
          break;
      }
      return state.order.direction == 'asc' ? cmp : -cmp;
    });
    return sorted;
  }

  /// Updates filter settings and triggers search
  void updateFilters(PokemonFilters filters) {
    state = state.copyWith(filters: filters);
    performSearch();
  }

  /// Clears a specific filter
  void clearFilter(String filterType) {
    PokemonFilters newFilters;
    switch (filterType) {
      case 'type':
        newFilters = state.filters.copyWith(clearType: true);
        break;
      case 'generation':
        newFilters = state.filters.copyWith(clearGeneration: true);
        break;
      case 'legendary':
        newFilters = state.filters.copyWith(isLegendary: false);
        break;
      case 'mythical':
        newFilters = state.filters.copyWith(isMythical: false);
        break;
      case 'ability':
        newFilters = state.filters.copyWith(clearAbility: true);
        break;
      case 'eggGroup':
        newFilters = state.filters.copyWith(clearEggGroup: true);
        break;
      default:
        return;
    }
    updateFilters(newFilters);
  }

  /// Resets all filters
  void resetFilters() {
    updateFilters(const PokemonFilters());
  }

  /// Updates order settings
  void updateOrder(PokemonOrder order) {
    state = state.copyWith(order: order);
    applyOrdering();
  }

  /// Applies ordering - for search results sorts client-side,
  /// for paginated list reloads from server
  void applyOrdering() {
    if (state.isSearchOrFilterActive) {
      // Sort search results client-side
      state = state.copyWith(searchResults: _sortResults(state.searchResults));
    } else {
      // Clear list and reload from server with new order
      state = state.copyWith(
        pokemonList: [],
        currentPage: 0,
        hasMore: true,
      );
      loadPokemon();
    }
  }

  /// Clears the search term
  void clearSearch() {
    state = state.copyWith(searchTerm: '');
    performSearch();
  }

  /// Clears any error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
