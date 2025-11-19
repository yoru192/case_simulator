import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:case_simulator/Models/case.dart';

class CasesScreen extends StatelessWidget {
  final Box<CaseModel> casesBox;
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
      builder: (context, Box<CaseModel> box, _) {
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

class _CasesGridView extends StatelessWidget {
  final Box<CaseModel> box;

  const _CasesGridView({required this.box});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: box.length,
      itemBuilder: (context, index) {
        final caseItem = box.getAt(index);
        return _CaseCard(caseItem: caseItem);
      },
    );
  }
}

class _CaseCard extends StatelessWidget {
  final CaseModel? caseItem;

  const _CaseCard({required this.caseItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.archive, size: 50, color: Colors.green),
          const SizedBox(height: 8),
          Text(
            caseItem?.name ?? 'Unknown',
            textAlign: TextAlign.center,
          ),
          Text(
            '\$${caseItem?.price.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }
}
