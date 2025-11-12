import 'package:flutter/material.dart';
import 'dart:async';
import '../services/pokeapi_graphql_service.dart';
import '../models/pokemon.dart';
import '../pokemon_card.dart';

class PokemonLiveSearch extends StatefulWidget {
  const PokemonLiveSearch({Key? key}) : super(key: key);

  @override
  State<PokemonLiveSearch> createState() => _PokemonLiveSearchState();
}

class _PokemonLiveSearchState extends State<PokemonLiveSearch> {
  final TextEditingController _searchController = TextEditingController();
  final PokeApiGraphQLService _apiService = PokeApiGraphQLService();
  
  List<Pokemon> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _debounce;

  // Filter state
  String? _selectedType;
  int? _selectedGeneration;
  bool _isLegendary = false;
  bool _isMythical = false;
  int _activeFiltersCount = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
    setState(() {
      _activeFiltersCount = count;
    });
  }

  
  Future<void> _performSearch() async {
    final searchTerm = _searchController.text.trim();
    
    if (searchTerm.isEmpty && _activeFiltersCount == 0) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _apiService.searchPokemonWithFilters(
        searchTerm: searchTerm.isEmpty ? null : searchTerm,
        type: _selectedType,
        generation: _selectedGeneration,
        isLegendary: _isLegendary ? true : null,
        isMythical: _isMythical ? true : null,
      );
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching Pokémon: $e';
        _isLoading = false;
        _searchResults = [];
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Pokémon'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
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
          if (_errorMessage.isNotEmpty)
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
                      _errorMessage,
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
      return _buildEmptyState(
        icon: Icons.search,
        title: 'Search for Pokémon',
        message: 'Type a Pokémon name or use filters to start searching',
      );
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
}