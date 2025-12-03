import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pokedex/utils.dart';
import '../models/pokemon.dart';
import '../screens/pokemon_details_screen.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonDetailsScreen(
                pokemonId: pokemon.nationalDex,
                pokemonName: pokemon.name,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Pokemon Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: pokemon.officialArtworkUrl != null
                    ? CachedNetworkImage(
                        imageUrl: pokemon.officialArtworkUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) {
                          return pokemon.spriteUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: pokemon.spriteUrl!,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) => 
                                    const Icon(Icons.catching_pokemon, size: 40),
                                )
                              : const Icon(Icons.catching_pokemon, size: 40);
                        },
                      )
                    : pokemon.spriteUrl != null
                        ? CachedNetworkImage(
                            imageUrl: pokemon.spriteUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => 
                              const Icon(Icons.catching_pokemon, size: 40),
                          )
                        : const Icon(Icons.catching_pokemon, size: 40),
              ),
              const SizedBox(width: 16),
              // Pokemon Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${pokemon.nationalDex.toString().padLeft(3, '0')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (pokemon.isLegendary)
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                        if (pokemon.isMythical)
                          const Icon(Icons.auto_awesome, color: Colors.purple, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pokemon.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Types
                    Row(
                      children: pokemon.types.map((type) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PokemonTypeColor.get(type),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
