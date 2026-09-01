import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/planets_data.dart';
import '../models/planet.dart';

class _SpaceMission {
  final String name;
  final Offset start;
  final Offset control;
  final Offset end;
  final bool active;

  const _SpaceMission({
    required this.name,
    required this.start,
    required this.control,
    required this.end,
    required this.active,
  });
}

const List<_SpaceMission> _spaceMissions = [
  _SpaceMission(
    name: 'Voyager 1',
    start: Offset(0, 0),
    control: Offset(20, 15),
    end: Offset(40, 40),
    active: true,
  ),
  _SpaceMission(
    name: 'New Horizons',
    start: Offset(0, 0),
    control: Offset(15, 8),
    end: Offset(30, 30),
    active: true,
  ),
];

class _StarSeed {
  final double dxFrac;
  final double dyFrac;
  final double radius;
  final double twinkleSeed;

  const _StarSeed(this.dxFrac, this.dyFrac, this.radius, this.twinkleSeed);
}

class _AsteroidSeed {
  final double angle;
  final double radius;
  final double size;
  final int textureIndex;

  const _AsteroidSeed(
    this.angle,
    this.radius,
    this.size,
    this.textureIndex,
  );
}

List<_StarSeed> _generateStars(int count) {
  final rnd = math.Random(7);
  return List.generate(count, (_) {
    return _StarSeed(
      rnd.nextDouble(),
      rnd.nextDouble(),
      0.5 + rnd.nextDouble() * 1.3,
      rnd.nextDouble() * math.pi * 2,
    );
  });
}

List<_AsteroidSeed> _generateAsteroids(int count) {
  final rnd = math.Random(11);
  return List.generate(count, (i) {
    final angle = (i / count) * math.pi * 2 + rnd.nextDouble() * 0.05;
    final radius = 18 + rnd.nextDouble() * 2.5;
    final size = 0.08 + rnd.nextDouble() * 0.1;
    final textureIndex = rnd.nextInt(asteroidTextures.length);
    return _AsteroidSeed(angle, radius, size, textureIndex);
  });
}

const double kMaxWorldRadius = 94;

double orbitAngleFor(Planet planet, double simTime) {
  return (planet.name.hashCode % 360) * math.pi / 180 +
      simTime * planet.orbitSpeed;
}

class PlanetHitTarget {
  final Planet planet;
  final Offset center;
  final double radius;

  const PlanetHitTarget(this.planet, this.center, this.radius);
}

class SolarSystemView extends StatefulWidget {
  final Planet selectedPlanet;
  final ValueChanged<Planet> onSelectPlanet;
  final bool autoRotate;

  /// Name of a [Planet] to smoothly pan/zoom the camera to, or null to
  /// return to the full-system overview. Only applied when [focusToken]
  /// changes, so the same planet can be re-focused repeatedly.
  final String? focusPlanetName;
  final int focusToken;

  const SolarSystemView({
    super.key,
    required this.selectedPlanet,
    required this.onSelectPlanet,
    required this.autoRotate,
    this.focusPlanetName,
    this.focusToken = 0,
  });

  @override
  State<SolarSystemView> createState() => _SolarSystemViewState();
}

