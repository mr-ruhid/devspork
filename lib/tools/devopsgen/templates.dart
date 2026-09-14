import 'models.dart';

class GitignoreTemplates {
  GitignoreTemplates._();

  static const List<GitignoreOption> all = <GitignoreOption>[
    // ---------- OS ----------
    GitignoreOption(
      id: 'macos',
      labelKey: 'devopsgen_gi_macos',
      category: 'os',
      isDefault: true,
      content: '''# macOS
.DS_Store
.AppleDouble
.LSOverride
._*
.Spotlight-V100
.Trashes
.fseventsd
''',
    ),
    GitignoreOption(
      id: 'windows',
      labelKey: 'devopsgen_gi_windows',
      category: 'os',
      isDefault: true,
      content: '''# Windows
Thumbs.db
Thumbs.db:encryptable
ehthumbs.db
ehthumbs_vista.db
Desktop.ini
\$RECYCLE.BIN/
*.lnk
*.cab
*.msi
*.msm
*.msp
''',
    ),
    GitignoreOption(
      id: 'linux',
      labelKey: 'devopsgen_gi_linux',
      category: 'os',
      isDefault: true,
      content: '''# Linux
*~
.fuse_hidden*
.directory
.Trash-*
.nfs*
''',
    ),
    GitignoreOption(
      id: 'jetbrains',
      labelKey: 'devopsgen_gi_jetbrains',
      category: 'os',
      isDefault: true,
      content: '''# JetBrains
.idea/
*.iml
*.ipr
*.iws
out/
''',
    ),
    GitignoreOption(
      id: 'vscode',
      labelKey: 'devopsgen_gi_vscode',
      category: 'os',
      isDefault: true,
      content: '''# VS Code
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
*.code-workspace
''',
    ),

    // ---------- Flutter / Dart ----------
    GitignoreOption(
      id: 'flutter',
      labelKey: 'devopsgen_gi_flutter',
      category: 'flutter',
      content: '''# Flutter/Dart/Pub
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/
.pub/
/build/
coverage/
''',
    ),
    GitignoreOption(
      id: 'flutter_android',
      labelKey: 'devopsgen_gi_flutter_android',
      category: 'flutter',
      content: '''# Flutter - Android
**/android/**/gradle-wrapper.jar
**/android/.gradle
**/android/captures/
**/android/gradlew
**/android/gradlew.bat
**/android/local.properties
**/android/**/GeneratedPluginRegistrant.java
**/android/key.properties
*.jks
*.keystore
''',
    ),
    GitignoreOption(
      id: 'flutter_ios',
      labelKey: 'devopsgen_gi_flutter_ios',
      category: 'flutter',
      content: '''# Flutter - iOS
**/ios/**/*.mode1v3
**/ios/**/*.mode2v3
**/ios/**/*.moved-aside
**/ios/**/*.pbxuser
**/ios/**/*.perspectivev3
**/ios/**/*sync/
**/ios/**/.sconsign.dblite
**/ios/**/.tags*
**/ios/**/.vagrant/
**/ios/**/DerivedData/
**/ios/**/Icon?
**/ios/**/Pods/
**/ios/**/.symlinks/
**/ios/**/profile
**/ios/**/xcuserdata
**/ios/.generated/
**/ios/Flutter/App.framework
**/ios/Flutter/Flutter.framework
**/ios/Flutter/Flutter.podspec
**/ios/Flutter/Generated.xcconfig
**/ios/Flutter/ephemeral/
**/ios/Flutter/app.flx
**/ios/Flutter/app.zip
**/ios/Flutter/flutter_assets/
**/ios/Flutter/flutter_export_environment.sh
**/ios/ServiceDefinitions.json
**/ios/Runner/GeneratedPluginRegistrant.*
''',
    ),
    GitignoreOption(
      id: 'flutter_windows',
      labelKey: 'devopsgen_gi_flutter_windows',
      category: 'flutter',
      content: '''# Flutter - Windows
**/windows/flutter/ephemeral/
**/windows/flutter/generated_plugin_registrant.h
**/windows/flutter/generated_plugin_registrant.cc
**/windows/flutter/generated_plugins.cmake
''',
    ),

    // ---------- Node ----------
    GitignoreOption(
      id: 'node',
      labelKey: 'devopsgen_gi_node',
      category: 'node',
      content: '''# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
.pnpm-store/
.npm/
.yarn/cache
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
.pnp.*
''',
    ),
    GitignoreOption(
      id: 'node_env',
      labelKey: 'devopsgen_gi_node_env',
      category: 'node',
      content: '''# Node - Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
''',
    ),
    GitignoreOption(
      id: 'node_build',
      labelKey: 'devopsgen_gi_node_build',
      category: 'node',
      content: '''# Node - Build
dist/
build/
.next/
.nuxt/
out/
.cache/
.parcel-cache/
''',
    ),

    // ---------- Python ----------
    GitignoreOption(
      id: 'python',
      labelKey: 'devopsgen_gi_python',
      category: 'python',
      content: '''# Python
__pycache__/
*.py[cod]
*\$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST
''',
    ),
    GitignoreOption(
      id: 'python_venv',
      labelKey: 'devopsgen_gi_python_venv',
      category: 'python',
      content: '''# Python - Virtual environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/
''',
    ),

    // ---------- Go ----------
    GitignoreOption(
      id: 'go',
      labelKey: 'devopsgen_gi_go',
      category: 'go',
      content: '''# Go
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out
vendor/
go.work
go.work.sum
''',
    ),

    // ---------- Rust ----------
    GitignoreOption(
      id: 'rust',
      labelKey: 'devopsgen_gi_rust',
      category: 'rust',
      content: '''# Rust
/target/
**/*.rs.bk
*.pdb
Cargo.lock
''',
    ),

    // ---------- Java ----------
    GitignoreOption(
      id: 'java',
      labelKey: 'devopsgen_gi_java',
      category: 'java',
      content: '''# Java
*.class
*.log
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar
hs_err_pid*
replay_pid*
target/
.gradle/
build/
''',
    ),

    // ---------- .NET ----------
    GitignoreOption(
      id: 'dotnet',
      labelKey: 'devopsgen_gi_dotnet',
      category: 'dotnet',
      content: '''# .NET
bin/
obj/
*.user
*.suo
*.cache
*.dll
*.pdb
*.exe
packages/
.vs/
''',
    ),

    // ---------- Secrets ----------
    GitignoreOption(
      id: 'secrets',
      labelKey: 'devopsgen_gi_secrets',
      category: 'security',
      content: '''# Secrets
*.pem
*.key
*.p12
*.pfx
*.jks
*.keystore
secrets.yaml
secrets.yml
.env
.env.*
!.env.example
''',
    ),

    // ---------- Misc ----------
    GitignoreOption(
      id: 'logs',
      labelKey: 'devopsgen_gi_logs',
      category: 'misc',
      content: '''# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
''',
    ),
    GitignoreOption(
      id: 'coverage',
      labelKey: 'devopsgen_gi_coverage',
      category: 'misc',
      content: '''# Coverage
coverage/
*.lcov
.nyc_output/
htmlcov/
.coverage
.coverage.*
''',
    ),
  ];

