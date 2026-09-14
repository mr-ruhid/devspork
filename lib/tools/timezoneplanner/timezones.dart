import 'models.dart';

class TimezoneData {
  TimezoneData._();

  static const List<TimezoneEntry> all = <TimezoneEntry>[
    // UTC-12 to UTC-8
    TimezoneEntry(id: 'Pacific/Baker', city: 'Baker Island', country: 'US Minor Outlying Islands', region: 'Pacific'),
    TimezoneEntry(id: 'Pacific/Honolulu', city: 'Honolulu', country: 'USA', region: 'Pacific'),
    TimezoneEntry(id: 'Pacific/Tahiti', city: 'Tahiti', country: 'French Polynesia', region: 'Pacific'),
    TimezoneEntry(id: 'America/Anchorage', city: 'Anchorage', country: 'USA', region: 'Americas'),
    TimezoneEntry(id: 'America/Los_Angeles', city: 'Los Angeles', country: 'USA', region: 'Americas'),
    TimezoneEntry(id: 'America/Vancouver', city: 'Vancouver', country: 'Canada', region: 'Americas'),
    TimezoneEntry(id: 'America/Tijuana', city: 'Tijuana', country: 'Mexico', region: 'Americas'),
    TimezoneEntry(id: 'America/Phoenix', city: 'Phoenix', country: 'USA', region: 'Americas'),

    // UTC-7 to UTC-5
    TimezoneEntry(id: 'America/Denver', city: 'Denver', country: 'USA', region: 'Americas'),
    TimezoneEntry(id: 'America/Edmonton', city: 'Edmonton', country: 'Canada', region: 'Americas'),
    TimezoneEntry(id: 'America/Chicago', city: 'Chicago', country: 'USA', region: 'Americas'),
    TimezoneEntry(id: 'America/Mexico_City', city: 'Mexico City', country: 'Mexico', region: 'Americas'),
    TimezoneEntry(id: 'America/Winnipeg', city: 'Winnipeg', country: 'Canada', region: 'Americas'),
    TimezoneEntry(id: 'America/New_York', city: 'New York', country: 'USA', region: 'Americas'),
    TimezoneEntry(id: 'America/Toronto', city: 'Toronto', country: 'Canada', region: 'Americas'),
    TimezoneEntry(id: 'America/Bogota', city: 'Bogotá', country: 'Colombia', region: 'Americas'),
    TimezoneEntry(id: 'America/Lima', city: 'Lima', country: 'Peru', region: 'Americas'),
    TimezoneEntry(id: 'America/Panama', city: 'Panama', country: 'Panama', region: 'Americas'),

    // UTC-4 to UTC-3
    TimezoneEntry(id: 'America/Caracas', city: 'Caracas', country: 'Venezuela', region: 'Americas'),
    TimezoneEntry(id: 'America/Halifax', city: 'Halifax', country: 'Canada', region: 'Americas'),
    TimezoneEntry(id: 'America/Santiago', city: 'Santiago', country: 'Chile', region: 'Americas'),
    TimezoneEntry(id: 'America/La_Paz', city: 'La Paz', country: 'Bolivia', region: 'Americas'),
    TimezoneEntry(id: 'America/Sao_Paulo', city: 'São Paulo', country: 'Brazil', region: 'Americas'),
    TimezoneEntry(id: 'America/Buenos_Aires', city: 'Buenos Aires', country: 'Argentina', region: 'Americas'),
    TimezoneEntry(id: 'America/Montevideo', city: 'Montevideo', country: 'Uruguay', region: 'Americas'),

    // UTC-2 to UTC+0
    TimezoneEntry(id: 'Atlantic/South_Georgia', city: 'South Georgia', country: 'UK', region: 'Atlantic'),
    TimezoneEntry(id: 'Atlantic/Azores', city: 'Azores', country: 'Portugal', region: 'Atlantic'),
    TimezoneEntry(id: 'Atlantic/Cape_Verde', city: 'Cape Verde', country: 'Cape Verde', region: 'Atlantic'),
    TimezoneEntry(id: 'UTC', city: 'UTC', country: 'Coordinated Universal Time', region: 'UTC'),
    TimezoneEntry(id: 'Europe/London', city: 'London', country: 'UK', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Dublin', city: 'Dublin', country: 'Ireland', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Lisbon', city: 'Lisbon', country: 'Portugal', region: 'Europe'),
    TimezoneEntry(id: 'Africa/Casablanca', city: 'Casablanca', country: 'Morocco', region: 'Africa'),
    TimezoneEntry(id: 'Africa/Accra', city: 'Accra', country: 'Ghana', region: 'Africa'),

    // UTC+1
    TimezoneEntry(id: 'Europe/Paris', city: 'Paris', country: 'France', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Berlin', city: 'Berlin', country: 'Germany', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Madrid', city: 'Madrid', country: 'Spain', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Rome', city: 'Rome', country: 'Italy', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Amsterdam', city: 'Amsterdam', country: 'Netherlands', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Brussels', city: 'Brussels', country: 'Belgium', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Vienna', city: 'Vienna', country: 'Austria', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Zurich', city: 'Zurich', country: 'Switzerland', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Warsaw', city: 'Warsaw', country: 'Poland', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Prague', city: 'Prague', country: 'Czech Republic', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Budapest', city: 'Budapest', country: 'Hungary', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Stockholm', city: 'Stockholm', country: 'Sweden', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Oslo', city: 'Oslo', country: 'Norway', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Copenhagen', city: 'Copenhagen', country: 'Denmark', region: 'Europe'),
    TimezoneEntry(id: 'Africa/Lagos', city: 'Lagos', country: 'Nigeria', region: 'Africa'),
    TimezoneEntry(id: 'Africa/Algiers', city: 'Algiers', country: 'Algeria', region: 'Africa'),
    TimezoneEntry(id: 'Africa/Tunis', city: 'Tunis', country: 'Tunisia', region: 'Africa'),

    // UTC+2
    TimezoneEntry(id: 'Europe/Athens', city: 'Athens', country: 'Greece', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Helsinki', city: 'Helsinki', country: 'Finland', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Bucharest', city: 'Bucharest', country: 'Romania', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Sofia', city: 'Sofia', country: 'Bulgaria', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Kiev', city: 'Kyiv', country: 'Ukraine', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Riga', city: 'Riga', country: 'Latvia', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Vilnius', city: 'Vilnius', country: 'Lithuania', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Tallinn', city: 'Tallinn', country: 'Estonia', region: 'Europe'),
    TimezoneEntry(id: 'Africa/Cairo', city: 'Cairo', country: 'Egypt', region: 'Africa'),
    TimezoneEntry(id: 'Africa/Johannesburg', city: 'Johannesburg', country: 'South Africa', region: 'Africa'),
    TimezoneEntry(id: 'Africa/Khartoum', city: 'Khartoum', country: 'Sudan', region: 'Africa'),

    // UTC+3
    TimezoneEntry(id: 'Europe/Moscow', city: 'Moscow', country: 'Russia', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Minsk', city: 'Minsk', country: 'Belarus', region: 'Europe'),
    TimezoneEntry(id: 'Europe/Istanbul', city: 'Istanbul', country: 'Türkiye', region: 'Europe'),
    TimezoneEntry(id: 'Asia/Riyadh', city: 'Riyadh', country: 'Saudi Arabia', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Kuwait', city: 'Kuwait City', country: 'Kuwait', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Qatar', city: 'Doha', country: 'Qatar', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Baghdad', city: 'Baghdad', country: 'Iraq', region: 'Asia'),
    TimezoneEntry(id: 'Africa/Nairobi', city: 'Nairobi', country: 'Kenya', region: 'Africa'),
    TimezoneEntry(id: 'Africa/Addis_Ababa', city: 'Addis Ababa', country: 'Ethiopia', region: 'Africa'),

    // UTC+4
    TimezoneEntry(id: 'Asia/Dubai', city: 'Dubai', country: 'UAE', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Muscat', city: 'Muscat', country: 'Oman', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Baku', city: 'Baku', country: 'Azerbaijan', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Tbilisi', city: 'Tbilisi', country: 'Georgia', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Yerevan', city: 'Yerevan', country: 'Armenia', region: 'Asia'),
    TimezoneEntry(id: 'Europe/Samara', city: 'Samara', country: 'Russia', region: 'Europe'),
    TimezoneEntry(id: 'Indian/Mauritius', city: 'Mauritius', country: 'Mauritius', region: 'Indian'),

    // UTC+5 to UTC+5:30
    TimezoneEntry(id: 'Asia/Karachi', city: 'Karachi', country: 'Pakistan', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Tashkent', city: 'Tashkent', country: 'Uzbekistan', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Yekaterinburg', city: 'Yekaterinburg', country: 'Russia', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Kolkata', city: 'Mumbai', country: 'India', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Colombo', city: 'Colombo', country: 'Sri Lanka', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Kathmandu', city: 'Kathmandu', country: 'Nepal', region: 'Asia'),

    // UTC+6 to UTC+7
    TimezoneEntry(id: 'Asia/Dhaka', city: 'Dhaka', country: 'Bangladesh', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Almaty', city: 'Almaty', country: 'Kazakhstan', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Novosibirsk', city: 'Novosibirsk', country: 'Russia', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Bangkok', city: 'Bangkok', country: 'Thailand', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Jakarta', city: 'Jakarta', country: 'Indonesia', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Ho_Chi_Minh', city: 'Ho Chi Minh City', country: 'Vietnam', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Phnom_Penh', city: 'Phnom Penh', country: 'Cambodia', region: 'Asia'),

    // UTC+8
    TimezoneEntry(id: 'Asia/Shanghai', city: 'Shanghai', country: 'China', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Hong_Kong', city: 'Hong Kong', country: 'China', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Taipei', city: 'Taipei', country: 'Taiwan', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Singapore', city: 'Singapore', country: 'Singapore', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Kuala_Lumpur', city: 'Kuala Lumpur', country: 'Malaysia', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Manila', city: 'Manila', country: 'Philippines', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Makassar', city: 'Makassar', country: 'Indonesia', region: 'Asia'),
    TimezoneEntry(id: 'Australia/Perth', city: 'Perth', country: 'Australia', region: 'Australia'),

    // UTC+9
    TimezoneEntry(id: 'Asia/Tokyo', city: 'Tokyo', country: 'Japan', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Seoul', city: 'Seoul', country: 'South Korea', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Pyongyang', city: 'Pyongyang', country: 'North Korea', region: 'Asia'),
    TimezoneEntry(id: 'Asia/Yakutsk', city: 'Yakutsk', country: 'Russia', region: 'Asia'),

    // UTC+9:30 to UTC+10
    TimezoneEntry(id: 'Australia/Darwin', city: 'Darwin', country: 'Australia', region: 'Australia'),
    TimezoneEntry(id: 'Australia/Adelaide', city: 'Adelaide', country: 'Australia', region: 'Australia'),
    TimezoneEntry(id: 'Australia/Brisbane', city: 'Brisbane', country: 'Australia', region: 'Australia'),
    TimezoneEntry(id: 'Australia/Sydney', city: 'Sydney', country: 'Australia', region: 'Australia'),
    TimezoneEntry(id: 'Australia/Melbourne', city: 'Melbourne', country: 'Australia', region: 'Australia'),
    TimezoneEntry(id: 'Pacific/Guam', city: 'Guam', country: 'Guam', region: 'Pacific'),
    TimezoneEntry(id: 'Asia/Vladivostok', city: 'Vladivostok', country: 'Russia', region: 'Asia'),

    // UTC+11 to UTC+12
    TimezoneEntry(id: 'Pacific/Noumea', city: 'Nouméa', country: 'New Caledonia', region: 'Pacific'),
    TimezoneEntry(id: 'Pacific/Norfolk', city: 'Norfolk Island', country: 'Australia', region: 'Pacific'),
    TimezoneEntry(id: 'Pacific/Auckland', city: 'Auckland', country: 'New Zealand', region: 'Pacific'),
    TimezoneEntry(id: 'Pacific/Fiji', city: 'Fiji', country: 'Fiji', region: 'Pacific'),
    TimezoneEntry(id: 'Pacific/Tongatapu', city: 'Nukuʻalofa', country: 'Tonga', region: 'Pacific'),

    // UTC+13 to UTC+14
    TimezoneEntry(id: 'Pacific/Apia', city: 'Apia', country: 'Samoa', region: 'Pacific'),
    TimezoneEntry(id: 'Pacific/Kiritimati', city: 'Kiritimati', country: 'Kiribati', region: 'Pacific'),
  ];

  static const Map<String, int> _standardOffsets = <String, int>{
    'Pacific/Baker': -12,
    'Pacific/Honolulu': -10,
    'Pacific/Tahiti': -10,
    'America/Anchorage': -9,
    'America/Los_Angeles': -8,
    'America/Vancouver': -8,
    'America/Tijuana': -8,
    'America/Phoenix': -7,
    'America/Denver': -7,
    'America/Edmonton': -7,
    'America/Chicago': -6,
    'America/Mexico_City': -6,
    'America/Winnipeg': -6,
    'America/New_York': -5,
    'America/Toronto': -5,
    'America/Bogota': -5,
    'America/Lima': -5,
    'America/Panama': -5,
    'America/Caracas': -4,
    'America/Halifax': -4,
    'America/Santiago': -4,
    'America/La_Paz': -4,
    'America/Sao_Paulo': -3,
    'America/Buenos_Aires': -3,
    'America/Montevideo': -3,
    'Atlantic/South_Georgia': -2,
    'Atlantic/Azores': -1,
    'Atlantic/Cape_Verde': -1,
    'UTC': 0,
    'Europe/London': 0,
    'Europe/Dublin': 0,
    'Europe/Lisbon': 0,
    'Africa/Casablanca': 0,
    'Africa/Accra': 0,
    'Europe/Paris': 1,
    'Europe/Berlin': 1,
    'Europe/Madrid': 1,
    'Europe/Rome': 1,
    'Europe/Amsterdam': 1,
    'Europe/Brussels': 1,
    'Europe/Vienna': 1,
    'Europe/Zurich': 1,
    'Europe/Warsaw': 1,
    'Europe/Prague': 1,
    'Europe/Budapest': 1,
    'Europe/Stockholm': 1,
    'Europe/Oslo': 1,
    'Europe/Copenhagen': 1,
    'Africa/Lagos': 1,
    'Africa/Algiers': 1,
    'Africa/Tunis': 1,
    'Europe/Athens': 2,
    'Europe/Helsinki': 2,
    'Europe/Bucharest': 2,
    'Europe/Sofia': 2,
    'Europe/Kiev': 2,
    'Europe/Riga': 2,
    'Europe/Vilnius': 2,
    'Europe/Tallinn': 2,
    'Africa/Cairo': 2,
    'Africa/Johannesburg': 2,
    'Africa/Khartoum': 2,
    'Europe/Moscow': 3,
    'Europe/Minsk': 3,
    'Europe/Istanbul': 3,
    'Asia/Riyadh': 3,
    'Asia/Kuwait': 3,
    'Asia/Qatar': 3,
    'Asia/Baghdad': 3,
    'Africa/Nairobi': 3,
    'Africa/Addis_Ababa': 3,
    'Asia/Dubai': 4,
    'Asia/Muscat': 4,
    'Asia/Baku': 4,
    'Asia/Tbilisi': 4,
    'Asia/Yerevan': 4,
    'Europe/Samara': 4,
    'Indian/Mauritius': 4,
    'Asia/Karachi': 5,
    'Asia/Tashkent': 5,
    'Asia/Yekaterinburg': 5,
    'Asia/Kolkata': 5,
    'Asia/Colombo': 5,
    'Asia/Kathmandu': 5,
    'Asia/Dhaka': 6,
    'Asia/Almaty': 6,
    'Asia/Novosibirsk': 6,
    'Asia/Bangkok': 7,
    'Asia/Jakarta': 7,
    'Asia/Ho_Chi_Minh': 7,
    'Asia/Phnom_Penh': 7,
    'Asia/Shanghai': 8,
    'Asia/Hong_Kong': 8,
    'Asia/Taipei': 8,
    'Asia/Singapore': 8,
    'Asia/Kuala_Lumpur': 8,
    'Asia/Manila': 8,
    'Asia/Makassar': 8,
    'Australia/Perth': 8,
    'Asia/Tokyo': 9,
    'Asia/Seoul': 9,
    'Asia/Pyongyang': 9,
    'Asia/Yakutsk': 9,
    'Australia/Darwin': 9,
    'Australia/Adelaide': 9,
    'Australia/Brisbane': 10,
    'Australia/Sydney': 10,
    'Australia/Melbourne': 10,
    'Pacific/Guam': 10,
    'Asia/Vladivostok': 10,
    'Pacific/Noumea': 11,
    'Pacific/Norfolk': 11,
    'Pacific/Auckland': 12,
    'Pacific/Fiji': 12,
    'Pacific/Tongatapu': 13,
    'Pacific/Apia': 13,
    'Pacific/Kiritimati': 14,
  };

  static const Map<String, int> _halfHourOffsets = <String, int>{
    'Asia/Kolkata': 30,
    'Asia/Colombo': 30,
    'Asia/Kathmandu': 45,
    'Australia/Darwin': 30,
    'Australia/Adelaide': 30,
    'Pacific/Norfolk': 30,
  };

  static int standardOffsetHours(String id) {
    return _standardOffsets[id] ?? 0;
  }

  static int halfHourMinutes(String id) {
    return _halfHourOffsets[id] ?? 0;
  }

  static int currentOffsetMinutes(String id) {
    final int base = standardOffsetHours(id) * 60;
    final int extra = halfHourMinutes(id);
    return base + extra;
  }

  static List<TimezoneEntry> search(String query, {int limit = 50}) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return all;

    final List<TimezoneEntry> results = <TimezoneEntry>[];
    for (final TimezoneEntry t in all) {
      if (t.city.toLowerCase().contains(q) ||
          t.country.toLowerCase().contains(q) ||
          t.id.toLowerCase().contains(q) ||
          t.region.toLowerCase().contains(q)) {
        results.add(t);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  static TimezoneEntry? findById(String id) {
    for (final TimezoneEntry t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static const List<String> defaults = <String>[
    'Asia/Baku',
    'Europe/London',
    'America/New_York',
  ];
}