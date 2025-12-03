import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:case_simulator/Models/case.dart';
import 'package:case_simulator/widgets/case_details_screen.dart';
import 'package:case_simulator/Services/api_service.dart';

enum PriceFilter { all, free, under1, range1to5, range5to10, over10 }

enum CaseSortBy { priceDesc, priceAsc, nameAsc }

class CasesScreen extends StatelessWidget {
  final Box casesBox;
  final VoidCallback onAddSampleCases;

  const CasesScreen({
    super.key,
    required this.casesBox,
    required this.onAddSampleCases,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: casesBox.listenable(),
      builder: (context, Box box, _) {
        if (box.isEmpty) {
          return _EmptyCasesView(onAddSampleCases: onAddSampleCases);
        }

        return _CasesGridView(box: box);
      },
    );
  }
}

class _EmptyCasesView extends StatelessWidget {
  final VoidCallback onAddSampleCases;

  const _EmptyCasesView({required this.onAddSampleCases});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Немає кейсів",
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onAddSampleCases,
            child: const Text("Додати тестові кейси"),
          ),
        ],
      ),
    );
  }
}

class _CasesGridView extends StatefulWidget {
  final Box box;

  const _CasesGridView({required this.box});

  @override
  State<_CasesGridView> createState() => _CasesGridViewState();
}

class _CasesGridViewState extends State<_CasesGridView> {
  PriceFilter _priceFilter = PriceFilter.all;
  CaseSortBy _sortBy = CaseSortBy.priceDesc;

  List get _filteredAndSortedCases {
    var cases = widget.box.values.toList();

    if (_priceFilter != PriceFilter.all) {
      cases = cases.where((caseItem) {
        final actualPrice = caseItem.name.toLowerCase().contains('recoil')
            ? ApiService.getRecoilCasePrice()
            : caseItem.price;

        switch (_priceFilter) {
          case PriceFilter.free:
            return actualPrice == 0;
          case PriceFilter.under1:
            return actualPrice > 0 && actualPrice < 1;
          case PriceFilter.range1to5:
            return actualPrice >= 1 && actualPrice < 5;
          case PriceFilter.range5to10:
            return actualPrice >= 5 && actualPrice < 10;
          case PriceFilter.over10:
            return actualPrice >= 10;
          default:
            return true;
        }
      }).toList();
    }

    switch (_sortBy) {
      case CaseSortBy.priceDesc:
        cases.sort((a, b) => b.price.compareTo(a.price));
        break;
      case CaseSortBy.priceAsc:
        cases.sort((a, b) => a.price.compareTo(b.price));
        break;
      case CaseSortBy.nameAsc:
        cases.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return cases;
  }

  @override
  Widget build(BuildContext context) {
    final displayedCases = _filteredAndSortedCases;
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (screenWidth > 1200) {
      crossAxisCount = 10;
    } else if (screenWidth > 900) {
      crossAxisCount = 6;
    } else if (screenWidth > 600) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 2;
    }

    return Column(
      children: [
        // Фільтри
        _CasesFiltersBar(
          priceFilter: _priceFilter,
          sortBy: _sortBy,
          onPriceFilterChanged: (value) => setState(() => _priceFilter = value),
          onSortChanged: (value) => setState(() => _sortBy = value),
        ),
        Expanded(
          child: displayedCases.isEmpty
              ? const Center(
            child: Text(
              'Немає кейсів з такими фільтрами',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: displayedCases.length,
            itemBuilder: (context, index) {
              final caseItem = displayedCases[index];
              return _CaseCard(caseItem: caseItem);
            },
          ),
        ),
      ],
    );
  }
}

class _CasesFiltersBar extends StatelessWidget {
  final PriceFilter priceFilter;
  final CaseSortBy sortBy;
  final ValueChanged onPriceFilterChanged;
  final ValueChanged onSortChanged;

  const _CasesFiltersBar({
    required this.priceFilter,
    required this.sortBy,
    required this.onPriceFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.green.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton(
              value: priceFilter,
              isExpanded: true,
              dropdownColor: Colors.grey[850],
              underline: Container(),
              items: const [
                DropdownMenuItem(value: PriceFilter.all, child: Text('Всі ціни')),
                DropdownMenuItem(value: PriceFilter.free, child: Text('Безкоштовні')),
                DropdownMenuItem(value: PriceFilter.under1, child: Text('< \$1')),
                DropdownMenuItem(value: PriceFilter.range1to5, child: Text('\$1 - \$5')),
                DropdownMenuItem(value: PriceFilter.range5to10, child: Text('\$5 - \$10')),
                DropdownMenuItem(value: PriceFilter.over10, child: Text('> \$10')),
              ],
              onChanged: (value) {
                if (value != null) onPriceFilterChanged(value);
              },
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.sort, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton(
              value: sortBy,
              isExpanded: true,
              dropdownColor: Colors.grey[850],
              underline: Container(),
              items: const [
                DropdownMenuItem(value: CaseSortBy.priceDesc, child: Text('Дорожчі спочатку')),
                DropdownMenuItem(value: CaseSortBy.priceAsc, child: Text('Дешевші спочатку')),
                DropdownMenuItem(value: CaseSortBy.nameAsc, child: Text('За назвою (А-Я)')),
              ],
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final CaseModel caseItem;

  const _CaseCard({required this.caseItem});

  @override
  Widget build(BuildContext context) {
    final isRecoil = caseItem.name.toLowerCase().contains('recoil');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CaseDetailsScreen(caseModel: caseItem),
          ),
        );
      },
      child: Card(
        color: Colors.grey[850],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (caseItem.imageUrl.isNotEmpty)
              Image.network(
                caseItem.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.archive,
                    size: 50,
                    color: Colors.green,
                  );
                },
              )
            else
              const Icon(Icons.archive, size: 50, color: Colors.green),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                caseItem.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            isRecoil
                ? _RecoilCasePriceWidget()
                : Text(
              caseItem.price == 0
                  ? 'FREE'
                  : '\$${caseItem.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: caseItem.price == 0 ? Colors.blue : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoilCasePriceWidget extends StatelessWidget {
  const _RecoilCasePriceWidget();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, box, _) {
        final currentPrice = ApiService.getRecoilCasePrice();
        final remaining = ApiService.getRecoilFreeOpensRemaining();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentPrice == 0 ? 'FREE' : '\$${currentPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: currentPrice == 0 ? Colors.blue : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (remaining > 0)
              Text(
                '($remaining left)',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 9,
                ),
              ),
          ],
        );
      },
    );
  }
}
