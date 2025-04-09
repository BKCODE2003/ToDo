import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  final Function(ThemeMode) onThemeChanged;

  const SettingsScreen({super.key, required this.onLanguageChanged, required this.onThemeChanged});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  String _appVersion = "Loading...";
  Locale _selectedLocale = Locale('en'); // Default language

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    widget.onThemeChanged(mode);
  }

  void _changeLanguage(Locale locale) {
    setState(() {
      _selectedLocale = locale;
    });
    widget.onLanguageChanged(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context).theme),
            subtitle: Text(_getThemeLabel(context)),
            trailing: DropdownButton<ThemeMode>(
              value: _themeMode,
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  _changeTheme(newMode);
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(AppLocalizations.of(context).systemDefault),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(AppLocalizations.of(context).lightMode),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(AppLocalizations.of(context).darkMode),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context).language),
            subtitle: Text(_getLanguageLabel(context)),
            trailing: DropdownButton<Locale>(
              value: _selectedLocale,
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  _changeLanguage(newLocale);
                }
              },
              items: [
                DropdownMenuItem(
                  value: Locale('en'),
                  child: Text("English"),
                ),
                DropdownMenuItem(
                  value: Locale('hi'),
                  child: Text("हिन्दी"),
                ),
                DropdownMenuItem(
                  value: Locale('mr'),
                  child: Text("मराठी"),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context).appVersion),
            subtitle: Text(_appVersion),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return AppLocalizations.of(context).lightMode;
      case ThemeMode.dark:
        return AppLocalizations.of(context).darkMode;
      default:
        return AppLocalizations.of(context).systemDefault;
    }
  }

  String _getLanguageLabel(BuildContext context) {
    switch (_selectedLocale.languageCode) {
      case 'hi':
        return "हिन्दी";
      case 'mr':
        return "मराठी";
      default:
        return "English";
    }
  }
}