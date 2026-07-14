import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/profile_provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              const GradientText('Settings',
                  gradient: AppGradients.aurora,
                  style:
                      TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpace.lg),
              _section('Audio', [
                _slider('Music Volume', Icons.music_note_rounded,
                    settings.musicVolume, settings.setMusicVolume),
                _slider('Sound Effects', Icons.graphic_eq_rounded,
                    settings.sfxVolume, settings.setSfxVolume),
                _switch('Vibration', Icons.vibration_rounded,
                    settings.vibration, settings.setVibration),
              ]),
              const SizedBox(height: AppSpace.md),
              _section('Gameplay', [
                _difficulty(settings),
                _slider(
                  'Note Speed (${settings.noteSpeed.toStringAsFixed(2)}×)',
                  Icons.speed_rounded,
                  (settings.noteSpeed - 0.7) / 0.8, // map 0.7..1.5 -> 0..1
                  (v) => settings.setNoteSpeed(0.7 + v * 0.8),
                ),
                _switch('Left-hand Mode', Icons.swap_horiz_rounded,
                    settings.leftHandMode, settings.setLeftHandMode),
              ]),
              const SizedBox(height: AppSpace.md),
              _section('Account', [
                _accountRow(context, profile),
              ]),
              const SizedBox(height: AppSpace.lg),
              const Center(
                child: Text('Piano Rhythm Master • v1.0.0',
                    style: TextStyle(color: AppColors.textLow, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        gradient: AppGradients.panel,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title,
                style: const TextStyle(
                    color: AppColors.neonPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _slider(
      String label, IconData icon, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMid, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(color: AppColors.textHi, fontSize: 14)),
          ),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                activeTrackColor: AppColors.neonPurple,
                inactiveTrackColor: AppColors.panelHi,
                thumbColor: AppColors.neonPink,
                overlayColor: Color(0x33FF4D9D),
              ),
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switch(
      String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMid, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.textHi, fontSize: 14)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.neonPurple,
            activeThumbColor: AppColors.neonPink,
          ),
        ],
      ),
    );
  }

  Widget _difficulty(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AppColors.textMid, size: 20),
          const SizedBox(width: 10),
          const Text('Difficulty',
              style: TextStyle(color: AppColors.textHi, fontSize: 14)),
          const Spacer(),
          Wrap(
            spacing: 6,
            children: [
              for (final d in Difficulty.values)
                GestureDetector(
                  onTap: () => settings.setPreferredDifficulty(d),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: settings.preferredDifficulty == d
                          ? d.color.withValues(alpha: 0.22)
                          : AppColors.panelHi,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(
                        color: settings.preferredDifficulty == d
                            ? d.color
                            : AppColors.stroke,
                      ),
                    ),
                    child: Text(d.label,
                        style: TextStyle(
                            color: settings.preferredDifficulty == d
                                ? d.color
                                : AppColors.textMid,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountRow(BuildContext context, ProfileProvider profile) {
    final loggedIn = profile.loggedIn;
    return Row(
      children: [
        Icon(loggedIn ? Icons.logout_rounded : Icons.login_rounded,
            color: AppColors.textMid, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(loggedIn ? 'Signed in as ${profile.profile.username}' : 'Signed out',
              style: const TextStyle(color: AppColors.textHi, fontSize: 14)),
        ),
        TextButton(
          onPressed: () {
            loggedIn ? profile.logout() : profile.login();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.panelHi,
                content: Text(loggedIn ? 'Logged out' : 'Logged in',
                    style: const TextStyle(color: AppColors.textHi)),
              ),
            );
          },
          child: Text(loggedIn ? 'Logout' : 'Login',
              style: const TextStyle(color: AppColors.neonPink)),
        ),
      ],
    );
  }
}
