class Moon {
  final String name;
  final double size;
  final double distance;
  final String texture;

  const Moon({
    required this.name,
    required this.size,
    required this.distance,
    required this.texture,
  });
}

class Planet {
  final String name;
  final double size;
  final double distanceFromSun;
  final String distanceFromSunKm;
  final double orbitalPeriod;
  final int diameter;
  final int averageTemp;
  final double rotationSpeed;
  final double orbitSpeed;
  final String texture;
  final String description;
  final List<String> funFacts;
  final List<Moon> moons;
  final String wikipediaUrl;

  const Planet({
    required this.name,
    required this.size,
    required this.distanceFromSun,
    required this.distanceFromSunKm,
    required this.orbitalPeriod,
    required this.diameter,
    required this.averageTemp,
    required this.rotationSpeed,
    required this.orbitSpeed,
    required this.texture,
    required this.description,
    required this.funFacts,
    required this.wikipediaUrl,
    this.moons = const [],
  });
}
