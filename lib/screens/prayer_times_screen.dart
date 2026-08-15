import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';

import '../repositories/prayer_times_repository.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

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
    final times = await _prayerRepo.prayerTimesFor(coords);
    if (!mounted) return;
    setState(() {
      _coordinates = coords;
      _times = times;
      _method = method;
      _madhab = madhab;
      _noLocation = false;
      _loading = false;
    });
  }

  Future<void> _showManualLocationSheet() async {
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
            const Text('أدخل موقعك يدويًا', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('يُستخدم فقط إذا تعذّر الوصول لموقعك عبر GPS', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'خط العرض (Latitude)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'خط الطول (Longitude)', border: OutlineInputBorder()),
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
              child: const Text('حفظ الموقع'),
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

  static const _methodLabels = {
    'muslimWorldLeague': 'رابطة العالم الإسلامي',
    'egyptian': 'الهيئة المصرية العامة للمساحة',
    'karachi': 'جامعة العلوم الإسلامية، كراتشي',
    'ummAlQura': 'أم القرى، مكة المكرمة',
    'dubai': 'دبي',
    'qatar': 'قطر',
    'kuwait': 'الكويت',
    'moonsightingCommittee': 'لجنة رؤية الهلال',
    'singapore': 'سنغافورة',
    'turkiye': 'تركيا (ديانت)',
    'tehran': 'طهران',
    'northAmerica': 'أمريكا الشمالية (ISNA)',
    'morocco': 'المغرب',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أوقات الصلاة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'طريقة الحساب',
            onPressed: () => _openSettingsSheet(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _noLocation
              ? _NoLocationView(onManualEntry: _showManualLocationSheet, onRetry: _load)
              : _buildTimes(),
    );
  }

  Widget _buildTimes() {
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
            child: const Text('يُستخدم موقع مُدخَل يدويًا', style: TextStyle(fontSize: 11.5, color: AppColors.primaryDark)),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              Text(_prayerNameAr(next), style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 4),
              Text(_formatTime(nextTime), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PrayerRow(label: 'الفجر', time: t.fajr, active: current == Prayer.fajr),
        _PrayerRow(label: 'الشروق', time: t.sunrise, active: false),
        _PrayerRow(label: 'الظهر', time: t.dhuhr, active: current == Prayer.dhuhr),
        _PrayerRow(label: 'العصر', time: t.asr, active: current == Prayer.asr),
        _PrayerRow(label: 'المغرب', time: t.maghrib, active: current == Prayer.maghrib),
        _PrayerRow(label: 'العشاء', time: t.isha, active: current == Prayer.isha),
        const SizedBox(height: 16),
        Text('طريقة الحساب: ${_methodLabels[_method] ?? _method}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        Text('مذهب العصر: ${_madhab == Madhab.hanafi ? "حنفي" : "الجمهور (شافعي/مالكي/حنبلي)"}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
      ],
    );
  }

  String _prayerNameAr(Prayer p) => switch (p) {
        Prayer.fajr => 'الفجر القادم',
        Prayer.sunrise => 'الشروق القادم',
        Prayer.dhuhr => 'الظهر القادم',
        Prayer.asr => 'العصر القادم',
        Prayer.maghrib => 'المغرب القادم',
        Prayer.isha => 'العشاء القادم',
        _ => 'الصلاة القادمة',
      };

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  Future<void> _openSettingsSheet(BuildContext context) async {
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
              const Text('طريقة حساب أوقات الصلاة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              DropdownButton<String>(
                isExpanded: true,
                value: _method,
                items: PrayerTimesRepository.methodNames
                    .map((m) => DropdownMenuItem(value: m, child: Text(_methodLabels[m] ?? m)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setSheetState(() => _method = v);
                  _changeMethod(v);
                },
              ),
              const SizedBox(height: 16),
              const Text('مذهب حساب العصر', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              RadioListTile<Madhab>(
                title: const Text('الجمهور (شافعي/مالكي/حنبلي)'),
                value: Madhab.shafi,
                groupValue: _madhab,
                onChanged: (v) {
                  if (v == null) return;
                  setSheetState(() => _madhab = v);
                  _changeMadhab(v);
                },
              ),
              RadioListTile<Madhab>(
                title: const Text('حنفي'),
                value: Madhab.hanafi,
                groupValue: _madhab,
                onChanged: (v) {
                  if (v == null) return;
                  setSheetState(() => _madhab = v);
                  _changeMadhab(v);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showManualLocationSheet();
                },
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('تعديل الموقع يدويًا'),
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
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'ص' : 'م';
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('لم نتمكن من تحديد موقعك', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text(
              'تحتاج أوقات الصلاة والقبلة إلى موقعك — فعّل خدمة الموقع أو أدخله يدويًا',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onManualEntry, child: const Text('إدخال الموقع يدويًا')),
          ],
        ),
      ),
    );
  }
}
