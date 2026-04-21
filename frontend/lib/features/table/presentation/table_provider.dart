import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'dart:async';

class TableState {
  final List<dynamic> items;
  final int currentPage;
  final int totalPages;
  final int totalRows;
  final bool isLoading;

  TableState({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalRows,
    required this.isLoading,
  });

  TableState copyWith({
    List<dynamic>? items,
    int? currentPage,
    int? totalPages,
    int? totalRows,
    bool? isLoading,
  }) {
    return TableState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRows: totalRows ?? this.totalRows,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TableNotifier extends StateNotifier<TableState> {
  final Ref ref;

  TableNotifier(this.ref)
      : super(TableState(
          items: [],
          currentPage: 1,
          totalPages: 1,
          totalRows: 0,
          isLoading: false,
        )) {
    fetchTables();
  }

  Future<void> fetchTables({int? page}) async {
    state = state.copyWith(isLoading: true);
    final dio = ref.read(dioProvider);
    
    final queryParams = {
      'page': page ?? state.currentPage,
      'limit': 15,
    };

    try {
      final response = await dio.get('tables', queryParameters: queryParams);
      final data = response.data;
      
      state = state.copyWith(
        items: data['rows'],
        currentPage: data['page'],
        totalPages: data['total_pages'],
        totalRows: data['total_rows'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setPage(int page) {
    if (page == state.currentPage) return;
    fetchTables(page: page);
  }
}

final tableManagementProvider = StateNotifierProvider<TableNotifier, TableState>((ref) {
  return TableNotifier(ref);
});
