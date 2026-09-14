
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'models.dart';
import 'templates.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class DevOpsGen extends StatefulWidget {
  const DevOpsGen({super.key});

  @override
  State<DevOpsGen> createState() => _DevOpsGenState();
}

class _DevOpsGenState extends State<DevOpsGen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final DevOpsOptions _options = DevOpsOptions();

  final Set<String> _selectedGitignore = <String>{
    'macos',
    'windows',
    'linux',
    'jetbrains',
    'vscode',
  };

  DockerLanguage _dockerLang = DockerLanguage.flutter;

  final Set<String> _selectedServices = <String>{'app', 'postgres', 'redis'};

  CicdProvider _cicdProvider = CicdProvider.github;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _gitignoreOutput() =>
      GitignoreTemplates.build(_selectedGitignore);

  String _dockerfileOutput() =>
      DockerfileTemplates.generate(_dockerLang, _options);

  String _composeOutput() =>
      ComposeTemplates.generate(_selectedServices, _options);

  String _cicdOutput() =>
      CicdTemplates.generate(_cicdProvider, _dockerLang, _options);

  String _currentOutput() {
    switch (_tabController.index) {
      case 0:
        return _gitignoreOutput();
      case 1:
        return _dockerfileOutput();
      case 2:
        return _composeOutput();
      case 3:
        return _cicdOutput();
      default:
        return '';
    }
  }

  String _currentFileName() {
    switch (_tabController.index) {
      case 0:
        return '.gitignore';
      case 1:
        return 'Dockerfile';
      case 2:
        return 'docker-compose.yml';
      case 3:
        return _cicdProvider.fileName;
      default:
        return '';
    }
  }

  Future<void> _copyOutput() async {
    final String output = _currentOutput();
    if (output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: output));
    if (!mounted) return;
    _showSnack(context.t('devopsgen_copied'));
  }

  void _resetCurrent() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedGitignore
            ..clear()
            ..addAll(<String>['macos', 'windows', 'linux', 'jetbrains', 'vscode']);
          break;
        case 1:
          _dockerLang = DockerLanguage.flutter;
          _options
            ..multiStage = true
            ..useAlpine = false
            ..nonRootUser = true
            ..exposePort = 8080
            ..includeHealthcheck = false;
          break;
        case 2:
          _selectedServices
            ..clear()
            ..addAll(<String>['app', 'postgres', 'redis']);
          break;
        case 3:
          _cicdProvider = CicdProvider.github;
          _options
            ..includeTest = true
            ..includeBuild = true
            ..includeDeploy = false
            ..cicdBranch = 'main'
            ..cicdRunner = 'ubuntu-latest';
          break;
      }
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.75),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('devopsgen_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.copy_rounded,
            tooltip: context.t('devopsgen_copy'),
            onTap: _copyOutput,
          ),
          _glassIconButton(
            icon: Icons.refresh_rounded,
            tooltip: context.t('devopsgen_reset'),
            onTap: _resetCurrent,
          ),
          const SizedBox(width: 8),
        ],
        bottom: _glassTabBar(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_bgTop, _bgMid, _bgBot],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blurBlob(220, _accentA)),
            Positioned(
              bottom: -100,
              right: -60,
              child: _blurBlob(260, _accentB),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _buildGitignoreTab(),
                    _buildDockerfileTab(),
                    _buildComposeTab(),
                    _buildCicdTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _glassTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _GlassCard(
          padding: const EdgeInsets.all(4),
          radius: 16,
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: <Color>[_accentA, _accentB],
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            onTap: (int i) => setState(() {}),
            tabs: <Widget>[
              Tab(text: context.t('devopsgen_tab_gitignore')),
              Tab(text: context.t('devopsgen_tab_dockerfile')),
              Tab(text: context.t('devopsgen_tab_compose')),
              Tab(text: context.t('devopsgen_tab_cicd')),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- GITIGNORE ----------------

  Widget _buildGitignoreTab() {
    final Map<String, List<GitignoreOption>> grouped =
    <String, List<GitignoreOption>>{};
    for (final GitignoreOption o in GitignoreTemplates.all) {
      grouped.putIfAbsent(o.category, () => <GitignoreOption>[]).add(o);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final String category in grouped.keys) ...<Widget>[
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.t('devopsgen_cat_$category'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${grouped[category]!.where((GitignoreOption o) => _selectedGitignore.contains(o.id)).length}'
                            '/${grouped[category]!.length}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: grouped[category]!.map((GitignoreOption o) {
                      final bool selected =
                      _selectedGitignore.contains(o.id);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedGitignore.remove(o.id);
                          } else {
                            _selectedGitignore.add(o.id);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                              colors: <Color>[_accentA, _accentB],
                            )
                                : null,
                            color: selected
                                ? null
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (selected) ...<Widget>[
                                const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                context.t(o.labelKey),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _outputCard(_gitignoreOutput(), '.gitignore'),
        ],
      ),
    );
  }

  // ---------------- DOCKERFILE ----------------

  Widget _buildDockerfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.language_rounded,
                  labelKey: 'devopsgen_language',
                ),
                const SizedBox(height: 10),
                _dockerLanguageSelector(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.tune_rounded,
                  labelKey: 'devopsgen_options',
                ),
                const SizedBox(height: 8),
                if (_dockerLang.supportsMultiStage)
                  _optionSwitch(
                    labelKey: 'devopsgen_opt_multistage',
                    value: _options.multiStage,
                    onChanged: (bool v) =>
                        setState(() => _options.multiStage = v),
                  ),
                if (_dockerLang.supportsAlpine)
                  _optionSwitch(
                    labelKey: 'devopsgen_opt_alpine',
                    value: _options.useAlpine,
                    onChanged: (bool v) =>
                        setState(() => _options.useAlpine = v),
                  ),
                _optionSwitch(
                  labelKey: 'devopsgen_opt_nonroot',
                  value: _options.nonRootUser,
                  onChanged: (bool v) =>
                      setState(() => _options.nonRootUser = v),
                ),
                _optionSwitch(
                  labelKey: 'devopsgen_opt_healthcheck',
                  value: _options.includeHealthcheck,
                  onChanged: (bool v) =>
                      setState(() => _options.includeHealthcheck = v),
                ),
                const SizedBox(height: 10),
                _portField(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _versionCard(),
          const SizedBox(height: 16),
          _outputCard(_dockerfileOutput(), 'Dockerfile'),
        ],
      ),
    );
  }

  Widget _dockerLanguageSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: DockerLanguage.values.map((DockerLanguage l) {
        final bool selected = _dockerLang == l;
        return GestureDetector(
          onTap: () => setState(() => _dockerLang = l),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                colors: <Color>[_accentA, _accentB],
              )
                  : null,
              color: selected ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Text(
              l.displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _portField() {
    return Row(
      children: <Widget>[
        const Icon(
          Icons.settings_ethernet_rounded,
          size: 16,
          color: Colors.white70,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.t('devopsgen_expose_port'),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            controller: TextEditingController(
              text: '${_options.exposePort}',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            onChanged: (String v) {
              final int? n = int.tryParse(v);
              if (n != null && n > 0 && n < 65536) {
                setState(() => _options.exposePort = n);
              }
            },
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: _accentB, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _versionCard() {
    if (_dockerLang == DockerLanguage.flutter ||
        _dockerLang == DockerLanguage.rust) {
      return const SizedBox.shrink();
    }

    String labelKey;
    String value;
    ValueChanged<String> onChanged;

    switch (_dockerLang) {
      case DockerLanguage.node:
        labelKey = 'devopsgen_node_version';
        value = _options.nodeVersion;
        onChanged = (String v) => setState(() => _options.nodeVersion = v);
        break;
      case DockerLanguage.python:
        labelKey = 'devopsgen_python_version';
        value = _options.pythonVersion;
        onChanged = (String v) => setState(() => _options.pythonVersion = v);
        break;
      case DockerLanguage.go:
        labelKey = 'devopsgen_go_version';
        value = _options.goVersion;
        onChanged = (String v) => setState(() => _options.goVersion = v);
        break;
      case DockerLanguage.java:
        labelKey = 'devopsgen_java_version';
        value = _options.javaVersion;
        onChanged = (String v) => setState(() => _options.javaVersion = v);
        break;
      case DockerLanguage.dotnet:
        labelKey = 'devopsgen_dotnet_version';
        value = _options.dotnetVersion;
        onChanged = (String v) => setState(() => _options.dotnetVersion = v);
        break;
      default:
        return const SizedBox.shrink();
    }

    return _GlassCard(
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.tag_rounded,
            size: 16,
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t(labelKey),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: TextEditingController(text: value),
              onChanged: onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  const BorderSide(color: _accentB, width: 1.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- COMPOSE ----------------

  Widget _buildComposeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.dns_rounded,
                  labelKey: 'devopsgen_services',
                ),
                const SizedBox(height: 10),
                for (final ComposeServiceDef svc
                in ComposeTemplates.services)
                  _serviceRow(svc),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.tune_rounded,
                  labelKey: 'devopsgen_options',
                ),
                const SizedBox(height: 8),
                _optionSwitch(
                  labelKey: 'devopsgen_opt_volumes',
                  value: _options.includeVolumes,
                  onChanged: (bool v) =>
                      setState(() => _options.includeVolumes = v),
                ),
                _optionSwitch(
                  labelKey: 'devopsgen_opt_networks',
                  value: _options.includeNetworks,
                  onChanged: (bool v) =>
                      setState(() => _options.includeNetworks = v),
                ),
                _optionSwitch(
                  labelKey: 'devopsgen_opt_restart',
                  value: _options.includeRestartPolicy,
                  onChanged: (bool v) =>
                      setState(() => _options.includeRestartPolicy = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.badge_outlined,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('devopsgen_project_name'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: TextEditingController(
                          text: _options.composeProjectName,
                        ),
                        onChanged: (String v) {
                          if (v.trim().isEmpty) return;
                          setState(
                                () => _options.composeProjectName = v.trim(),
                          );
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _accentB,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _outputCard(_composeOutput(), 'docker-compose.yml'),
        ],
      ),
    );
  }

  Widget _serviceRow(ComposeServiceDef svc) {
    final bool selected = _selectedServices.contains(svc.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => setState(() {
          if (selected) {
            _selectedServices.remove(svc.id);
          } else {
            _selectedServices.add(svc.id);
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _accentB.withOpacity(0.12)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _accentB.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: <Widget>[
              Text(
                svc.icon,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.t(svc.labelKey),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected
                      ? _accentB.withOpacity(0.3)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected
                        ? _accentB
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: selected
                    ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: _accentB,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- CICD ----------------

  Widget _buildCicdTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.cloud_outlined,
                  labelKey: 'devopsgen_provider',
                ),
                const SizedBox(height: 10),
                _providerSelector(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.language_rounded,
                  labelKey: 'devopsgen_language',
                ),
                const SizedBox(height: 10),
                _dockerLanguageSelector(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.tune_rounded,
                  labelKey: 'devopsgen_options',
                ),
                const SizedBox(height: 8),
                _optionSwitch(
                  labelKey: 'devopsgen_opt_test',
                  value: _options.includeTest,
                  onChanged: (bool v) =>
                      setState(() => _options.includeTest = v),
                ),
                _optionSwitch(
                  labelKey: 'devopsgen_opt_build',
                  value: _options.includeBuild,
                  onChanged: (bool v) =>
                      setState(() => _options.includeBuild = v),
                ),
                _optionSwitch(
                  labelKey: 'devopsgen_opt_deploy',
                  value: _options.includeDeploy,
                  onChanged: (bool v) =>
                      setState(() => _options.includeDeploy = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.alt_route_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('devopsgen_branch'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: TextEditingController(
                          text: _options.cicdBranch,
                        ),
                        onChanged: (String v) {
                          if (v.trim().isEmpty) return;
                          setState(() => _options.cicdBranch = v.trim());
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _accentB,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _outputCard(
            _cicdOutput(),
            _cicdProvider.fileName,
          ),
        ],
      ),
    );
  }

  Widget _providerSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: CicdProvider.values.map((CicdProvider p) {
        final bool selected = _cicdProvider == p;
        return GestureDetector(
          onTap: () => setState(() => _cicdProvider = p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                colors: <Color>[_accentA, _accentB],
              )
                  : null,
              color: selected ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Text(
              p.displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------- SHARED ----------------

  Widget _outputCard(String output, String fileName) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _success.withOpacity(0.4)),
                ),
                child: Text(
                  fileName,
                  style: const TextStyle(
                    color: _success,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _copyOutput,
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: _accentB,
                ),
                label: Text(
                  context.t('devopsgen_copy'),
                  style: const TextStyle(color: _accentB, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            constraints: const BoxConstraints(maxHeight: 400),
            child: output.isEmpty
                ? Text(
              context.t('devopsgen_empty'),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            )
                : SingleChildScrollView(
              child: SelectableText(
                output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.55,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String labelKey,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          context.t(labelKey),
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _optionSwitch({
    required String labelKey,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              context.t(labelKey),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _accentB,
            activeTrackColor: _accentB.withOpacity(0.4),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withOpacity(0.08),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blurBlob(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}