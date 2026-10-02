import 'package:flutter/material.dart';
import 'package:diax/db/database_helper.dart';
import 'package:diax/services/auth_service.dart';
import 'package:diax/screens/main/main_screen.dart'; // Убедись, что путь правильный

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Режим входа (true) или регистрации (false)
  bool _isLoginMode = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Общий метод для Входа и Регистрации
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final login = _loginController.text.trim();
    final password = _passwordController.text;

    bool ok = false;

    // Проверяем, какой сейчас режим
    if (_isLoginMode) {
      // ПЫТАЕМСЯ ВОЙТИ
      ok = await DatabaseHelper.instance.checkUser(login, password);
    } else {
      // РЕГИСТРИРУЕМСЯ
      ok = await DatabaseHelper.instance.registerUser(login, password);
    }

    // Проверка после первого await
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      await AuthService.login(); // Запоминаем статус

      // Проверка после второго await
      if (!mounted) return;

      _showSnack(_isLoginMode ? 'Вход выполнен!' : 'Регистрация успешна!');

      // Проверка перед навигацией
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      _showSnack(
        _isLoginMode ? 'Неверный логин или пароль' : 'Такой логин уже существует',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7), // Тот же воздушный фон
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // === ИКОНКА / ЛОГОТИП ===
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/app_icon.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.health_and_safety_rounded,
                              size: 80,
                              color: Color(0xFF4CAF50),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // === ЗАГОЛОВОК ===
                  Text(
                    _isLoginMode ? 'С возвращением' : 'Создать аккаунт',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332), // Глубокий зеленый
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoginMode 
                        ? 'Войдите, чтобы продолжить работу с DiaX' 
                        : 'Заполните данные для регистрации',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // === ПОЛЕ: ЛОГИН ===
                  _buildModernTextField(
                    controller: _loginController,
                    label: 'Логин',
                    hint: 'Например: Никита',
                    icon: Icons.person_outline_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Введите логин';
                      if (v.trim().length < 3) return 'Логин не короче 3 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // === ПОЛЕ: ПАРОЛЬ ===
                  _buildModernTextField(
                    controller: _passwordController,
                    label: 'Пароль',
                    hint: 'Например: 1234',
                    helper: 'Минимум 4 символа',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Введите пароль';
                      if (v.length < 4) return 'Пароль не короче 4 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // === ПОЛЕ: ПОВТОР ПАРОЛЯ ===
                  // Анимируем появление/исчезновение поля, чтобы интерфейс не "прыгал" жестко
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: !_isLoginMode
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildModernTextField(
                              controller: _confirmController,
                              label: 'Повторите пароль',
                              hint: 'Повторите введенный пароль',
                              icon: Icons.lock_reset_rounded,
                              isPassword: true,
                              obscureText: _obscureConfirm,
                              onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              validator: (v) {
                                if (_isLoginMode) return null; // При входе не валидируем
                                if (v == null || v.isEmpty) return 'Подтвердите пароль';
                                if (v != _passwordController.text) return 'Пароли не совпадают';
                                return null;
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // === ГЛАВНАЯ КНОПКА ===
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              _isLoginMode ? 'Войти' : 'Зарегистрироваться',
                              style: const TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // === ПЕРЕКЛЮЧЕНИЕ РЕЖИМОВ ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLoginMode ? 'Нет аккаунта?' : 'Уже есть аккаунт?',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                            _formKey.currentState?.reset(); // Сбрасываем ошибки
                            _passwordController.clear();
                            _confirmController.clear();
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                        ),
                        child: Text(
                          _isLoginMode ? 'Создать' : 'Войти',
                          style: const TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Обновленный виджет, теперь работает с TextFormField для валидации
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? helper,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
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
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade300),
          helperText: helper,
          helperStyle: TextStyle(color: Colors.green.shade600, fontSize: 11),
          prefixIcon: Icon(icon, color: const Color(0xFF81C784), size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          // Чтобы ошибка не ломала высоту контейнера слишком сильно
          errorStyle: const TextStyle(height: 0.8),
        ),
      ),
    );
  }
}