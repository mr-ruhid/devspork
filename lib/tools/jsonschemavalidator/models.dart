enum ValidationSeverity { error, warning }

class ValidationError {
  final String path;
  final String messageKey;
  final String messageDetail;
  final ValidationSeverity severity;

  const ValidationError({
    required this.path,
    required this.messageKey,
    required this.messageDetail,
    this.severity = ValidationSeverity.error,
  });

  String get displayPath => path.isEmpty ? r'$' : path;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'messageKey': messageKey,
    'messageDetail': messageDetail,
    'severity': severity.name,
  };
}

class ValidationResult {
  final bool valid;
  final List<ValidationError> errors;
  final int checkedNodes;

  const ValidationResult({
    required this.valid,
    required this.errors,
    this.checkedNodes = 0,
  });

  int get errorCount =>
      errors.where((ValidationError e) => e.severity == ValidationSeverity.error).length;

  int get warningCount =>
      errors.where((ValidationError e) => e.severity == ValidationSeverity.warning).length;

  static const ValidationResult empty = ValidationResult(
    valid: true,
    errors: <ValidationError>[],
  );
}

class ValidatorOptions {
  bool checkFormat;
  bool strictTypes;
  bool allowUnknownFormats;

  ValidatorOptions({
    this.checkFormat = true,
    this.strictTypes = true,
    this.allowUnknownFormats = true,
  });

  ValidatorOptions copy() => ValidatorOptions(
    checkFormat: checkFormat,
    strictTypes: strictTypes,
    allowUnknownFormats: allowUnknownFormats,
  );
}