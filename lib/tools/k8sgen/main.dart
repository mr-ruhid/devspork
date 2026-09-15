import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'generator.dart';
import 'models.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class K8sGen extends StatefulWidget {
  const K8sGen({super.key});

  @override
  State<K8sGen> createState() => _K8sGenState();
}

class _K8sGenState extends State<K8sGen> {
  K8sResourceType _type = K8sResourceType.deployment;

  final DeploymentConfig _deployment = DeploymentConfig();
  final StatefulSetConfig _statefulSet = StatefulSetConfig();
  final DaemonSetConfig _daemonSet = DaemonSetConfig();
  final ServiceConfig _service = ServiceConfig();
  final ConfigMapConfig _configMap = ConfigMapConfig();
  final SecretConfig _secret = SecretConfig();
  final IngressConfig _ingress = IngressConfig();
  final K8sMetadata _namespace = K8sMetadata();
  final PvcConfig _pvc = PvcConfig();
  final CronJobConfig _cronJob = CronJobConfig();
  final JobConfig _job = JobConfig();
  final HpaConfig _hpa = HpaConfig();

  String _output = '';
  bool _copied = false;

  static const List<String> _labelPresets = <String>[
    'app',
    'app.kubernetes.io/name',
    'app.kubernetes.io/instance',
    'app.kubernetes.io/version',
    'app.kubernetes.io/component',
    'app.kubernetes.io/part-of',
    'app.kubernetes.io/managed-by',
    'tier',
    'environment',
    'version',
  ];

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  Object _activeConfig() {
    switch (_type) {
      case K8sResourceType.deployment:
        return _deployment;
      case K8sResourceType.statefulSet:
        return _statefulSet;
      case K8sResourceType.daemonSet:
        return _daemonSet;
      case K8sResourceType.service:
        return _service;
      case K8sResourceType.configMap:
        return _configMap;
      case K8sResourceType.secret:
        return _secret;
      case K8sResourceType.ingress:
        return _ingress;
      case K8sResourceType.namespace:
        return _namespace;
      case K8sResourceType.pvc:
        return _pvc;
      case K8sResourceType.cronJob:
        return _cronJob;
      case K8sResourceType.job:
        return _job;
      case K8sResourceType.hpa:
        return _hpa;
    }
  }

  void _regenerate() {
    final String out = K8sYamlGenerator.generate(_type, _activeConfig());
    setState(() => _output = out);
  }

  Future<void> _copy() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  String _typeKey(K8sResourceType t) {
    switch (t) {
      case K8sResourceType.deployment:
        return 'k8sgen_type_deployment';
      case K8sResourceType.statefulSet:
        return 'k8sgen_type_statefulset';
      case K8sResourceType.daemonSet:
        return 'k8sgen_type_daemonset';
      case K8sResourceType.service:
        return 'k8sgen_type_service';
      case K8sResourceType.configMap:
        return 'k8sgen_type_configmap';
      case K8sResourceType.secret:
        return 'k8sgen_type_secret';
      case K8sResourceType.ingress:
        return 'k8sgen_type_ingress';
      case K8sResourceType.namespace:
        return 'k8sgen_type_namespace';
      case K8sResourceType.pvc:
        return 'k8sgen_type_pvc';
      case K8sResourceType.cronJob:
        return 'k8sgen_type_cronjob';
      case K8sResourceType.job:
        return 'k8sgen_type_job';
      case K8sResourceType.hpa:
        return 'k8sgen_type_hpa';
    }
  }

