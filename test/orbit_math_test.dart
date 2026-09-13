import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:solar_system_flutter/data/planets_data.dart';
import 'package:solar_system_flutter/widgets/solar_system_view.dart';

void main() {
  final mercury = planets.firstWhere((p) => p.name == 'Mercury');
  final earth = planets.firstWhere((p) => p.name == 'Earth');
  final neptune = planets.firstWhere((p) => p.name == 'Neptune');

  group('orbitAngleFor', () {
    test('is deterministic for the same inputs', () {
      final a1 = orbitAngleFor(earth, 12.5);
      final a2 = orbitAngleFor(earth, 12.5);
      expect(a1, a2);
    });

    test('advances linearly with simTime at the planet\'s orbitSpeed', () {
      const dt = 37.0;
      final before = orbitAngleFor(earth, 5.0);
      final after = orbitAngleFor(earth, 5.0 + dt);
      expect(after - before, closeTo(earth.orbitSpeed * dt, 1e-9));
    });

    test('different planets can have different base offsets at simTime 0', () {
      final mercuryAngle = orbitAngleFor(mercury, 0);
      final earthAngle = orbitAngleFor(earth, 0);
      // Not a strict guarantee for all possible names, but true for our
      // current data set and catches an accidental "always 0" regression.
      expect(mercuryAngle == earthAngle, isFalse);
    });
  });

  group('computeZoomTarget', () {
    test('returns the full overview zoom when no planet is focused', () {
      expect(computeZoomTarget(null, planets), 1.0);
    });

    test('returns the full overview zoom for an unknown planet name', () {
      expect(computeZoomTarget('Not A Planet', planets), 1.0);
    });

    test('zooms in more for closer planets than farther ones', () {
      final mercuryZoom = computeZoomTarget('Mercury', planets);
      final neptuneZoom = computeZoomTarget('Neptune', planets);
      expect(mercuryZoom, greaterThan(neptuneZoom));
    });

    test('always stays within the configured clamp range', () {
      for (final planet in planets) {
        final zoom = computeZoomTarget(planet.name, planets);
        expect(zoom, inInclusiveRange(kZoomTargetMin, kZoomTargetMax));
      }
    });
  });

  group('computePanTarget', () {
    test('is the origin when no planet is focused', () {
      expect(computePanTarget(null, planets, 3.0, 0.4), Offset.zero);
    });

    test('is the origin for an unknown planet name', () {
      expect(computePanTarget('Not A Planet', planets, 3.0, 0.4), Offset.zero);
    });

    test('matches manual polar-to-cartesian projection for a known planet', () {
      const simTime = 8.25;
      const viewRotation = 0.9;
      final target = computePanTarget('Earth', planets, simTime, viewRotation);

      final expectedAngle = orbitAngleFor(earth, simTime) + viewRotation;
      final expectedOffset = Offset(
        math.cos(expectedAngle) * earth.distanceFromSun,
        math.sin(expectedAngle) * earth.distanceFromSun,
      );

      expect(target.dx, closeTo(expectedOffset.dx, 1e-9));
      expect(target.dy, closeTo(expectedOffset.dy, 1e-9));
    });

    test('places a farther planet farther from the origin', () {
      final earthTarget = computePanTarget('Earth', planets, 1.0, 0.0);
      final neptuneTarget = computePanTarget('Neptune', planets, 1.0, 0.0);
      expect(neptuneTarget.distance, greaterThan(earthTarget.distance));
      expect(neptuneTarget.distance, closeTo(neptune.distanceFromSun, 1e-9));
    });
  });

  group('moonWorldPosition', () {
    test('rotates together with viewRotation, matching the planet\'s basis', () {
      const simTime = 5.0;
      final atZero = moonWorldPosition(earth, 0, simTime, 0.0);
      final planetAtZero = computePanTarget('Earth', planets, simTime, 0.0);
      final moonOffsetAtZero = atZero - planetAtZero;

      const rotation = math.pi / 2;
      final rotated = moonWorldPosition(earth, 0, simTime, rotation);
      final planetRotated = computePanTarget('Earth', planets, simTime, rotation);
      final moonOffsetRotated = rotated - planetRotated;

      // The moon's offset from its planet should rotate by exactly
      // `rotation`, same as everything else in the scene — it must not stay
      // fixed in the un-rotated frame.
      final expectedOffset = Offset(
        moonOffsetAtZero.dx * math.cos(rotation) - moonOffsetAtZero.dy * math.sin(rotation),
        moonOffsetAtZero.dx * math.sin(rotation) + moonOffsetAtZero.dy * math.cos(rotation),
      );
      expect(moonOffsetRotated.dx, closeTo(expectedOffset.dx, 1e-9));
      expect(moonOffsetRotated.dy, closeTo(expectedOffset.dy, 1e-9));
    });
  });
}
