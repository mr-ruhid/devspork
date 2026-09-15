enum K8sResourceType {
  deployment,
  service,
  configMap,
  secret,
  ingress,
  namespace,
  pvc,
  cronJob,
  job,
  statefulSet,
  daemonSet,
  hpa,
}

class K8sMetadata {
  String name;
  String namespace;
  Map<String, String> labels;
  Map<String, String> annotations;

  K8sMetadata({
    this.name = '',
    this.namespace = 'default',
    Map<String, String>? labels,
    Map<String, String>? annotations,
  })  : labels = labels ?? <String, String>{},
        annotations = annotations ?? <String, String>{};
}

class ContainerPort {
  String name;
  int port;
  String protocol;
  int? targetPort;

  ContainerPort({
    this.name = '',
    this.port = 80,
    this.protocol = 'TCP',
    this.targetPort,
  });
}

class EnvVar {
  String key;
  String value;
  bool isSecret;
  bool isConfigMap;
  String sourceName;
  String sourceKey;

  EnvVar({
    this.key = '',
    this.value = '',
    this.isSecret = false,
    this.isConfigMap = false,
    this.sourceName = '',
    this.sourceKey = '',
  });
}

class ResourceLimits {
  String cpuRequest;
  String cpuLimit;
  String memoryRequest;
  String memoryLimit;

  ResourceLimits({
    this.cpuRequest = '',
    this.cpuLimit = '',
    this.memoryRequest = '',
    this.memoryLimit = '',
  });

  bool get isEmpty =>
      cpuRequest.isEmpty &&
          cpuLimit.isEmpty &&
          memoryRequest.isEmpty &&
          memoryLimit.isEmpty;
}

class ContainerConfig {
  String name;
  String image;
  String imagePullPolicy;
  List<ContainerPort> ports;
  List<EnvVar> env;
  ResourceLimits resources;
  List<String> command;
  List<String> args;

  ContainerConfig({
    this.name = 'app',
    this.image = '',
    this.imagePullPolicy = 'IfNotPresent',
    List<ContainerPort>? ports,
    List<EnvVar>? env,
    ResourceLimits? resources,
    List<String>? command,
    List<String>? args,
  })  : ports = ports ?? <ContainerPort>[],
        env = env ?? <EnvVar>[],
        resources = resources ?? ResourceLimits(),
        command = command ?? <String>[],
        args = args ?? <String>[];
}

class DeploymentConfig {
  K8sMetadata metadata;
  int replicas;
  String selectorKey;
  String selectorValue;
  ContainerConfig container;

  DeploymentConfig({
    K8sMetadata? metadata,
    this.replicas = 1,
    this.selectorKey = 'app',
    this.selectorValue = '',
    ContainerConfig? container,
  })  : metadata = metadata ?? K8sMetadata(),
        container = container ?? ContainerConfig();
}

class StatefulSetConfig {
  K8sMetadata metadata;
  int replicas;
  String serviceName;
  String selectorKey;
  String selectorValue;
  ContainerConfig container;

  StatefulSetConfig({
    K8sMetadata? metadata,
    this.replicas = 1,
    this.serviceName = '',
    this.selectorKey = 'app',
    this.selectorValue = '',
    ContainerConfig? container,
  })  : metadata = metadata ?? K8sMetadata(),
        container = container ?? ContainerConfig();
}

class DaemonSetConfig {
  K8sMetadata metadata;
  String selectorKey;
  String selectorValue;
  ContainerConfig container;

  DaemonSetConfig({
    K8sMetadata? metadata,
    this.selectorKey = 'app',
    this.selectorValue = '',
    ContainerConfig? container,
  })  : metadata = metadata ?? K8sMetadata(),
        container = container ?? ContainerConfig();
}

class ServicePort {
  String name;
  int port;
  int targetPort;
  String protocol;
  int? nodePort;

  ServicePort({
    this.name = '',
    this.port = 80,
    this.targetPort = 80,
    this.protocol = 'TCP',
    this.nodePort,
  });
}

class ServiceConfig {
  K8sMetadata metadata;
  String type;
  String selectorKey;
  String selectorValue;
  List<ServicePort> ports;
  String clusterIP;
  String sessionAffinity;

