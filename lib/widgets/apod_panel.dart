import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/apod_entry.dart';
import '../services/apod_service.dart';
import '../theme/app_theme.dart';
import '../utils/external_link.dart';

/// NASA's image host doesn't send CORS headers, which blocks Flutter Web's
/// [Image.network] (it needs to fetch raw bytes, unlike a plain `<img>`
/// tag). Route through a CORS-friendly image proxy on web only — native
/// platforms hit the original URL directly since CORS is a browser-only
/// restriction.
String _displayImageUrl(String originalUrl) {
  if (!kIsWeb) return originalUrl;
  return Uri.https('images.weserv.nl', '/', {'url': originalUrl}).toString();
}

class ApodPanel extends StatefulWidget {
  const ApodPanel({super.key});

  @override
  State<ApodPanel> createState() => _ApodPanelState();
}

class _ApodPanelState extends State<ApodPanel> {
  late Future<ApodEntry> _future;

  @override
  void initState() {
    super.initState();
    _future = ApodService.fetch();
  }

  void _retry() {
    setState(() => _future = ApodService.fetch());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApodEntry>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (snapshot.hasError) {
          return _ErrorState(onRetry: _retry);
        }
        return _ApodContent(entry: snapshot.data!);
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.satellite_alt_outlined, color: Color(0xFF9CA3AF), size: 40),
            const SizedBox(height: 16),
            const Text(
              "Couldn't load today's picture — try again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ApodContent extends StatelessWidget {
  final ApodEntry entry;

  const _ApodContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        const Text(
          'Astronomy Picture of the Day',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(entry.date, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        const SizedBox(height: 16),
        if (entry.mediaType == 'image' && entry.imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                _displayImageUrl(entry.imageUrl),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Today's entry is a video — view it on NASA's site below.",
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          entry.title,
          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600),
        ),
        if (entry.copyright != null) ...[
          const SizedBox(height: 4),
          Text('© ${entry.copyright}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Text(
          entry.explanation,
          style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => openExternalUrl(context, entry.nasaUrl),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('View on NASA.gov'),
        ),
      ],
    );
  }
}
