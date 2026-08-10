import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../domain/models/punjabi_search_query.dart';

class RemoteSearchDataSource {
  RemoteSearchDataSource(this._dio);
  final Dio _dio;

  Future<List<dynamic>> search(
    PunjabiSearchQuery query, {
    int limit = 40,
    CancelToken? cancelToken,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.raw.trim());
      final response = await _dio.get(
        '${AppConstants.banidbBaseUrl}/search/$encodedQuery', 
        queryParameters: {
          'searchtype': (query.kind == PunjabiSearchKind.romanInitial) ? 7 : 0,
          'results': limit,
        },
        cancelToken: cancelToken,
      );
      return response.data['verses'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getShabad(
    String shabadId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.get(
        '${AppConstants.banidbBaseUrl}/shabads/$shabadId',
        cancelToken: cancelToken,
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