class _SolarSystemViewState extends State<SolarSystemView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _simTime = 0;

  double _viewRotation = -math.pi / 2.4;
  double _tilt = 0.55;
  double _zoom = 1.0;
  double _zoomTarget = 1.0;
  Offset _panOffset = Offset.zero;
  String? _trackedPlanetName;

  double _scaleStartZoom = 1.0;
  double _rotationStart = 0.0;
  double _tiltStart = 0.55;
  Offset _dragStart = Offset.zero;

  final Map<String, ui.Image> _images = {};
  bool _assetsLoaded = false;

  List<PlanetHitTarget> _hitTargets = [];
  final List<_StarSeed> _stars = _generateStars(240);
  final List<_AsteroidSeed> _asteroids = _generateAsteroids(240);

  @override
  void initState() {
    super.initState();
    _loadImages();
    _applyFocus(widget.focusPlanetName);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant SolarSystemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusToken != oldWidget.focusToken) {
      _applyFocus(widget.focusPlanetName);
    }
  }

  void _applyFocus(String? planetName) {
    _trackedPlanetName = planetName;
    if (planetName == null) {
      _zoomTarget = 1.0;
      return;
    }
    for (final planet in planets) {
      if (planet.name == planetName) {
        _zoomTarget =
            (kMaxWorldRadius / (planet.distanceFromSun + 10)).clamp(0.7, 4.5);
        return;
      }
    }
  }

  Offset _panTarget() {
    final name = _trackedPlanetName;
    if (name == null) return Offset.zero;
    for (final planet in planets) {
      if (planet.name == name) {
        final a = orbitAngleFor(planet, _simTime) + _viewRotation;
        return Offset(
          math.cos(a) * planet.distanceFromSun,
          math.sin(a) * planet.distanceFromSun,
        );
      }
    }
    return Offset.zero;
  }

  Future<void> _loadImages() async {
    final paths = <String>{
      sunTexture,
      saturnRingTexture,
      ...asteroidTextures,
      for (final p in planets) p.texture,
      for (final p in planets)
        for (final m in p.moons) m.texture,
    };
    await Future.wait(paths.map((path) async {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      _images[path] = frame.image;
    }));
    if (mounted) setState(() => _assetsLoaded = true);
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt >= 1) return;

    var changed = false;
    if (widget.autoRotate) {
      _simTime += dt;
      changed = true;
    }

    final lerpT = (dt * 4.0).clamp(0.0, 1.0);
    final newPan = Offset.lerp(_panOffset, _panTarget(), lerpT)!;
    final newZoom = _zoom + (_zoomTarget - _zoom) * lerpT;
    if ((newPan - _panOffset).distance > 0.0005 || (newZoom - _zoom).abs() > 0.0005) {
      _panOffset = newPan;
      _zoom = newZoom;
      changed = true;
    }

    if (changed) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details) {
    final local = details.localPosition;
    PlanetHitTarget? closest;
    double closestDist = double.infinity;
    for (final target in _hitTargets) {
      final dist = (target.center - local).distance;
      final hitRadius = math.max(target.radius + 10, 22.0);
      if (dist <= hitRadius && dist < closestDist) {
        closest = target;
        closestDist = dist;
      }
    }
    if (closest != null) {
      widget.onSelectPlanet(closest.planet);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _trackedPlanetName = null;
    _zoomTarget = _zoom;
    _scaleStartZoom = _zoom;
    _rotationStart = _viewRotation;
    _tiltStart = _tilt;
    _dragStart = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _zoom = (_scaleStartZoom * details.scale).clamp(0.3, 6.0);
      _zoomTarget = _zoom;
      final delta = details.localFocalPoint - _dragStart;
      _viewRotation = _rotationStart + delta.dx * 0.01;
      _tilt = (_tiltStart - delta.dy * 0.0025).clamp(0.18, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _handleTapUp,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: SizedBox.expand(
        child: !_assetsLoaded
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            : CustomPaint(
                painter: _SolarSystemPainter(
                  simTime: _simTime,
                  viewRotation: _viewRotation,
                  tilt: _tilt,
                  zoom: _zoom,
                  panOffset: _panOffset,
                  images: _images,
                  selectedPlanet: widget.selectedPlanet,
                  stars: _stars,
                  asteroids: _asteroids,
                  onHitTargets: (targets) => _hitTargets = targets,
                ),
              ),
      ),
    );
  }
}

class _SolarSystemPainter extends CustomPainter {
  final double simTime;
  final double viewRotation;
  final double tilt;
  final double zoom;
  final Offset panOffset;
  final Map<String, ui.Image> images;
  final Planet selectedPlanet;
  final List<_StarSeed> stars;
  final List<_AsteroidSeed> asteroids;
  final ValueChanged<List<PlanetHitTarget>> onHitTargets;

