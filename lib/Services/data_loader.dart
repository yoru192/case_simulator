import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:case_simulator/Models/case.dart';

class DataLoader {
  static Future<void> loadInitialData() async {
    final casesBox = Hive.box<CaseModel>('cases');

    if (casesBox.isNotEmpty) return;

    final String jsonString = await rootBundle.loadString('assets/data/cases.json');
    final List<dynamic> jsonData = jsonDecode(jsonString);

    for (var caseData in jsonData) {
      final caseModel = CaseModel.fromJson(caseData);
      await casesBox.put(caseModel.id, caseModel);
    }
  }
}
