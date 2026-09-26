import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:diax/db/database_helper.dart';
import 'package:diax/models/saved_calculation.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _carbsPer100Controller = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();

  double? _resultBreadUnits;
  double? _resultCarbsInPortion;

  File? _photoFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _carbsPer100Controller.dispose();
    _weightController.dispose();
    _productNameController.dispose();
    super.dispose();
  }

  double? _parseDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  double _roundToHalf(double value) {
    return (value * 2).round() / 2;
  }

  void _calculate() {
    final carbsPer100 = _parseDouble(_carbsPer100Controller.text);
    final weight = _parseDouble(_weightController.text);

    if (carbsPer100 == null || weight == null) {
      _showSnack('Заполните оба поля');
      return;
    }
    if (carbsPer100 < 0 || weight < 0) {
      _showSnack('Значения должны быть положительными');
      return;
    }

    final carbsInPortion = carbsPer100 * weight / 100;
    final breadUnits = carbsInPortion / 10;
    final rounded = _roundToHalf(breadUnits);

    setState(() {
      _resultCarbsInPortion = carbsInPortion;
      _resultBreadUnits = rounded;
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final fileName = 'calc_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${photosDir.path}/$fileName';

      final File savedFile = await File(picked.path).copy(savedPath);

      if (!mounted) return;
      setState(() {
        _photoFile = savedFile;
      });
    } catch (e) {
      _showSnack('Не удалось сделать фото: $e');
    }
  }

  Future<void> _removePhoto() async {
    if (_photoFile != null) {
      try {
        if (await _photoFile!.exists()) await _photoFile!.delete();
      } catch (_) {}
    }
    setState(() {
      _photoFile = null;
    });
  }

  Future<void> _saveResult() async {
    if (_resultBreadUnits == null || _resultCarbsInPortion == null) {
      _showSnack('Сначала рассчитайте ХЕ');
      return;
    }

    final carbsPer100 = _parseDouble(_carbsPer100Controller.text);
    final weight = _parseDouble(_weightController.text);
    if (carbsPer100 == null || weight == null) return;

    final calc = SavedCalculation(
      createdAt: DateTime.now().toIso8601String(),
      productName: _productNameController.text.trim(),
      carbsPer100: carbsPer100,
      weight: weight,
      breadUnits: _resultBreadUnits!,
      carbsInPortion: _resultCarbsInPortion!,
      photoPath: _photoFile?.path,
    );

    await DatabaseHelper.instance.saveCalculation(calc);

    if (!mounted) return;
    _showSnack('Результат сохранён', color: Colors.green);

    setState(() {
      _carbsPer100Controller.clear();
      _weightController.clear();
      _productNameController.clear();
      _resultBreadUnits = null;
      _resultCarbsInPortion = null;
      _photoFile = null;
    });
  }

  void _clear() {
    setState(() {
      _carbsPer100Controller.clear();
      _weightController.clear();
      _productNameController.clear();
      _resultBreadUnits = null;
      _resultCarbsInPortion = null;
      _photoFile = null;
    });
  }

  void _showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор ХЕ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clear,
            tooltip: 'Сбросить',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === ИНФО ===
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blueAccent,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Как это работает',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1 хлебная единица (ХЕ) = 10 г углеводов.\n'
                      'Введите данные — калькулятор посчитает ХЕ.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Название продукта (необязательно)',
                hintText: 'Например: гречка',
                prefixIcon: Icon(Icons.restaurant_menu),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _carbsPer100Controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Углеводы на 100 г продукта',
                hintText: 'Например: 15',
                suffixText: 'г',
                prefixIcon: Icon(Icons.grain),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _resetResultIfNeeded(),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Масса порции',
                hintText: 'Например: 150',
                suffixText: 'г',
                prefixIcon: Icon(Icons.scale),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _resetResultIfNeeded(),
              onSubmitted: (_) => _calculate(),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'Рассчитать',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_resultBreadUnits != null && _resultCarbsInPortion != null) ...[
              _buildResultCard(),
              const SizedBox(height: 16),
              _buildPhotoSection(),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveResult,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Сохранить результат',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _resetResultIfNeeded() {
    if (_resultBreadUnits != null) {
      setState(() {
        _resultBreadUnits = null;
        _resultCarbsInPortion = null;
      });
    }
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Хлебные единицы',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(_resultBreadUnits!),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ХЕ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Углеводов в порции: ${_resultCarbsInPortion!.toStringAsFixed(1)} г',
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo_camera,
                  color: Colors.blueAccent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Фото продукта',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_photoFile != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: _removePhoto,
                    tooltip: 'Удалить фото',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_photoFile == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.add_a_photo, size: 20),
                  label: const Text('Сделать фото'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    side: BorderSide(
                      color: Colors.blueAccent.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _photoFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}
