import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'dart:async';

class CommonPagingState {
  final List<dynamic> items;
  final int currentPage;
  final int totalPages;
  final int totalRows;
  final bool isLoading;
  final String searchQuery;

  CommonPagingState({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalRows,
    required this.isLoading,
    required this.searchQuery,
  });

  CommonPagingState copyWith({
    List<dynamic>? items,
    int? currentPage,
    int? totalPages,
    int? totalRows,
    bool? isLoading,
    String? searchQuery,
  }) {
    return CommonPagingState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRows: totalRows ?? this.totalRows,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MenuNotifier extends StateNotifier<CommonPagingState> {
  final Ref ref;
  Timer? _debounce;

  MenuNotifier(this.ref)
      : super(CommonPagingState(
          items: [],
          currentPage: 1,
          totalPages: 1,
          totalRows: 0,
          isLoading: false,
          searchQuery: '',
        )) {
    fetchMenus();
  }

  Future<void> fetchMenus({int? page, String? search}) async {
    state = state.copyWith(isLoading: true);
    final dio = ref.read(dioProvider);
    
    final queryParams = {
      'page': page ?? state.currentPage,
      'search': search ?? state.searchQuery,
      'limit': 12,
    };

    try {
      final response = await dio.get('menus', queryParameters: queryParams);
      final data = response.data;
      
      state = state.copyWith(
        items: data['rows'],
        currentPage: data['page'],
        totalPages: data['total_pages'],
        totalRows: data['total_rows'],
        isLoading: false,
        searchQuery: search ?? state.searchQuery,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchMenus(page: 1, search: query);
    });
  }

  void setPage(int page) {
    if (page == state.currentPage) return;
    fetchMenus(page: page);
  }
}

final menuManagementProvider = StateNotifierProvider<MenuNotifier, CommonPagingState>((ref) {
  return MenuNotifier(ref);
});

// Category Paging Provider
class CategoryNotifier extends StateNotifier<CommonPagingState> {
  final Ref ref;

  CategoryNotifier(this.ref)
      : super(CommonPagingState(
          items: [],
          currentPage: 1,
          totalPages: 1,
          totalRows: 0,
          isLoading: false,
          searchQuery: '',
        )) {
    fetchCategories();
  }

  Future<void> fetchCategories({int? page}) async {
    state = state.copyWith(isLoading: true);
    final dio = ref.read(dioProvider);
    
    final queryParams = {
      'page': page ?? state.currentPage,
      'limit': 10,
    };

    try {
      final response = await dio.get('categories', queryParameters: queryParams);
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
    fetchCategories(page: page);
  }
}

final categoryManagementProvider = StateNotifierProvider<CategoryNotifier, CommonPagingState>((ref) {
  return CategoryNotifier(ref);
});
