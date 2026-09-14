enum DockerLanguage {
  flutter,
  node,
  python,
  go,
  rust,
  java,
  dotnet,
  php,
  ruby,
}

extension DockerLanguageX on DockerLanguage {
  String get displayName {
    switch (this) {
      case DockerLanguage.flutter:
        return 'Flutter';
      case DockerLanguage.node:
        return 'Node.js';
      case DockerLanguage.python:
        return 'Python';
      case DockerLanguage.go:
        return 'Go';
      case DockerLanguage.rust:
        return 'Rust';
      case DockerLanguage.java:
        return 'Java';
      case DockerLanguage.dotnet:
        return '.NET';
      case DockerLanguage.php:
        return 'PHP';
      case DockerLanguage.ruby:
        return 'Ruby';
    }
  }

  String get id => name;

  bool get supportsAlpine {
    switch (this) {
      case DockerLanguage.flutter:
      case DockerLanguage.dotnet:
        return false;
      default:
        return true;
    }
  }

  bool get supportsMultiStage {
    return this != DockerLanguage.flutter;
  }
}

enum CicdProvider { github, gitlab, circleci }

extension CicdProviderX on CicdProvider {
  String get displayName {
    switch (this) {
      case CicdProvider.github:
        return 'GitHub Actions';
      case CicdProvider.gitlab:
        return 'GitLab CI';
      case CicdProvider.circleci:
        return 'CircleCI';
    }
  }

  String get fileName {
    switch (this) {
      case CicdProvider.github:
        return '.github/workflows/ci.yml';
      case CicdProvider.gitlab:
        return '.gitlab-ci.yml';
      case CicdProvider.circleci:
        return '.circleci/config.yml';
    }
  }
}

class GitignoreOption {
  final String id;
  final String labelKey;
  final String category;
  final String content;
  final bool isDefault;

  const GitignoreOption({
    required this.id,
    required this.labelKey,
    required this.category,
    required this.content,
    this.isDefault = false,
  });
}

class ComposeServiceDef {
  final String id;
  final String labelKey;
  final String icon;
  final bool hasVolume;
  final bool hasPort;
  final bool hasEnv;

  const ComposeServiceDef({
    required this.id,
    required this.labelKey,
    required this.icon,
    this.hasVolume = true,
    this.hasPort = true,
    this.hasEnv = true,
  });
}

class DevOpsOptions {
  // Dockerfile
  bool multiStage;
  bool useAlpine;
  bool nonRootUser;
  int exposePort;
  bool includeHealthcheck;
  String nodeVersion;
  String pythonVersion;
  String goVersion;
  String javaVersion;
  String dotnetVersion;

  // Compose
  bool includeVolumes;
  bool includeNetworks;
  bool includeRestartPolicy;
  String composeProjectName;

  // CI/CD
  bool includeTest;
  bool includeBuild;
  bool includeDeploy;
  String cicdBranch;
  String cicdRunner;

  DevOpsOptions({
    this.multiStage = true,
    this.useAlpine = false,
    this.nonRootUser = true,
    this.exposePort = 8080,
    this.includeHealthcheck = false,
    this.nodeVersion = '20',
    this.pythonVersion = '3.12',
    this.goVersion = '1.22',
    this.javaVersion = '21',
    this.dotnetVersion = '8.0',
    this.includeVolumes = true,
    this.includeNetworks = true,
    this.includeRestartPolicy = true,
    this.composeProjectName = 'myapp',
    this.includeTest = true,
    this.includeBuild = true,
    this.includeDeploy = false,
    this.cicdBranch = 'main',
    this.cicdRunner = 'ubuntu-latest',
  });

  DevOpsOptions copy() => DevOpsOptions(
    multiStage: multiStage,
    useAlpine: useAlpine,
    nonRootUser: nonRootUser,
    exposePort: exposePort,
    includeHealthcheck: includeHealthcheck,
    nodeVersion: nodeVersion,
    pythonVersion: pythonVersion,
    goVersion: goVersion,
    javaVersion: javaVersion,
    dotnetVersion: dotnetVersion,
    includeVolumes: includeVolumes,
    includeNetworks: includeNetworks,
    includeRestartPolicy: includeRestartPolicy,
    composeProjectName: composeProjectName,
    includeTest: includeTest,
    includeBuild: includeBuild,
    includeDeploy: includeDeploy,
    cicdBranch: cicdBranch,
    cicdRunner: cicdRunner,
  );
}

enum GenerationTab { gitignore, dockerfile, compose, cicd }

extension GenerationTabX on GenerationTab {
  String get labelKey {
    switch (this) {
      case GenerationTab.gitignore:
        return 'devopsgen_tab_gitignore';
      case GenerationTab.dockerfile:
        return 'devopsgen_tab_dockerfile';
      case GenerationTab.compose:
        return 'devopsgen_tab_compose';
      case GenerationTab.cicd:
        return 'devopsgen_tab_cicd';
    }
  }
}