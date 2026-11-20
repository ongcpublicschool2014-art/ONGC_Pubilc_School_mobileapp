import 'package:http/http.dart' as http;
import 'supabase_service.dart';

/// HTTP client that attaches the parent session token as an `x-app-token`
/// header on EVERY Supabase request (REST + RPC).
///
/// The server's `db-pre-request` hook (`public.app_pre_request`) validates the
/// header, resolves the parent (`app.par_id`), and RLS then scopes reads/writes
/// to that parent's students. When there is no token (logged out), no header is
/// sent. The token is read live from [SupabaseService.sessionToken], which
/// AuthProvider keeps current across login / session restore / logout.
class AppTokenHttpClient extends http.BaseClient {
  final http.Client _inner;
  AppTokenHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final token = SupabaseService.sessionToken;
    if (token != null && token.isNotEmpty) {
      request.headers['x-app-token'] = token;
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