  static String build(Set<String> selectedIds) {
    final List<GitignoreOption> selected = all
        .where((GitignoreOption o) => selectedIds.contains(o.id))
        .toList();

    if (selected.isEmpty) return '';

    final StringBuffer sb = StringBuffer();
    sb.writeln('# Generated by DevSpork');
    sb.writeln();

    for (final GitignoreOption opt in selected) {
      sb.writeln(opt.content.trimRight());
      sb.writeln();
    }

    return sb.toString().trimRight();
  }
}

class DockerfileTemplates {
  DockerfileTemplates._();

  static String generate(
      DockerLanguage lang,
      DevOpsOptions opts,
      ) {
    switch (lang) {
      case DockerLanguage.flutter:
        return _flutter(opts);
      case DockerLanguage.node:
        return _node(opts);
      case DockerLanguage.python:
        return _python(opts);
      case DockerLanguage.go:
        return _go(opts);
      case DockerLanguage.rust:
        return _rust(opts);
      case DockerLanguage.java:
        return _java(opts);
      case DockerLanguage.dotnet:
        return _dotnet(opts);
      case DockerLanguage.php:
        return _php(opts);
      case DockerLanguage.ruby:
        return _ruby(opts);
    }
  }

  static String _header() => '# Generated by DevSpork\n\n';

  static String _flutter(DevOpsOptions opts) {
    final StringBuffer sb = StringBuffer();
    sb.write(_header());

    sb.writeln('FROM ghcr.io/cirruslabs/flutter:stable AS build');
    sb.writeln();
    sb.writeln('WORKDIR /app');
    sb.writeln();
    sb.writeln('COPY pubspec.* ./');
    sb.writeln('RUN flutter pub get');
    sb.writeln();
    sb.writeln('COPY . .');
    sb.writeln('RUN flutter build web --release');
    sb.writeln();
    sb.writeln('FROM nginx:alpine');
    sb.writeln('COPY --from=build /app/build/web /usr/share/nginx/html');
    sb.writeln('EXPOSE ${opts.exposePort}');
    sb.writeln('CMD ["nginx", "-g", "daemon off;"]');
    return sb.toString().trimRight();
  }

  static String _node(DevOpsOptions opts) {
    final StringBuffer sb = StringBuffer();
    sb.write(_header());

    final String version = opts.nodeVersion;
    final String baseImage = opts.useAlpine ? 'node:${version}-alpine' : 'node:${version}';

    if (opts.multiStage) {
      sb.writeln('FROM $baseImage AS build');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln();
      sb.writeln('COPY package*.json ./');
      sb.writeln('RUN npm ci');
      sb.writeln();
      sb.writeln('COPY . .');
      sb.writeln('RUN npm run build');
      sb.writeln();
      sb.writeln('FROM $baseImage');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('ENV NODE_ENV=production');
      sb.writeln();
      sb.writeln('COPY package*.json ./');
      sb.writeln('RUN npm ci --omit=dev');
      sb.writeln();
      sb.writeln('COPY --from=build /app/dist ./dist');
    } else {
      sb.writeln('FROM $baseImage');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('ENV NODE_ENV=production');
      sb.writeln();
      sb.writeln('COPY package*.json ./');
      sb.writeln('RUN npm ci --omit=dev');
      sb.writeln();
      sb.writeln('COPY . .');
    }

    if (opts.nonRootUser) {
      sb.writeln();
      sb.writeln('RUN addgroup -S app && adduser -S app -G app');
      sb.writeln('USER app');
    }

    sb.writeln();
    sb.writeln('EXPOSE ${opts.exposePort}');
    if (opts.includeHealthcheck) {
      sb.writeln(
        'HEALTHCHECK --interval=30s --timeout=5s --start-period=10s '
            '--retries=3 CMD wget -qO- http://localhost:${opts.exposePort}/health || exit 1',
      );
    }
    sb.writeln('CMD ["node", "dist/index.js"]');
    return sb.toString().trimRight();
  }

