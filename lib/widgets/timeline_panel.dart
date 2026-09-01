import 'package:flutter/material.dart';

import '../data/timeline_data.dart';
import '../models/historical_event.dart';
import '../theme/app_theme.dart';

Color _typeColor(HistoricalEventType type) {
  switch (type) {
    case HistoricalEventType.mission:
      return const Color(0xFF22C55E);
    case HistoricalEventType.discovery:
      return const Color(0xFF3B82F6);
    case HistoricalEventType.theory:
      return const Color(0xFFA855F7);
    case HistoricalEventType.observation:
      return const Color(0xFFF97316);
  }
}

String _typeLabel(HistoricalEventType type) {
  final name = type.name;
  return name[0].toUpperCase() + name.substring(1);
}

class TimelinePanel extends StatelessWidget {
  final ValueChanged<HistoricalEvent> onEventSelect;

  const TimelinePanel({super.key, required this.onEventSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        const Text(
          'Astronomical Timeline',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 20),
        ...historicalEvents.map((event) => _TimelineEntry(
              event: event,
              onTap: () => onEventSelect(event),
            )),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final HistoricalEvent event;
  final VoidCallback onTap;

  const _TimelineEntry({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(event.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.only(top: 4),
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.date,
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _typeLabel(event.type),
                              style: TextStyle(color: color, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
