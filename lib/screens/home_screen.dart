import 'package:flutter/material.dart';

import '../data/planets_data.dart';
import '../models/historical_event.dart';
import '../models/planet.dart';
import '../theme/app_theme.dart';
import '../widgets/controls_bar.dart';
import '../widgets/planet_info_panel.dart';
import '../widgets/quiz_panel.dart';
import '../widgets/solar_system_view.dart';
import '../widgets/timeline_panel.dart';
import '../utils/external_link.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Planet _selectedPlanet = planets[2];
  bool _autoRotate = true;
  HistoricalEvent? _selectedEvent;

  // Bumped on every timeline selection so SolarSystemView can react even if
  // the same planet (or the null "overview") is picked again.
  int _focusToken = 0;
  String? _focusPlanetName;

  void _handleEventSelect(HistoricalEvent event) {
    setState(() {
      _selectedEvent = event;
      _focusToken++;
      _focusPlanetName = event.relatedPlanet;
      if (event.relatedPlanet != null) {
        for (final planet in planets) {
          if (planet.name == event.relatedPlanet) {
            _selectedPlanet = planet;
            break;
          }
        }
      }
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          event.relatedPlanet != null
              ? '${event.title} (${event.date}) — focusing ${event.relatedPlanet}'
              : '${event.title} (${event.date})',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Learn More',
          textColor: AppColors.primary,
          onPressed: () => openExternalUrl(event.wikipediaUrl),
        ),
      ),
    );
  }

  void _openInfoSheet(int initialTab) {
    final isNarrow = MediaQuery.of(context).size.width <= 900;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: isNarrow ? 0.55 : 0.82,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _InfoSheet(
              initialTab: initialTab,
              planet: _selectedPlanet,
              onEventSelect: (event) {
                _handleEventSelect(event);
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    final mainArea = Stack(
      children: [
        Positioned.fill(
          child: SolarSystemView(
            selectedPlanet: _selectedPlanet,
            onSelectPlanet: (p) => setState(() => _selectedPlanet = p),
            autoRotate: _autoRotate,
            focusPlanetName: _focusPlanetName,
            focusToken: _focusToken,
          ),
        ),
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: ControlsBar(
              autoRotate: _autoRotate,
              onToggleAutoRotate: () => setState(() => _autoRotate = !_autoRotate),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _BottomButton(label: 'Planet Info', onTap: () => _openInfoSheet(0)),
                _BottomButton(label: 'Timeline', onTap: () => _openInfoSheet(1)),
                _BottomButton(label: 'Quiz', onTap: () => _openInfoSheet(2)),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(child: mainArea),
                  Container(
                    width: 380,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        left: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: TimelinePanel(onEventSelect: _handleEventSelect),
                        ),
                        if (_selectedEvent != null)
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Selected Event:',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedEvent!.title} (${_selectedEvent!.date})',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )
            : mainArea,
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BottomButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(label),
    );
  }
}

class _InfoSheet extends StatefulWidget {
  final int initialTab;
  final Planet planet;
  final ValueChanged<HistoricalEvent> onEventSelect;

  const _InfoSheet({
    required this.initialTab,
    required this.planet,
    required this.onEventSelect,
  });

  @override
  State<_InfoSheet> createState() => _InfoSheetState();
}

class _InfoSheetState extends State<_InfoSheet> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _TabButton(label: 'Planet Info', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
              const SizedBox(width: 8),
              _TabButton(label: 'Timeline', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
              const SizedBox(width: 8),
              _TabButton(label: 'Quiz', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
            ],
          ),
        ),
        const Divider(height: 20, color: Colors.white12),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [
              PlanetInfoPanel(planet: widget.planet),
              TimelinePanel(onEventSelect: widget.onEventSelect),
              const QuizPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.white24,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
