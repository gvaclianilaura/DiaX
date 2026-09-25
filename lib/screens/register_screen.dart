import 'package:flutter/material.dart';
import 'package:diax/db/database_helper.dart';
import 'package:diax/services/auth_service.dart';
import 'package:diax/screens/main/main_screen.dart';

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

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      await AuthService.login(); // Запоминаем статус

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLoginMode ? 'Вход выполнен!' : 'Регистрация успешна!',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLoginMode
                ? 'Неверный логин или пароль'
                : 'Такой логин уже существует',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Вход' : 'Регистрация')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Логин
                  TextFormField(
                    controller: _loginController,
                    decoration: const InputDecoration(
                      labelText: 'Логин',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Введите логин';
                      if (v.trim().length < 3)
                        return 'Логин не короче 3 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Пароль
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Введите пароль';
                      if (v.length < 4) return 'Пароль не короче 4 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Повтор пароля (ПОКАЗЫВАЕМ ТОЛЬКО ПРИ РЕГИСТРАЦИИ)
                  if (!_isLoginMode)
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Повторите пароль',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (v != _passwordController.text)
                          return 'Пароли не совпадают';
                        return null;
                      },
                    ),

                  if (!_isLoginMode) const SizedBox(height: 24),
                  if (_isLoginMode) const SizedBox(height: 8),

                  // Главная Кнопка
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLoginMode ? 'Войти' : 'Зарегистрироваться'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // КНОПКА ПЕРЕКЛЮЧЕНИЯ РЕЖИМОВ (Вход <-> Регистрация)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode; // Переключаем режим
                        _formKey.currentState
                            ?.reset(); // Сбрасываем ошибки ввода
                      });
                    },
                    child: Text(
                      _isLoginMode
                          ? 'Нет аккаунта? Зарегистрироваться'
                          : 'Уже есть аккаунт? Войти',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
