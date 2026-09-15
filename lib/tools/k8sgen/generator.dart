import 'dart:convert';
import 'models.dart';

class K8sYamlGenerator {
  K8sYamlGenerator._();

  static String generate(K8sResourceType type, Object config) {
    switch (type) {
      case K8sResourceType.deployment:
        return _deployment(config as DeploymentConfig);
      case K8sResourceType.statefulSet:
        return _statefulSet(config as StatefulSetConfig);
      case K8sResourceType.daemonSet:
        return _daemonSet(config as DaemonSetConfig);
      case K8sResourceType.service:
        return _service(config as ServiceConfig);
      case K8sResourceType.configMap:
        return _configMap(config as ConfigMapConfig);
      case K8sResourceType.secret:
        return _secret(config as SecretConfig);
      case K8sResourceType.ingress:
        return _ingress(config as IngressConfig);
      case K8sResourceType.namespace:
        return _namespace(config as K8sMetadata);
      case K8sResourceType.pvc:
        return _pvc(config as PvcConfig);
      case K8sResourceType.cronJob:
        return _cronJob(config as CronJobConfig);
      case K8sResourceType.job:
        return _job(config as JobConfig);
      case K8sResourceType.hpa:
        return _hpa(config as HpaConfig);
    }
  }

  static String _deployment(DeploymentConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: apps/v1');
    _w(sb, 0, 'kind: Deployment');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    _w(sb, 0, 'spec:');
    _w(sb, 2, 'replicas: ${c.replicas}');
    _w(sb, 2, 'selector:');
    _w(sb, 4, 'matchLabels:');
    _w(sb, 6, '${c.selectorKey}: ${_q(c.selectorValue.isNotEmpty ? c.selectorValue : c.metadata.name)}');
    _w(sb, 2, 'template:');
    _w(sb, 4, 'metadata:');
    _w(sb, 6, 'labels:');
    _w(sb, 8, '${c.selectorKey}: ${_q(c.selectorValue.isNotEmpty ? c.selectorValue : c.metadata.name)}');
    _w(sb, 4, 'spec:');
    _w(sb, 6, 'containers:');
    _container(sb, 8, c.container, restartPolicy: null);
    return _trim(sb);
  }

  static String _statefulSet(StatefulSetConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: apps/v1');
    _w(sb, 0, 'kind: StatefulSet');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    _w(sb, 0, 'spec:');
    _w(sb, 2, 'serviceName: ${_q(c.serviceName.isNotEmpty ? c.serviceName : c.metadata.name)}');
    _w(sb, 2, 'replicas: ${c.replicas}');
    _w(sb, 2, 'selector:');
    _w(sb, 4, 'matchLabels:');
    _w(sb, 6, '${c.selectorKey}: ${_q(c.selectorValue.isNotEmpty ? c.selectorValue : c.metadata.name)}');
    _w(sb, 2, 'template:');
    _w(sb, 4, 'metadata:');
    _w(sb, 6, 'labels:');
    _w(sb, 8, '${c.selectorKey}: ${_q(c.selectorValue.isNotEmpty ? c.selectorValue : c.metadata.name)}');
    _w(sb, 4, 'spec:');
    _w(sb, 6, 'containers:');
    _container(sb, 8, c.container, restartPolicy: null);
    return _trim(sb);
  }

  static String _daemonSet(DaemonSetConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: apps/v1');
    _w(sb, 0, 'kind: DaemonSet');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    _w(sb, 0, 'spec:');
    _w(sb, 2, 'selector:');
    _w(sb, 4, 'matchLabels:');
    _w(sb, 6, '${c.selectorKey}: ${_q(c.selectorValue.isNotEmpty ? c.selectorValue : c.metadata.name)}');
    _w(sb, 2, 'template:');
    _w(sb, 4, 'metadata:');
    _w(sb, 6, 'labels:');
    _w(sb, 8, '${c.selectorKey}: ${_q(c.selectorValue.isNotEmpty ? c.selectorValue : c.metadata.name)}');
    _w(sb, 4, 'spec:');
    _w(sb, 6, 'containers:');
    _container(sb, 8, c.container, restartPolicy: null);
    return _trim(sb);
  }

