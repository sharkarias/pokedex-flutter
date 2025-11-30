import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pokemon.dart';
import '../services/pokeapi_graphql_service.dart';

class WhoIsThatPokemonScreen extends StatefulWidget {
  /// Pass your full pokedex list here (for example _pokemonList from your list screen).
  final List<Pokemon> pokedex;

  const WhoIsThatPokemonScreen({
    super.key,
    required this.pokedex,
  });

  @override
  State<WhoIsThatPokemonScreen> createState() =>
      _WhoIsThatPokemonScreenState();
}

class _WhoIsThatPokemonScreenState extends State<WhoIsThatPokemonScreen> {
  final Random _random = Random();
  final TextEditingController _guessController = TextEditingController();
  final PokeApiGraphQLService _apiService = PokeApiGraphQLService();

  Pokemon? _currentPokemon;
  bool _isRevealed = false;
  bool _roundActive = false;
  bool _isLoadingPokemon = false;

  int _timeLeft = 20;
  Timer? _timer;

  int _score = 0;
  int _bestScore = 0;
  List<int> _topScores = [];
  List<Pokemon> _allPokemon = [];

  String _feedback = '';

  @override
  void initState() {
    super.initState();
    _loadRanking();
    _loadAllPokemon();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _guessController.dispose();
    super.dispose();
  }

  Future<void> _loadRanking() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final best = prefs.getInt('wtp_best_score') ?? 0;
    final topScoresStrings = prefs.getStringList('wtp_top_scores') ?? [];
    final topScores = topScoresStrings.map(int.parse).toList()..sort((a, b) => b.compareTo(a));