  static String _python(DevOpsOptions opts) {
    final StringBuffer sb = StringBuffer();
    sb.write(_header());

    final String v = opts.pythonVersion;
    final String baseImage = opts.useAlpine ? 'python:${v}-alpine' : 'python:${v}-slim';

    if (opts.multiStage) {
      sb.writeln('FROM $baseImage AS build');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln();
      sb.writeln('COPY requirements.txt .');
      sb.writeln('RUN pip install --no-cache-dir --user -r requirements.txt');
      sb.writeln();
      sb.writeln('FROM $baseImage');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln();
      sb.writeln('COPY --from=build /root/.local /root/.local');
      sb.writeln('ENV PATH=/root/.local/bin:\$PATH');
      sb.writeln();
      sb.writeln('COPY . .');
    } else {
      sb.writeln('FROM $baseImage');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln();
      sb.writeln('COPY requirements.txt .');
      sb.writeln('RUN pip install --no-cache-dir -r requirements.txt');
      sb.writeln();
      sb.writeln('COPY . .');
    }

    if (opts.nonRootUser) {
      sb.writeln();
      sb.writeln('RUN adduser --disabled-password --gecos "" app');
      sb.writeln('USER app');
    }

    sb.writeln();
    sb.writeln('EXPOSE ${opts.exposePort}');
    if (opts.includeHealthcheck) {
      sb.writeln(
        'HEALTHCHECK --interval=30s --timeout=5s --start-period=10s '
            '--retries=3 CMD python -c "import urllib.request; '
            'urllib.request.urlopen(\'http://localhost:${opts.exposePort}/health\')" || exit 1',
      );
    }
    sb.writeln('CMD ["python", "-m", "uvicorn", "main:app", '
        '"--host", "0.0.0.0", "--port", "${opts.exposePort}"]');
    return sb.toString().trimRight();
  }

  static String _go(DevOpsOptions opts) {
    final StringBuffer sb = StringBuffer();
    sb.write(_header());

    final String v = opts.goVersion;

    if (opts.multiStage) {
      sb.writeln('FROM golang:${v}-alpine AS build');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln();
      sb.writeln('COPY go.mod go.sum ./');
      sb.writeln('RUN go mod download');
      sb.writeln();
      sb.writeln('COPY . .');
      sb.writeln('RUN CGO_ENABLED=0 GOOS=linux go build -a '
          '-ldflags "-s -w" -o /app/server .');
      sb.writeln();
      sb.writeln('FROM alpine:latest');
      sb.writeln();
      sb.writeln('RUN apk --no-cache add ca-certificates');
      sb.writeln();
      if (opts.nonRootUser) {
        sb.writeln('RUN addgroup -S app && adduser -S app -G app');
        sb.writeln('USER app');
      }
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('COPY --from=build /app/server ./server');
    } else {
      sb.writeln('FROM golang:${v}-alpine');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln();
      sb.writeln('COPY go.mod go.sum ./');
      sb.writeln('RUN go mod download');
      sb.writeln();
      sb.writeln('COPY . .');
      sb.writeln('RUN CGO_ENABLED=0 go build -o server .');
    }

    sb.writeln();
    sb.writeln('EXPOSE ${opts.exposePort}');
    if (opts.includeHealthcheck) {
      sb.writeln(
        'HEALTHCHECK --interval=30s --timeout=5s --start-period=10s '
            '--retries=3 CMD wget -qO- http://localhost:${opts.exposePort}/health || exit 1',
      );
    }
    sb.writeln('CMD ["./server"]');
    return sb.toString().trimRight();
  }

  static String _rust(DevOpsOptions opts) {
    final StringBuffer sb = StringBuffer();
    sb.write(_header());

    if (opts.multiStage) {
      sb.writeln('FROM rust:1.78 AS build');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln();
      sb.writeln('COPY Cargo.toml Cargo.lock ./');
      sb.writeln('RUN mkdir src && echo "fn main() {}" > src/main.rs');
      sb.writeln('RUN cargo build --release');
      sb.writeln('RUN rm -rf src');
      sb.writeln();
      sb.writeln('COPY . .');
      sb.writeln('RUN cargo build --release');
      sb.writeln();
      sb.writeln('FROM debian:bookworm-slim');
      sb.writeln();
      sb.writeln('RUN apt-get update && apt-get install -y '
          'ca-certificates && rm -rf /var/lib/apt/lists/*');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('COPY --from=build /app/target/release/app ./app');
    } else {
      sb.writeln('FROM rust:1.78');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('COPY . .');
      sb.writeln('RUN cargo build --release');
    }

    sb.writeln();
    sb.writeln('EXPOSE ${opts.exposePort}');
    sb.writeln('CMD ["./app"]');
    return sb.toString().trimRight();
  }

  static String _java(DevOpsOptions opts) {
    final StringBuffer sb = StringBuffer();
    sb.write(_header());

    final String v = opts.javaVersion;
    final String baseImage = opts.useAlpine ? 'eclipse-temurin:${v}-alpine' : 'eclipse-temurin:${v}';

    if (opts.multiStage) {
      sb.writeln('FROM maven:3.9-eclipse-temurin-${v} AS build');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln();
      sb.writeln('COPY pom.xml .');
      sb.writeln('RUN mvn dependency:go-offline');
      sb.writeln();
      sb.writeln('COPY src ./src');
      sb.writeln('RUN mvn package -DskipTests');
      sb.writeln();
      sb.writeln('FROM $baseImage');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('COPY --from=build /app/target/*.jar app.jar');
    } else {
      sb.writeln('FROM $baseImage');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('COPY . .');
      sb.writeln('RUN ./mvnw package -DskipTests');
    }

    sb.writeln();
    sb.writeln('EXPOSE ${opts.exposePort}');
    sb.writeln('CMD ["java", "-jar", "app.jar"]');
    return sb.toString().trimRight();
  }

