import 'package:flutter/material.dart';

import '../models/planet.dart';
import '../theme/app_theme.dart';
import '../utils/external_link.dart';

class PlanetInfoPanel extends StatelessWidget {
  final Planet planet;

  const PlanetInfoPanel({super.key, required this.planet});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        Text(
          planet.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Quick Facts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.6,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _Fact(label: 'Distance from Sun', value: '${planet.distanceFromSunKm} km'),
            _Fact(label: 'Orbital Period', value: '${planet.orbitalPeriod} Earth days'),
            _Fact(label: 'Surface Temperature', value: '${planet.averageTemp}°C'),
            _Fact(label: 'Diameter', value: '${planet.diameter} km'),
          ],
        ),
        const Divider(height: 40, color: Colors.white24),
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          planet.description,
          style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 16, height: 1.5),
        ),
        const Divider(height: 40, color: Colors.white24),
        Text(
          'Fun Facts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...planet.funFacts.map(
          (fact) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 16)),
                Expanded(
                  child: Text(
                    fact,
                    style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 16, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => openExternalUrl(planet.wikipediaUrl),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Learn More on Wikipedia'),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
