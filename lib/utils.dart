import 'package:flutter/material.dart';

class PokemonTypeColor {
  static final Map<String, Color> _colors = {
    'grass': Colors.green,
    'poison': Colors.purple,
    'fire': Colors.red,
    'water': Colors.blue,
    'electric': Colors.yellow,
    'normal': Colors.grey,
    'fighting': Colors.orange,
    'flying': Colors.lightBlue,
    'ground': Colors.brown,
    'rock': Colors.grey,
    'bug': Colors.lightGreen,
    'ghost': Colors.deepPurple,
    'steel': Colors.blueGrey,
    'psychic': Colors.pink,
    'ice': Colors.cyan,
    'dragon': Colors.indigo,
    'dark': Colors.brown,
    'fairy': Colors.pinkAccent,
  };

  static Color get(String type) =>
      _colors[type.toLowerCase()] ?? Colors.grey;
}
  
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  const List<String> pokemonTypes = [
    'Normal', 'Fire', 'Water', 'Electric', 'Grass', 'Ice',
    'Fighting', 'Poison', 'Ground', 'Flying', 'Psychic', 'Bug',
    'Rock', 'Ghost', 'Dragon', 'Dark', 'Steel', 'Fairy'
  ];

  const List<String> pokemonEggGroups = [
    'Monster', 'Water 1', 'Bug', 'Flying', 'Field', 'Fairy',
    'Grass', 'Human-Like', 'Water 3', 'Mineral', 'Amorphous',
    'Water 2', 'Ditto', 'Undiscovered'
  ];