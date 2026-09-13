enum SchemaDraft { draft07, draft2019, draft2020 }

extension SchemaDraftX on SchemaDraft {
  String get id {
    switch (this) {
      case SchemaDraft.draft07:
        return 'http://json-schema.org/draft-07/schema#';
      case SchemaDraft.draft2019:
        return 'https://json-schema.org/draft/2019-09/schema';
      case SchemaDraft.draft2020:
        return 'https://json-schema.org/draft/2020-12/schema';
    }
  }

  String get displayName {
    switch (this) {
      case SchemaDraft.draft07:
        return 'Draft-07';
      case SchemaDraft.draft2019:
        return 'Draft 2019-09';
      case SchemaDraft.draft2020:
        return 'Draft 2020-12';
    }
  }

  bool get usesDefsKey => this != SchemaDraft.draft07;
}

enum NumericFormat { integer, number }

enum StringFormat {
  none,
  dateTime,
  date,
  time,
  email,
  uri,
  uuid,
  ipv4,
  ipv6,
  hostname,
}

extension StringFormatX on StringFormat {
  String? get value {
    switch (this) {
      case StringFormat.none:
        return null;
      case StringFormat.dateTime:
        return 'date-time';
      case StringFormat.date:
        return 'date';
      case StringFormat.time:
        return 'time';
      case StringFormat.email:
        return 'email';
      case StringFormat.uri:
        return 'uri';
      case StringFormat.uuid:
        return 'uuid';
      case StringFormat.ipv4:
        return 'ipv4';
      case StringFormat.ipv6:
        return 'ipv6';
      case StringFormat.hostname:
        return 'hostname';
    }
  }

  String get label {
    switch (this) {
      case StringFormat.none:
        return 'None';
      case StringFormat.dateTime:
        return 'date-time';
      case StringFormat.date:
        return 'date';
      case StringFormat.time:
        return 'time';
      case StringFormat.email:
        return 'email';
      case StringFormat.uri:
        return 'uri';
      case StringFormat.uuid:
        return 'uuid';
      case StringFormat.ipv4:
        return 'ipv4';
      case StringFormat.ipv6:
        return 'ipv6';
      case StringFormat.hostname:
        return 'hostname';
    }
  }
}

class SchemaOptions {
  bool addTitle;
  bool addDescription;
  bool addExamples;
  bool addDefaults;
  bool addRequired;
  bool addAdditionalPropertiesFalse;
  bool detectStringFormats;
  bool useDefinitions;
  bool detectEnums;
  int enumThreshold;

  SchemaOptions({
    this.addTitle = true,
    this.addDescription = false,
    this.addExamples = true,
    this.addDefaults = false,
    this.addRequired = true,
    this.addAdditionalPropertiesFalse = false,
    this.detectStringFormats = true,
    this.useDefinitions = true,
    this.detectEnums = false,
    this.enumThreshold = 3,
  });

  SchemaOptions copy() => SchemaOptions(
    addTitle: addTitle,
    addDescription: addDescription,
    addExamples: addExamples,
    addDefaults: addDefaults,
    addRequired: addRequired,
    addAdditionalPropertiesFalse: addAdditionalPropertiesFalse,
    detectStringFormats: detectStringFormats,
    useDefinitions: useDefinitions,
    detectEnums: detectEnums,
    enumThreshold: enumThreshold,
  );
}