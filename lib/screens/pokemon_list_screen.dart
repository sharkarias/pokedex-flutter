import 'package:flutter/material.dart';
import '../services/pokeapi_graphql_service.dart';
import '../pokemon_card.dart';
import '../models/pokemon.dart';
import '../services/pokemon_live_search.dart';

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final PokeApiGraphQLService _apiService = PokeApiGraphQLService();
  final List<Pokemon> _pokemonList = [];
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPokemon();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore) {
      _loadMorePokemon();
    }
  }

  Future<void> _loadPokemon() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.fetchPokemonList(
        pageSize: 20,
        pageNumber: 1,
      );

      setState(() {
        _pokemonList.clear();
        _pokemonList.addAll(response.results);
        _currentPage = 1;
        _hasMore = response.nextCursor != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Pokemon: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePokemon() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.fetchPokemonList(
        pageSize: 20,
        pageNumber: _currentPage + 1,
      );

      setState(() {
        _pokemonList.addAll(response.results);
        _currentPage++;
        _hasMore = response.nextCursor != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more Pokemon: $e')),
        );
      }
    }
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
            icon: const Icon(Icons.search),
            tooltip: 'Search Pokémon',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PokemonLiveSearch(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null && _pokemonList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPokemon,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pokemonList.isEmpty && _isLoading) {
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
}
