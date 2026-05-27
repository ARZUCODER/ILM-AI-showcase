import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/network/api_client.dart';

class KnowledgeFile {
  KnowledgeFile({
    required this.id,
    required this.filename,
    required this.chunkCount,
    required this.charCount,
    required this.createdAt,
  });

  final int id;
  final String filename;
  final int chunkCount;
  final int charCount;
  final String createdAt;

  factory KnowledgeFile.fromMap(Map<String, dynamic> m) => KnowledgeFile(
        id: m['id'] is int ? m['id'] : int.tryParse('${m['id']}') ?? 0,
        filename: m['filename'] ?? 'document',
        chunkCount: m['chunk_count'] is int ? m['chunk_count'] : int.tryParse('${m['chunk_count']}') ?? 0,
        charCount: m['char_count'] is int ? m['char_count'] : int.tryParse('${m['char_count']}') ?? 0,
        createdAt: '${m['created_at'] ?? ''}',
      );
}

class FilesState {
  FilesState({this.files = const [], this.loading = false, this.error});
  final List<KnowledgeFile> files;
  final bool loading;
  final String? error;

  FilesState copyWith({List<KnowledgeFile>? files, bool? loading, String? error}) =>
      FilesState(files: files ?? this.files, loading: loading ?? this.loading, error: error);
}

class FilesNotifier extends StateNotifier<FilesState> {
  FilesNotifier(this._api) : super(FilesState()) {
    refresh();
  }
  final ApiClient _api;

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    try {
      final res = await _api.get('/knowledge/files');
      final list = (res['files'] as List?) ?? [];
      final files = list.map((e) => KnowledgeFile.fromMap(Map<String, dynamic>.from(e))).toList();
      state = FilesState(files: files, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> delete(int id) async {
    try {
      await _api.delete('/knowledge/files/$id');
      await refresh();
    } catch (_) {}
  }
}

final filesProvider = StateNotifierProvider<FilesNotifier, FilesState>((ref) {
  return FilesNotifier(ref.watch(apiClientProvider));
});

/// Upload state: idle | uploading | success | error
sealed class UploadState {
  const UploadState();
}

class UploadIdle extends UploadState {
  const UploadIdle();
}

class UploadInProgress extends UploadState {
  const UploadInProgress(this.filename);
  final String filename;
}

class UploadSuccess extends UploadState {
  const UploadSuccess({required this.filename, required this.chunksSaved, required this.chunksTotal});
  final String filename;
  final int chunksSaved;
  final int chunksTotal;
}

class UploadFailed extends UploadState {
  const UploadFailed(this.message, {this.isQuota = false, this.upgradeMessage});
  final String message;
  final bool isQuota;
  final String? upgradeMessage;
}

class UploadNotifier extends StateNotifier<UploadState> {
  UploadNotifier(this._api, this._ref) : super(const UploadIdle());
  final ApiClient _api;
  final Ref _ref;

  Future<void> uploadFile(PlatformFile file) async {
    state = UploadInProgress(file.name);
    try {
      List<int>? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        state = const UploadFailed("Faylni o'qib bo'lmadi");
        return;
      }
      final res = await _api.uploadFile('/knowledge/upload', bytes: bytes, filename: file.name);
      final saved = (res['chunks_saved'] ?? 0) as int;
      final total = (res['chunks_total'] ?? 0) as int;
      state = UploadSuccess(filename: file.name, chunksSaved: saved, chunksTotal: total);
      await _ref.read(filesProvider.notifier).refresh();
    } on ApiException catch (e) {
      state = UploadFailed(
        e.message,
        isQuota: e.isQuotaError,
        upgradeMessage: e.upgradeMessage,
      );
    } catch (e) {
      state = UploadFailed(e.toString());
    }
  }

  void reset() => state = const UploadIdle();
}

final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref.watch(apiClientProvider), ref);
});
