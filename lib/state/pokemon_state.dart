import 'package:equatable/equatable.dart';
import '../models/pokemon.dart';

/// Represents the filter criteria for searching Pokemon
class PokemonFilters extends Equatable {
  final String? type;
  final int? generation;
  final bool isLegendary;
  final bool isMythical;
  final String? ability;
  final String? eggGroup;

  const PokemonFilters({
    this.type,
    this.generation,
    this.isLegendary = false,
    this.isMythical = false,
    this.ability,
    this.eggGroup,
  });

  /// Returns the count of active filters
  int get activeCount {
    int count = 0;
    if (type != null) count++;
    if (generation != null) count++;
    if (isLegendary) count++;
    if (isMythical) count++;
    if (ability != null) count++;
    if (eggGroup != null) count++;
    return count;
  }

  /// Whether any filters are active
  bool get hasActiveFilters => activeCount > 0;

  /// Creates a copy with updated values
  PokemonFilters copyWith({
    String? type,
    int? generation,
    bool? isLegendary,
    bool? isMythical,
    String? ability,
    String? eggGroup,
    bool clearType = false,
    bool clearGeneration = false,
    bool clearAbility = false,
    bool clearEggGroup = false,
  }) {
    return PokemonFilters(
      type: clearType ? null : (type ?? this.type),
      generation: clearGeneration ? null : (generation ?? this.generation),
      isLegendary: isLegendary ?? this.isLegendary,
      isMythical: isMythical ?? this.isMythical,
      ability: clearAbility ? null : (ability ?? this.ability),
      eggGroup: clearEggGroup ? null : (eggGroup ?? this.eggGroup),
    );
  }

  /// Resets all filters to default values
  PokemonFilters reset() {
    return const PokemonFilters();
  }

  @override
  List<Object?> get props => [
        type,
        generation,
        isLegendary,
        isMythical,
        ability,
        eggGroup,
      ];
}

/// Represents the ordering/sorting preferences for Pokemon list
class PokemonOrder extends Equatable {
  final String field; // 'id' or 'name'
  final String direction; // 'asc' or 'desc'

  const PokemonOrder({
    this.field = 'id',
    this.direction = 'asc',
  });

  /// Whether this is the default order (id ascending)
  bool get isDefault => field == 'id' && direction == 'asc';

  /// Creates a copy with updated values
  PokemonOrder copyWith({
    String? field,
    String? direction,
  }) {
    return PokemonOrder(
      field: field ?? this.field,
      direction: direction ?? this.direction,
    );
  }

  /// Resets to default order
  PokemonOrder reset() {
    return const PokemonOrder();
  }

  @override
  List<Object?> get props => [field, direction];
}

/// Represents the complete state for the Pokemon list screen
class PokemonListState extends Equatable {
  /// Main paginated list of Pokemon (browse mode)
  final List<Pokemon> pokemonList;

  /// Search/filter results
  final List<Pokemon> searchResults;

  /// Current search term
  final String searchTerm;

  /// Current page number for pagination
  final int currentPage;

  /// Whether more pages are available
  final bool hasMore;

  /// Loading state for scroll-based pagination
  final bool isLoadingMore;

  /// Loading state for search/filters
  final bool isSearching;

  /// Error message (if any)
  final String? error;

  /// Current filter settings
  final PokemonFilters filters;

  /// Current order/sort settings
  final PokemonOrder order;

  const PokemonListState({
    this.pokemonList = const [],
    this.searchResults = const [],
    this.searchTerm = '',
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.error,
    this.filters = const PokemonFilters(),
    this.order = const PokemonOrder(),
  });

  /// Whether we're in search/filter mode (not browse mode)
  bool get isSearchOrFilterActive =>
      searchTerm.isNotEmpty || filters.hasActiveFilters;

  /// The list to display (search results or paginated list)
  List<Pokemon> get displayList =>
      isSearchOrFilterActive ? searchResults : pokemonList;

  /// Creates a copy with updated values
  PokemonListState copyWith({
    List<Pokemon>? pokemonList,
    List<Pokemon>? searchResults,
    String? searchTerm,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isSearching,
    String? error,
    PokemonFilters? filters,
    PokemonOrder? order,
    bool clearError = false,
  }) {
    return PokemonListState(
      pokemonList: pokemonList ?? this.pokemonList,
      searchResults: searchResults ?? this.searchResults,
      searchTerm: searchTerm ?? this.searchTerm,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearching: isSearching ?? this.isSearching,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [
        pokemonList,
        searchResults,
        searchTerm,
        currentPage,
        hasMore,
        isLoadingMore,
        isSearching,
        error,
        filters,
        order,
      ];
}
