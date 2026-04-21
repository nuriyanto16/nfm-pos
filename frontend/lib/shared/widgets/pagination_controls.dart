import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
    final int currentPage;
    final int totalPages;
    final int totalRows;
    final Function(int) onPageChanged;

    const PaginationControls({
        super.key,
        required this.currentPage,
        required this.totalPages,
        required this.totalRows,
        required this.onPageChanged,
    });

    @override
    Widget build(BuildContext context) {
        if (totalPages <= 1) return const SizedBox.shrink();

        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text(
                        'Total: $totalRows item',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                    ),
                    Row(
                        children: [
                            IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                            ),
                            Text(
                                'Halaman $currentPage dari $totalPages',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
                            ),
                        ],
                    ),
                ],
            ),
        );
    }
}
