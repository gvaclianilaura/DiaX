import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:diax/db/database_helper.dart';
import 'package:diax/models/saved_calculation.dart';
import 'package:diax/screens/saved_calculations_screen.dart';

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
      _showSnack('Заполните оба поля', color: Colors.orange.shade400);
      return;
    }
    if (carbsPer100 < 0 || weight < 0) {
      _showSnack('Значения должны быть положительными', color: Colors.orange.shade400);
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
      _showSnack('Не удалось сделать фото', color: Colors.redAccent);
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
      _showSnack('Сначала рассчитайте ХЕ', color: Colors.orange.shade400);
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
    _showSnack('Результат сохранён', color: const Color(0xFF2E7D32));

    _clear();
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
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color ?? Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Очень легкий серый оттенок фона, чтобы белые карточки казались объемными
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7), 
      appBar: AppBar(
        title: const Text(
          'Калькулятор',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Воздушная шапка
        foregroundColor: const Color(0xFF1B4332), // Глубокий темно-зеленый
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.format_list_bulleted_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavedCalculationsScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _clear,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === ЖУРНАЛЬНЫЙ ИНФО-БЛОК ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: const Border(
                  left: BorderSide(color: Color(0xFF4CAF50), width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF4CAF50), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Справка',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1 хлебная единица (ХЕ) = 10 г углеводов.\nВведите данные, и мы всё рассчитаем.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === СОВРЕМЕННЫЕ ПОЛЯ ВВОДА ===
            _buildModernTextField(
              controller: _productNameController,
              label: 'Название продукта',
              hint: 'Например: Яблоко',
              icon: Icons.fastfood_rounded,
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _carbsPer100Controller,
              label: 'Углеводы на 100 г',
              hint: '0.0',
              icon: Icons.grain_rounded,
              suffix: 'г',
              isNumber: true,
              onChanged: (_) => _resetResultIfNeeded(),
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _weightController,
              label: 'Масса порции',
              hint: '0',
              icon: Icons.scale_rounded,
              suffix: 'г',
              isNumber: true,
              onChanged: (_) => _resetResultIfNeeded(),
            ),
            const SizedBox(height: 32),

            // === ГЛАВНАЯ КНОПКА ===
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), // Изумрудный
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Рассчитать',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 24),

            // === РЕЗУЛЬТАТ ===
            if (_resultBreadUnits != null && _resultCarbsInPortion != null) ...[
              _buildResultCard(),
              const SizedBox(height: 20),
              _buildPhotoSection(),
              const SizedBox(height: 24),
              
              // Вторичная кнопка (Outlined)
              OutlinedButton.icon(
                onPressed: _saveResult,
                icon: const Icon(Icons.bookmark_border_rounded, size: 20),
                label: const Text(
                  'Сохранить в дневник',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  // Виджет кастомного поля ввода с мягкими тенями
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade300),
          prefixIcon: Icon(icon, color: const Color(0xFF81C784), size: 22),
          suffixText: suffix,
          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  // Премиальная карточка результата с водяным знаком
  Widget _buildResultCard() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Водяной знак на фоне
          Positioned(
            right: -20,
            bottom: -20,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(
                Icons.bakery_dining_rounded,
                size: 140,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Основной контент
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'РЕЗУЛЬТАТ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white60,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatNumber(_resultBreadUnits!),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'ХЕ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Углеводов: ${_resultCarbsInPortion!.toStringAsFixed(1)} г',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF4CAF50), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Фото продукта',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B4332)),
                  ),
                ],
              ),
              if (_photoFile != null)
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                  onPressed: _removePhoto,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_photoFile == null)
            InkWell(
              onTap: _takePhoto,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE8F5E9), width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFFAFAFA),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_a_photo_rounded, color: Colors.green.shade300, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Нажмите, чтобы добавить фото',
                      style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _photoFile!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
  void _resetResultIfNeeded() {
    if (_resultBreadUnits != null) {
      setState(() {
        _resultBreadUnits = null;
        _resultCarbsInPortion = null;
      });
    }
  }
}