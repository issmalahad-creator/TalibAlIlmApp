import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/prayer_times_repository.dart';
import '../services/language_preference_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

/// "أوقات الصلاة" — QURAN_COMPANION_ROADMAP.md Phase 9. Shows today's six
/// prayers computed offline (once a location is available) via the
/// verified `adhan_dart` engine, plus the calculation-method/madhab the
/// student has chosen — these genuinely change Fajr/Isha/Asr by tens of
/// minutes depending on region and school, so the setting is visible and
/// changeable right here, not buried.
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final _locationService = LocationService();
  final _prayerRepo = PrayerTimesRepository();

  AppCoordinates? _coordinates;
  PrayerTimes? _times;
  String _method = 'muslimWorldLeague';
  Madhab _madhab = Madhab.shafi;
  String _highLatitudeRule = 'auto';
  bool _loading = true;
  bool _noLocation = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final coords = await _locationService.currentLocation();
    if (coords == null) {
      if (!mounted) return;
      setState(() {
        _noLocation = true;
        _loading = false;
      });
      return;
    }
    final method = await _prayerRepo.selectedMethod();
    final madhab = await _prayerRepo.selectedMadhab();
    final highLatitudeRule = await _prayerRepo.selectedHighLatitudeRule();
    final times = await _prayerRepo.prayerTimesFor(coords);
    if (!mounted) return;
    setState(() {
      _coordinates = coords;
      _times = times;
      _method = method;
      _madhab = madhab;
      _highLatitudeRule = highLatitudeRule;
      _noLocation = false;
      _loading = false;
    });
  }

  Future<void> _showManualLocationSheet() async {
    final lang = LanguagePreferenceService.currentLanguage;
    final latController = TextEditingController();
    final lngController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(basicText('enter_location_manually_title', lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(basicText('enter_location_manually_subtitle', lang), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(labelText: basicText('latitude_field_label', lang), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(labelText: basicText('longitude_field_label', lang), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());
                if (lat == null || lng == null) return;
                await _locationService.setManualLocation(lat, lng);
                if (context.mounted) Navigator.pop(context);
                _load();
              },
              child: Text(basicText('save_location_action', lang)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeMethod(String method) async {
    await _prayerRepo.setMethod(method);
    _load();
  }

  Future<void> _changeMadhab(Madhab madhab) async {
    await _prayerRepo.setMadhab(madhab);
    _load();
  }

  Future<void> _changeHighLatitudeRule(String rule) async {
    await _prayerRepo.setHighLatitudeRule(rule);
    _load();
  }

  static const _highLatitudeRuleKeys = {
    'auto': 'hlr_auto_label',
    'middleOfTheNight': 'hlr_middle_of_night_label',
    'seventhOfTheNight': 'hlr_seventh_of_night_label',
    'twilightAngle': 'hlr_twilight_angle_label',
  };

  static const _methodKeys = {
    'muslimWorldLeague': 'method_muslim_world_league',
    'egyptian': 'method_egyptian',
    'karachi': 'method_karachi',
    'ummAlQura': 'method_umm_al_qura',
    'dubai': 'method_dubai',
    'qatar': 'method_qatar',
    'kuwait': 'method_kuwait',
    'moonsightingCommittee': 'method_moonsighting_committee',
    'singapore': 'method_singapore',
    'turkiye': 'method_turkiye',
    'tehran': 'method_tehran',
    'northAmerica': 'method_north_america',
    'morocco': 'method_morocco',
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(
        title: Text(basicText('prayer_times', lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: basicText('calc_method_tooltip', lang),
            onPressed: () => _openSettingsSheet(context),
          ),
        ],
      ),
      body: _loading
          ? AppLoadingView(icon: Icons.access_time_outlined, message: basicText('calculating_prayer_times_message', lang))
          : _noLocation
              ? _NoLocationView(onManualEntry: _showManualLocationSheet, onRetry: _load)
              : _buildTimes(lang),
    ),
    );
  }

  Widget _buildTimes(String lang) {
    final t = _times!;
    final current = t.currentPrayer(date: DateTime.now());
    final next = t.nextPrayer();
    final nextTime = t.timeForPrayer(next);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_coordinates?.isManual == true)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Text(basicText('manual_location_used_banner', lang), style: const TextStyle(fontSize: 11.5, color: AppColors.primaryDark)),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              Text(_prayerNameFor(next, lang), style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 4),
              Text(_formatTime(nextTime), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PrayerRow(label: basicText('prayer_fajr', lang), time: t.fajr, active: current == Prayer.fajr),
        _PrayerRow(label: basicText('prayer_sunrise', lang), time: t.sunrise, active: false),
        _PrayerRow(label: basicText('prayer_dhuhr', lang), time: t.dhuhr, active: current == Prayer.dhuhr),
        _PrayerRow(label: basicText('prayer_asr', lang), time: t.asr, active: current == Prayer.asr),
        _PrayerRow(label: basicText('prayer_maghrib', lang), time: t.maghrib, active: current == Prayer.maghrib),
        _PrayerRow(label: basicText('prayer_isha', lang), time: t.isha, active: current == Prayer.isha),
        const SizedBox(height: 16),
        Text('${basicText('calc_method_label_prefix', lang)}: ${basicText(_methodKeys[_method] ?? '', lang).isEmpty ? _method : basicText(_methodKeys[_method] ?? '', lang)}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        Text(
            '${basicText('asr_madhab_label_prefix', lang)}: ${_madhab == Madhab.hanafi ? basicText('hanafi_label', lang) : basicText('jumhoor_madhab_label', lang)}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
      ],
    );
  }

  String _prayerNameFor(Prayer p, String lang) {
    final key = switch (p) {
      Prayer.fajr => 'prayer_fajr',
      Prayer.sunrise => 'prayer_sunrise',
      Prayer.dhuhr => 'prayer_dhuhr',
      Prayer.asr => 'prayer_asr',
      Prayer.maghrib => 'prayer_maghrib',
      Prayer.isha => 'prayer_isha',
      _ => null,
    };
    if (key == null) return basicText('next_prayer_generic', lang);
    return '${basicText(key, lang)} ${basicText('next_prayer_suffix', lang)}';
  }

  /// `adhan_dart` builds every prayer time as a UTC `DateTime` internally
  /// — reading `.hour`/`.minute` straight off it (as this used to) shows
  /// the UTC clock time, not the phone's local time. `.toLocal()` first.
  String _formatTime(DateTime t) {
    final lang = LanguagePreferenceService.currentLanguage;
    final local = t.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = basicText(local.hour < 12 ? 'am_period_short' : 'pm_period_short', lang);
    return '$hour:$minute $period';
  }

  Future<void> _openSettingsSheet(BuildContext context) async {
    final lang = LanguagePreferenceService.currentLanguage;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(basicText('calc_method_sheet_title', lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              DropdownButton<String>(
                isExpanded: true,
                value: _method,
                items: PrayerTimesRepository.methodNames
                    .map((m) => DropdownMenuItem(value: m, child: Text(basicText(_methodKeys[m] ?? '', lang).isEmpty ? m : basicText(_methodKeys[m] ?? '', lang))))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setSheetState(() => _method = v);
                  _changeMethod(v);
                },
              ),
              const SizedBox(height: 16),
              Text(basicText('asr_madhab_sheet_title', lang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _BorderedOptionTile(
                label: basicText('jumhoor_madhab_label', lang),
                selected: _madhab == Madhab.shafi,
                onTap: () {
                  setSheetState(() => _madhab = Madhab.shafi);
                  _changeMadhab(Madhab.shafi);
                },
              ),
              _BorderedOptionTile(
                label: basicText('hanafi_label', lang),
                selected: _madhab == Madhab.hanafi,
                onTap: () {
                  setSheetState(() => _madhab = Madhab.hanafi);
                  _changeMadhab(Madhab.hanafi);
                },
              ),
              const SizedBox(height: 16),
              Text(basicText('high_latitude_rule_title', lang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(
                basicText('high_latitude_rule_desc', lang),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              DropdownButton<String>(
                isExpanded: true,
                value: _highLatitudeRule,
                items: PrayerTimesRepository.highLatitudeRuleNames
                    .map((r) => DropdownMenuItem(
                        value: r, child: Text(basicText(_highLatitudeRuleKeys[r] ?? '', lang).isEmpty ? r : basicText(_highLatitudeRuleKeys[r] ?? '', lang))))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setSheetState(() => _highLatitudeRule = v);
                  _changeHighLatitudeRule(v);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showManualLocationSheet();
                },
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: Text(basicText('edit_location_manually_action', lang)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool active;
  const _PrayerRow({required this.label, required this.time, required this.active});

  String _formatTime(DateTime t) {
    final lang = LanguagePreferenceService.currentLanguage;
    final local = t.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = basicText(local.hour < 12 ? 'am_period_short' : 'pm_period_short', lang);
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? AppColors.primary : AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? AppColors.primaryDark : AppColors.textDark)),
          Text(_formatTime(time), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? AppColors.primaryDark : AppColors.textDark)),
        ],
      ),
    );
  }
}

class _NoLocationView extends StatelessWidget {
  final VoidCallback onManualEntry;
  final VoidCallback onRetry;
  const _NoLocationView({required this.onManualEntry, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(basicText('no_location_title', lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              basicText('no_location_desc', lang),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: Text(basicText('retry_action', lang))),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onManualEntry, child: Text(basicText('enter_location_manually_action', lang))),
          ],
        ),
      ),
    );
  }
}

/// Bordered selectable option button — Ismail's 2026-08-16 decorative-
/// features request (roadmap §4.34 point 3), replacing this screen's
/// `RadioListTile` madhab picker with a bordered-card look closer to the
/// reference app's option buttons. Same selection semantics as before
/// (still just calls `onTap` with the value to select), only the visual
/// presentation changed — and it drops the `RadioListTile`/`groupValue`
/// pair along the way, which was already flagged deprecated.
class _BorderedOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BorderedOptionTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18, color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, color: selected ? AppColors.primaryDark : AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
