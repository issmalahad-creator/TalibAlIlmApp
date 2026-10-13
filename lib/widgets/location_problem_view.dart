import 'package:flutter/material.dart';

import '../data/major_cities.dart';
import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);

/// What prayer times and qibla show when no location is available: the
/// exact reason, the one button that fixes it, and «choose your city» as a
/// way that always works offline. Shared by both screens.
class LocationProblemView extends StatelessWidget {
  final LocationProblem? problem;
  final LocationService service;
  final VoidCallback onRetry;
  const LocationProblemView({super.key, required this.problem, required this.service, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final (icon, title, body, action, onAction) = switch (problem) {
      LocationProblem.serviceOff => (
          Icons.location_disabled_rounded,
          'loc_off_title',
          'loc_off_body',
          'loc_off_action',
          () async {
            await service.openLocationSettings();
          },
        ),
      LocationProblem.deniedForever => (
          Icons.lock_outline_rounded,
          'loc_denied_title',
          'loc_denied_forever_body',
          'loc_open_settings',
          () async {
            await service.openAppSettings();
          },
        ),
      LocationProblem.denied => (
          Icons.lock_outline_rounded,
          'loc_denied_title',
          'loc_denied_body',
          'loc_allow_action',
          () async => onRetry(),
        ),
      _ => (
          Icons.gps_not_fixed_rounded,
          'loc_nofix_title',
          'loc_nofix_body',
          'feedback_retry',
          () async => onRetry(),
        ),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(icon, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(_t(title), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_t(body), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.6)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              await onAction();
              // Coming back from the system settings: try again by itself.
              if (problem == LocationProblem.serviceOff || problem == LocationProblem.deniedForever) {
                await Future<void>.delayed(const Duration(milliseconds: 600));
              }
              onRetry();
            },
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: Text(_t(action)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _pickCity(context),
            icon: const Icon(Icons.location_city_rounded, size: 18),
            label: Text(_t('loc_choose_city')),
          ),
        ]),
      ),
    );
  }

  Future<void> _pickCity(BuildContext context) async {
    final city = await showModalBottomSheet<MajorCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CityPicker(),
    );
    if (city == null) return;
    await service.setManualLocation(city.lat, city.lng);
    onRetry();
  }
}

class _CityPicker extends StatefulWidget {
  const _CityPicker();
  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = majorCities
        .where((c) => q.isEmpty || c.ar.contains(q) || c.en.toLowerCase().contains(q) || c.countryAr.contains(q))
        .toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: _t('loc_city_search'),
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              final ar = LanguagePreferenceService.currentLanguage == 'ar';
              return ListTile(
                leading: const Icon(Icons.place_outlined, color: AppColors.primary),
                title: Text(ar ? c.ar : c.en),
                subtitle: Text(ar ? c.countryAr : c.ar, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                onTap: () => Navigator.pop(context, c),
              );
            },
          ),
        ),
      ]),
    );
  }
}
