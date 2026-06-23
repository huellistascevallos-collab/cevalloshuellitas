import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://sjdlannkcqdupfoxxbxt.supabase.co/rest/v1/citas?select=*&limit=1';
  final anonKey = 'sb_publishable_BIk1beMqBJnTrqqsKW1jng_lixaeoEz';

  print('Sending HTTP request to Supabase REST API...');
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    );

    print('Status code: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      if (list.isNotEmpty) {
        print('Columns in citas table:');
        final firstRow = list.first as Map<String, dynamic>;
        for (final key in firstRow.keys) {
          print(' - $key : ${firstRow[key]} (${firstRow[key].runtimeType})');
        }
      } else {
        print('Citas table is empty, so we cannot list columns from a row directly.');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