  IconData _typeIcon(K8sResourceType t) {
    switch (t) {
      case K8sResourceType.deployment:
        return Icons.apps_rounded;
      case K8sResourceType.statefulSet:
        return Icons.storage_rounded;
      case K8sResourceType.daemonSet:
        return Icons.memory_rounded;
      case K8sResourceType.service:
        return Icons.lan_rounded;
      case K8sResourceType.configMap:
        return Icons.settings_suggest_rounded;
      case K8sResourceType.secret:
        return Icons.lock_outline_rounded;
      case K8sResourceType.ingress:
        return Icons.public_rounded;
      case K8sResourceType.namespace:
        return Icons.folder_outlined;
      case K8sResourceType.pvc:
        return Icons.disc_full_rounded;
      case K8sResourceType.cronJob:
        return Icons.schedule_rounded;
      case K8sResourceType.job:
        return Icons.play_circle_outline_rounded;
      case K8sResourceType.hpa:
        return Icons.trending_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('k8sgen_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
            tooltip: context.t('k8sgen_copy'),
            onTap: _copy,
            highlighted: _copied,
          ),
          const SizedBox(width: 8),
        ],
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
            Positioned(top: -80, left: -60, child: _blob(220, _accentA)),
            Positioned(bottom: -100, right: -60, child: _blob(260, _accentB)),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _buildTypeSelector(),
                  const SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ..._buildForm(),
                          const SizedBox(height: 14),
                          _buildOutput(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: K8sResourceType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          final K8sResourceType t = K8sResourceType.values[i];
          final bool selected = _type == t;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _type = t);
              _regenerate();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                    colors: <Color>[_accentA, _accentB])
                    : null,
                color: selected ? null : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(_typeIcon(t), size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    context.t(_typeKey(t)),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildForm() {
    switch (_type) {
      case K8sResourceType.deployment:
        return <Widget>[
          _metadataCard(_deployment.metadata),
          const SizedBox(height: 14),
          _buildDeploymentFields(),
          const SizedBox(height: 14),
          _containerCard(_deployment.container),
        ];
      case K8sResourceType.statefulSet:
        return <Widget>[
          _metadataCard(_statefulSet.metadata),
          const SizedBox(height: 14),
          _buildStatefulSetFields(),
          const SizedBox(height: 14),
          _containerCard(_statefulSet.container),
        ];
      case K8sResourceType.daemonSet:
        return <Widget>[
          _metadataCard(_daemonSet.metadata),
          const SizedBox(height: 14),
          _buildDaemonSetFields(),
          const SizedBox(height: 14),
          _containerCard(_daemonSet.container),
        ];
      case K8sResourceType.service:
        return <Widget>[
          _metadataCard(_service.metadata),
          const SizedBox(height: 14),
          _buildServiceFields(),
          const SizedBox(height: 14),
          _buildServicePortsCard(),
        ];
      case K8sResourceType.configMap:
        return <Widget>[
          _metadataCard(_configMap.metadata),
          const SizedBox(height: 14),
          _buildKeyValueCard(
            titleKey: 'k8sgen_section_data',
            icon: Icons.data_object_rounded,
            map: _configMap.data,
          ),
        ];
      case K8sResourceType.secret:
        return <Widget>[
          _metadataCard(_secret.metadata),
          const SizedBox(height: 14),
          _buildSecretFields(),
          const SizedBox(height: 14),
          _buildKeyValueCard(
            titleKey: 'k8sgen_section_data',
            icon: Icons.lock_outline_rounded,
            map: _secret.data,
          ),
        ];
      case K8sResourceType.ingress:
        return <Widget>[
          _metadataCard(_ingress.metadata),
          const SizedBox(height: 14),
          _buildIngressFields(),
          const SizedBox(height: 14),
          _buildIngressRulesCard(),
          const SizedBox(height: 14),
          _buildIngressTlsCard(),
        ];
      case K8sResourceType.namespace:
        return <Widget>[_metadataCard(_namespace)];
      case K8sResourceType.pvc:
        return <Widget>[
          _metadataCard(_pvc.metadata),
          const SizedBox(height: 14),
          _buildPvcFields(),
        ];
      case K8sResourceType.cronJob:
        return <Widget>[
          _metadataCard(_cronJob.metadata),
          const SizedBox(height: 14),
          _buildCronJobFields(),
          const SizedBox(height: 14),
          _containerCard(_cronJob.container),
        ];
      case K8sResourceType.job:
        return <Widget>[
          _metadataCard(_job.metadata),
          const SizedBox(height: 14),
          _buildJobFields(),
          const SizedBox(height: 14),
          _containerCard(_job.container),
        ];
      case K8sResourceType.hpa:
        return <Widget>[
          _metadataCard(_hpa.metadata),
          const SizedBox(height: 14),
          _buildHpaFields(),
        ];
    }
  }

  Widget _metadataCard(K8sMetadata m) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.info_outline_rounded,
            context.t('k8sgen_section_metadata'),
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_name'),
            value: m.name,
            hint: context.t('k8sgen_hint_name'),
            onChanged: (String v) {
              m.name = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          if (_type != K8sResourceType.namespace)
            _field(
              label: context.t('k8sgen_field_namespace'),
              value: m.namespace,
              hint: context.t('k8sgen_hint_namespace'),
              onChanged: (String v) {
                m.namespace = v;
                _regenerate();
              },
            ),
          const SizedBox(height: 10),
          _buildMapEditor(
            titleKey: 'k8sgen_section_labels',
            map: m.labels,
            keyPresets: _labelPresets,
            onChanged: _regenerate,
          ),
          const SizedBox(height: 10),
          _buildMapEditor(
            titleKey: 'k8sgen_section_annotations',
            map: m.annotations,
            keyPresets: const <String>[],
            onChanged: _regenerate,
          ),
        ],
      ),
    );
  }

  Widget _buildDeploymentFields() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            context.t('k8sgen_section_deployment'),
          ),
          const SizedBox(height: 10),
          _numberField(
            label: context.t('k8sgen_field_replicas'),
            value: _deployment.replicas,
            onChanged: (int v) {
              _deployment.replicas = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_selector_key'),
                  value: _deployment.selectorKey,
                  hint: 'app',
                  onChanged: (String v) {
                    _deployment.selectorKey = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_selector_value'),
                  value: _deployment.selectorValue,
                  hint: context.t('k8sgen_hint_name_optional'),
                  onChanged: (String v) {
                    _deployment.selectorValue = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatefulSetFields() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            context.t('k8sgen_section_statefulset'),
          ),
          const SizedBox(height: 10),
          _numberField(
            label: context.t('k8sgen_field_replicas'),
            value: _statefulSet.replicas,
            onChanged: (int v) {
              _statefulSet.replicas = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_service_name'),
            value: _statefulSet.serviceName,
            hint: context.t('k8sgen_hint_name_optional'),
            onChanged: (String v) {
              _statefulSet.serviceName = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_selector_key'),
                  value: _statefulSet.selectorKey,
                  hint: 'app',
                  onChanged: (String v) {
                    _statefulSet.selectorKey = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_selector_value'),
                  value: _statefulSet.selectorValue,
                  hint: context.t('k8sgen_hint_name_optional'),
                  onChanged: (String v) {
                    _statefulSet.selectorValue = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaemonSetFields() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            context.t('k8sgen_section_daemonset'),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_selector_key'),
                  value: _daemonSet.selectorKey,
                  hint: 'app',
                  onChanged: (String v) {
                    _daemonSet.selectorKey = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_selector_value'),
                  value: _daemonSet.selectorValue,
                  hint: context.t('k8sgen_hint_name_optional'),
                  onChanged: (String v) {
                    _daemonSet.selectorValue = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceFields() {
    const List<String> types = <String>[
      'ClusterIP',
      'NodePort',
      'LoadBalancer',
      'ExternalName',
    ];
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            context.t('k8sgen_section_service'),
          ),
          const SizedBox(height: 10),
          _enumField(
            label: context.t('k8sgen_field_type'),
            value: _service.type,
            values: types,
            onChanged: (String v) {
              _service.type = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_selector_key'),
                  value: _service.selectorKey,
                  hint: 'app',
                  onChanged: (String v) {
                    _service.selectorKey = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_selector_value'),
                  value: _service.selectorValue,
                  hint: context.t('k8sgen_hint_name_optional'),
                  onChanged: (String v) {
                    _service.selectorValue = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_cluster_ip'),
            value: _service.clusterIP,
            hint: context.t('k8sgen_hint_cluster_ip'),
            onChanged: (String v) {
              _service.clusterIP = v;
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServicePortsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.settings_ethernet_rounded,
            context.t('k8sgen_section_ports'),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _service.ports.length; i++) _servicePortRow(i),
          const SizedBox(height: 8),
          _dashedButton(
            label: context.t('k8sgen_add_port'),
            onTap: () {
              setState(() {
                _service.ports.add(ServicePort());
              });
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _servicePortRow(int index) {
    final ServicePort p = _service.ports[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '${context.t('k8sgen_port_label')} #${index + 1}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_service.ports.length > 1)
                _miniIconButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    setState(() {
                      _service.ports.removeAt(index);
                    });
                    _regenerate();
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_name'),
                  value: p.name,
                  hint: 'http',
                  onChanged: (String v) {
                    p.name = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_port'),
                  value: p.port,
                  onChanged: (int v) {
                    p.port = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_target'),
                  value: p.targetPort,
                  onChanged: (int v) {
                    p.targetPort = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (_service.type == 'NodePort')
                Expanded(
                  child: _numberField(
                    label: context.t('k8sgen_field_node_port'),
                    value: p.nodePort ?? 30000,
                    onChanged: (int v) {
                      p.nodePort = v;
                      _regenerate();
                    },
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecretFields() {
    const List<String> types = <String>[
      'Opaque',
      'kubernetes.io/service-account-token',
      'kubernetes.io/dockercfg',
      'kubernetes.io/dockerconfigjson',
      'kubernetes.io/basic-auth',
      'kubernetes.io/ssh-auth',
      'kubernetes.io/tls',
      'bootstrap.kubernetes.io/token',
    ];
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            context.t('k8sgen_section_secret'),
          ),
          const SizedBox(height: 10),
          _enumField(
            label: context.t('k8sgen_field_type'),
            value: _secret.type,
            values: types,
            onChanged: (String v) {
              _secret.type = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 8),
          _switchRow(
            label: context.t('k8sgen_field_base64'),
            value: _secret.encodeBase64,
            onChanged: (bool v) {
              _secret.encodeBase64 = v;
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIngressFields() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            context.t('k8sgen_section_ingress'),
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_ingress_class'),
            value: _ingress.ingressClassName,
            hint: 'nginx',
            onChanged: (String v) {
              _ingress.ingressClassName = v;
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIngressRulesCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.rule_rounded,
            context.t('k8sgen_section_rules'),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _ingress.rules.length; i++) _ingressRuleRow(i),
          const SizedBox(height: 8),
          _dashedButton(
            label: context.t('k8sgen_add_rule'),
            onTap: () {
              setState(() {
                _ingress.rules.add(IngressRule());
              });
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _ingressRuleRow(int index) {
    final IngressRule r = _ingress.rules[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '${context.t('k8sgen_rule_label')} #${index + 1}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_ingress.rules.length > 1)
                _miniIconButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    setState(() {
                      _ingress.rules.removeAt(index);
                    });
                    _regenerate();
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          _field(
            label: context.t('k8sgen_field_host'),
            value: r.host,
            hint: context.t('k8sgen_hint_host'),
            onChanged: (String v) {
              r.host = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          for (int j = 0; j < r.paths.length; j++) _ingressPathRow(r, j),
          const SizedBox(height: 4),
          _dashedButton(
            label: context.t('k8sgen_add_path'),
            onTap: () {
              setState(() {
                r.paths.add(IngressPath());
              });
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _ingressPathRow(IngressRule r, int index) {
    final IngressPath p = r.paths[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_path'),
                  value: p.path,
                  hint: '/',
                  onChanged: (String v) {
                    p.path = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (r.paths.length > 1)
                _miniIconButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    setState(() {
                      r.paths.removeAt(index);
                    });
                    _regenerate();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_service_name'),
                  value: p.serviceName,
                  hint: context.t('k8sgen_hint_service_name'),
                  onChanged: (String v) {
                    p.serviceName = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_service_port'),
                  value: p.servicePort,
                  onChanged: (int v) {
                    p.servicePort = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngressTlsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.lock_outline_rounded,
            context.t('k8sgen_section_tls'),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _ingress.tls.length; i++) _ingressTlsRow(i),
          const SizedBox(height: 8),
          _dashedButton(
            label: context.t('k8sgen_add_tls'),
            onTap: () {
              setState(() {
                _ingress.tls.add(IngressTls());
              });
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _ingressTlsRow(int index) {
    final IngressTls t = _ingress.tls[index];
    final TextEditingController hostsCtrl =
    TextEditingController(text: t.hosts.join(', '));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'TLS #${index + 1}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _miniIconButton(
                icon: Icons.close_rounded,
                onTap: () {
                  setState(() {
                    _ingress.tls.removeAt(index);
                  });
                  _regenerate();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          _field(
            label: context.t('k8sgen_field_secret_name'),
            value: t.secretName,
            hint: context.t('k8sgen_hint_secret_name'),
            onChanged: (String v) {
              t.secretName = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: hostsCtrl,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            decoration: _inputDecoration(
              context.t('k8sgen_field_hosts'),
              context.t('k8sgen_hint_hosts'),
            ),
            onChanged: (String v) {
              t.hosts = v
                  .split(',')
                  .map((String s) => s.trim())
                  .where((String s) => s.isNotEmpty)
                  .toList();
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPvcFields() {
    const List<String> access = <String>[
      'ReadWriteOnce',
      'ReadOnlyMany',
      'ReadWriteMany',
      'ReadWriteOncePod',
    ];
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(Icons.tune_rounded, context.t('k8sgen_section_pvc')),
          const SizedBox(height: 10),
          _enumField(
            label: context.t('k8sgen_field_access_mode'),
            value: _pvc.accessMode,
            values: access,
            onChanged: (String v) {
              _pvc.accessMode = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_size'),
            value: _pvc.size,
            hint: '1Gi',
            onChanged: (String v) {
              _pvc.size = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_storage_class'),
            value: _pvc.storageClass,
            hint: context.t('k8sgen_hint_storage_class'),
            onChanged: (String v) {
              _pvc.storageClass = v;
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCronJobFields() {
    const List<String> conc = <String>['Allow', 'Forbid', 'Replace'];
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            context.t('k8sgen_section_cronjob'),
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_schedule'),
            value: _cronJob.schedule,
            hint: context.t('k8sgen_hint_schedule'),
            onChanged: (String v) {
              _cronJob.schedule = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          _enumField(
            label: context.t('k8sgen_field_concurrency'),
            value: _cronJob.concurrencyPolicy,
            values: conc,
            onChanged: (String v) {
              _cronJob.concurrencyPolicy = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_backoff_limit'),
                  value: _cronJob.backoffLimit,
                  onChanged: (int v) {
                    _cronJob.backoffLimit = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_success_history'),
                  value: _cronJob.successfulJobsHistoryLimit ?? 3,
                  onChanged: (int v) {
                    _cronJob.successfulJobsHistoryLimit = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobFields() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(Icons.tune_rounded, context.t('k8sgen_section_job')),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_completions'),
                  value: _job.completions,
                  onChanged: (int v) {
                    _job.completions = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_parallelism'),
                  value: _job.parallelism,
                  onChanged: (int v) {
                    _job.parallelism = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _numberField(
            label: context.t('k8sgen_field_backoff_limit'),
            value: _job.backoffLimit,
            onChanged: (int v) {
              _job.backoffLimit = v;
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHpaFields() {
    const List<String> kinds = <String>[
      'Deployment',
      'StatefulSet',
      'ReplicaSet',
    ];
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(Icons.tune_rounded, context.t('k8sgen_section_hpa')),
          const SizedBox(height: 10),
          _enumField(
            label: context.t('k8sgen_field_target_kind'),
            value: _hpa.targetKind,
            values: kinds,
            onChanged: (String v) {
              _hpa.targetKind = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_target_name'),
            value: _hpa.targetName,
            hint: context.t('k8sgen_hint_target_name'),
            onChanged: (String v) {
              _hpa.targetName = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_min_replicas'),
                  value: _hpa.minReplicas,
                  onChanged: (int v) {
                    _hpa.minReplicas = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_max_replicas'),
                  value: _hpa.maxReplicas,
                  onChanged: (int v) {
                    _hpa.maxReplicas = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_cpu_target'),
                  value: _hpa.cpuTarget,
                  onChanged: (int v) {
                    _hpa.cpuTarget = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(
                  label: context.t('k8sgen_field_memory_target'),
                  value: _hpa.memoryTarget,
                  onChanged: (int v) {
                    _hpa.memoryTarget = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _containerCard(ContainerConfig c) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.widgets_rounded,
            context.t('k8sgen_section_container'),
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_name'),
            value: c.name,
            hint: 'app',
            onChanged: (String v) {
              c.name = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_image'),
            value: c.image,
            hint: context.t('k8sgen_hint_image'),
            onChanged: (String v) {
              c.image = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 10),
          _field(
            label: context.t('k8sgen_field_image_pull'),
            value: c.imagePullPolicy,
            hint: 'IfNotPresent',
            onChanged: (String v) {
              c.imagePullPolicy = v;
              _regenerate();
            },
          ),
          const SizedBox(height: 14),
          _sectionTitle(
            Icons.settings_ethernet_rounded,
            context.t('k8sgen_section_ports'),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < c.ports.length; i++) _containerPortRow(c, i),
          const SizedBox(height: 6),
          _dashedButton(
            label: context.t('k8sgen_add_port'),
            onTap: () {
              setState(() {
                c.ports.add(ContainerPort());
              });
              _regenerate();
            },
          ),
          const SizedBox(height: 14),
          _sectionTitle(
            Icons.vpn_key_rounded,
            context.t('k8sgen_section_env'),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < c.env.length; i++) _envRow(c, i),
          const SizedBox(height: 6),
          _dashedButton(
            label: context.t('k8sgen_add_env'),
            onTap: () {
              setState(() {
                c.env.add(EnvVar());
              });
              _regenerate();
            },
          ),
          const SizedBox(height: 14),
          _sectionTitle(
            Icons.memory_rounded,
            context.t('k8sgen_section_resources'),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_cpu_request'),
                  value: c.resources.cpuRequest,
                  hint: '100m',
                  onChanged: (String v) {
                    c.resources.cpuRequest = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_cpu_limit'),
                  value: c.resources.cpuLimit,
                  hint: '500m',
                  onChanged: (String v) {
                    c.resources.cpuLimit = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_mem_request'),
                  value: c.resources.memoryRequest,
                  hint: '128Mi',
                  onChanged: (String v) {
                    c.resources.memoryRequest = v;
                    _regenerate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_mem_limit'),
                  value: c.resources.memoryLimit,
                  hint: '512Mi',
                  onChanged: (String v) {
                    c.resources.memoryLimit = v;
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _containerPortRow(ContainerConfig c, int index) {
    final ContainerPort p = c.ports[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _field(
              label: context.t('k8sgen_field_name'),
              value: p.name,
              hint: 'http',
              onChanged: (String v) {
                p.name = v;
                _regenerate();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _numberField(
              label: context.t('k8sgen_field_port'),
              value: p.port,
              onChanged: (int v) {
                p.port = v;
                _regenerate();
              },
            ),
          ),
          _miniIconButton(
            icon: Icons.close_rounded,
            onTap: () {
              setState(() {
                c.ports.removeAt(index);
              });
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _envRow(ContainerConfig c, int index) {
    final EnvVar e = c.env[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  label: context.t('k8sgen_field_key'),
                  value: e.key,
                  hint: context.t('k8sgen_hint_env_key'),
                  onChanged: (String v) {
                    e.key = v;
                    _regenerate();
                  },
                ),
              ),
              _miniIconButton(
                icon: Icons.close_rounded,
                onTap: () {
                  setState(() {
                    c.env.removeAt(index);
                  });
                  _regenerate();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!e.isSecret && !e.isConfigMap)
            _field(
              label: context.t('k8sgen_field_value'),
              value: e.value,
              hint: context.t('k8sgen_hint_value'),
              onChanged: (String v) {
                e.value = v;
                _regenerate();
              },
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: <Widget>[
              _chip(
                labelKey: 'k8sgen_chip_plain',
                selected: !e.isSecret && !e.isConfigMap,
                onTap: () {
                  e.isSecret = false;
                  e.isConfigMap = false;
                  _regenerate();
                },
              ),
              _chip(
                labelKey: 'k8sgen_chip_secret',
                selected: e.isSecret,
                onTap: () {
                  e.isSecret = true;
                  e.isConfigMap = false;
                  _regenerate();
                },
              ),
              _chip(
                labelKey: 'k8sgen_chip_configmap',
                selected: e.isConfigMap,
                onTap: () {
                  e.isSecret = false;
                  e.isConfigMap = true;
                  _regenerate();
                },
              ),
            ],
          ),
          if (e.isSecret || e.isConfigMap) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _field(
                    label: e.isSecret
                        ? context.t('k8sgen_field_secret_name')
                        : context.t('k8sgen_field_configmap_name'),
                    value: e.sourceName,
                    hint: context.t('k8sgen_hint_source_name'),
                    onChanged: (String v) {
                      e.sourceName = v;
                      _regenerate();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(
                    label: context.t('k8sgen_field_key'),
                    value: e.sourceKey,
                    hint: context.t('k8sgen_hint_source_key'),
                    onChanged: (String v) {
                      e.sourceKey = v;
                      _regenerate();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip({
    required String labelKey,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: <Color>[_accentA, _accentB])
              : null,
          color: selected ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Text(
          context.t(labelKey),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyValueCard({
    required String titleKey,
    required IconData icon,
    required Map<String, String> map,
  }) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(icon, context.t(titleKey)),
          const SizedBox(height: 10),
          for (int i = 0; i < map.length; i++) _kvRow(map, i),
          const SizedBox(height: 6),
          _dashedButton(
            label: context.t('k8sgen_add_entry'),
            onTap: () {
              setState(() {
                map['key${map.length + 1}'] = '';
              });
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _kvRow(Map<String, String> map, int index) {
    final List<String> keys = map.keys.toList();
    final String k = keys[index];
    final TextEditingController keyCtrl = TextEditingController(text: k);
    final TextEditingController valCtrl = TextEditingController(text: map[k]);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: keyCtrl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              decoration: _inputDecoration(
                context.t('k8sgen_field_key'),
                'key',
              ),
              onSubmitted: (String v) {
                if (v.isEmpty || v == k) return;
                final String val = map[k] ?? '';
                map.remove(k);
                map[v] = val;
                _regenerate();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: TextField(
              controller: valCtrl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              decoration: _inputDecoration(
                context.t('k8sgen_field_value'),
                context.t('k8sgen_hint_value'),
              ),
              onChanged: (String v) {
                map[k] = v;
                _regenerate();
              },
            ),
          ),
          _miniIconButton(
            icon: Icons.close_rounded,
            onTap: () {
              setState(() {
                map.remove(k);
              });
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapEditor({
    required String titleKey,
    required Map<String, String> map,
    required List<String> keyPresets,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.t(titleKey),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        for (final MapEntry<String, String> e in map.entries.toList())
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    e.key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: TextEditingController(text: e.value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    decoration: _inputDecoration(
                      context.t('k8sgen_field_value'),
                      context.t('k8sgen_hint_value'),
                    ),
                    onChanged: (String v) {
                      map[e.key] = v;
                      onChanged();
                    },
                  ),
                ),
                _miniIconButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    setState(() {
                      map.remove(e.key);
                    });
                    onChanged();
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        if (keyPresets.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: keyPresets.map((String p) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    map[p] = '';
                  });
                  onChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _accentB.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _accentB.withOpacity(0.4)),
                  ),
                  child: Text(
                    p,
                    style: const TextStyle(
                      color: _accentB,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildOutput() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.code_rounded,
                  context.t('k8sgen_section_output'),
                ),
              ),
              _glassIconButton(
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                tooltip: context.t('k8sgen_copy'),
                onTap: _copy,
                highlighted: _copied,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 200, maxHeight: 500),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontFamily: 'monospace',
      ),
      decoration: _inputDecoration(label, hint),
      onChanged: onChanged,
    );
  }

  Widget _numberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value.toString())
        ..selection =
        TextSelection.collapsed(offset: value.toString().length),
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontFamily: 'monospace',
      ),
      decoration: _inputDecoration(label, '0'),
      onChanged: (String v) {
        final int? parsed = int.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  Widget _enumField({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: values.map((String v) {
            final bool selected = v == value;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                      colors: <Color>[_accentA, _accentB])
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
                  v,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.25),
        fontSize: 12,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accentB, width: 1.4),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _dashedButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accentB.withOpacity(0.4)),
          color: _accentB.withOpacity(0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.add_rounded, color: _accentB, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: _accentB,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: highlighted
                ? _success.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  size: 18,
                  color: highlighted ? _success : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
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