  ServiceConfig({
    K8sMetadata? metadata,
    this.type = 'ClusterIP',
    this.selectorKey = 'app',
    this.selectorValue = '',
    List<ServicePort>? ports,
    this.clusterIP = '',
    this.sessionAffinity = 'None',
  })  : metadata = metadata ?? K8sMetadata(),
        ports = ports ?? <ServicePort>[ServicePort()];
}

class ConfigMapConfig {
  K8sMetadata metadata;
  Map<String, String> data;

  ConfigMapConfig({
    K8sMetadata? metadata,
    Map<String, String>? data,
  })  : metadata = metadata ?? K8sMetadata(),
        data = data ?? <String, String>{};
}

class SecretConfig {
  K8sMetadata metadata;
  String type;
  Map<String, String> data;
  bool encodeBase64;

  SecretConfig({
    K8sMetadata? metadata,
    this.type = 'Opaque',
    Map<String, String>? data,
    this.encodeBase64 = true,
  })  : metadata = metadata ?? K8sMetadata(),
        data = data ?? <String, String>{};
}

class IngressPath {
  String path;
  String pathType;
  String serviceName;
  int servicePort;

  IngressPath({
    this.path = '/',
    this.pathType = 'Prefix',
    this.serviceName = '',
    this.servicePort = 80,
  });
}

class IngressRule {
  String host;
  List<IngressPath> paths;

  IngressRule({
    this.host = '',
    List<IngressPath>? paths,
  }) : paths = paths ?? <IngressPath>[IngressPath()];
}

class IngressTls {
  String secretName;
  List<String> hosts;

  IngressTls({
    this.secretName = '',
    List<String>? hosts,
  }) : hosts = hosts ?? <String>[];
}

class IngressConfig {
  K8sMetadata metadata;
  String ingressClassName;
  List<IngressRule> rules;
  List<IngressTls> tls;

  IngressConfig({
    K8sMetadata? metadata,
    this.ingressClassName = 'nginx',
    List<IngressRule>? rules,
    List<IngressTls>? tls,
  })  : metadata = metadata ?? K8sMetadata(),
        rules = rules ?? <IngressRule>[IngressRule()],
        tls = tls ?? <IngressTls>[];
}

class PvcConfig {
  K8sMetadata metadata;
  String accessMode;
  String size;
  String storageClass;

  PvcConfig({
    K8sMetadata? metadata,
    this.accessMode = 'ReadWriteOnce',
    this.size = '1Gi',
    this.storageClass = '',
  }) : metadata = metadata ?? K8sMetadata();
}

class CronJobConfig {
  K8sMetadata metadata;
  String schedule;
  String concurrencyPolicy;
  int? successfulJobsHistoryLimit;
  int? failedJobsHistoryLimit;
  int backoffLimit;
  ContainerConfig container;

  CronJobConfig({
    K8sMetadata? metadata,
    this.schedule = '*/5 * * * *',
    this.concurrencyPolicy = 'Allow',
    this.successfulJobsHistoryLimit,
    this.failedJobsHistoryLimit,
    this.backoffLimit = 6,
    ContainerConfig? container,
  })  : metadata = metadata ?? K8sMetadata(),
        container = container ?? ContainerConfig();
}

class JobConfig {
  K8sMetadata metadata;
  int completions;
  int parallelism;
  int backoffLimit;
  ContainerConfig container;

  JobConfig({
    K8sMetadata? metadata,
    this.completions = 1,
    this.parallelism = 1,
    this.backoffLimit = 6,
    ContainerConfig? container,
  })  : metadata = metadata ?? K8sMetadata(),
        container = container ?? ContainerConfig();
}

class HpaConfig {
  K8sMetadata metadata;
  String targetKind;
  String targetName;
  int minReplicas;
  int maxReplicas;
  int cpuTarget;
  int memoryTarget;

  HpaConfig({
    K8sMetadata? metadata,
    this.targetKind = 'Deployment',
    this.targetName = '',
    this.minReplicas = 1,
    this.maxReplicas = 10,
    this.cpuTarget = 80,
    this.memoryTarget = 0,
  }) : metadata = metadata ?? K8sMetadata();
}