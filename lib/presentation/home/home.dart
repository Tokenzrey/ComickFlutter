// ignore_for_file: use_build_context_synchronously

import 'package:boilerplate/data/sharedpref/constants/preferences.dart';
import 'package:boilerplate/di/service_locator.dart';
import 'package:boilerplate/presentation/home/store/language/language_store.dart';
import 'package:boilerplate/presentation/home/store/theme/theme_store.dart';
import 'package:boilerplate/presentation/login/store/login_store.dart';
import 'package:boilerplate/presentation/post/post_list.dart';
import 'package:boilerplate/utils/locale/app_localization.dart';
import 'package:boilerplate/utils/routes/routes.dart';
import 'package:boilerplate/core/widgets/custom_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //stores:---------------------------------------------------------------------
  final ThemeStore _themeStore = getIt<ThemeStore>();
  final LanguageStore _languageStore = getIt<LanguageStore>();
  final LoginStore _loginStore = getIt<LoginStore>();

  // Logout state
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const PostListScreen(),
          // Show loading overlay when logging out
          if (_isLoggingOut)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      // Remove FAB from here as it's now in PostListScreen
    );
  }

  // app bar methods:-----------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(AppLocalizations.of(context).translate('home_tv_posts')),
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return <Widget>[
      _buildLanguageButton(),
      _buildThemeButton(),
      _buildLogoutButton(),
    ];
  }

  Widget _buildThemeButton() {
    return Observer(
      builder: (context) {
        return IconButton(
          onPressed: () {
            _themeStore.changeBrightnessToDark(!_themeStore.darkMode);
          },
          icon: Icon(
            _themeStore.darkMode ? Icons.brightness_5 : Icons.brightness_3,
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      onPressed: _isLoggingOut ? null : _performLogout,
      icon: const Icon(Icons.power_settings_new),
    );
  }

  // Improved logout method with confirmation dialog
  Future<void> _performLogout() async {
    // Show confirmation dialog
    final bool confirmLogout =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Logout'),
              content: Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Logout'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmLogout) return;

    // Start logout process
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // First, call logout on the login store to clear auth state
      await _loginStore.logout();

      // Then update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(Preferences.is_logged_in, false);

      // Show success message
      CustomPopup.show(
        context,
        message: 'Successfully logged out',
        type: PopupType.success,
        onDismiss: () {},
      );
      Navigator.of(context).pushReplacementNamed(Routes.login);
    } catch (e) {
      // Handle logout error
      CustomPopup.show(
        context,
        message: 'Error logging out: $e',
        type: PopupType.error,
        onDismiss: () {},
      );
      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  Widget _buildLanguageButton() {
    return IconButton(
      onPressed: () {
        _buildLanguageDialog();
      },
      icon: const Icon(Icons.language),
    );
  }

  _buildLanguageDialog() {
    _showDialog<String>(
      context: context,
      child: AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('home_tv_choose_language'),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions:
            _languageStore.supportedLanguages
                .map(
                  (object) => ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.all(0.0),
                    title: Text(
                      object.language,
                      style: TextStyle(
                        color:
                            _languageStore.locale == object.locale
                                ? Theme.of(context).primaryColor
                                : _themeStore.darkMode
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      // change user language based on selected locale
                      _languageStore.changeLanguage(object.locale);
                    },
                  ),
                )
                .toList(),
      ),
    );
  }

  _showDialog<T>({required BuildContext context, required Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T? value) {
      // The value passed to Navigator.pop() or null.
    });
  }
}