    setState(() {
      _bestScore = best;
      _topScores = topScores;
    });
  }

  Future<void> _loadAllPokemon() async {
    try {
      setState(() {
        _isLoadingPokemon = true;
      });

      final response = await _apiService.fetchPokemonList(
        pageSize: 1302, // Fetch all Pokémon (total count in PokeAPI)
        pageNumber: 1,
        orderByField: 'id',
        orderDirection: 'asc',
      );

      if (mounted) {
        setState(() {
          _allPokemon = response.results;
          _isLoadingPokemon = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPokemon = false;
        });
        _showErrorDialog('Failed to load Pokémon: $e');
      }
    }
  }

  Future<void> _updateRankingWithScore(int runScore) async {
  if (runScore <= 0) return;

  final prefs = await SharedPreferences.getInstance();

  // Update best score
  int best = prefs.getInt('wtp_best_score') ?? 0;
  if (runScore > best) {
    best = runScore;
    await prefs.setInt('wtp_best_score', best);
  }

  // Update top scores list
  final topScoresStrings = prefs.getStringList('wtp_top_scores') ?? [];
  final topScores = topScoresStrings.map(int.parse).toList();
  topScores.add(runScore);
  topScores.sort((a, b) => b.compareTo(a));
  final trimmed = topScores.length > 5 ? topScores.sublist(0, 5) : topScores;

  await prefs.setStringList(
    'wtp_top_scores',
    trimmed.map((e) => e.toString()).toList(),
  );

  if (!mounted) return;
  setState(() {
    _bestScore = best;
    _topScores = trimmed;
  });
}


  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      try {
        setState(fn);
      } catch (e) {
        print('Error in setState: $e');
      }
    }
  }

  void _startNewRound() {
    try {
      if (!mounted) return;
      
      // Use loaded API Pokémon, or fallback to passed pokedex
      final pokemonList = _allPokemon.isNotEmpty ? _allPokemon : widget.pokedex;
      
      if (pokemonList.isEmpty) {
        _safeSetState(() {
          _feedback = 'No Pokémon available for the game.';
        });
        return;
      }

      _timer?.cancel();

      final randomIndex = _random.nextInt(pokemonList.length);
      final pokemon = pokemonList[randomIndex];

      _safeSetState(() {
        _currentPokemon = pokemon;
        _isRevealed = false;
        _roundActive = true;
        _timeLeft = 20;
        _feedback = '';
        _guessController.clear();
      });

      _startTimer();
    } catch (e, stackTrace) {
      print('Error in _startNewRound: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft <= 1) {
        timer.cancel();
        _onTimeUp();
      } else {
        _safeSetState(() {
          _timeLeft--;
        });
      }
    });
  }

  void _onTimeUp() {
    try {
      if (!_roundActive || !mounted) return;

      final endedScore = _score;
      final pokemonName = _currentPokemon?.name ?? '???';

      _safeSetState(() {
        _roundActive = false;
        _isRevealed = true;
        _feedback = "Time's up! It was $pokemonName";
        _timeLeft = 0;
      });

      // Save this run's score to ranking, then reset for next round
      try {
        _updateRankingWithScore(endedScore);
        
        _safeSetState(() {
          _score = 0;  // Reset score for next round after saving
        });
      } catch (e, stackTrace) {
        print('Error saving score on time up: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          _showErrorDialog('Error saving score on time up: $e');
          _safeSetState(() {
            _score = 0;  // Reset score anyway even if save failed
          });
        }
      }
    } catch (e, stackTrace) {
      print('Error in _onTimeUp: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showErrorDialog('Error in time up handler: $e');
      }
    }
  }

 
  void _submitGuess() {
    try {
      if (!_roundActive || _currentPokemon == null) return;

      final guess = _guessController.text.trim().toLowerCase();
      if (guess.isEmpty) return;

      final correctName = _currentPokemon!.name.trim().toLowerCase();

      if (guess == correctName) {
        // Correct!
        final points = 10 + _timeLeft; // base + bonus for remaining time
        _safeSetState(() {
          _score += points;
          _roundActive = false;
          _isRevealed = true;
          _feedback = 'Correct! +$points points. It was ${_currentPokemon!.name}.';
        });

        _timer?.cancel();
        
        try {
          _updateRankingWithScore(_score);
        } catch (e) {
          if (mounted) {
            _showErrorDialog('Error saving score on correct guess: $e');
          }
        }
      } else {
        // Wrong but round continues
        _safeSetState(() {
          _feedback = 'Not quite! Try again...';
        });
      }
    } catch (e, stackTrace) {
      print('Error in _submitGuess: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showErrorDialog('Error processing guess: $e');
      }
    }
  }

  void _resetGame() {
    try {
      _timer?.cancel();

      // Only save score if a round is active (game in progress)
      if (_roundActive) {
        try {
          final endedScore = _score;
          _updateRankingWithScore(endedScore);
        } catch (e, stackTrace) {
          print('Error saving score on reset: $e');
          print('Stack trace: $stackTrace');
          if (mounted) {
            _showErrorDialog('Error saving score on reset: $e');
          }
        }
      }

      _safeSetState(() {
        _score = 0;
        _feedback = '';
        _roundActive = false;
        _isRevealed = false;
        _timeLeft = 20;
        _currentPokemon = null;
      });
    } catch (e, stackTrace) {
      print('Error in _resetGame: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showErrorDialog('Error resetting game: $e');
      }
    }
  }


  String _achievementLabel() {
    if (_bestScore >= 80) {
      return 'League Champion';
    } else if (_bestScore >= 50) {
      return 'Gym Challenger';
    } else if (_bestScore >= 20) {
      return 'Rookie Trainer';
    } else {
      return 'New Trainer';
    }
  }

  Color _achievementColor() {
    if (_bestScore >= 80) {
      return Colors.amber;
    } else if (_bestScore >= 50) {
      return Colors.purpleAccent;
    } else if (_bestScore >= 20) {
      return Colors.blueAccent;
    } else {
      return Colors.green;
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = _currentPokemon;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Who's That Pokémon?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score + Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '$_timeLeft s',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Achievements + Best score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    _achievementLabel(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _achievementColor().withOpacity(0.2),
                  
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Best: $_bestScore',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current: $_score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ranking (top scores)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Local Ranking:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _topScores.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final score = _topScores[index];
                  return Chip(
                    label: Text('#${index + 1}: $score'),
                    backgroundColor: Colors.grey[200],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Silhouette / Image
            Expanded(
              child: Center(
                child: pokemon == null
                    ? const Text(
                        'Tap "Start" to begin!',
                        style: TextStyle(fontSize: 18),
                      )
                    : _buildPokemonImage(pokemon),
              ),
            ),

            const SizedBox(height: 8),

            // Guess input
            TextField(
              controller: _guessController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitGuess(),
              enabled: _roundActive && pokemon != null,
              decoration: InputDecoration(
                hintText: _roundActive
                    ? 'Type your guess here...'
                    : 'Press "Next" to continue',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 8),

            // Feedback text
            if (_feedback.isNotEmpty)
              Text(
                _feedback,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _feedback.startsWith('Correct') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 12),

            // Buttons: Start/Next + Reset
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _roundActive ? null : _startNewRound,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_currentPokemon == null ? 'Start' : 'Next Pokémon'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset game',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonImage(Pokemon pokemon) {
    // Adjust this to your model: imageUrl, sprite, artwork, etc.
    final String? imageUrl = pokemon.officialArtworkUrl; // <-- change if your field is different

    final Widget image = Image.network(
      imageUrl ?? '',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.broken_image,
        size: 120,
        color: Colors.grey,
      ),
    );

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isRevealed
            ? image
            : ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcATop,
                ),
                child: image,
              ),
      ),
    );
  }
}
