import 'package:flutter/material.dart';
import 'dart:async';
import '../services/pokeapi_graphql_service.dart';
import '../pokemon_card.dart';
import '../models/pokemon.dart';
import 'who_is_that_pokemon_screen.dart';
import 'favorites_screen.dart';

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PokeApiGraphQLService _apiService = PokeApiGraphQLService();
  final List<Pokemon> _pokemonList = [];
  List<Pokemon> _searchResults = [];
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 1;
  bool _isLoadingS = false; //for loading based on scrolling
  bool _isLoading = false; //for loading based on search or filters
  bool _hasMore = true;
  String? _error;
  Timer? _debounce;

  // Filter state
  String? _selectedType;
  int? _selectedGeneration;
  bool _isLegendary = false;
  bool _isMythical = false;
  String? _selectedAbility;
  String? _selectedEggGroup;
  int _activeFiltersCount = 0;

  // Order state
  String _orderDirection = 'asc';
  String _orderByField = 'id';

  @override
  void initState() {
    super.initState();
    _loadPokemon();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingS &&
        _hasMore) {
      _loadMorePokemon();
    }
  }

  Future<void> _loadPokemon() async {
    if (_isLoadingS) return;

    setState(() {
      _isLoadingS = true;
      _error = null;
    });

    try {
      final response = await _apiService.fetchPokemonList(
        pageSize: 20,
        pageNumber: 1,
        orderByField: _orderByField,
        orderDirection: _orderDirection,
      );

      setState(() {
        _pokemonList.clear();
        _pokemonList.addAll(response.results);
        _currentPage = 1;
        _hasMore = response.nextCursor != null;
        _isLoadingS = false;
      });
    } catch (e) {
      setState(() {
        _error = 'You are offline. Please check your internet connection.';
        _isLoadingS = false;
      });
    }
  }

  Future<void> _loadMorePokemon() async {
    if (_isLoadingS || !_hasMore) return;

    setState(() {
      _isLoadingS = true;
    });

    try {
      final response = await _apiService.fetchPokemonList(
        pageSize: 20,
        pageNumber: _currentPage + 1,
        orderByField: _orderByField,
        orderDirection: _orderDirection,
      );

      setState(() {
        _pokemonList.addAll(response.results);
        _currentPage++;
        _hasMore = response.nextCursor != null;
        _isLoadingS = false;
      });

      //for debugging 
      //print('Loaded page $_currentPage, total Pokemon: ${_pokemonList.length}');

    } catch (e) {
      setState(() {
        _isLoadingS = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are offline. Cannot load more Pokémon.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

/*every time there's some change in the search bar, it will wait
for 1 second of inactivity before performing the search*/
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(seconds: 1), () {
      _performSearch();
    });
  }

  void _updateActiveFiltersCount() {
    int count = 0;
    if (_selectedType != null) count++;
    if (_selectedGeneration != null) count++;
    if (_isLegendary) count++;
    if (_isMythical) count++;
    if (_selectedAbility != null) count++;
    if (_selectedEggGroup != null) count++;
    setState(() {
      _activeFiltersCount = count;
    });
  }
  
  Future<void> _performSearch() async {
    final searchTerm = _searchController.text.trim();
    
    if (searchTerm.isEmpty && _activeFiltersCount == 0) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _apiService.searchPokemonWithFilters(
        searchTerm: searchTerm.isEmpty ? null : searchTerm,
        type: _selectedType,
        generation: _selectedGeneration,
        isLegendary: _isLegendary ? true : null,
        isMythical: _isMythical ? true : null,
        ability: _selectedAbility,
        eggGroup: _selectedEggGroup,
      );
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search unavailable offline. Please check your internet connection.';
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

void _applyOrdering() {
  setState(() {
    // Determine if search/filter view is active
    final bool isSearchOrFilterActive =
        _searchController.text.trim().isNotEmpty || _activeFiltersCount > 0;

    if (isSearchOrFilterActive) {
      // For searches/filters we already load the full matching set from the server,
      // so client-side sorting is fine.
      _searchResults.sort((a, b) {
        final int cmp;
        switch (_orderByField) {
          case 'name':
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            break;
          case 'id':
          default:
            cmp = (a.nationalDex).compareTo(b.nationalDex);
            break;
        }
        return _orderDirection == 'asc' ? cmp : -cmp;
      });
    } else {
      // For the main paginated list we must request the pages already ordered from
      // the server. Clear the local list and reset pagination so the next load
      // will fetch page 1 with the new order.
      _pokemonList.clear();
      _currentPage = 0;
      _hasMore = true;
    }
  });

  // If not in search/filter mode, trigger a reload (first page) using the
  // updated ordering so the entire dataset will come back in order as the user
  // scrolls.
  if (!(_searchController.text.trim().isNotEmpty || _activeFiltersCount > 0)) {
    _loadPokemon();
  }
}

  void _showOrderDialog() {
  // Local copies for the modal, we only commit on "Apply"
  String tempOrderBy = _orderByField;
  String tempOrderDirection = _orderDirection;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        final bool isDefaultOrder =
            tempOrderBy == 'id' && tempOrderDirection == 'asc';

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title + Reset
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Pokémon',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isDefaultOrder)
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempOrderBy = 'id';
                          tempOrderDirection = 'asc';
                        });
                      },
                      child: const Text('Reset'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Order by',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  // Dropdown: Number / Name / Type
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: tempOrderBy,
                      decoration: InputDecoration(
                        hintText: 'Select field',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'id',
                          child: Text('Number'),
                        ),
                        DropdownMenuItem(
                          value: 'name',
                          child: Text('Name'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          tempOrderBy = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Arrow toggle
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          setModalState(() {
                            tempOrderDirection =
                                tempOrderDirection == 'asc' ? 'desc' : 'asc';
                          });
                        },
                        icon: Icon(
                          tempOrderDirection == 'asc'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Colors.red,
                        ),
                        tooltip: tempOrderDirection == 'asc'
                            ? 'Ascending'
                            : 'Descending',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _orderByField = tempOrderBy;
                      _orderDirection = tempOrderDirection;
                    });
                    Navigator.pop(context);
                    _applyOrdering();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}


  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title with clear filters button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Pokémon',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_activeFiltersCount > 0)
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedType = null;
                            _selectedGeneration = null;
                            _isLegendary = false;
                            _isMythical = false;
                          });
                          setState(() {
                            _selectedType = null;
                            _selectedGeneration = null;
                            _isLegendary = false;
                            _isMythical = false;
                            _selectedEggGroup = null;
                            _selectedAbility = null;
                            _updateActiveFiltersCount();
                          });
                          _performSearch();
                        },
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Type Filter
                const Text(
                  'Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    hintText: 'Select type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Types')),
                    ..._pokemonTypes.map((type) {
                      return DropdownMenuItem(
                        value: type.toLowerCase(),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getTypeColor(type),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(type),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setModalState(() {
                      _selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Generation Filter
                const Text(
                  'Generation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedGeneration,
                  decoration: InputDecoration(
                    hintText: 'Select generation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Generations')),
                    ...List.generate(9, (index) {
                      final gen = index + 1;
                      return DropdownMenuItem(
                        value: gen,
                        child: Text('Generation $gen'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setModalState(() {
                      _selectedGeneration = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Special Filters
                const Text(
                  'Special',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Legendary Only'),
                  value: _isLegendary,
                  onChanged: (value) {
                    setModalState(() {
                      _isLegendary = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.amber,
                ),
                CheckboxListTile(
                  title: const Text('Mythical Only'),
                  value: _isMythical,
                  onChanged: (value) {
                    setModalState(() {
                      _isMythical = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.purple,
                ),
                const SizedBox(height: 16),

                // Ability Filter
                /*const Text(
                  'Ability',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedAbility,
                  decoration: InputDecoration(
                    hintText: 'Select ability',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Abilities')),
                    ..._pokemonAbilities.map((ability) {
                      return DropdownMenuItem(
                        value: ability.toLowerCase(),
                        child: Text(ability),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setModalState(() {
                      _selectedAbility = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
*/
                // Egg Group Filter
                const Text(
                  'Egg Group',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedEggGroup,
                  decoration: InputDecoration(
                    hintText: 'Select egg group',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Egg Groups')),
                    ..._pokemonEggGroups.map((eggGroup) {
                      return DropdownMenuItem(
                        value: eggGroup.toLowerCase(),
                        child: Text(eggGroup),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setModalState(() {
                      _selectedEggGroup = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedType = _selectedType;
                        _selectedGeneration = _selectedGeneration;
                        _isLegendary = _isLegendary;
                        _isMythical = _isMythical;
                        _selectedAbility = _selectedAbility;
                        _selectedEggGroup = _selectedEggGroup;
                        _updateActiveFiltersCount();
                      });
                      Navigator.pop(context);
                      _performSearch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.catching_pokemon,
                  size: 64,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  'Pokedex Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list, color: Colors.red),
            title: const Text(
              'All Pokémon',
              style: TextStyle(fontSize: 16),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text(
              'My Favorites',
              style: TextStyle(fontSize: 16),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.videogame_asset, color: Colors.red),
            title: const Text(
              "Who's That Pokémon?",
              style: TextStyle(fontSize: 16),
            ),
            subtitle: const Text('Trivia Game'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WhoIsThatPokemonScreen(
                    pokedex: _pokemonList,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pokedex!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
           IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPokemon,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Search Bar with Filter Button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Pokémon by name...',
                      prefixIcon: const Icon(Icons.search, color: Colors.red),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Button
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _activeFiltersCount > 0 ? Colors.red : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color: _activeFiltersCount > 0 ? Colors.white : Colors.grey[700],
                        ),
                        onPressed: _showFilterDialog,
                        tooltip: 'Filters',
                      ),
                    ),
                    if (_activeFiltersCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$_activeFiltersCount',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                // ****//
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_alt_outlined,
                          color: Colors.grey[700],
                        ),
                        onPressed: _showOrderDialog,
                        tooltip: 'Order',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Active Filters Chips
          if (_activeFiltersCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedType != null)
                    _buildFilterChip(
                      label: _capitalize(_selectedType!),
                      onDeleted: () {
                        setState(() {
                          _selectedType = null;
                          _updateActiveFiltersCount();
                        });
                        _performSearch();
                      },
                      color: _getTypeColor(_capitalize(_selectedType!)),
                    ),
                  if (_selectedGeneration != null)
                    _buildFilterChip(
                      label: 'Gen $_selectedGeneration',
                      onDeleted: () {
                        setState(() {
                          _selectedGeneration = null;
                          _updateActiveFiltersCount();
                        });
                        _performSearch();
                      },
                      color: Colors.blue,
                    ),
                  if (_isLegendary)
                    _buildFilterChip(
                      label: 'Legendary',
                      onDeleted: () {
                        setState(() {
                          _isLegendary = false;
                          _updateActiveFiltersCount();
                        });
                        _performSearch();
                      },
                      color: Colors.amber,
                    ),
                  if (_isMythical)
                    _buildFilterChip(
                      label: 'Mythical',
                      onDeleted: () {
                        setState(() {
                          _isMythical = false;
                          _updateActiveFiltersCount();
                        });
                        _performSearch();
                      },
                      color: Colors.purple,
                    ),
                ],
              ),
            ),

          // Loading Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Searching Pokémon...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          // Error Message
          if (_error?.isNotEmpty ?? false)
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Search Results
          Expanded(
            child: _buildResultsContent(),
          ),
        ],
      ),
    );
  }

  // Where the actual visuals of the list screen are built
  Widget _buildBody() {
    if (_error != null && _pokemonList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'You are offline',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPokemon,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_pokemonList.isEmpty && _isLoadingS) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Pokemon...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPokemon,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _pokemonList.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _pokemonList.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return PokemonCard(pokemon: _pokemonList[index]);
        },
      ),
    );
  }


  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
    required Color color,
  }) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
      onDeleted: onDeleted,
    );
  }

  Widget _buildResultsContent() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_searchController.text.isEmpty && _activeFiltersCount == 0) {
      return _buildBody();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sentiment_dissatisfied,
        title: 'No Pokémon found',
        message: 'Try adjusting your search or filters',
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, index) {
        final pokemon = _searchResults[index];
        return PokemonCard(pokemon: pokemon);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    final typeColors = {
      'Normal': const Color(0xFFA8A878),
      'Fire': const Color(0xFFF08030),
      'Water': const Color(0xFF6890F0),
      'Electric': const Color(0xFFF8D030),
      'Grass': const Color(0xFF78C850),
      'Ice': const Color(0xFF98D8D8),
      'Fighting': const Color(0xFFC03028),
      'Poison': const Color(0xFFA040A0),
      'Ground': const Color(0xFFE0C068),
      'Flying': const Color(0xFFA890F0),
      'Psychic': const Color(0xFFF85888),
      'Bug': const Color(0xFFA8B820),
      'Rock': const Color(0xFFB8A038),
      'Ghost': const Color(0xFF705898),
      'Dragon': const Color(0xFF7038F8),
      'Dark': const Color(0xFF705848),
      'Steel': const Color(0xFFB8B8D0),
      'Fairy': const Color(0xFFEE99AC),
    };
    return typeColors[type] ?? Colors.grey;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static const List<String> _pokemonTypes = [
    'Normal', 'Fire', 'Water', 'Electric', 'Grass', 'Ice',
    'Fighting', 'Poison', 'Ground', 'Flying', 'Psychic', 'Bug',
    'Rock', 'Ghost', 'Dragon', 'Dark', 'Steel', 'Fairy'
  ];

  // daba warning de no usarse  (i did writed forgot about english)
  // static const List<String> _pokemonAbilities = [
  //   'Adaptability', 'Aftermath', 'Air Lock', 'Analytic', 'Anger Point',
  //   'Anticipation', 'Arena Trap', 'Aroma Veil', 'Aura Break', 'Bad Dreams',
  //   'Battle Armor', 'Battle Bond', 'Beast Boost', 'Berserk', 'Big Pecks',
  //   'Blaze', 'Bleeds', 'Blind Eye', 'Bountiful Harvest', 'Brick Break',
  //   'Bright Aura', 'Bulletproof', 'Burnt Out', 'Cacophony', 'Cakewalk',
  //   'Calm Mind', 'Camaraderie', 'Camouflage', 'Cataclysm', 'Cell Battery',
  //   'Cement Armor', 'Chain Reaction', 'Chainsmoker', 'Chameleon', 'Champ',
  //   'Change', 'Chaos', 'Charge', 'Charmed', 'Charisma', 'Charm',
  //   'Cheap Shot', 'Check Mate', 'Chlorophyll', 'Choice Band', 'Chomp',
  //   'Chosen One', 'Circuit Trail', 'Cleanliness', 'Clear Body', 'Clear Smog',
  //   'Clerical', 'Clever', 'Cloud Nine', 'Cloudy Day', 'Coating',
  //   'Coast Guard', 'Coat Change', 'Cobweb', 'Cocoon', 'Code of Chivalry',
  //   'Coercion', 'Cold Front', 'Color Change', 'Colorless', 'Combat Instinct',
  //   'Comfort', 'Comfortable', 'Comforting Aura', 'Command Card', 'Commander',
  //   'Commando', 'Commercial', 'Commitment', 'Committed', 'Common',
  //   'Communion', 'Community', 'Como', 'Compact', 'Company',
  //   'Companion', 'Comparator', 'Compare', 'Compassion', 'Compatible',
  //   'Compete', 'Competence', 'Competent', 'Competing', 'Competitive',
  //   'Competitor', 'Compilation', 'Compile', 'Compiler', 'Compiling',
  //   'Complacence', 'Complacent', 'Complain', 'Complaining', 'Complaint',
  //   'Complaisant', 'Complaisance', 'Complement', 'Complementary', 'Complete',
  //   'Completed', 'Completely', 'Completeness', 'Completing', 'Completion',
  //   'Complex', 'Complexion', 'Complexity', 'Compliance', 'Compliant',
  //   'Complicate', 'Complicated', 'Complication', 'Complicity', 'Complied',
  //   'Compliment', 'Complimentary', 'Compline', 'Comply', 'Complying',
  //   'Compo', 'Component', 'Comport', 'Comportment', 'Compose',
  //   'Composed', 'Composedly', 'Composedness', 'Composer', 'Composing',
  //   'Composite', 'Composition', 'Compositor', 'Compost', 'Composure',
  //   'Compote', 'Compound', 'Compounded', 'Compoundable', 'Compounding',
  //   'Compounds', 'Comprador', 'Compradore', 'Comprecar', 'Compreco',
  //   'Comprend', 'Comprehend', 'Comprehendable', 'Comprehended', 'Comprehending',
  //   'Comprehensible', 'Comprehension', 'Comprehensive', 'Comprehensively', 'Comprehensiveness',
  //   'Compresses', 'Compressibility', 'Compressible', 'Compressing', 'Compression',
  //   'Compressive', 'Compressor', 'Comprise', 'Comprised', 'Comprising',
  //   'Comprises', 'Compromise', 'COMPROMISED', 'COMPROMISING', 'COMPTROLLER'
  // ];

  static const List<String> _pokemonEggGroups = [
    'Monster', 'Water 1', 'Bug', 'Flying', 'Field', 'Fairy',
    'Grass', 'Human-Like', 'Water 3', 'Mineral', 'Amorphous',
    'Water 2', 'Ditto', 'Undiscovered'
  ];

}
