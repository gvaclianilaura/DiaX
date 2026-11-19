import 'dart:io';
import 'package:flutter/material.dart';

import 'package:diax/db/database_helper.dart';
import 'package:diax/models/saved_calculation.dart';
import 'package:diax/services/api_service.dart';
import 'package:diax/services/auth_service.dart';

class SavedCalculationsScreen extends StatefulWidget {
  const SavedCalculationsScreen({super.key});

  @override
  State<SavedCalculationsScreen> createState() => _SavedCalculationsScreenState();
}

class _SavedCalculationsScreenState extends State<SavedCalculationsScreen> {
  List<SavedCalculation> _allCalculations = [];
  List<SavedCalculation> _filteredCalculations = [];
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
    setState(() => _isLoading = true);

    final userId = await AuthService.getUserId();
    
    // Если юзер не авторизован
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return; 
    }

    // Запрашиваем данные с сервера Onreza
    final serverData = await ApiService.getUserRecords(userId);

    if (!mounted) return;
    
    setState(() {
      _allCalculations = serverData; 
      _filteredCalculations = serverData; 
      _isLoading = false;
    });
  }

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
      // 1. Отправляем команду на удаление в Onreza
      final serverSuccess = await ApiService.deleteRecord(item.id!);
      
      if (!serverSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка удаления из облака', style: TextStyle(color: Colors.white)), 
              backgroundColor: Colors.redAccent,
            ),
          );
          _loadData(); 
        }
        return; 
      }

      // 2. Удаляем из локальной БД
      await DatabaseHelper.instance.deleteCalculation(item.id!);
    }
    
    // 3. Удаляем локальное фото (ТОЛЬКО если это не ссылка на облако Cloud.ru)
    if (item.photoPath != null && !item.photoPath!.startsWith('http')) {
      try {
        final file = File(item.photoPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    
    // 4. Убираем из интерфейса
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
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterList,
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

  // Вспомогательный виджет для отрисовки картинки (облако или локальная)
  Widget _buildProductImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: Colors.green.shade50,
        child: Icon(Icons.restaurant, color: Colors.green.shade300),
      );
    }

    // Если это ссылка из Cloud.ru
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            color: Colors.green.shade50,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: 60,
          height: 60,
          color: Colors.red.shade50,
          child: const Icon(Icons.broken_image, color: Colors.redAccent),
        ),
      );
    }

    // Если это старый локальный путь
    return Image.file(
      File(path),
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 60,
        height: 60,
        color: Colors.red.shade50,
        child: const Icon(Icons.broken_image, color: Colors.redAccent),
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
                child: _buildProductImage(item.photoPath), // Используем новый метод
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