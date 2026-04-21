import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'dart:async';

class CustomerState {
  final List<dynamic> customers;
  final int currentPage;
  final int totalPages;
  final int totalRows;
  final bool isLoading;
  final String searchQuery;

  CustomerState({
    required this.customers,
    required this.currentPage,
    required this.totalPages,
    required this.totalRows,
    required this.isLoading,
    required this.searchQuery,
  });

  CustomerState copyWith({
    List<dynamic>? customers,
    int? currentPage,
    int? totalPages,
    int? totalRows,
    bool? isLoading,
    String? searchQuery,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRows: totalRows ?? this.totalRows,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  final Ref ref;
  Timer? _debounce;

  CustomerNotifier(this.ref)
      : super(CustomerState(
          customers: [],
          currentPage: 1,
          totalPages: 1,
          totalRows: 0,
          isLoading: false,
          searchQuery: '',
        )) {
    fetchCustomers();
  }

  Future<void> fetchCustomers({int? page, String? search}) async {
    state = state.copyWith(isLoading: true);
    final dio = ref.read(dioProvider);
    
    final queryParams = {
      'page': page ?? state.currentPage,
      'search': search ?? state.searchQuery,
      'limit': 10,
    };

    try {
      final response = await dio.get('customers', queryParameters: queryParams);
      final data = response.data;
      
      state = state.copyWith(
        customers: data['rows'],
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
      fetchCustomers(page: 1, search: query);
    });
  }

  void setPage(int page) {
    if (page == state.currentPage) return;
    fetchCustomers(page: page);
  }
}

final customerManagementProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  return CustomerNotifier(ref);
});

// Keep the old provider for POS screen simplified use if needed, but update it to handle paging
final customerProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('customers', queryParameters: {'limit': 100});
  if (response.data is Map) {
    return response.data['rows'] as List<dynamic>;
  }
  return response.data as List<dynamic>;
});