  _SolarSystemPainter({
    required this.simTime,
    required this.viewRotation,
    required this.tilt,
    required this.zoom,
    required this.panOffset,
    required this.images,
    required this.selectedPlanet,
    required this.stars,
    required this.asteroids,
    required this.onHitTargets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final availableRadius = math.min(size.width, size.height) / 2 - 20;
    final basePxPerUnit = availableRadius / kMaxWorldRadius;
    final scale = basePxPerUnit * zoom;

    Offset project(double angle, double radius, {double heightOffset = 0}) {
      final a = angle + viewRotation;
      final wx = math.cos(a) * radius - panOffset.dx;
      final wz = math.sin(a) * radius - panOffset.dy;
      final sy = wz * tilt - heightOffset * tilt;
      return center + Offset(wx, sy) * scale;
    }

    _drawBackground(canvas, size);
    _drawStars(canvas, size);

    for (final planet in planets) {
      _drawOrbitPath(canvas, project, planet);
    }
    _drawAsteroidBelt(canvas, project);
    _drawMissions(canvas, project);

    final sunScreenPos = project(0, 0);
    _drawSun(canvas, sunScreenPos, scale);

    final hitTargets = <PlanetHitTarget>[];
    final drawList = <_PlanetDrawInfo>[];
    for (final planet in planets) {
      final screenPos =
          project(orbitAngleFor(planet, simTime), planet.distanceFromSun);
      final radiusPx = math.max(planet.size * scale, 6.0);
      drawList.add(_PlanetDrawInfo(planet, screenPos, radiusPx));
    }
    drawList.sort((a, b) => a.screenPos.dy.compareTo(b.screenPos.dy));

    for (final info in drawList) {
      _drawPlanet(canvas, info, center, sunScreenPos, scale);
      hitTargets.add(
        PlanetHitTarget(info.planet, info.screenPos, info.radiusPx),
      );
    }
    onHitTargets(hitTargets);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.radial(
      size.center(Offset.zero),
      size.longestSide * 0.75,
      [const Color(0xFF10071F), const Color(0xFF020204)],
    );
    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final star in stars) {
      final twinkle =
          0.55 + 0.45 * math.sin(simTime * 1.5 + star.twinkleSeed);
      paint.color = Colors.white.withValues(alpha: twinkle.clamp(0.15, 1.0));
      canvas.drawCircle(
        Offset(star.dxFrac * size.width, star.dyFrac * size.height),
        star.radius,
        paint,
      );
    }
  }

  void _drawOrbitPath(
    Canvas canvas,
    Offset Function(double, double, {double heightOffset}) project,
    Planet planet,
  ) {
    final isSelected = planet.name == selectedPlanet.name;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.6 : 1.0
      ..color = (isSelected ? const Color(0xFF4A9EFF) : Colors.white)
          .withValues(alpha: isSelected ? 0.55 : 0.22);

    final path = Path();
    const segments = 128;
    for (int i = 0; i <= segments; i++) {
      final theta = (i / segments) * math.pi * 2;
      final p = project(theta, planet.distanceFromSun);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawAsteroidBelt(
    Canvas canvas,
    Offset Function(double, double, {double heightOffset}) project,
  ) {
    for (final asteroid in asteroids) {
      final image = images[asteroidTextures[asteroid.textureIndex]];
      if (image == null) continue;
      final p = project(asteroid.angle, asteroid.radius);
      final r = math.max(asteroid.size * 14, 1.2);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      final clip = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
      canvas.clipPath(clip);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCircle(center: Offset.zero, radius: r),
        Paint()..filterQuality = FilterQuality.low,
      );
      canvas.restore();
    }
  }

  void _drawMissions(
    Canvas canvas,
    Offset Function(double, double, {double heightOffset}) project,
  ) {
    for (final mission in _spaceMissions) {
      final points = <Offset>[];
      const steps = 48;
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        final mt = 1 - t;
        final x = mt * mt * mission.start.dx +
            2 * mt * t * mission.control.dx +
            t * t * mission.end.dx;
        final z = mt * mt * mission.start.dy +
            2 * mt * t * mission.control.dy +
            t * t * mission.end.dy;
        final angle = math.atan2(z, x);
        final radius = math.sqrt(x * x + z * z);
        points.add(project(angle, radius));
      }
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      final color = mission.active ? const Color(0xFF00FF6A) : const Color(0xFF666666);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: 0.5),
      );

