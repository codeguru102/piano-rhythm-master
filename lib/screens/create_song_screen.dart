import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../config/app_config.dart';
import '../data/game_repository.dart';
import '../models/song.dart';
import '../services/text_to_midi_client.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_text.dart';
import '../widgets/glow_button.dart';
import 'game_screen.dart';

/// "Create a Song from Text" — sends a prompt to the configured text2midi
/// endpoint (see [AppConfig.midiApiUrl]), converts the returned MIDI into a
/// playable chart, saves it to the library, and jumps into the game.
class CreateSongScreen extends StatefulWidget {
  const CreateSongScreen({super.key});

  @override
  State<CreateSongScreen> createState() => _CreateSongScreenState();
}

class _CreateSongScreenState extends State<CreateSongScreen> {
  final _promptCtrl = TextEditingController();
  final _client = TextToMidiClient();

  Difficulty _difficulty = Difficulty.normal;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _difficulty = context.read<SettingsProvider>().preferredDifficulty;
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _client.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    final repo = context.read<GameRepository>();

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final song = await _client.generate(
        baseUrl: AppConfig.midiApiUrl,
        prompt: _promptCtrl.text,
        difficulty: _difficulty,
      );
      await repo.saveCustomSong(song);
      if (!mounted) return;
      // Replace this screen with the game so returning lands back in the
      // library (which will show the freshly saved song).
      Navigator.of(context).pushReplacement(
        AppRoutes.scaleFade(GameScreen(song: song)),
      );
    } on TextToMidiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    _label('Describe your song'),
                    _promptField(),
                    const SizedBox(height: 8),
                    const Text(
                      'A vibe, mood, or genre works best — the generator turns '
                      'it into a melody you play.',
                      style: TextStyle(color: AppColors.textLow, fontSize: 12),
                    ),
                    const SizedBox(height: 22),
                    _label('Difficulty'),
                    _difficultyRow(),
                    if (!AppConfig.hasMidiApi) ...[
                      const SizedBox(height: 22),
                      _notConfiguredBox(),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      _errorBox(_error!),
                    ],
                    const SizedBox(height: 28),
                    GlowButton(
                      label: _busy ? 'Generating…' : 'Generate & Play',
                      icon: _busy ? null : Icons.auto_awesome_rounded,
                      onPressed: _busy ? null : _generate,
                    ),
                    if (_busy) ...[
                      const SizedBox(height: 20),
                      const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonPurple),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Composing your track…',
                          style:
                              TextStyle(color: AppColors.textMid, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textHi),
            onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          ),
          const GradientText(
            'Create a Song',
            gradient: AppGradients.aurora,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              color: AppColors.textMid,
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
      );

  Widget _promptField() {
    return TextField(
      controller: _promptCtrl,
      enabled: !_busy,
      maxLines: 3,
      style: const TextStyle(color: AppColors.textHi),
      decoration: _decoration(
        'e.g. "an upbeat happy arcade tune with a catchy melody"',
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLow),
        filled: true,
        fillColor: AppColors.panel,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.neonPurple),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
      );

  Widget _difficultyRow() {
    return Wrap(
      spacing: 8,
      children: [
        for (final d in Difficulty.values)
          GestureDetector(
            onTap: _busy ? null : () => setState(() => _difficulty = d),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: _difficulty == d ? AppGradients.primary : null,
                color: _difficulty == d ? null : AppColors.panel,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: _difficulty == d ? Colors.transparent : AppColors.stroke,
                ),
              ),
              child: Text(
                d.label,
                style: TextStyle(
                  color: _difficulty == d ? Colors.white : AppColors.textMid,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _notConfiguredBox() {
    return _infoBox(
      icon: Icons.info_outline_rounded,
      color: AppColors.textLow,
      message:
          'Generator endpoint not configured. Run with --dart-define=MIDI_API_URL='
          '<url> (or --dart-define-from-file=config/app_config.json).',
    );
  }

  Widget _errorBox(String message) => _infoBox(
        icon: Icons.error_outline_rounded,
        color: AppColors.miss,
        message: message,
      );

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textHi, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
