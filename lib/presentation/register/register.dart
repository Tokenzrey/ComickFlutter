// ignore_for_file: use_build_context_synchronously

import 'package:boilerplate/constants/assets.dart';
import 'package:boilerplate/core/stores/form/form_store.dart';
import 'package:boilerplate/core/widgets/empty_app_bar_widget.dart';
import 'package:boilerplate/core/widgets/progress_indicator_widget.dart';
import 'package:boilerplate/presentation/home/store/theme/theme_store.dart';
import 'package:boilerplate/presentation/register/store/register_store.dart';
import 'package:boilerplate/utils/device/device_utils.dart';
import 'package:boilerplate/utils/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:boilerplate/core/widgets/custom_popup.dart';

import '../../di/service_locator.dart';
import '../../core/theme/auth_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  // Text controllers
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Stores
  final ThemeStore _themeStore = getIt<ThemeStore>();
  final FormStore _formStore = getIt<FormStore>();
  final RegisterStore _registerStore = getIt<RegisterStore>();

  // Focus nodes
  late FocusNode _passwordFocusNode;
  late FocusNode _confirmPasswordFocusNode;

  // Toggle password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Tambahkan flag untuk debounce
  bool _isButtonDisabled = false;

  // Fungsi debounce untuk button
  void _debounceButton() {
    setState(() {
      _isButtonDisabled = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isButtonDisabled = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();

    // Sync controller changes ke formStore
    _userEmailController.addListener(_syncEmailToStore);
    _passwordController.addListener(_syncPasswordToStore);
    _confirmPasswordController.addListener(_syncConfirmPasswordToStore);

    // Validasi awal (opsional)
    // Future.delayed(Duration.zero, () {
    //   _formStore.validateUserEmail(_userEmailController.text);
    //   _formStore.validatePassword(_passwordController.text);
    //   _formStore.validateConfirmPassword(_confirmPasswordController.text);
    // });
  }

  // Update store ketika user mengetik email
  void _syncEmailToStore() {
    if (_userEmailController.text != _formStore.userEmail) {
      _formStore.setUserId(_userEmailController.text);
      _registerStore.setUserEmail(_userEmailController.text);
    }
  }

  // Update store ketika user mengetik password
  void _syncPasswordToStore() {
    if (_passwordController.text != _formStore.password) {
      _formStore.setPassword(_passwordController.text);
      _registerStore.setPassword(_passwordController.text);
    }
  }

  // Update store ketika user mengetik confirm password
  void _syncConfirmPasswordToStore() {
    if (_confirmPasswordController.text != _formStore.confirmPassword) {
      _formStore.setConfirmPassword(_confirmPasswordController.text);
      _registerStore.setConfirmPassword(_confirmPasswordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _themeStore.darkMode;
    final AuthColors colors = isDark ? AuthColors.dark() : AuthColors.light();

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      primary: true,
      appBar: const EmptyAppBar(),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AuthColors colors) {
    return Stack(
      children: <Widget>[
        // Layout responsif berdasarkan orientasi layar
        MediaQuery.of(context).orientation == Orientation.landscape
            ? Row(
              children: <Widget>[
                Expanded(flex: 1, child: _buildLeftSide()),
                Expanded(flex: 1, child: _buildRightSide(colors)),
              ],
            )
            : Center(child: _buildRightSide(colors)),

        // Observer untuk register success atau error
        Observer(
          builder: (context) {
            if (_registerStore.success) {
              // Tampilkan popup sukses dan navigasikan ke login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                CustomPopup.show(
                  context,
                  message:
                      "Registration successful! Please login with your new account.",
                  type: PopupType.success,
                  onDismiss: () {
                    Navigator.of(context).pushReplacementNamed(Routes.login);
                  },
                );
              });
            } else if (_registerStore.errorStore.errorMessage.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                CustomPopup.show(
                  context,
                  message: _registerStore.errorStore.errorMessage,
                  type: PopupType.error,
                  onDismiss: () {},
                );
                // Reset pesan error setelah ditampilkan
                _registerStore.errorStore.errorMessage = '';
              });
            }
            return const SizedBox.shrink();
          },
        ),

        // Observer untuk loading indicator
        Observer(
          builder: (context) {
            return Visibility(
              visible: _registerStore.isLoading,
              child: const CustomProgressIndicatorWidget(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLeftSide() {
    return SizedBox.expand(
      child: Image.asset(Assets.carBackground, fit: BoxFit.cover),
    );
  }

  Widget _buildRightSide(AuthColors colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitle(colors),
            const SizedBox(height: 24),
            _buildUserIdField(colors),
            const SizedBox(height: 16),
            _buildPasswordField(colors),
            const SizedBox(height: 16),
            _buildConfirmPasswordField(colors),
            const SizedBox(height: 24),
            _buildRegisterButton(colors),
            const SizedBox(height: 16),
            _buildLoginLink(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(AuthColors colors) {
    return Text(
      "Create Account",
      style: TextStyle(
        color: colors.labelColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUserIdField(AuthColors colors) {
    return Observer(
      builder: (context) {
        final errorText = _formStore.formErrorStore.userEmail;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Email",
              style: TextStyle(
                color: colors.labelColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _userEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
              cursorColor: colors.cursorColor,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.email, color: colors.iconColor),
                hintText: "email@gmail.com",
                hintStyle: TextStyle(color: colors.hintColor),
                errorText: errorText?.isNotEmpty == true ? errorText : null,
                errorStyle: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
                errorMaxLines: 1,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.borderColor, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colors.focusBorderColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordField(AuthColors colors) {
    return Observer(
      builder: (context) {
        final errorText = _formStore.formErrorStore.password;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Password",
              style: TextStyle(
                color: colors.labelColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              cursorColor: colors.cursorColor,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock, color: colors.iconColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: colors.iconColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                hintText: "********",
                hintStyle: TextStyle(color: colors.hintColor),
                errorText: errorText?.isNotEmpty == true ? errorText : null,
                errorStyle: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
                errorMaxLines: 1,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.borderColor, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colors.focusBorderColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmPasswordField(AuthColors colors) {
    return Observer(
      builder: (context) {
        final errorText = _formStore.formErrorStore.confirmPassword;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Confirm Password",
              style: TextStyle(
                color: colors.labelColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              obscureText: _obscureConfirmPassword,
              cursorColor: colors.cursorColor,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _attemptRegister(),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_outline, color: colors.iconColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: colors.iconColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                hintText: "********",
                hintStyle: TextStyle(color: colors.hintColor),
                errorText: errorText?.isNotEmpty == true ? errorText : null,
                errorStyle: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
                errorMaxLines: 1,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.borderColor, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colors.focusBorderColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRegisterButton(AuthColors colors) {
    return Observer(
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(0, 48),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
              disabledBackgroundColor: colors.buttonColor.withValues(
                alpha: 0.5,
              ),
            ),
            onPressed:
                (_registerStore.isLoading || _isButtonDisabled)
                    ? null
                    : () {
                      _debounceButton(); // Aktifkan debounce
                      _attemptRegister(); // Jalankan login
                    },
            child:
                _registerStore.isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      "Register",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
          ),
        );
      },
    );
  }

  Widget _buildLoginLink(AuthColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(color: colors.labelColor, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushReplacementNamed(Routes.login);
          },
          child: Text(
            "Login here",
            style: TextStyle(
              color: colors.buttonColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _attemptRegister() {
    // Trigger validasi manual
    _formStore.validateUserEmail(_userEmailController.text);
    _formStore.validatePassword(_passwordController.text);
    _formStore.validateConfirmPassword(_confirmPasswordController.text);

    if (_formStore.canRegister) {
      DeviceUtils.hideKeyboard(context);

      final email = _userEmailController.text;
      final password = _passwordController.text;

      _registerStore.registerWithValue(email, password);
    } else {
      String errorMessage = "Please fix the following errors:";
      if (_formStore.formErrorStore.userEmail?.isNotEmpty == true) {
        errorMessage += "\n• ${_formStore.formErrorStore.userEmail}";
      }
      if (_formStore.formErrorStore.password?.isNotEmpty == true) {
        errorMessage += "\n• ${_formStore.formErrorStore.password}";
      }
      if (_formStore.formErrorStore.confirmPassword?.isNotEmpty == true) {
        errorMessage += "\n• ${_formStore.formErrorStore.confirmPassword}";
      }

      if (errorMessage == "Please fix the following errors:") {
        if (_userEmailController.text.isEmpty) {
          errorMessage += "\n• Email cannot be empty";
        }
        if (_passwordController.text.isEmpty) {
          errorMessage += "\n• Password cannot be empty";
        }
        if (_confirmPasswordController.text.isEmpty) {
          errorMessage += "\n• Confirm password cannot be empty";
        }
      }

      CustomPopup.show(
        context,
        message: errorMessage,
        type: PopupType.error,
        onDismiss: () {},
      );
    }
  }

  @override
  void dispose() {
    _userEmailController.removeListener(_syncEmailToStore);
    _passwordController.removeListener(_syncPasswordToStore);
    _confirmPasswordController.removeListener(_syncConfirmPasswordToStore);
    _userEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }
}
