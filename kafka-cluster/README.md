# Strimzi Kafka Cluster Configuration Documentation

**Credit**: https://strimzi.io/docs/0.15.0/#assembly-deployment-configuration-kafka-str
 
## Appendix:

- [**1.1 Sample Kafka YAML configuration**](#11-sample-kafka-yaml-configuration)
- [**1.2 Data storage considerations**](#12-data-storage-considerations)
    - [Apache Kafka and Zookeeper Storage](#apache-kafka-and-zookeeper-storage)
    - [File systems](#file-systems)
- [**1.3 Kafka and Zookeeper storage types**](#13-kafka-and-zookeeper-storage-types)
    - [Ephemeral storage](#ephemeral-storage)
    - [Persistent storage](#persistent-storage)
        - [Storage class overrides ](#storage-class-overrides)
        - [Persistent Volume Claim naming](#persistent-volume-claim-naming)
        - [Log directories](#log-directories)
    - [Adding volumes to JBOD storage](#adding-volumes-to-jbod-storage)
    - [Removing volumes from JBOD storage](#removing-volumes-from-jbod-storage)
- [**1.4 Kafka broker replicas**](#14-kafka-broker-replicas)
    - [Configuring the number of broker nodes](#configuring-the-number-of-broker-nodes)
- [**1.5 Kafka broker configuration**](#15-kafka-broker-configuration)
    - [Kafka broker configuration](#kafka-broker-configuration)
    - [Configuring Kafka brokers](#configuring-kafka-brokers)
- [**1.6 Kafka broker listeners**](#16-kafka-broker-listeners)
    - [Kafka listeners](#kafka-listeners)
    - [Configuring Kafka listeners](#configuring-kafka-listeners)
    - [Listener authentication](#listener-authentication)
        - [Authentication configuration for a listener](#authentication-configuration-for-a-listener)
        - [Mutual TLS Authentication](#mutual-tls-authentication)
        - [SCRAM-SHA Authentication](#scram-sha-authentication)
    - [External listeners](#external-listeners)

### 1.1 Sample Kafka YAML configuration

For help in understanding the configuration options available for your **Kafka** deployment, refer to sample YAML file 
provided here.

The sample shows only some of the possible configuration options, but those that are particularly important include:

- Resource requests (CPU / Memory)

- JVM options for maximum and minimum memory allocation

- Listeners (and authentication)

- Authentication

- Storage

- Rack awareness

- Metrics

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    replicas: 3 # (1)
    version: 0.15.0 # (2)
    resources: # (3)
      requests:
        memory: 64Gi
        cpu: "8"
      limits: # (4)
        memory: 64Gi
        cpu: "12"
    jvmOptions: # (5)
      -Xms: 8192m
      -Xmx: 8192m
    listeners: # (6)
      tls:
        authentication: # (7)
          type: tls
      external: (8)
        type: route
        authentication:
          type: tls
    authorization: # (9)
      type: simple
    config: # (10)
      auto.create.topics.enable: "false"
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
    storage: # (11)
      type: persistent-claim # (12)
      size: 10000Gi # (13)
    rack: # (14)
      topologyKey: failure-domain.beta.kubernetes.io/zone
    metrics: # (15)
      lowercaseOutputName: true
      rules: # (16)
      # Special cases and very specific rules
      - pattern : kafka.server<type=(.+), name=(.+), clientId=(.+), topic=(.+), partition=(.*)><>Value
        name: kafka_server_$1_$2
        type: GAUGE
        labels:
          clientId: "$3"
          topic: "$4"
          partition: "$5"
        # ...
  zookeeper: # (17)
    replicas: 3
    resources:
      requests:
        memory: 8Gi
        cpu: "2"
      limits:
        memory: 8Gi
        cpu: "2"
    jvmOptions:
      -Xms: 4096m
      -Xmx: 4096m
    storage:
      type: persistent-claim
      size: 1000Gi
    metrics:
      # ...
  entityOperator: # (18)
    topicOperator:
      resources:
        requests:
          memory: 512Mi
          cpu: "1"
        limits:
          memory: 512Mi
          cpu: "1"
    userOperator:
      resources:
        requests:
          memory: 512Mi
          cpu: "1"
        limits:
          memory: 512Mi
          cpu: "1"
  kafkaExporter: # (19)
    # ...
```

1. Replicas specifies the number of broker nodes.

2. **Kafka** version, which can be changed by following the upgrade procedure.

3. Resource requests specify the resources to reserve for a given container.

4. Resource limits specify the maximum resources that can be consumed by a container.

5. JVM options can specify the minimum (`-Xms`) and maximum (`-Xmx`) memory allocation for **JVM**.

6. Listeners configure how clients connect to the **Kafka** cluster via bootstrap addresses. Listeners are configured as 
`plain` (without encryption), `tls` or `external`.

7. Listener authentication mechanisms may be configured for each listener, and specified as mutual **TLS** or **SCRAM-SHA**.

8. External listener configuration specifies how the **Kafka** cluster is exposed outside **Kubernetes**, such as through 
a `route`, `loadbalancer` or `nodeport`.

9. Authorization enables `simple` authorization on the Kafka broker using the `SimpleAclAuthorizer` **Kafka** plugin.

10. Config specifies the broker configuration. Standard **Apache Kafka** configuration may be provided, restricted to those 
properties not managed directly by **Strimzi**.

11. Storage is configured as `ephemeral`, `persistent-claim` or `jbod` (just a bunch of disks).

12. Storage size for persistent volumes may be increased and additional volumes may be added to **JBOD** storage.

13. Persistent storage has additional configuration options, such as a storage `id` and `class` for dynamic volume 
provisioning.

14. Rack awareness is configured to spread replicas across different racks. A `topology` key must match the label of 
a cluster node.

15. **Kafka** metrics configuration for use with Prometheus.

16. **Kafka** rules for exporting metrics to a **Grafana** dashboard through the **JMX Exporter**. A set of rules provided 
with **Strimzi** may be copied to your **Kafka** resource configuration.

17. **ZooKeeper**-specific configuration, which contains properties similar to the **Kafka** configuration.

18. **Entity Operator** configuration, which specifies the configuration for the **Topic Operator** and **User Operator**.

19. Kafka Exporter configuration, which is used to expose data as Prometheus metrics.

### 1.2 Data storage considerations

An efficient data storage infrastructure is essential to the optimal performance of **Strimzi**.

**Strimzi** requires *block storage* and is designed to work optimally with cloud-based block storage solutions, including 
**Amazon Elastic Block Store (EBS)**. The use of file storage (for example, **NFS**) is not recommended.

Choose local storage (local persistent volumes) when possible. If local storage is not available, you can use a **Storage 
Area Network (SAN)** accessed by a protocol such as **Fibre Channel** or **iSCSI**.

#### Apache Kafka and ZooKeeper storage

Use separate disks for **Apache Kafka** and **ZooKeeper**.

Three types of data storage are supported:

- **Ephemeral** (Recommended for development only)
- **Persistent**
- **JBOD** (Just a Bunch of Disks, suitable for **Kafka** only)

Solid-state drives (SSDs), though not essential, can improve the performance of **Kafka** in large clusters where data is 
sent to and received from multiple topics asynchronously. **SSD**s are particularly effective with **ZooKeeper**, which 
requires fast, low latency data access.

#### File systems

It is recommended that you configure your storage system to use the **XFS** file system. **Strimzi** is also compatible 
with the **ext4** file system, but this might require additional configuration for best results.

### 1.3 Kafka and ZooKeeper storage types

As stateful applications, **Kafka** and **ZooKeeper** need to store data on disk. **Strimzi** supports three storage types 
for this data:

- Ephemeral
- Persistent
- JBOD storage

**!!! NOTE**

**JBOD** storage is supported only for **Kafka**, not for **ZooKeeper**. When configuring a **Kafka** resource, you can 
specify the type of storage used by the **Kafka** broker and its corresponding **ZooKeeper** node. You configure the storage 
type using the storage property in the following resources:

- `Kafka.spec.kafka`
- `Kafka.spec.zookeeper`

The storage type is configured in the `type` field.

**!!! WARNING**

The storage type cannot be changed after a **Kafka** cluster is deployed.

#### Ephemeral storage

Ephemeral storage uses the `emptyDir` volumes to store data. To use ephemeral storage, the type field should be set to
`ephemeral`.

**!!! IMPORTANT**

`EmptyDir` volumes are not persistent and the data stored in them will be lost when the Pod is restarted. After the new 
pod is started, it has to recover all data from other nodes of the cluster. Ephemeral storage is not suitable for use 
with single node ZooKeeper clusters and for Kafka topics with replication factor 1, because it will lead to data loss.

An example of Ephemeral storage:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
    storage:
      type: ephemeral
    # ...
  zookeeper:
    # ...
    storage:
      typ`e: ephemeral
    # ...
```

The ephemeral volume will be used by the **Kafka** brokers as log directories mounted into the following path:`

    /var/lib/kafka/data/kafka-log_idx_`

Where `idx` is the **Kafka** broker pod index. For example `/var/lib/kafka/data/kafka-log0`.

#### Persistent storage

Persistent storage uses **Persistent Volume Claims (PVC)** to provision persistent volumes for storing data. **PVC** can 
be used to provision volumes of many different types, depending on the **Storage Class** which will provision the volume. 
The data types which can be used with persistent volume claims include many types of SAN storage as well as Local 
persistent volumes.

To use persistent storage, the `type` has to be set to `persistent-claim`. Persistent storage supports additional 
configuration options:

- `id` (optional):
    Storage identification number. This option is mandatory for storage volumes defined in a **JBOD** storage declaration. 
    Default is `0`.

- `size` (required)
    Defines the size of the persistent volume claim, for example, "1000Gi".

- `class` (optional)
    The **Kubernetes** **Storage Class** to use for dynamic volume provisioning.

- `selector` (optional)
    Allows selecting a specific persistent volume to use. It contains key:value pairs representing labels for selecting 
    such a volume.

- `deleteClaim` (optional)
    Boolean value which specifies if the Persistent Volume Claim has to be deleted when the cluster is undeployed. 
    Default is `false`.
    
**!!! WARNING**

Increasing the size of persistent volumes in an existing **Strimzi** cluster is only supported in **Kubernetes** versions 
that support *persistent volume resizing*. The persistent volume to be resized must use a storage class that supports 
volume expansion. For other versions of **Kubernetes** and storage classes which do not support volume expansion, you must 
decide the necessary storage size before deploying the cluster. Decreasing the size of existing persistent volumes is 
not possible.

---

Example fragment of persistent storage configuration with 1000Gi `size`:

```yaml
# ...
storage:
  type: persistent-claim
  size: 1000Gi
# ...
```

--- 

The following example demonstrates the use of a storage class. Example fragment of persistent storage configuration with 
specific **Storage Class**:

```yaml
# ...
storage:
  type: persistent-claim
  size: 1Gi
  class: my-storage-c`lass
# ...
```

--- 
Finally, a `selector` can be used to select a specific labeled persistent volume to provide needed features such as an SSD.
Example fragment of persistent storage configuration with selector:

```yaml
# ...
storage:
  type: persistent-claim
  size: 1Gi
  selector:
    hdd-type: ssd
  deleteClaim: true
# ...
```

---

##### Storage Class Overrides

You can specify a different storage class for one or more **Kafka** brokers, instead of using the default storage class. 
This is useful if, for example, storage classes are restricted to different availability zones or data centers. You can use 
the `overrides` field for this purpose. In this example, the default storage class is named `my-storage-class`:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  labels:
    app: my-cluster
  name: my-cluster
  namespace: myproject
spec:
  # ...
  kafka:
    replicas: 3
    storage:
      deleteClaim: true
      size: 100Gi
      type: persistent-claim
      class: my-storage-class
      overrides:
        - broker: 0
          class: my-storage-class-zone-1a
        - broker: 1
          class: my-storage-class-zone-1b
        - broker: 2
          class: my-storage-class-zone-1c
  # ...
```

---

As a result of the configured overrides property, the broker volumes use the following storage classes:

- The persistent volumes of broker 0 will use `my-storage-class-zone-1a`.
- The persistent volumes of broker 1 will use `my-storage-class-zone-1b`.
- The persistent volumes of broker 2 will use `my-storage-class-zone-1c`.

The `overrides` property is currently used only to override storage class configurations. Overriding other storage 
configuration fields is not currently supported. Other fields from the storage configuration are currently not supported.

##### Persistent Volume Claim Naming

When persistent storage is used, it creates **Persistent Volume Claims** with the following names:

- `[data-cluster-name]-kafka-idx`:
    **Persistent Volume Claim** for the volume used for storing data for the **Kafka** broker pod `idx`.

- `[data-cluster-name]-zookeeper-idx`:
    **Persistent Volume Claim** for the volume used for storing data for the **ZooKeeper** node pod `idx`.
    
##### Log directories

The persistent volume will be used by the **Kafka** brokers as log directories mounted into the following path:

- `/var/lib/kafka/data/kafka-log_idx_`:
    Where `idx` is the **Kafka** broker pod index. For example `/var/lib/kafka/data/kafka-log0`.
    
#### Adding volumes to JBOD storage

This procedure describes how to add volumes to a **Kafka*-* cluster configured to use **JBOD** storage. It cannot be applied to 
**Kafka** clusters configured to use any other storage type.
    
**!!! NOTE**

When adding a new volume under an `id` which was already used in the past and removed, you have to make sure that the 
previously used **PersistentVolumeClaims** have been deleted.

Prerequisites:

- A **Kubernetes** cluster
- A running **Cluster Operator**
- A **Kafka** cluster with **JBOD** storage.

Procedure

1. Edit the `spec.kafka.storage.volumes` property in the `Kafka` resource. Add the new volumes to the `volumes` array.
For example, add the new volume with id `2`.

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 100Gi
        deleteClaim: false
      - id: 1
        type: persistent-claim
        size: 100Gi
        deleteClaim: false
      - id: 2
        type: persistent-claim
        size: 100Gi
        deleteClaim: false
    # ...
  zookeeper:
    # ...
```

2. Create or update the resource.

This can be done using `kubectl apply`:

    kubectl apply -f your-file
    
#### Removing volumes from JBOD storage

This procedure describes how to remove volumes from **Kafka** cluster configured to use **JBOD** storage. It cannot be applied 
to **Kafka** clusters configured to use any other storage type. The **JBOD** storage always has to contain at least one volume.

**!!! IMPORTANT**

To avoid data loss, you have to move all partitions before removing the volumes.

Prerequisites:

- A **Kubernetes** cluster

- A running **Cluster Operator**

- A **Kafka** cluster with **JBOD** storage with two or more volumes.

Procedure:

1. Reassign all partitions from the disks which are you going to remove. Any data in partitions still assigned to the
disks which are going to be removed might be lost.

2. Edit the `spec.kafka.storage.volumes` property in `Kafka` resource. Remove one or more volumes from the `volumes` array.
For example, remove the volumes with ids `1` and `2`.

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 100Gi
        deleteClaim: false
    # ...
  zookeeper:
    # ...
```

3. Create or update the resource.

   This can be done using `kubectl apply`:
   
        kubectl apply -f your-file
        
### 1.4 Kafka broker replicas

A **Kafka** cluster can run with many brokers. You can configure the number of brokers used for the **Kafka** cluster in
`Kafka.spec.kafka.replicas`. The best number of brokers for your cluster hast to be determined based on your specific use
case.

#### Configuring the number of broker nodes

This procedure describes how to configure the number of **Kafka** broker nodes in a new cluster. It only applies to new
clusters with no partitions.

Prerequisites

- A **Kubernetes** cluster
- A running **Cluster Operator**
- A **Kafka** cluster with no topics defined yet.

Procedure

1. Edit the `replicas` property in the `Kafka` resource. For example:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
    replicas: 3
    # ...
  zookeeper:
    # ...
```

2. Create or update the resource.

   This can be done using `kubectl apply:

       kubectl apply -f your-file

### 1.5 Kafka broker configuration

**Strimzi** allows you to customize the configuration of the **Kafka** brokers in your **Kafka** cluster. You can specify and 
configure most of the options listed in the "Broker Configs" section of the **Apache Kafka** documentation. You cannot 
configure options that are related to the following areas:

- Security (Encryption, Authentication, and Authorization)
- Listener configuration
- Broker ID configuration
- Configuration of log data directories
- Inter-broker communication
- ZooKeeper connectivity

These options are automatically configured by **Strimzi**.

#### Kafka broker configuration

The config property in `Kafka.spec.kafka` contains **Kafka** broker configuration options as keys with values in one of 
the following JSON types:

- String
- Number
- Boolean

You can specify and configure all of the options in the "Broker Configs" section of the **Apache Kafka** documentation apart 
from those managed directly by **Strimzi.** Specifically, you are prevented from modifying all configuration options with 
keys equal to or starting with one of the following strings:

- `listeners`
- `advertised.`
- `broker.`
- `listener.`
- `host.name`
- `port`
- `inter.broker.listener.name`
- `sasl.`
- `ssl.`
- `security.`
- `password.`
- `principal.builder.class`
- `log.dir`
- `zookeeper.connect`
- `zookeeper.set.acl`
- `authorizer.`
- `super.user`

If the config property specifies a restricted option, it is ignored and a warning message is printed to the **Cluster 
Operator** log file. All other supported options are passed to **Kafka**.

An example **Kafka** broker configuration

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
    config:
      num.partitions: 1
      num.recovery.threads.per.data.dir: 1
      default.replication.factor: 3
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 1
      log.retention.hours: 168
      log.segment.bytes: 1073741824
      log.retention.check.interval.ms: 300000
      num.network.threads: 3
      num.io.threads: 8
      socket.send.buffer.bytes: 102400
      socket.receive.buffer.bytes: 102400
      socket.request.max.bytes: 104857600
      group.initial.rebalance.delay.ms: 0
    # ...
```

#### Configuring Kafka brokers

You can configure an existing **Kafka** broker, or create a new **Kafka** broker with a specified configuration.

Prerequisites

- A **Kubernetes** cluster is available.
- The **Cluster Operator** is running.

Procedure

1. Open the YAML configuration file that contains the `Kafka` resource specifying the cluster deployment.

2. In the `spec.kafka.config` property in the `Kafka` resource, enter one or more **Kafka** configuration settings. 
For example:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
spec:
  kafka:
    # ...
    config:
      default.replication.factor: 3
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 1
    # ...
  zookeeper:
    # ...
```

3. Apply the new configuration to create or update the resource.

    Use `kubectl apply`:

        kubectl apply -f kafka.yaml
        
where `kafka.yaml` is the YAML configuration file for the resource that you want to configure; for example, 
`kafka-persistent.yaml`.

### 1.6 Kafka broker listeners

You can configure the listeners enabled in **Kafka** brokers. The following types of listener are supported:

- Plain listener on port 9092 (without encryption)
- TLS listener on port 9093 (with encryption)
- External listener on port 9094 for access from outside of Kubernetes

OAuth 2.0
If you are using OAuth 2.0 token based authentication, you can configure the listeners to connect to your authorization 
server. For more information, see Using OAuth 2.0 token based authentication.

#### Kafka listeners

You can configure **Kafka** broker listeners using the `listeners` property in the `Kafka.spec.kafka` resource. The 
`listeners` property contains three sub-properties:

- `plain`
- `tls`
- `external`

Each listener will only be defined when the listeners object has the given property.

An example of `listeners` property with all listeners enabled:

```yaml
# ...
listeners:
  plain: {}
  tls: {}
  external:
    type: loadbalancer
# ...
```

---

An example of `listeners` property with only the plain listener enabled

```yaml
# ...
listeners:
  plain: {}
# ...
```

#### Configuring Kafka listeners

Prerequisites

- A **Kubernetes** cluster
- A running **Cluster Operator**

Procedure

1. Edit the `listeners` property in the `Kafka.spec.kafka` resource.

An example configuration of the plain (unencrypted) listener without authentication:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
spec:
  kafka:
    # ...
    listeners:
      plain: {}
    # ...
  zookeeper:
    # ...
```

2. Create or update the resource.

    This can be done using `kubectl` apply:

        kubectl apply -f your-file
        
#### Listener authentication

The listener `authentication` property is used to specify an authentication mechanism specific to that listener:

- **Mutual TLS** authentication (only on the listeners with **TLS** encryption)
- **SCRAM-SHA** authentication

If no `authentication` property is specified then the listener does not authenticate clients which connect through that listener.
Authentication must be configured when using the **User Operator** to manage `KafkaUsers`.

##### Authentication configuration for a listener

The following example shows:

- A `plain` listener configured for **SCRAM-SHA** authentication
- A `tls` listener with **mutual TLS** authentication
- An `external` listener with **mutual TLS** authentication

An example showing listener authentication configuration:

```yaml
An example showing listener authentication configuration
# ...
listeners:
  plain:
    authentication:
      type: scram-sha-512
  tls:
    authentication:
      type: tls
  external:
    type: loadbalancer
    tls: true
    authentication:
      type: tls
# ...
```

##### Mutual TLS authentication

**Mutual TLS** authentication is always used for the communication between **Kafka** brokers and **ZooKeeper** pods.

**Mutual authentication** or **two-way authentication** is when both the server and the client present certificates. 
**Strimzi** can configure **Kafka** to use **TLS (Transport Layer Security)** to provide encrypted communication between 
**Kafka** brokers and clients either with or without mutual authentication. When you configure mutual authentication, the 
broker authenticates the client and the client authenticates the broker.

**!!! NOTE**
**TLS** authentication is more commonly one-way, with one party authenticating the identity of another. For example, when 
HTTPS is used between a web browser and a web server, the server obtains proof of the identity of the browser. When to 
use **mutual TLS** authentication for clients **Mutual TLS** authentication is recommended for authenticating **Kafka** 
clients when:

- The client supports authentication using **mutual TLS** authentication
- It is necessary to use the **TLS** certificates rather than passwords
- You can reconfigure and restart client applications periodically so that they do not use expired certificates.

##### SCRAM-SHA authentication

**SCRAM (Salted Challenge Response Authentication Mechanism)** is an authentication protocol that can establish mutual 
authentication using passwords. **Strimzi** can configure **Kafka** to use **SASL (Simple Authentication and Security Layer)**
**SCRAM-SHA-512** to provide authentication on both unencrypted and TLS-encrypted client connections. **TLS** authentication is 
always used internally between **Kafka** brokers and **ZooKeeper** nodes. When used with a **TLS** client connection, the 
**TLS** protocol provides encryption, but is not used for authentication.

The following properties of **SCRAM** make it safe to use **SCRAM-SHA** even on unencrypted connections:

- The passwords are not sent in the clear over the communication channel. Instead the client and the server are each 
challenged by the other to offer proof that they know the password of the authenticating user.
- The server and client each generate a new challenge for each authentication exchange. This means that the exchange is 
resilient against replay attacks.

**Strimzi** supports **SCRAM-SHA-512** only. When a `KafkaUser.spec.authentication.type` is configured with `scram-sha-512` 
the **User Operator** will generate a random 12 character password consisting of upper and lowercase ASCII letters and numbers.

When to use **SCRAM-SHA** authentication for clients

**SCRAM-SHA** is recommended for authenticating **Kafka** clients when:

- The client supports authentication using **SCRAM-SHA-512**
- It is necessary to use passwords rather than the **TLS** certificates
- Authentication for unencrypted communication is required

#### External listeners


