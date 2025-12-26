import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteService {
  static Future<Map<String, String>> fetchQuote() async {
    final url = Uri.parse("https://api.quotable.io/random");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "content": data["content"],
        "author": data["author"]
      };
    } else {
      throw Exception("Failed to load quote");
    }
  }
}
