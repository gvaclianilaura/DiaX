import 'dart:io';
import 'package:flutter/material.dart';

import 'package:diax/db/database_helper.dart';
import 'package:diax/models/saved_calculation.dart';

class SavedCalculationsScreen extends StatefulWidget {
  const SavedCalculationsScreen({super.key});

  @override
  State<SavedCalculationsScreen> createState() => _SavedCalculationsScreenState();
}

class _SavedCalculationsScreenState extends State<SavedCalculationsScreen> {
  List<SavedCalculation> _allCalculations = [];
  List<SavedCalculation> _filteredCalculations = []; // Список для отображения
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await DatabaseHelper.instance.getAllCalculations();
    if (!mounted) return;
    setState(() {
      _allCalculations = data;
      _filteredCalculations = data; // Изначально показываем всё
      _isLoading = false;
    });
  }

  // Метод живого поиска
  void _filterList(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCalculations = _allCalculations);
      return;
    }
    setState(() {
      _filteredCalculations = _allCalculations.where((item) {
        final productName = item.productName.toLowerCase();
        final searchLower = query.toLowerCase();
        return productName.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _deleteItem(SavedCalculation item) async {
    if (item.id != null) {
      await DatabaseHelper.instance.deleteCalculation(item.id!);
    }
    
    if (item.photoPath != null) {
      try {
        final file = File(item.photoPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    
    // Удаляем из обоих списков, чтобы интерфейс не сломался
    setState(() {
      _allCalculations.remove(item);
      _filteredCalculations.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Сохранённые продукты'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
              children: [
                // Поисковая строка
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterList, // Запускает фильтрацию при каждом нажатии клавиши
                    decoration: InputDecoration(
                      hintText: 'Поиск продукта...',
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterList('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.green.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                
                // Сам список продуктов
                Expanded(
                  child: _filteredCalculations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredCalculations.length,
                          itemBuilder: (context, index) {
                            final item = _filteredCalculations[index];
                            return _buildCalculationCard(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.green.shade200),
          const SizedBox(height: 16),
          Text(
            'Ничего не найдено',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationCard(SavedCalculation item) {
    final hasName = item.productName.trim().isNotEmpty;
    final name = hasName ? item.productName : 'Продукт без названия';

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        _deleteItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись удалена')),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.green.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green.shade100),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.photoPath != null
                    ? Image.file(
                        File(item.photoPath!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.green.shade50,
                        child: Icon(Icons.restaurant, color: Colors.green.shade300),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Порция: ${item.weight} г',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    Text(
                      'Углеводов: ${item.carbsInPortion.toStringAsFixed(1)} г',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      item.breadUnits.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      'ХЕ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}