      final t = (simTime * 0.1) % 1;
      final mt = 1 - t;
      final mx = mt * mt * mission.start.dx +
          2 * mt * t * mission.control.dx +
          t * t * mission.end.dx;
      final mz = mt * mt * mission.start.dy +
          2 * mt * t * mission.control.dy +
          t * t * mission.end.dy;
      final markerAngle = math.atan2(mz, mx);
      final markerRadius = math.sqrt(mx * mx + mz * mz);
      final markerPos = project(markerAngle, markerRadius);
      canvas.drawCircle(markerPos, 3, Paint()..color = color);
    }
  }

  void _drawSun(Canvas canvas, Offset center, double scale) {
    final glowRadius = math.max(2.0 * scale * 2.2, 30.0);
    final glow = ui.Gradient.radial(
      center,
      glowRadius,
      [
        const Color(0xFFFDB813).withValues(alpha: 0.55),
        const Color(0xFFFDB813).withValues(alpha: 0.0),
      ],
    );
    canvas.drawCircle(center, glowRadius, Paint()..shader = glow);

    final image = images[sunTexture];
    final radius = math.max(2.0 * scale, 16.0);
    if (image != null) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      final clip = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: radius));
      canvas.clipPath(clip);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCircle(center: Offset.zero, radius: radius),
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFFDB813));
    }
  }

  void _drawPlanet(
    Canvas canvas,
    _PlanetDrawInfo info,
    Offset canvasCenter,
    Offset sunScreenPos,
    double scale,
  ) {
    final planet = info.planet;
    final isSelected = planet.name == selectedPlanet.name;
    final center = info.screenPos;
    final radius = info.radiusPx;

    if (isSelected) {
      canvas.drawCircle(
        center,
        radius + 6,
        Paint()
          ..color = const Color(0xFF4A9EFF).withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    if (planet.name == 'Saturn') {
      final ringImage = images[saturnRingTexture];
      if (ringImage != null) {
        _drawSaturnRing(canvas, ringImage, center, radius * 2.3);
      }
    }

    final image = images[planet.texture];
    final lightDir = (sunScreenPos - center);
    final lightDirNorm = lightDir.distance == 0
        ? const Offset(0, -1)
        : lightDir / lightDir.distance;
    final spin = simTime * planet.rotationSpeed * 6;

    if (image != null) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(spin);
      final clip = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: radius));
      canvas.clipPath(clip);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCircle(center: Offset.zero, radius: radius),
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();

      final shadeCenter = center - lightDirNorm * radius * 0.7;
      final shadeGradient = ui.Gradient.radial(
        shadeCenter,
        radius * 2.0,
        [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = shadeGradient
          ..blendMode = BlendMode.multiply,
      );

      if (isSelected) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = const Color(0xFF4A9EFF),
        );
      }
    } else {
      canvas.drawCircle(center, radius, Paint()..color = Colors.grey);
    }

    for (int i = 0; i < planet.moons.length; i++) {
      final moon = planet.moons[i];
      final moonAngle = simTime * (planet.orbitSpeed * 5 + 0.2) +
          (2 * math.pi * i / planet.moons.length);
      final moonWorldAngle = orbitAngleFor(planet, simTime);
      final baseA = moonWorldAngle + viewRotation;
      final planetWorldX = math.cos(baseA) * planet.distanceFromSun;
      final planetWorldZ = math.sin(baseA) * planet.distanceFromSun;
      final ma = moonAngle;
      final moonWorldX = planetWorldX + math.cos(ma) * moon.distance;
      final moonWorldZ = planetWorldZ + math.sin(ma) * moon.distance;
      final sx = moonWorldX - panOffset.dx;
      final sy = (moonWorldZ - panOffset.dy) * tilt;
      final moonPos = canvasCenter + Offset(sx, sy) * scale;
      final moonImage = images[moon.texture];
      final moonRadius = math.max(moon.size * scale, 2.5);
      if (moonImage != null) {
        canvas.save();
        canvas.translate(moonPos.dx, moonPos.dy);
        final clip = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: moonRadius));
        canvas.clipPath(clip);
        canvas.drawImageRect(
          moonImage,
          Rect.fromLTWH(0, 0, moonImage.width.toDouble(), moonImage.height.toDouble()),
          Rect.fromCircle(center: Offset.zero, radius: moonRadius),
          Paint()..filterQuality = FilterQuality.medium,
        );
        canvas.restore();
      }
    }
  }

  void _drawSaturnRing(Canvas canvas, ui.Image ringImage, Offset center, double rx) {
    final ry = rx * 0.34;
    final outer = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    final inner = Rect.fromCenter(
      center: center,
      width: rx * 2 * 0.6,
      height: ry * 2 * 0.6,
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addOval(outer),
      Path()..addOval(inner),
    );
    canvas.save();
    canvas.clipPath(path);
    canvas.drawImageRect(
      ringImage,
      Rect.fromLTWH(0, 0, ringImage.width.toDouble(), ringImage.height.toDouble()),
      outer,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SolarSystemPainter oldDelegate) {
    return oldDelegate.simTime != simTime ||
        oldDelegate.viewRotation != viewRotation ||
        oldDelegate.tilt != tilt ||
        oldDelegate.zoom != zoom ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.selectedPlanet.name != selectedPlanet.name;
  }
}

class _PlanetDrawInfo {
  final Planet planet;
  final Offset screenPos;
  final double radiusPx;

  _PlanetDrawInfo(this.planet, this.screenPos, this.radiusPx);
}