  static String _dotnet(DevOpsOptions opts) {
    final StringBuffer sb = StringBuffer();
    sb.write(_header());

    final String v = opts.dotnetVersion;

    if (opts.multiStage) {
      sb.writeln('FROM mcr.microsoft.com/dotnet/sdk:${v} AS build');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln();
      sb.writeln('COPY *.csproj ./');
      sb.writeln('RUN dotnet restore');
      sb.writeln();
      sb.writeln('COPY . .');
      sb.writeln('RUN dotnet publish -c Release -o /app/publish '
          '/p:UseAppHost=false');
      sb.writeln();
      sb.writeln('FROM mcr.microsoft.com/dotnet/aspnet:${v}');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('COPY --from=build /app/publish .');
    } else {
      sb.writeln('FROM mcr.microsoft.com/dotnet/sdk:${v}');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('COPY . .');
      sb.writeln('RUN dotnet publish -c Release -o out');
      sb.writeln('WORKDIR /app/out');
    }

    sb.writeln();
    sb.writeln('EXPOSE ${opts.exposePort}');
    sb.writeln('CMD ["dotnet", "app.dll"]');
    return sb.toString().trimRight();
  }

  static String _php(DevOpsOptions opts) {
    final StringBuffer sb = StringBuffer();
    sb.write(_header());

    final String baseImage = opts.useAlpine
        ? 'php:8.3-fpm-alpine'
        : 'php:8.3-fpm';

    if (opts.multiStage) {
      sb.writeln('FROM composer:2 AS build');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('COPY composer.json composer.lock ./');
      sb.writeln('RUN composer install --no-dev --no-scripts --no-autoloader');
      sb.writeln();
      sb.writeln('COPY . .');
      sb.writeln('RUN composer dump-autoload --optimize');
      sb.writeln();
      sb.writeln('FROM $baseImage');
      sb.writeln();
      sb.writeln('WORKDIR /var/www/html');
      sb.writeln('COPY --from=build /app .');
    } else {
      sb.writeln('FROM $baseImage');
      sb.writeln();
      sb.writeln('WORKDIR /var/www/html');
      sb.writeln('COPY . .');
      sb.writeln('RUN composer install --no-dev --optimize-autoloader');
    }

    sb.writeln();
    sb.writeln('EXPOSE ${opts.exposePort}');
    sb.writeln('CMD ["php-fpm"]');
    return sb.toString().trimRight();
  }

  static String _ruby(DevOpsOptions opts) {
    final StringBuffer sb = StringBuffer();
    sb.write(_header());

    final String baseImage = opts.useAlpine
        ? 'ruby:3.3-alpine'
        : 'ruby:3.3-slim';

    if (opts.multiStage) {
      sb.writeln('FROM $baseImage AS build');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln();
      sb.writeln('RUN apk add --no-cache build-base || '
          'apt-get update && apt-get install -y build-essential');
      sb.writeln();
      sb.writeln('COPY Gemfile Gemfile.lock ./');
      sb.writeln('RUN bundle install --without development test');
      sb.writeln();
      sb.writeln('FROM $baseImage');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('COPY --from=build /usr/local/bundle /usr/local/bundle');
      sb.writeln('COPY . .');
    } else {
      sb.writeln('FROM $baseImage');
      sb.writeln();
      sb.writeln('WORKDIR /app');
      sb.writeln('COPY . .');
      sb.writeln('RUN bundle install');
    }

    sb.writeln();
    sb.writeln('EXPOSE ${opts.exposePort}');
    sb.writeln('CMD ["bundle", "exec", "puma", "-p", "${opts.exposePort}"]');
    return sb.toString().trimRight();
  }
}

class ComposeTemplates {
  ComposeTemplates._();

  static const List<ComposeServiceDef> services = <ComposeServiceDef>[
    ComposeServiceDef(
      id: 'app',
      labelKey: 'devopsgen_svc_app',
      icon: '📦',
    ),
    ComposeServiceDef(
      id: 'postgres',
      labelKey: 'devopsgen_svc_postgres',
      icon: '🐘',
    ),
    ComposeServiceDef(
      id: 'mysql',
      labelKey: 'devopsgen_svc_mysql',
      icon: '🐬',
    ),
    ComposeServiceDef(
      id: 'mongodb',
      labelKey: 'devopsgen_svc_mongodb',
      icon: '🍃',
    ),
    ComposeServiceDef(
      id: 'redis',
      labelKey: 'devopsgen_svc_redis',
      icon: '🔴',
    ),
    ComposeServiceDef(
      id: 'nginx',
      labelKey: 'devopsgen_svc_nginx',
      icon: '🌐',
    ),
    ComposeServiceDef(
      id: 'rabbitmq',
      labelKey: 'devopsgen_svc_rabbitmq',
      icon: '🐰',
    ),
    ComposeServiceDef(
      id: 'elasticsearch',
      labelKey: 'devopsgen_svc_elastic',
      icon: '🔍',
    ),
  ];

