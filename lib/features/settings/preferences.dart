part of '../../main.dart';

final appPreferences = AppPreferences();

class AppPreferences {
  final SharedPreferencesAsync storage = SharedPreferencesAsync();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  static const String themeKey = 'servora.theme';

  Future<void> load() async {
    try {
      final saved = await storage.getString(themeKey);

      themeMode.value = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      themeMode.value = ThemeMode.system;
      debugPrint('Unable to load appearance preferences.');
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    await storage.setString(themeKey, mode.name);
    themeMode.value = mode;
  }

  String notificationKey(
    String userId,
    String preference,
  ) {
    return 'servora.notifications.$userId.$preference';
  }

  Future<bool> notificationEnabled(
    String userId,
    String preference,
  ) async {
    return await storage.getBool(
          notificationKey(userId, preference),
        ) ??
        true;
  }

  Future<void> setNotification(
    String userId,
    String preference,
    bool enabled,
  ) async {
    await storage.setBool(
      notificationKey(userId, preference),
      enabled,
    );
  }
}

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  bool saving = false;

  Future<void> changeTheme(ThemeMode mode) async {
    if (saving) return;

    setState(() => saving = true);

    await handle(context, () async {
      await appPreferences.setTheme(mode);
    });

    if (mounted) {
      setState(() => saving = false);
    }
  }

  Widget previewPanel(bool dark, IconData icon) {
    final background = dark ? const Color(0xFF152620) : const Color(0xFFF3F8F5);

    final foreground = dark ? const Color(0xFF91E4C8) : const Color(0xFF006B59);

    return Container(
      padding: const EdgeInsets.all(5),
      color: background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: foreground,
            size: 18,
          ),
          const SizedBox(height: 5),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: foreground.withAlpha(150),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: foreground.withAlpha(70),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget themePreview(
    ThemeMode mode,
    IconData icon,
  ) {
    return Container(
      width: 60,
      height: 54,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: mode == ThemeMode.system
          ? Row(
              children: [
                Expanded(
                  child: previewPanel(
                    false,
                    Icons.light_mode_outlined,
                  ),
                ),
                Expanded(
                  child: previewPanel(
                    true,
                    Icons.dark_mode_outlined,
                  ),
                ),
              ],
            )
          : previewPanel(
              mode == ThemeMode.dark,
              icon,
            ),
    );
  }

  Widget themeOption({
    required String title,
    required String description,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode selected,
  }) {
    final active = mode == selected;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      selected: active,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: active ? colors.primary : colors.outlineVariant,
            width: active ? 1.5 : 0.7,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: themePreview(mode, icon),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            active ? '$description - Selected' : description,
          ),
          trailing: Icon(
            active ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: active ? colors.primary : colors.onSurfaceVariant,
          ),
          onTap: saving ? null : () => changeTheme(mode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appPreferences.themeMode,
      builder: (context, selected, child) {
        return page('Appearance', [
          _settingsPageIntro(
            context,
            label: 'SERVORA APPEARANCE',
            title: 'Make it yours',
            description: 'Choose a comfortable appearance for your '
                'Servora experience.',
            icon: Icons.palette_outlined,
          ),
          Text(
            'Colour theme',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          themeOption(
            title: 'Light mode',
            description: 'A bright and clean appearance',
            icon: Icons.light_mode_outlined,
            mode: ThemeMode.light,
            selected: selected,
          ),
          themeOption(
            title: 'Dark mode',
            description: 'A darker appearance',
            icon: Icons.dark_mode_outlined,
            mode: ThemeMode.dark,
            selected: selected,
          ),
          themeOption(
            title: 'System default',
            description: 'Follow your device settings',
            icon: Icons.settings_brightness,
            mode: ThemeMode.system,
            selected: selected,
          ),
          if (saving) const LinearProgressIndicator(),
          const Text(
            'Your appearance preference is saved '
            'automatically on this device.',
          ),
        ]);
      },
    );
  }
}
