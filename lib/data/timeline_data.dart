import '../models/historical_event.dart';

const List<HistoricalEvent> historicalEvents = [
  HistoricalEvent(
    date: '1543',
    title: 'Heliocentric Theory',
    description:
        'Nicolaus Copernicus publishes his heliocentric theory, placing the Sun at the center of the universe.',
    type: HistoricalEventType.theory,
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Heliocentrism',
  ),
  HistoricalEvent(
    date: '1610',
    title: "Galileo's Observations",
    description:
        "Galileo Galilei discovers Jupiter's four largest moons using his telescope.",
    type: HistoricalEventType.discovery,
    relatedPlanet: 'Jupiter',
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Galileo_Galilei',
  ),
  HistoricalEvent(
    date: '1687',
    title: "Newton's Laws",
    description:
        'Isaac Newton publishes Principia, explaining universal gravitation and laws of motion.',
    type: HistoricalEventType.theory,
    wikipediaUrl: "https://en.wikipedia.org/wiki/Newton's_laws_of_motion",
  ),
  HistoricalEvent(
    date: '1781',
    title: 'Discovery of Uranus',
    description:
        'William Herschel discovers Uranus, the first planet found using a telescope.',
    type: HistoricalEventType.discovery,
    relatedPlanet: 'Uranus',
    wikipediaUrl: 'https://en.wikipedia.org/wiki/William_Herschel',
  ),
  HistoricalEvent(
    date: '1846',
    title: 'Discovery of Neptune',
    description:
        'Neptune is discovered through mathematical predictions by Urbain Le Verrier.',
    type: HistoricalEventType.discovery,
    relatedPlanet: 'Neptune',
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Discovery_of_Neptune',
  ),
  HistoricalEvent(
    date: '1957',
    title: 'Sputnik 1',
    description:
        'First artificial satellite launched into Earth orbit by the Soviet Union.',
    type: HistoricalEventType.mission,
    relatedPlanet: 'Earth',
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Sputnik_1',
  ),
  HistoricalEvent(
    date: '1961',
    title: 'First Human in Space',
    description: 'Yuri Gagarin becomes the first human to orbit Earth.',
    type: HistoricalEventType.mission,
    relatedPlanet: 'Earth',
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Vostok_1',
  ),
  HistoricalEvent(
    date: '1969',
    title: 'Moon Landing',
    description:
        'Apollo 11 mission successfully lands humans on the Moon for the first time.',
    type: HistoricalEventType.mission,
    relatedPlanet: 'Earth',
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Apollo_11',
  ),
  HistoricalEvent(
    date: '1977',
    title: 'Voyager Missions',
    description:
        'Launch of Voyager 1 & 2, which would become the first human-made objects to enter interstellar space.',
    type: HistoricalEventType.mission,
    relatedPlanet: 'Jupiter',
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Voyager_program',
  ),
  HistoricalEvent(
    date: '1990',
    title: 'Hubble Launch',
    description:
        'The Hubble Space Telescope is launched, revolutionizing our view of the cosmos.',
    type: HistoricalEventType.mission,
    relatedPlanet: 'Earth',
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Hubble_Space_Telescope',
  ),
  HistoricalEvent(
    date: '2006',
    title: "Pluto's Reclassification",
    description:
        'Pluto is reclassified as a dwarf planet by the International Astronomical Union.',
    type: HistoricalEventType.discovery,
    relatedPlanet: 'Pluto',
    wikipediaUrl: 'https://en.wikipedia.org/wiki/IAU_definition_of_planet',
  ),
  HistoricalEvent(
    date: '2015',
    title: 'Pluto Flyby',
    description:
        "NASA's New Horizons spacecraft completes its historic flyby of Pluto.",
    type: HistoricalEventType.mission,
    relatedPlanet: 'Pluto',
    wikipediaUrl: 'https://en.wikipedia.org/wiki/New_Horizons',
  ),
  HistoricalEvent(
    date: '2019',
    title: 'First Black Hole Image',
    description:
        'First-ever image of a black hole is captured by the Event Horizon Telescope.',
    type: HistoricalEventType.observation,
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Event_Horizon_Telescope',
  ),
];