  static String generate(
      Set<String> selectedServices,
      DevOpsOptions opts,
      ) {
    if (selectedServices.isEmpty) return '';

    final StringBuffer sb = StringBuffer();
    sb.writeln('# Generated by DevSpork');
    sb.writeln('version: "3.9"');
    sb.writeln();
    sb.writeln('services:');

    for (final ComposeServiceDef svc in services) {
      if (!selectedServices.contains(svc.id)) continue;
      _writeService(sb, svc, opts);
    }

    if (opts.includeVolumes) {
      sb.writeln();
      sb.writeln('volumes:');
      if (selectedServices.contains('postgres')) {
        sb.writeln('  postgres_data:');
      }
      if (selectedServices.contains('mysql')) {
        sb.writeln('  mysql_data:');
      }
      if (selectedServices.contains('mongodb')) {
        sb.writeln('  mongodb_data:');
      }
      if (selectedServices.contains('redis')) {
        sb.writeln('  redis_data:');
      }
      if (selectedServices.contains('rabbitmq')) {
        sb.writeln('  rabbitmq_data:');
      }
      if (selectedServices.contains('elasticsearch')) {
        sb.writeln('  elasticsearch_data:');
      }
    }

    if (opts.includeNetworks) {
      sb.writeln();
      sb.writeln('networks:');
      sb.writeln('  default:');
      sb.writeln('    name: ${opts.composeProjectName}_network');
    }

    return sb.toString().trimRight();
  }

  static void _writeService(
      StringBuffer sb,
      ComposeServiceDef svc,
      DevOpsOptions opts,
      ) {
    sb.writeln('  ${svc.id}:');

    switch (svc.id) {
      case 'app':
        sb.writeln('    build:');
        sb.writeln('      context: .');
        sb.writeln('      dockerfile: Dockerfile');
        sb.writeln('    image: ${opts.composeProjectName}_app:latest');
        sb.writeln('    ports:');
        sb.writeln('      - "${opts.exposePort}:${opts.exposePort}"');
        if (opts.includeRestartPolicy) {
          sb.writeln('    restart: unless-stopped');
        }
        sb.writeln('    environment:');
        sb.writeln('      - NODE_ENV=production');
        break;

      case 'postgres':
        sb.writeln('    image: postgres:16-alpine');
        sb.writeln('    ports:');
        sb.writeln('      - "5432:5432"');
        if (opts.includeRestartPolicy) {
          sb.writeln('    restart: unless-stopped');
        }
        sb.writeln('    environment:');
        sb.writeln('      POSTGRES_USER: devuser');
        sb.writeln('      POSTGRES_PASSWORD: devpass');
        sb.writeln('      POSTGRES_DB: devdb');
        if (opts.includeVolumes) {
          sb.writeln('    volumes:');
          sb.writeln('      - postgres_data:/var/lib/postgresql/data');
        }
        break;

      case 'mysql':
        sb.writeln('    image: mysql:8.0');
        sb.writeln('    ports:');
        sb.writeln('      - "3306:3306"');
        if (opts.includeRestartPolicy) {
          sb.writeln('    restart: unless-stopped');
        }
        sb.writeln('    environment:');
        sb.writeln('      MYSQL_ROOT_PASSWORD: rootpass');
        sb.writeln('      MYSQL_DATABASE: devdb');
        sb.writeln('      MYSQL_USER: devuser');
        sb.writeln('      MYSQL_PASSWORD: devpass');
        if (opts.includeVolumes) {
          sb.writeln('    volumes:');
          sb.writeln('      - mysql_data:/var/lib/mysql');
        }
        break;

      case 'mongodb':
        sb.writeln('    image: mongo:7');
        sb.writeln('    ports:');
        sb.writeln('      - "27017:27017"');
        if (opts.includeRestartPolicy) {
          sb.writeln('    restart: unless-stopped');
        }
        sb.writeln('    environment:');
        sb.writeln('      MONGO_INITDB_ROOT_USERNAME: devuser');
        sb.writeln('      MONGO_INITDB_ROOT_PASSWORD: devpass');
        sb.writeln('      MONGO_INITDB_DATABASE: devdb');
        if (opts.includeVolumes) {
          sb.writeln('    volumes:');
          sb.writeln('      - mongodb_data:/data/db');
        }
        break;

      case 'redis':
        sb.writeln('    image: redis:7-alpine');
        sb.writeln('    ports:');
        sb.writeln('      - "6379:6379"');
        if (opts.includeRestartPolicy) {
          sb.writeln('    restart: unless-stopped');
        }
        sb.writeln('    command: redis-server --appendonly yes');
        if (opts.includeVolumes) {
          sb.writeln('    volumes:');
          sb.writeln('      - redis_data:/data');
        }
        break;

      case 'nginx':
        sb.writeln('    image: nginx:alpine');
        sb.writeln('    ports:');
        sb.writeln('      - "80:80"');
        sb.writeln('      - "443:443"');
        if (opts.includeRestartPolicy) {
          sb.writeln('    restart: unless-stopped');
        }
        sb.writeln('    volumes:');
        sb.writeln('      - ./nginx.conf:/etc/nginx/nginx.conf:ro');
        break;

      case 'rabbitmq':
        sb.writeln('    image: rabbitmq:3-management-alpine');
        sb.writeln('    ports:');
        sb.writeln('      - "5672:5672"');
        sb.writeln('      - "15672:15672"');
        if (opts.includeRestartPolicy) {
          sb.writeln('    restart: unless-stopped');
        }
        sb.writeln('    environment:');
        sb.writeln('      RABBITMQ_DEFAULT_USER: devuser');
        sb.writeln('      RABBITMQ_DEFAULT_PASS: devpass');
        if (opts.includeVolumes) {
          sb.writeln('    volumes:');
          sb.writeln('      - rabbitmq_data:/var/lib/rabbitmq');
        }
        break;

      case 'elasticsearch':
        sb.writeln('    image: docker.elastic.co/elasticsearch/elasticsearch:8.13.0');
        sb.writeln('    ports:');
        sb.writeln('      - "9200:9200"');
        if (opts.includeRestartPolicy) {
          sb.writeln('    restart: unless-stopped');
        }
        sb.writeln('    environment:');
        sb.writeln('      - discovery.type=single-node');
        sb.writeln('      - xpack.security.enabled=false');
        sb.writeln('      - ES_JAVA_OPTS=-Xms512m -Xmx512m');
        if (opts.includeVolumes) {
          sb.writeln('    volumes:');
          sb.writeln('      - elasticsearch_data:/usr/share/elasticsearch/data');
        }
        break;
    }
  }
}