  static String _service(ServiceConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: v1');
    _w(sb, 0, 'kind: Service');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    _w(sb, 0, 'spec:');
    _w(sb, 2, 'type: ${c.type}');
    if (c.clusterIP.isNotEmpty) {
      _w(sb, 2, 'clusterIP: ${_q(c.clusterIP)}');
    }
    if (c.sessionAffinity != 'None') {
      _w(sb, 2, 'sessionAffinity: ${c.sessionAffinity}');
    }
    _w(sb, 2, 'selector:');
    _w(sb, 4, '${c.selectorKey}: ${_q(c.selectorValue.isNotEmpty ? c.selectorValue : c.metadata.name)}');
    if (c.ports.isNotEmpty) {
      _w(sb, 2, 'ports:');
      for (final ServicePort p in c.ports) {
        _w(sb, 4, '- port: ${p.port}');
        if (p.name.isNotEmpty) {
          _w(sb, 6, 'name: ${_q(p.name)}');
        }
        _w(sb, 6, 'targetPort: ${p.targetPort}');
        if (p.protocol != 'TCP') {
          _w(sb, 6, 'protocol: ${p.protocol}');
        }
        if (p.nodePort != null && c.type == 'NodePort') {
          _w(sb, 6, 'nodePort: ${p.nodePort}');
        }
      }
    }
    return _trim(sb);
  }

  static String _configMap(ConfigMapConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: v1');
    _w(sb, 0, 'kind: ConfigMap');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    if (c.data.isNotEmpty) {
      _w(sb, 0, 'data:');
      for (final MapEntry<String, String> e in c.data.entries) {
        _kv(sb, 2, e.key, e.value);
      }
    }
    return _trim(sb);
  }

  static String _secret(SecretConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: v1');
    _w(sb, 0, 'kind: Secret');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    _w(sb, 0, 'type: ${c.type}');
    if (c.data.isNotEmpty) {
      _w(sb, 0, 'data:');
      for (final MapEntry<String, String> e in c.data.entries) {
        if (c.encodeBase64) {
          final String encoded = base64.encode(utf8.encode(e.value));
          _w(sb, 2, '${e.key}: ${encoded}');
        } else {
          _w(sb, 2, '${e.key}: ${_q(e.value)}');
        }
      }
    }
    return _trim(sb);
  }

  static String _ingress(IngressConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: networking.k8s.io/v1');
    _w(sb, 0, 'kind: Ingress');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    _w(sb, 0, 'spec:');
    if (c.ingressClassName.isNotEmpty) {
      _w(sb, 2, 'ingressClassName: ${_q(c.ingressClassName)}');
    }
    if (c.rules.isNotEmpty) {
      _w(sb, 2, 'rules:');
      for (final IngressRule r in c.rules) {
        if (r.host.isNotEmpty) {
          _w(sb, 4, '- host: ${_q(r.host)}');
          _w(sb, 6, 'http:');
        } else {
          _w(sb, 4, '- http:');
        }
        _w(sb, 8, 'paths:');
        for (final IngressPath p in r.paths) {
          _w(sb, 10, '- path: ${_q(p.path)}');
          _w(sb, 12, 'pathType: ${p.pathType}');
          _w(sb, 12, 'backend:');
          _w(sb, 14, 'service:');
          _w(sb, 16, 'name: ${_q(p.serviceName)}');
          _w(sb, 16, 'port:');
          _w(sb, 18, 'number: ${p.servicePort}');
        }
      }
    }
    if (c.tls.isNotEmpty) {
      _w(sb, 2, 'tls:');
      for (final IngressTls t in c.tls) {
        _w(sb, 4, '- hosts:');
        for (final String h in t.hosts) {
          _w(sb, 6, '- ${_q(h)}');
        }
        _w(sb, 6, 'secretName: ${_q(t.secretName)}');
      }
    }
    return _trim(sb);
  }

