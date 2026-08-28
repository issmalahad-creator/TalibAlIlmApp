import '../models/turath_models.dart';
import '../services/turath_api_client.dart';

/// Turns `TurathApiClient`'s raw responses into what the rest of the app
/// (Phase 79) actually needs — the layer Ismail's spec calls for so a
/// widget never talks to `TurathApiClient`/HTTP directly (item 3). Thin
/// today because the models are already app-shaped; this is still kept
/// as its own class rather than skipped, since that's exactly the seam a
/// future cache layer (79.9) or a second data source plugs into without
/// touching any screen.
class TurathRepository {
  final TurathApiClient _client;
  TurathRepository({TurathApiClient? client}) : _client = client ?? TurathApiClient();

  Future<TurathSearchResults> search(String query, {int? categoryId, int? page}) =>
      _client.search(query, categoryId: categoryId, page: page);

  Future<TurathBook> getBookInfo(int bookId) => _client.getBookInfo(bookId);

  Future<TurathPage> getPage(int bookId, int pageNumber) => _client.getPage(bookId, pageNumber);

  Future<TurathAuthor> getAuthor(int authorId) => _client.getAuthor(authorId);
}