class CicdTemplates {
  CicdTemplates._();

  static String generate(
      CicdProvider provider,
      DockerLanguage lang,
      DevOpsOptions opts,
      ) {
    switch (provider) {
      case CicdProvider.github:
        return _github(lang, opts);
      case CicdProvider.gitlab:
        return _gitlab(lang, opts);
      case CicdProvider.circleci:
        return _circleci(lang, opts);
    }
  }

  static String _github(DockerLanguage lang, DevOpsOptions opts) {
    final StringBuffer sb = StringBuffer();
    sb.writeln('# Generated by DevSpork');
    sb.writeln('name: CI');
    sb.writeln();
    sb.writeln('on:');
    sb.writeln('  push:');
    sb.writeln('    branches: [${opts.cicdBranch}]');
    sb.writeln('  pull_request:');
    sb.writeln('    branches: [${opts.cicdBranch}]');
    sb.writeln();
    sb.writeln('jobs:');
    sb.writeln('  build:');
    sb.writeln('    runs-on: ${opts.cicdRunner}');
    sb.writeln();
    sb.writeln('    steps:');
    sb.writeln('      - uses: actions/checkout@v4');
    sb.writeln();

    _writeSetupSteps(sb, lang, opts);

    if (opts.includeTest) {
      _writeTestSteps(sb, lang);
    }

    if (opts.includeBuild) {
      _writeBuildSteps(sb, lang);
    }

    if (opts.includeDeploy) {
      sb.writeln('      - name: Deploy');
      sb.writeln('        run: echo "Add deploy steps here"');
    }

    return sb.toString().trimRight();
  }

  static void _writeSetupSteps(
      StringBuffer sb,
      DockerLanguage lang,
      DevOpsOptions opts,
      ) {
    switch (lang) {
      case DockerLanguage.flutter:
        sb.writeln('      - uses: subosito/flutter-action@v2');
        sb.writeln('        with:');
        sb.writeln('          channel: stable');
        sb.writeln('          cache: true');
        sb.writeln();
        sb.writeln('      - name: Install dependencies');
        sb.writeln('        run: flutter pub get');
        break;
      case DockerLanguage.node:
        sb.writeln('      - uses: actions/setup-node@v4');
        sb.writeln('        with:');
        sb.writeln('          node-version: "${opts.nodeVersion}"');
        sb.writeln('          cache: npm');
        sb.writeln();
        sb.writeln('      - name: Install dependencies');
        sb.writeln('        run: npm ci');
        break;
      case DockerLanguage.python:
        sb.writeln('      - uses: actions/setup-python@v5');
        sb.writeln('        with:');
        sb.writeln('          python-version: "${opts.pythonVersion}"');
        sb.writeln('          cache: pip');
        sb.writeln();
        sb.writeln('      - name: Install dependencies');
        sb.writeln('        run: pip install -r requirements.txt');
        break;
      case DockerLanguage.go:
        sb.writeln('      - uses: actions/setup-go@v5');
        sb.writeln('        with:');
        sb.writeln('          go-version: "${opts.goVersion}"');
        sb.writeln('          cache: true');
        sb.writeln();
        sb.writeln('      - name: Download modules');
        sb.writeln('        run: go mod download');
        break;
      case DockerLanguage.rust:
        sb.writeln('      - uses: dtolnay/rust-toolchain@stable');
        sb.writeln('        with:');
        sb.writeln('          components: rustfmt, clippy');
        sb.writeln();
        sb.writeln('      - uses: Swatinem/rust-cache@v2');
        break;
      case DockerLanguage.java:
        sb.writeln('      - uses: actions/setup-java@v4');
        sb.writeln('        with:');
        sb.writeln('          distribution: temurin');
        sb.writeln('          java-version: "${opts.javaVersion}"');
        sb.writeln('          cache: maven');
        break;
      case DockerLanguage.dotnet:
        sb.writeln('      - uses: actions/setup-dotnet@v4');
        sb.writeln('        with:');
        sb.writeln('          dotnet-version: "${opts.dotnetVersion}"');
        sb.writeln();
        sb.writeln('      - name: Restore');
        sb.writeln('        run: dotnet restore');
        break;
      case DockerLanguage.php:
        sb.writeln('      - uses: shivammathur/setup-php@v2');
        sb.writeln('        with:');
        sb.writeln('          php-version: "8.3"');
        sb.writeln('          tools: composer');
        sb.writeln();
        sb.writeln('      - name: Install dependencies');
        sb.writeln('        run: composer install');
        break;
      case DockerLanguage.ruby:
        sb.writeln('      - uses: ruby/setup-ruby@v1');
        sb.writeln('        with:');
        sb.writeln('          ruby-version: "3.3"');
        sb.writeln('          bundler-cache: true');
        break;
    }
  }

