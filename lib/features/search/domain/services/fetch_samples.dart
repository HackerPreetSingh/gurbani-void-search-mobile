import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  final client = HttpClient();
  const baseUrl = 'https://api.banidb.com/v2';
  final dir = Directory('sample-json');
  if (!dir.existsSync()) dir.createSync();

  final targets = {
    'sources': '$baseUrl/sources',
    'writers': '$baseUrl/writers',
    'raags': '$baseUrl/raags',
    'search_roman': '$baseUrl/search/hkhdr?searchtype=7&results=5',
    'search_gurmukhi': '$baseUrl/search/ਸਸਸਗ?searchtype=0&results=5',
    'shabad_detail': '$baseUrl/shabads/1',
    'ang_sggs': '$baseUrl/angs/1/G',
    'ang_bhai_gurdas': '$baseUrl/angs/1/B',
    'ang_dasam': '$baseUrl/angs/1/D',
  };

  for (final entry in targets.entries) {
    try {
      print('Fetching ${entry.key}...');
      final request = await client.getUrl(Uri.parse(entry.value));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final file = File('${dir.path}/${entry.key}.json');
      file.writeAsStringSync(body);
      print('Saved ${entry.key}.json');
    } catch (e) {
      print('Error fetching ${entry.key}: $e');
    }
  }
  client.close();
  print('Done.');
}