  static String _namespace(K8sMetadata m) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: v1');
    _w(sb, 0, 'kind: Namespace');
    _w(sb, 0, 'metadata:');
    _w(sb, 2, 'name: ${_q(m.name)}');
    if (m.labels.isNotEmpty) {
      _w(sb, 2, 'labels:');
      m.labels.forEach((String k, String v) => _w(sb, 4, '$k: ${_q(v)}'));
    }
    return _trim(sb);
  }

  static String _pvc(PvcConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: v1');
    _w(sb, 0, 'kind: PersistentVolumeClaim');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    _w(sb, 0, 'spec:');
    _w(sb, 2, 'accessModes:');
    _w(sb, 4, '- ${c.accessMode}');
    _w(sb, 2, 'resources:');
    _w(sb, 4, 'requests:');
    _w(sb, 6, 'storage: ${c.size}');
    if (c.storageClass.isNotEmpty) {
      _w(sb, 2, 'storageClassName: ${_q(c.storageClass)}');
    }
    return _trim(sb);
  }

  static String _cronJob(CronJobConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: batch/v1');
    _w(sb, 0, 'kind: CronJob');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    _w(sb, 0, 'spec:');
    _w(sb, 2, 'schedule: ${_q(c.schedule)}');
    if (c.concurrencyPolicy != 'Allow') {
      _w(sb, 2, 'concurrencyPolicy: ${c.concurrencyPolicy}');
    }
    if (c.successfulJobsHistoryLimit != null) {
      _w(sb, 2, 'successfulJobsHistoryLimit: ${c.successfulJobsHistoryLimit}');
    }
    if (c.failedJobsHistoryLimit != null) {
      _w(sb, 2, 'failedJobsHistoryLimit: ${c.failedJobsHistoryLimit}');
    }
    _w(sb, 2, 'jobTemplate:');
    _w(sb, 4, 'spec:');
    _w(sb, 6, 'backoffLimit: ${c.backoffLimit}');
    _w(sb, 6, 'template:');
    _w(sb, 8, 'spec:');
    _w(sb, 10, 'restartPolicy: OnFailure');
    _w(sb, 10, 'containers:');
    _container(sb, 12, c.container, restartPolicy: null);
    return _trim(sb);
  }

  static String _job(JobConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: batch/v1');
    _w(sb, 0, 'kind: Job');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    _w(sb, 0, 'spec:');
    _w(sb, 2, 'completions: ${c.completions}');
    _w(sb, 2, 'parallelism: ${c.parallelism}');
    _w(sb, 2, 'backoffLimit: ${c.backoffLimit}');
    _w(sb, 2, 'template:');
    _w(sb, 4, 'spec:');
    _w(sb, 6, 'restartPolicy: OnFailure');
    _w(sb, 6, 'containers:');
    _container(sb, 8, c.container, restartPolicy: null);
    return _trim(sb);
  }

  static String _hpa(HpaConfig c) {
    final StringBuffer sb = StringBuffer();
    _w(sb, 0, 'apiVersion: autoscaling/v2');
    _w(sb, 0, 'kind: HorizontalPodAutoscaler');
    _w(sb, 0, 'metadata:');
    _metadata(sb, 2, c.metadata);
    _w(sb, 0, 'spec:');
    _w(sb, 2, 'scaleTargetRef:');
    _w(sb, 4, 'apiVersion: apps/v1');
    _w(sb, 4, 'kind: ${c.targetKind}');
    _w(sb, 4, 'name: ${_q(c.targetName)}');
    _w(sb, 2, 'minReplicas: ${c.minReplicas}');
    _w(sb, 2, 'maxReplicas: ${c.maxReplicas}');
    _w(sb, 2, 'metrics:');
    if (c.cpuTarget > 0) {
      _w(sb, 4, '- type: Resource');
      _w(sb, 6, 'resource:');
      _w(sb, 8, 'name: cpu');
      _w(sb, 10, 'target:');
      _w(sb, 12, 'type: Utilization');
      _w(sb, 12, 'averageUtilization: ${c.cpuTarget}');
    }
    if (c.memoryTarget > 0) {
      _w(sb, 4, '- type: Resource');
      _w(sb, 6, 'resource:');
      _w(sb, 8, 'name: memory');
      _w(sb, 10, 'target:');
      _w(sb, 12, 'type: Utilization');
      _w(sb, 12, 'averageUtilization: ${c.memoryTarget}');
    }
    return _trim(sb);
  }

  static void _metadata(StringBuffer sb, int indent, K8sMetadata m) {
    _w(sb, indent, 'name: ${_q(m.name)}');
    if (m.namespace.isNotEmpty) {
      _w(sb, indent, 'namespace: ${_q(m.namespace)}');
    }
    if (m.labels.isNotEmpty) {
      _w(sb, indent, 'labels:');
      m.labels.forEach((String k, String v) => _w(sb, indent + 2, '$k: ${_q(v)}'));
    }
    if (m.annotations.isNotEmpty) {
      _w(sb, indent, 'annotations:');
      m.annotations.forEach((String k, String v) => _w(sb, indent + 2, '$k: ${_q(v)}'));
    }
  }

  static void _container(
      StringBuffer sb,
      int indent,
      ContainerConfig c, {
        String? restartPolicy,
      }) {
    _w(sb, indent, '- name: ${_q(c.name)}');
    _w(sb, indent + 2, 'image: ${_q(c.image)}');
    if (c.imagePullPolicy != 'IfNotPresent') {
      _w(sb, indent + 2, 'imagePullPolicy: ${c.imagePullPolicy}');
    }
    if (c.command.isNotEmpty) {
      _w(sb, indent + 2, 'command:');
      for (final String cmd in c.command) {
        _w(sb, indent + 4, '- ${_q(cmd)}');
      }
    }
    if (c.args.isNotEmpty) {
      _w(sb, indent + 2, 'args:');
      for (final String a in c.args) {
        _w(sb, indent + 4, '- ${_q(a)}');
      }
    }
    if (c.ports.isNotEmpty) {
      _w(sb, indent + 2, 'ports:');
      for (final ContainerPort p in c.ports) {
        _w(sb, indent + 4, '- containerPort: ${p.port}');
        if (p.name.isNotEmpty) {
          _w(sb, indent + 6, 'name: ${_q(p.name)}');
        }
        if (p.protocol != 'TCP') {
          _w(sb, indent + 6, 'protocol: ${p.protocol}');
        }
        if (p.targetPort != null) {
          _w(sb, indent + 6, 'hostPort: ${p.targetPort}');
        }
      }
    }
    if (c.env.isNotEmpty) {
      _w(sb, indent + 2, 'env:');
      for (final EnvVar e in c.env) {
        _w(sb, indent + 4, '- name: ${_q(e.key)}');
        if (e.isSecret) {
          _w(sb, indent + 6, 'valueFrom:');
          _w(sb, indent + 8, 'secretKeyRef:');
          _w(sb, indent + 10, 'name: ${_q(e.sourceName)}');
          _w(sb, indent + 10, 'key: ${_q(e.sourceKey)}');
        } else if (e.isConfigMap) {
          _w(sb, indent + 6, 'valueFrom:');
          _w(sb, indent + 8, 'configMapKeyRef:');
          _w(sb, indent + 10, 'name: ${_q(e.sourceName)}');
          _w(sb, indent + 10, 'key: ${_q(e.sourceKey)}');
        } else {
          _w(sb, indent + 6, 'value: ${_q(e.value)}');
        }
      }
    }
    if (!c.resources.isEmpty) {
      _w(sb, indent + 2, 'resources:');
      final bool hasReq = c.resources.cpuRequest.isNotEmpty ||
          c.resources.memoryRequest.isNotEmpty;
      final bool hasLim = c.resources.cpuLimit.isNotEmpty ||
          c.resources.memoryLimit.isNotEmpty;
      if (hasReq) {
        _w(sb, indent + 4, 'requests:');
        if (c.resources.cpuRequest.isNotEmpty) {
          _w(sb, indent + 6, 'cpu: ${c.resources.cpuRequest}');
        }
        if (c.resources.memoryRequest.isNotEmpty) {
          _w(sb, indent + 6, 'memory: ${c.resources.memoryRequest}');
        }
      }
      if (hasLim) {
        _w(sb, indent + 4, 'limits:');
        if (c.resources.cpuLimit.isNotEmpty) {
          _w(sb, indent + 6, 'cpu: ${c.resources.cpuLimit}');
        }
        if (c.resources.memoryLimit.isNotEmpty) {
          _w(sb, indent + 6, 'memory: ${c.resources.memoryLimit}');
        }
      }
    }
  }

  static void _kv(StringBuffer sb, int indent, String key, String value) {
    if (value.contains('\n')) {
      _w(sb, indent, '$key: |');
      for (final String line in value.split('\n')) {
        _w(sb, indent + 2, line);
      }
    } else {
      _w(sb, indent, '$key: ${_q(value)}');
    }
  }

  static void _w(StringBuffer sb, int indent, String line) {
    if (line.isEmpty) {
      sb.writeln();
      return;
    }
    sb.writeln('${' ' * indent}$line');
  }

  static String _trim(StringBuffer sb) {
    final String s = sb.toString();
    return s.endsWith('\n') ? s.substring(0, s.length - 1) : s;
  }

  static String _q(String v) {
    if (v.isEmpty) return '""';
    final bool needsQuote = v.contains(': ') ||
        v.contains(' #') ||
        v.startsWith(' ') ||
        v.endsWith(' ') ||
        v.startsWith('#') ||
        v.startsWith('!') ||
        v.startsWith('&') ||
        v.startsWith('*') ||
        v.startsWith('|') ||
        v.startsWith('>') ||
        v.startsWith('@') ||
        v.startsWith('`') ||
        v.startsWith('-') ||
        v == '~' ||
        v.toLowerCase() == 'true' ||
        v.toLowerCase() == 'false' ||
        v.toLowerCase() == 'null' ||
        v.toLowerCase() == 'yes' ||
        v.toLowerCase() == 'no' ||
        v.toLowerCase() == 'on' ||
        v.toLowerCase() == 'off';
    if (needsQuote) {
      final String escaped = v.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      return '"$escaped"';
    }
    return v;
  }
}