import 'dart:io';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TcgDexService {
  static const String _endpoint = 'https://api.tcgdex.net/v2/graphql';

  late GraphQLClient _client;

  TcgDexService() {
    final HttpLink httpLink = HttpLink(_endpoint);

    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
  }

  /// Query to get a Pokemon card by national dex ID
  static String getCardByDexId(int dexId) => '''
    query GetPokemonCard {
      card(filters: {dexId: $dexId}) {
        dexId
        image
        name
      }
    }
  ''';

  /// Fetches the Pokemon card image URL from TCGdex API
  Future<String?> fetchPokemonCardImageUrl(int nationalDexId) async {
    final QueryOptions options = QueryOptions(
      document: gql(getCardByDexId(nationalDexId)),
    );

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      print('TCGdex query error: ${result.exception}');
      return null;
    }

    final cardData = result.data?['card'];
    if (cardData == null || cardData['image'] == null) {
      return null;
    }

    // Append '/high.png' to get the high-resolution image
    final imageBaseUrl = cardData['image'] as String;
    return '$imageBaseUrl/high.png';
  }

  /// Downloads a Pokemon card image and saves it to a temporary file
  /// Returns the file path if successful, null otherwise
  Future<String?> downloadPokemonCardImage(int nationalDexId, String pokemonName) async {
    try {
      // First, get the image URL
      final imageUrl = await fetchPokemonCardImageUrl(nationalDexId);
      if (imageUrl == null) {
        print('No card image found for Pokemon #$nationalDexId');
        return null;
      }

      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        print('Failed to download image: ${response.statusCode}');
        return null;
      }

      // Get temporary directory to save the image
      final tempDir = await getTemporaryDirectory();
      final fileName = '${pokemonName.toLowerCase().replaceAll(' ', '_')}_card.png';
      final filePath = '${tempDir.path}/$fileName';

      // Write the image to a file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } catch (e) {
      print('Error downloading Pokemon card: $e');
      return null;
    }
  }
}
