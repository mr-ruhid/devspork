enum CronField {
  minute,
  hour,
  dayOfMonth,
  month,
  dayOfWeek,
}

extension CronFieldX on CronField {
  int get minValue {
    switch (this) {
      case CronField.minute:
        return 0;
      case CronField.hour:
        return 0;
      case CronField.dayOfMonth:
        return 1;
      case CronField.month:
        return 1;
      case CronField.dayOfWeek:
        return 0;
    }
  }

  int get maxValue {
    switch (this) {
      case CronField.minute:
        return 59;
      case CronField.hour:
        return 23;
      case CronField.dayOfMonth:
        return 31;
      case CronField.month:
        return 12;
      case CronField.dayOfWeek:
        return 6;
    }
  }

  String get labelKey {
    switch (this) {
      case CronField.minute:
        return 'cronbuilder_field_minute';
      case CronField.hour:
        return 'cronbuilder_field_hour';
      case CronField.dayOfMonth:
        return 'cronbuilder_field_dom';
      case CronField.month:
        return 'cronbuilder_field_month';
      case CronField.dayOfWeek:
        return 'cronbuilder_field_dow';
    }
  }

  String get shortLabel {
    switch (this) {
      case CronField.minute:
        return 'min';
      case CronField.hour:
        return 'hour';
      case CronField.dayOfMonth:
        return 'dom';
      case CronField.month:
        return 'month';
      case CronField.dayOfWeek:
        return 'dow';
    }
  }

  String? get aliasList {
    switch (this) {
      case CronField.month:
        return 'JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC';
      case CronField.dayOfWeek:
        return 'SUN,MON,TUE,WED,THU,FRI,SAT';
      default:
        return null;
    }
  }
}

enum CronFieldMode {
  any,
  specific,
  range,
  step,
  list,
}

extension CronFieldModeX on CronFieldMode {
  String get labelKey {
    switch (this) {
      case CronFieldMode.any:
        return 'cronbuilder_mode_any';
      case CronFieldMode.specific:
        return 'cronbuilder_mode_specific';
      case CronFieldMode.range:
        return 'cronbuilder_mode_range';
      case CronFieldMode.step:
        return 'cronbuilder_mode_step';
      case CronFieldMode.list:
        return 'cronbuilder_mode_list';
    }
  }
}

class CronFieldConfig {
  CronFieldMode mode;
  int specificValue;
  int rangeFrom;
  int rangeTo;
  int stepEvery;
  int stepFrom;
  List<int> listValues;

  CronFieldConfig({
    required CronField field,
    this.mode = CronFieldMode.any,
    int? specificValue,
    int? rangeFrom,
    int? rangeTo,
    int? stepEvery,
    int? stepFrom,
    List<int>? listValues,
  })  : specificValue = specificValue ?? field.minValue,
        rangeFrom = rangeFrom ?? field.minValue,
        rangeTo = rangeTo ?? field.maxValue,
        stepEvery = stepEvery ?? 5,
        stepFrom = stepFrom ?? field.minValue,
        listValues = listValues ?? <int>[field.minValue];

  CronFieldConfig copyFor(CronField field) => CronFieldConfig(
    field: field,
    mode: mode,
    specificValue: specificValue,
    rangeFrom: rangeFrom,
    rangeTo: rangeTo,
    stepEvery: stepEvery,
    stepFrom: stepFrom,
    listValues: List<int>.from(listValues),
  );
}

class CronPreset {
  final String nameKey;
  final String expression;

  const CronPreset({
    required this.nameKey,
    required this.expression,
  });
}

const List<CronPreset> kCronPresets = <CronPreset>[
  CronPreset(
    nameKey: 'cronbuilder_preset_every_minute',
    expression: '* * * * *',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_every_5_minutes',
    expression: '*/5 * * * *',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_every_15_minutes',
    expression: '*/15 * * * *',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_every_30_minutes',
    expression: '*/30 * * * *',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_hourly',
    expression: '0 * * * *',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_daily_midnight',
    expression: '0 0 * * *',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_daily_9am',
    expression: '0 9 * * *',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_weekly_monday',
    expression: '0 0 * * 1',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_monthly_first',
    expression: '0 0 1 * *',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_yearly',
    expression: '0 0 1 1 *',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_weekdays_9am',
    expression: '0 9 * * 1-5',
  ),
  CronPreset(
    nameKey: 'cronbuilder_preset_weekends_noon',
    expression: '0 12 * * 0,6',
  ),
];

const Map<int, String> kMonthNames = <int, String>{
  1: 'Jan',
  2: 'Feb',
  3: 'Mar',
  4: 'Apr',
  5: 'May',
  6: 'Jun',
  7: 'Jul',
  8: 'Aug',
  9: 'Sep',
  10: 'Oct',
  11: 'Nov',
  12: 'Dec',
};

const Map<int, String> kDayNames = <int, String>{
  0: 'Sun',
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
};