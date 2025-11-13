import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_graphql_service.dart';

class PokemonDetailsScreen extends StatefulWidget {
  final int pokemonId;
  final String pokemonName;

  const PokemonDetailsScreen({
    super.key,
    required this.pokemonId,
    required this.pokemonName,
  });

  @override
  State<PokemonDetailsScreen> createState() => _PokemonDetailsScreenState();
}

class _PokemonDetailsScreenState extends State<PokemonDetailsScreen>
    with SingleTickerProviderStateMixin {
  final PokeApiGraphQLService _apiService = PokeApiGraphQLService();
  
  // Maximum stat value for bar charts and radar (rn it is hardcoded, can be dynamic)
  final double maxStatValue = 255.0;
  
  Pokemon? _pokemon;
  bool _isLoading = true;
  String? _error;
  bool _isFavorite = false;
  bool _showShiny = false;
  String _selectedMoveFilter = 'level-up';

  /*tabController controls the tabs where you can see different informations
  from a specific pokemon, such as stats, moves, evolution, etc */
  late TabController _tabController; 
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPokemonDetails();
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPokemonDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pokemon = await _apiService.fetchPokemonById(widget.pokemonId);
      setState(() {
        _pokemon = pokemon;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Pokemon details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    setState(() {
      _isFavorite = favorites.contains(widget.pokemonId.toString());
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    
    setState(() {
      if (_isFavorite) {
        favorites.remove(widget.pokemonId.toString());
        _isFavorite = false;
      } else {
        favorites.add(widget.pokemonId.toString());
        _isFavorite = true;
      }
    });
    
    await prefs.setStringList('favorites', favorites);
  }

  void _sharePokemon() {
    if (_pokemon != null) {
      Share.share(
        'Check out ${_pokemon!.name} (#${_pokemon!.nationalDex})!\n'
        'Types: ${_pokemon!.types.join(", ")}\n'
        'Total Base Stats: ${_pokemon!.baseStats.total}',
        subject: _pokemon!.name,
      );
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'grass':
        return Colors.green;
      case 'poison':
        return Colors.purple;
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'electric':
        return Colors.yellow;
      case 'normal':
        return Colors.grey;
      case 'fighting':
        return Colors.orange;
      case 'flying':
        return Colors.lightBlue;
      case 'ground':
        return Colors.brown;
      case 'rock':
        return Colors.grey[600]!;
      case 'bug':
        return Colors.lightGreen;
      case 'ghost':
        return Colors.deepPurple;
      case 'steel':
        return Colors.blueGrey;
      case 'psychic':
        return Colors.pink;
      case 'ice':
        return Colors.cyan;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.brown[800]!;
      case 'fairy':
        return Colors.pinkAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPokemonDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pokemon == null) {
      return const Center(child: Text('No Pokemon data'));
    }

    final pokemon = _pokemon!;
    final primaryColor = _getTypeColor(pokemon.types.first);

    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                pokemon.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 1.0,
                      color: Colors.black,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryColor.withOpacity(0.7),
                          primaryColor,
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Hero(
                      tag: 'pokemon_${pokemon.nationalDex}',
                      child: Image.network(
                        _showShiny
                            ? (pokemon.shinyOfficialArtworkUrl ??
                                pokemon.officialArtworkUrl!)
                            : pokemon.officialArtworkUrl!,
                        height: 250,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            _showShiny
                                ? (pokemon.shinySpriteeUrl ?? pokemon.spriteUrl!)
                                : pokemon.spriteUrl!,
                            height: 250,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (pokemon.shinyAvailable)
                IconButton(
                  icon: Icon(_showShiny ? Icons.star : Icons.star_border),
                  tooltip: 'Toggle Shiny',
                  onPressed: () {
                    setState(() {
                      _showShiny = !_showShiny;
                    });
                  },
                ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(_isFavorite),
                  ),
                ),
                onPressed: _toggleFavorite,
                tooltip: 'Favorite',
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _sharePokemon,
                tooltip: 'Share',
              ),
            ],
          ),

          // Pokemon Info Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#${pokemon.nationalDex.toString().padLeft(3, '0')}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (pokemon.isLegendary)
                        const Icon(Icons.star, color: Colors.amber, size: 24),
                      if (pokemon.isMythical)
                        const Icon(Icons.auto_awesome,
                            color: Colors.purple, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: pokemon.types.map((type) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(type),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (pokemon.flavorText != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      pokemon.flavorText!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn('Height', '${pokemon.heightM ?? 0} m'),
                      _buildInfoColumn('Weight', '${pokemon.weightKg ?? 0} kg'),
                      _buildInfoColumn('Generation', '${pokemon.generation}'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: primaryColor,
                tabs: const [
                  Tab(text: 'Stats'),
                  Tab(text: 'Abilities'),
                  Tab(text: 'Evolution'),
                  Tab(text: 'Moves'),
                  Tab(text: 'Matchups'),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(pokemon),
          _buildAbilitiesTab(pokemon),
          _buildEvolutionTab(pokemon),
          _buildMovesTab(pokemon),
          _buildMatchupsTab(pokemon),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab(Pokemon pokemon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Base Stats',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatBar('HP', pokemon.baseStats.hp),
          _buildStatBar('Attack', pokemon.baseStats.attack),
          _buildStatBar('Defense', pokemon.baseStats.defense),
          _buildStatBar('Sp. Atk', pokemon.baseStats.specialAttack),
          _buildStatBar('Sp. Def', pokemon.baseStats.specialDefense),
          _buildStatBar('Speed', pokemon.baseStats.speed),
          const Divider(height: 32),
          _buildStatBar('Total', pokemon.baseStats.total, isTotal: true),
          const SizedBox(height: 32),
          const Text(
            'Stats Radar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  radarBackgroundColor: Colors.transparent,
                  radarBorderData: BorderSide(
                    color: _getTypeColor(pokemon.types.first).withOpacity(0.3),
                    width: 2,
                  ),
                  gridBorderData: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                  tickCount: 6,
                  ticksTextStyle: TextStyle(
                    fontSize: 0,
                    color: Colors.blue[600],
                  ),
                  tickBorderData: const BorderSide(color: Colors.transparent),
                  getTitle: (index, angle) {
                    switch (index) {
                      case 0:
                        return RadarChartTitle(
                          text: 'HP\n${pokemon.baseStats.hp}',
                          angle: angle,
                        );
                      case 1:
                        return RadarChartTitle(
                          text: 'Attack\n${pokemon.baseStats.attack}',
                          angle: 0,
                        );
                      case 2:
                        return RadarChartTitle(
                          text: 'Defense\n${pokemon.baseStats.defense}',
                          angle: 0,
                        );
                      case 3:
                        return RadarChartTitle(
                          text: 'Sp.Atk\n${pokemon.baseStats.specialAttack}',
                          angle: 0,
                        );
                      case 4:
                        return RadarChartTitle(
                          text: 'Sp.Def\n${pokemon.baseStats.specialDefense}',
                          angle: 0,
                        );
                      case 5:
                        return RadarChartTitle(
                          text: 'Speed\n${pokemon.baseStats.speed}',
                          angle: 0,
                        );
                      default:
                        return const RadarChartTitle(text: '');
                    }
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: _getTypeColor(pokemon.types.first).withOpacity(0.2),
                      borderColor: _getTypeColor(pokemon.types.first),
                      borderWidth: 3,
                      entryRadius: 4,
                      dataEntries: [
                        RadarEntry(value: (pokemon.baseStats.hp / maxStatValue) * 100),
                        RadarEntry(value: (pokemon.baseStats.attack / maxStatValue) * 100),
                        RadarEntry(value: (pokemon.baseStats.defense / maxStatValue) * 100),
                        RadarEntry(value: (pokemon.baseStats.specialAttack / maxStatValue) * 100),
                        RadarEntry(value: (pokemon.baseStats.specialDefense / maxStatValue) * 100),
                        RadarEntry(value: (pokemon.baseStats.speed / maxStatValue) * 100),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (pokemon.eggGroups.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Egg Groups',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: pokemon.eggGroups.map((group) {
                return Chip(
                  label: Text(group),
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, {bool isTotal = false}) {
    final maxValue = isTotal ? 720 : maxStatValue;
    final percentage = (value / maxValue * 100).clamp(0.0, 100.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                '$value (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: isTotal ? Colors.blue : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isTotal ? Colors.blue : Colors.green,
            ),
            minHeight: isTotal ? 12 : 8,
          ),
        ],
      ),
    );
  }

  Widget _buildAbilitiesTab(Pokemon pokemon) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Abilities',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...pokemon.abilities.map((ability) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ability.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (ability.isHidden) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Hidden',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ability.shortEffect,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEvolutionTab(Pokemon pokemon) {
    if (pokemon.evolutionChain.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No evolutions',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This Pokemon does not evolve',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Evolution Chain',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Column(
            children: pokemon.evolutionChain.asMap().entries.map((entry) {
              final index = entry.key;
              final stage = entry.value;
              final isLast = index == pokemon.evolutionChain.length - 1;
              final isCurrentPokemon = stage.name.toLowerCase() == pokemon.name.toLowerCase();

              return Column(
                children: [
                  // Evolution stage node - clickable
                  InkWell(
                    onTap: () {
                      // Navigate to this Pokemon's details
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PokemonDetailsScreen(
                            pokemonId: stage.id,
                            pokemonName: stage.name,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: isCurrentPokemon
                            ? LinearGradient(
                                colors: [
                                  _getTypeColor(pokemon.types.first).withOpacity(0.2),
                                  _getTypeColor(pokemon.types.first).withOpacity(0.1),
                                ],
                              )
                            : null,
                        border: Border.all(
                          color: isCurrentPokemon
                              ? _getTypeColor(pokemon.types.first)
                              : Colors.grey[300]!,
                          width: isCurrentPokemon ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                        children: [
                          // Pokemon sprite
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCurrentPokemon
                                        ? _getTypeColor(pokemon.types.first)
                                        : Colors.grey[300]!,
                                    width: isCurrentPokemon ? 3 : 2,
                                  ),
                                  boxShadow: isCurrentPokemon ? [
                                    BoxShadow(
                                      color: _getTypeColor(pokemon.types.first).withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ] : null,
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${stage.id}.png',
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.catching_pokemon,
                                        size: 50,
                                        color: Colors.grey[400],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (isCurrentPokemon)
                                Positioned(
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(pokemon.types.first),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            stage.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isCurrentPokemon
                                  ? _getTypeColor(pokemon.types.first)
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stage ${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          // Show previous evolution info
                          if (stage.evolvesFromId != null) ...[
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                // Find the Pokemon this one evolved from
                                final evolvedFrom = pokemon.evolutionChain.firstWhere(
                                  (e) => e.id == stage.evolvesFromId,
                                  orElse: () => pokemon.evolutionChain[index > 0 ? index - 1 : 0],
                                );
                                return Text(
                                  'From: ${evolvedFrom.name}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ),
                  
                  // Evolution arrow and trigger
                  if (!isLast) ...[
                    const SizedBox(height: 8),
                    // Vertical connecting line
                    Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey[400]!,
                            Colors.grey[300]!,
                          ],
                        ),
                      ),
                    ),
                    // Arrow and trigger
                    Column(
                      children: [
                        Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.grey[600],
                          size: 32,
                        ),
                        if (pokemon.evolutionChain[index + 1].trigger != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue[200]!,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getEvolutionIcon(pokemon.evolutionChain[index + 1].trigger!.trigger),
                                  size: 18,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  pokemon.evolutionChain[index + 1].trigger!.getDisplayText(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Vertical connecting line
                    Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey[300]!,
                            Colors.grey[400]!,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getEvolutionIcon(String trigger) {
    switch (trigger.toLowerCase()) {
      case 'level-up':
        return Icons.trending_up;
      case 'use-item':
        return Icons.category;
      case 'trade':
        return Icons.swap_horiz;
      case 'other':
        return Icons.star;
      default:
        return Icons.arrow_forward;
    }
  }

  Widget _buildMovesTab(Pokemon pokemon) {
    final filteredMoves = pokemon.movesSample
        .where((move) => move.method == _selectedMoveFilter)
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Move Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Level Up', 'level-up'),
                    //_buildFilterChip('TM/HM', 'machine'),
                    //_buildFilterChip('Tutor', 'tutor'),
                    //_buildFilterChip('Egg', 'egg'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredMoves.isEmpty
              ? Center(
                  child: Text(
                    'No moves found for $_selectedMoveFilter',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredMoves.length,
                  itemBuilder: (context, index) {
                    final move = filteredMoves[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: move.level != null && move.level! > 0
                            ? CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  '${move.level}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(
                                  Icons.question_mark,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                        title: Text(
                          move.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          move.method.replaceAll('-', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedMoveFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedMoveFilter = value;
          });
        },
        selectedColor: _getTypeColor(_pokemon!.types.first).withOpacity(0.3),
        checkmarkColor: _getTypeColor(_pokemon!.types.first),
      ),
    );
  }

  Widget _buildMatchupsTab(Pokemon pokemon) {
    final weaknesses = <String, double>{};
    final resistances = <String, double>{};
    final immunities = <String>[];

    pokemon.damageRelations.forEach((type, multiplier) {
      if (multiplier == 0) {
        immunities.add(type);
      } else if (multiplier > 1.0) {
        weaknesses[type] = multiplier;
      } else if (multiplier < 1.0) {
        resistances[type] = multiplier;
      }
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (weaknesses.isNotEmpty) ...[
          const Text(
            'Weaknesses',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weaknesses.entries.map((entry) {
              return _buildTypeChip(
                entry.key,
                'x${entry.value}',
                Colors.red[100]!,
                Colors.red[800]!,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (resistances.isNotEmpty) ...[
          const Text(
            'Resistances',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resistances.entries.map((entry) {
              return _buildTypeChip(
                entry.key,
                'x${entry.value}',
                Colors.green[100]!,
                Colors.green[800]!,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (immunities.isNotEmpty) ...[
          const Text(
            'Immunities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: immunities.map((type) {
              return _buildTypeChip(
                type,
                'x0',
                Colors.grey[300]!,
                Colors.grey[800]!,
              );
            }).toList(),
          ),
        ],
        if (weaknesses.isEmpty && resistances.isEmpty && immunities.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No special type matchups',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeChip(
      String type, String multiplier, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTypeColor(type),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            multiplier,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
