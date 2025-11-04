import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main(){
  runApp(const PokemonApp());
}

class PokemonApp extends StatelessWidget {
  const PokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon list',
      debugShowCheckedModeBanner: false,
      /*theme: ThemeData(
        primarySwatch: Colors.blue,
      ),*/
      home: PokemonHomePage(),
    );
  }
}

class PokemonHomePage extends StatefulWidget {
  const PokemonHomePage({super.key});

  @override
  _PokemonHomePageState createState() => _PokemonHomePageState();
}

class _PokemonHomePageState extends State<PokemonHomePage> {

  List<Map<String, dynamic>> pokemonList = []; 

  @override
  void initState() {
    super.initState();
    fetchPokemonData();  // Fetch Pokemon data when widget initializes
  }


  Future<void> fetchPokemonData() async {
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=100'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];

      List<Map<String, dynamic>> loadedPokemon = [];

      for(int i = 0; i < results.length; i++) {
        final name = results[i]['name'];
        final id = i + 1; // IDs start from 1
        final imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
        
        loadedPokemon.add({
          'name': name,
          'image': imageUrl,
        });
      }

      setState(() {
        pokemonList = loadedPokemon;
      });
    } else {
      throw Exception('Failed to load Pokémon data');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokémon List'),
      ),
      body: pokemonList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: pokemonList.length,
              itemBuilder: (context, index) {
                final pokemon = pokemonList[index];
                return ListTile(
                  leading: Image.network(pokemon['image']),
                  title: Text(
                    pokemon['name'].toString().toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
    );
  }
}