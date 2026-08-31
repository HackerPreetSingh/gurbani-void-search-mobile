class SearchQueryBuilder {
  static Map<String, dynamic> buildOperatorQuery(String charCodeQuery) {
    final regex = RegExp(r'[+-]?[^+-]+');
    final matches = regex.allMatches(charCodeQuery).map((m) => m.group(0)!).toList();
    final conditions = <String>[];
    final parameters = <dynamic>[];

    for (var match in matches) {
      String modifiedMatch = match.replaceAll(RegExp("[*\"']"), '');
      if (matches.length == 1 && !match.contains('+') && !match.contains('-')) {
        conditions.add('first_letter_str LIKE ?');
        parameters.add('$modifiedMatch%');
      } else if (match.startsWith('-')) {
        modifiedMatch = modifiedMatch.substring(1);
        conditions.add('first_letter_str NOT LIKE ?');
        parameters.add('%$modifiedMatch%');
      } else {
        if (match.startsWith('+')) modifiedMatch = modifiedMatch.substring(1);
        conditions.add('first_letter_str LIKE ?');
        parameters.add('%$modifiedMatch%');
      }
    }
    return {'condition': conditions.join(' AND '), 'parameters': parameters};
  }

  static Map<String, dynamic> buildBindiQuery(String charCodeQuery) {
    final bindiMap = {'103': '090', '106': '122', '115': '083', '075': '094', '080': '038'};
    String updatedQuery = charCodeQuery;
    
    for (var entry in bindiMap.entries) {
      updatedQuery = updatedQuery.replaceAll(entry.key, entry.value);
    }
    
    if (updatedQuery != charCodeQuery) {
      return {
        'condition': '(first_letter_str LIKE ? OR first_letter_str LIKE ?)',
        'parameters': ['%$charCodeQuery%', '%$updatedQuery%'],
      };
    }
    return {
      'condition': 'first_letter_str LIKE ?',
      'parameters': ['%$charCodeQuery%'],
    };
  }
}