  static void _writeTestSteps(StringBuffer sb, DockerLanguage lang) {
    sb.writeln();
    switch (lang) {
      case DockerLanguage.flutter:
        sb.writeln('      - name: Analyze');
        sb.writeln('        run: flutter analyze');
        sb.writeln();
        sb.writeln('      - name: Test');
        sb.writeln('        run: flutter test');
        break;
      case DockerLanguage.node:
        sb.writeln('      - name: Lint');
        sb.writeln('        run: npm run lint --if-present');
        sb.writeln();
        sb.writeln('      - name: Test');
        sb.writeln('        run: npm test --if-present');
        break;
      case DockerLanguage.python:
        sb.writeln('      - name: Lint');
        sb.writeln('        run: pip install ruff && ruff check .');
        sb.writeln();
        sb.writeln('      - name: Test');
        sb.writeln('        run: pytest || true');
        break;
      case DockerLanguage.go:
        sb.writeln('      - name: Vet');
        sb.writeln('        run: go vet ./...');
        sb.writeln();
        sb.writeln('      - name: Test');
        sb.writeln('        run: go test -v ./...');
        break;
      case DockerLanguage.rust:
        sb.writeln('      - name: Fmt');
        sb.writeln('        run: cargo fmt --check');
        sb.writeln();
        sb.writeln('      - name: Clippy');
        sb.writeln('        run: cargo clippy -- -D warnings');
        sb.writeln();
        sb.writeln('      - name: Test');
        sb.writeln('        run: cargo test');
        break;
      case DockerLanguage.java:
        sb.writeln('      - name: Test');
        sb.writeln('        run: mvn test');
        break;
      case DockerLanguage.dotnet:
        sb.writeln('      - name: Test');
        sb.writeln('        run: dotnet test');
        break;
      case DockerLanguage.php:
        sb.writeln('      - name: Test');
        sb.writeln('        run: vendor/bin/phpunit || true');
        break;
      case DockerLanguage.ruby:
        sb.writeln('      - name: Test');
        sb.writeln('        run: bundle exec rspec || true');
        break;
    }
  }

  static void _writeBuildSteps(StringBuffer sb, DockerLanguage lang) {
    sb.writeln();
    switch (lang) {
      case DockerLanguage.flutter:
        sb.writeln('      - name: Build web');
        sb.writeln('        run: flutter build web --release');
        break;
      case DockerLanguage.node:
        sb.writeln('      - name: Build');
        sb.writeln('        run: npm run build --if-present');
        break;
      case DockerLanguage.python:
        sb.writeln('      - name: Build');
        sb.writeln('        run: python -m build || echo "No build step"');
        break;
      case DockerLanguage.go:
        sb.writeln('      - name: Build');
        sb.writeln('        run: go build -v ./...');
        break;
      case DockerLanguage.rust:
        sb.writeln('      - name: Build');
        sb.writeln('        run: cargo build --release');
        break;
      case DockerLanguage.java:
        sb.writeln('      - name: Build');
        sb.writeln('        run: mvn package -DskipTests');
        break;
      case DockerLanguage.dotnet:
        sb.writeln('      - name: Build');
        sb.writeln('        run: dotnet build --no-restore -c Release');
        break;
      case DockerLanguage.php:
        sb.writeln('      - name: Build');
        sb.writeln('        run: echo "No build step"');
        break;
      case DockerLanguage.ruby:
        sb.writeln('      - name: Build');
        sb.writeln('        run: echo "No build step"');
        break;
    }
  }

  static String _gitlab(DockerLanguage lang, DevOpsOptions opts) {
    final String image = _gitlabImage(lang, opts);
    final StringBuffer sb = StringBuffer();
    sb.writeln('# Generated by DevSpork');
    sb.writeln('stages:');
    if (opts.includeTest) sb.writeln('  - test');
    if (opts.includeBuild) sb.writeln('  - build');
    if (opts.includeDeploy) sb.writeln('  - deploy');
    sb.writeln();
    sb.writeln('variables:');
    sb.writeln('  GIT_DEPTH: "10"');
    sb.writeln();

    if (opts.includeTest) {
      sb.writeln('test:');
      sb.writeln('  stage: test');
      sb.writeln('  image: $image');
      sb.writeln('  script:');
      _gitlabTestScript(sb, lang);
      sb.writeln();
    }

    if (opts.includeBuild) {
      sb.writeln('build:');
      sb.writeln('  stage: build');
      sb.writeln('  image: $image');
      sb.writeln('  script:');
      _gitlabBuildScript(sb, lang);
      sb.writeln();
    }

    if (opts.includeDeploy) {
      sb.writeln('deploy:');
      sb.writeln('  stage: deploy');
      sb.writeln('  script:');
      sb.writeln('    - echo "Add deploy steps here"');
      sb.writeln('  only:');
      sb.writeln('    - ${opts.cicdBranch}');
    }

    return sb.toString().trimRight();
  }

  static String _gitlabImage(DockerLanguage lang, DevOpsOptions opts) {
    switch (lang) {
      case DockerLanguage.flutter:
        return 'ghcr.io/cirruslabs/flutter:stable';
      case DockerLanguage.node:
        return 'node:${opts.nodeVersion}-alpine';
      case DockerLanguage.python:
        return 'python:${opts.pythonVersion}-slim';
      case DockerLanguage.go:
        return 'golang:${opts.goVersion}-alpine';
      case DockerLanguage.rust:
        return 'rust:1.78';
      case DockerLanguage.java:
        return 'maven:3.9-eclipse-temurin-${opts.javaVersion}';
      case DockerLanguage.dotnet:
        return 'mcr.microsoft.com/dotnet/sdk:${opts.dotnetVersion}';
      case DockerLanguage.php:
        return 'php:8.3-cli';
      case DockerLanguage.ruby:
        return 'ruby:3.3';
    }
  }

