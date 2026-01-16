import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class FoodApiService {
  // Replace this with your actual key from CalorieNinjas
  static const String _apiKey = 'xvvuN2rZSCituyHOOopxUX6gHxLODTp1CWsOObIS'; 
  static const String _baseUrl = 'https://api.calorieninjas.com/v1/nutrition';

  // Returns null if failed, or integer calories if success
  static Future<int?> getCalories(String query) async {
    if (query.isEmpty) return null;

    try {
      final url = Uri.parse('$_baseUrl?query=$query');
      final response = await http.get(
        url,
        headers: {'X-Api-Key': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'];

        if (items.isNotEmpty) {
          // Sum up calories if multiple items were found (e.g., "egg and toast")
          double totalCals = 0;
          for (var item in items) {
            totalCals += item['calories'];
          }
          return totalCals.round();
        }
      } else {
        log("API Error: ${response.statusCode}", name: 'FoodApiService');
      }
    } catch (e) {
      log("Network Error: $e", name: 'FoodApiService');
    }
    return null;
  }
}