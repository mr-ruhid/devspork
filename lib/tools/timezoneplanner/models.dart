class TimezoneEntry {
  final String id;
  final String city;
  final String country;
  final String region;

  const TimezoneEntry({
    required this.id,
    required this.city,
    required this.country,
    required this.region,
  });
}

class MeetingHour {
  final int utcHour;
  final List<int> localHours;
  final List<bool> inWorking;
  final int workingCount;

  const MeetingHour({
    required this.utcHour,
    required this.localHours,
    required this.inWorking,
    required this.workingCount,
  });

  bool get allWorking =>
      localHours.isNotEmpty && workingCount == localHours.length;

  bool get noneWorking => workingCount == 0;
}

class PlannerOptions {
  int workStart;
  int workEnd;

  PlannerOptions({
    this.workStart = 9,
    this.workEnd = 18,
  }) {
    if (workStart < 0) workStart = 0;
    if (workEnd > 24) workEnd = 24;
    if (workEnd <= workStart) workEnd = workStart + 1;
  }

  PlannerOptions copy() => PlannerOptions(
    workStart: workStart,
    workEnd: workEnd,
  );
}