  static void _gitlabTestScript(StringBuffer sb, DockerLanguage lang) {
    switch (lang) {
      case DockerLanguage.flutter:
        sb.writeln('    - flutter pub get');
        sb.writeln('    - flutter analyze');
        sb.writeln('    - flutter test');
        break;
      case DockerLanguage.node:
        sb.writeln('    - npm ci');
        sb.writeln('    - npm test --if-present');
        break;
      case DockerLanguage.python:
        sb.writeln('    - pip install -r requirements.txt');
        sb.writeln('    - pytest || true');
        break;
      case DockerLanguage.go:
        sb.writeln('    - go mod download');
        sb.writeln('    - go test ./...');
        break;
      case DockerLanguage.rust:
        sb.writeln('    - cargo test');
        break;
      case DockerLanguage.java:
        sb.writeln('    - mvn test');
        break;
      case DockerLanguage.dotnet:
        sb.writeln('    - dotnet restore');
        sb.writeln('    - dotnet test');
        break;
      case DockerLanguage.php:
        sb.writeln('    - composer install');
        sb.writeln('    - vendor/bin/phpunit || true');
        break;
      case DockerLanguage.ruby:
        sb.writeln('    - bundle install');
        sb.writeln('    - bundle exec rspec || true');
        break;
    }
  }

  static void _gitlabBuildScript(StringBuffer sb, DockerLanguage lang) {
    switch (lang) {
      case DockerLanguage.flutter:
        sb.writeln('    - flutter build web --release');
        break;
      case DockerLanguage.node:
        sb.writeln('    - npm run build --if-present');
        break;
      case DockerLanguage.python:
        sb.writeln('    - echo "No build step"');
        break;
      case DockerLanguage.go:
        sb.writeln('    - go build -v ./...');
        break;
      case DockerLanguage.rust:
        sb.writeln('    - cargo build --release');
        break;
      case DockerLanguage.java:
        sb.writeln('    - mvn package -DskipTests');
        break;
      case DockerLanguage.dotnet:
        sb.writeln('    - dotnet build --no-restore -c Release');
        break;
      case DockerLanguage.php:
      case DockerLanguage.ruby:
        sb.writeln('    - echo "No build step"');
        break;
    }
  }

  static String _circleci(DockerLanguage lang, DevOpsOptions opts) {
    final String image = _circleciImage(lang, opts);
    final StringBuffer sb = StringBuffer();
    sb.writeln('# Generated by DevSpork');
    sb.writeln('version: 2.1');
    sb.writeln();
    sb.writeln('jobs:');
    sb.writeln('  build-and-test:');
    sb.writeln('    docker:');
    sb.writeln('      - image: $image');
    sb.writeln('    steps:');
    sb.writeln('      - checkout');
    sb.writeln();

    switch (lang) {
      case DockerLanguage.flutter:
        sb.writeln('      - run: flutter pub get');
        sb.writeln('      - run: flutter analyze');
        sb.writeln('      - run: flutter test');
        sb.writeln('      - run: flutter build web --release');
        break;
      case DockerLanguage.node:
        sb.writeln('      - restore_cache:');
        sb.writeln('          keys:');
        sb.writeln('            - v1-deps-{{ checksum "package-lock.json" }}');
        sb.writeln('      - run: npm ci');
        sb.writeln('      - save_cache:');
        sb.writeln('          key: v1-deps-{{ checksum "package-lock.json" }}');
        sb.writeln('          paths:');
        sb.writeln('            - node_modules');
        sb.writeln('      - run: npm test --if-present');
        sb.writeln('      - run: npm run build --if-present');
        break;
      case DockerLanguage.python:
        sb.writeln('      - run: pip install -r requirements.txt');
        sb.writeln('      - run: pytest || true');
        break;
      case DockerLanguage.go:
        sb.writeln('      - run: go mod download');
        sb.writeln('      - run: go test ./...');
        sb.writeln('      - run: go build ./...');
        break;
      case DockerLanguage.rust:
        sb.writeln('      - run: cargo test');
        sb.writeln('      - run: cargo build --release');
        break;
      case DockerLanguage.java:
        sb.writeln('      - run: mvn test');
        sb.writeln('      - run: mvn package -DskipTests');
        break;
      case DockerLanguage.dotnet:
        sb.writeln('      - run: dotnet restore');
        sb.writeln('      - run: dotnet build');
        sb.writeln('      - run: dotnet test');
        break;
      case DockerLanguage.php:
        sb.writeln('      - run: composer install');
        sb.writeln('      - run: vendor/bin/phpunit || true');
        break;
      case DockerLanguage.ruby:
        sb.writeln('      - run: bundle install');
        sb.writeln('      - run: bundle exec rspec || true');
        break;
    }

    sb.writeln();
    sb.writeln('workflows:');
    sb.writeln('  version: 2');
    sb.writeln('  main:');
    sb.writeln('    jobs:');
    sb.writeln('      - build-and-test');
    return sb.toString().trimRight();
  }

  static String _circleciImage(DockerLanguage lang, DevOpsOptions opts) {
    switch (lang) {
      case DockerLanguage.flutter:
        return 'ghcr.io/cirruslabs/flutter:stable';
      case DockerLanguage.node:
        return 'cimg/node:${opts.nodeVersion}';
      case DockerLanguage.python:
        return 'cimg/python:${opts.pythonVersion}';
      case DockerLanguage.go:
        return 'cimg/go:${opts.goVersion}';
      case DockerLanguage.rust:
        return 'cimg/rust:1.78';
      case DockerLanguage.java:
        return 'cimg/openjdk:${opts.javaVersion}';
      case DockerLanguage.dotnet:
        return 'mcr.microsoft.com/dotnet/sdk:${opts.dotnetVersion}';
      case DockerLanguage.php:
        return 'cimg/php:8.3';
      case DockerLanguage.ruby:
        return 'cimg/ruby:3.3';
    }
  }
}