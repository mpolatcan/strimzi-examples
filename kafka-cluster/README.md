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
        - [Load balancer external listeners](#load-balancer-external-listeners)
            - [Exposing Kafka using loadbalancers](#exposing-kafka-using-loadbalancers)
            - [Customizing the DNS names of external loadbalancer listeners](#customizing-the-dns-names-of-external-loadbalancer-listeners)
            - [Customizing the loadbalancer IP addresses](#customizing-the-loadbalancer-ip-addresses)
            - [Accessing Kafka using loadbalancers](#accessing-kafka-using-loadbalancers)
        - [Node Port external listeners](#node-port-external-listeners)
            - [Exposing Kafka using node ports](#exposing-kafka-using-node-ports)
            - [Customizing the DNS names of external node port listeners](#customizing-the-dns-names-of-external-node-port-listeners)
            - [Accessing Kafka using node ports](#accessing-kafka-using-node-ports)
        - [Kubernetes Ingress external listeners](#kubernetes-ingress-external-listeners)           
            - [Exposing Kafka using Kubernetes Ingress](#exposing-kafka-using-kubernetes-ingress)
            - [Configuring the Ingress class](#configuring-the-ingress-class)
            - [Customizing the DNS names of external ingress listeners](#customizing-the-dns-names-of-external-ingress-listeners)
            - [Accessing Kafka using ingress](#accessing-kafka-using-ingress)
    - [Network policies](#network-policies)
        - [Network policy configuration for a listener](#network-policy-configuration-for-a-listener)
        - [Restricting access to Kafka listeners using networkPolicyPeers](#restricting-access-to-kafka-listeners-using-networkpolicypeers)
- [**1.7 Authentication and Authorization**](#17-authentication-and-authorization)
    - [Authentication](#authentication)
        - [TLS client authentication](#tls-client-authentication)
    - [Configuring authentication in Kafka brokers](#configuring-authentication-in-kafka-brokers)
    - [Authorization](#authorization)
        - [Simple authorization](#simple-authorization)
        - [Super users](#super-users)
    - [Configuring authorization in Kafka brokers](#configuring-authorization-in-kafka-brokers)
- [**1.8 Zookeeper replicas**](#18-zookeeper-replicas)
    - [Number of ZooKeeper nodes](#number-of-zookeeper-nodes)
    - [Changing the number of ZooKeeper replicas](#changing-the-number-of-zookeeper-replicas)
- [**1.9 ZooKeeper configuration**](#19-zookeeper-configuration)
    - [ZooKeeper configuration](#zookeeper-configuration)
    - [Configuring ZooKeeper](#configuring-zookeeper)
- [**1.10 ZooKeeper connection**](#110-zookeeper-connection)
    - [Connecting to ZooKeeper from a terminal](#connecting-to-zookeeper-from-a-terminal)
- [**1.11 Entity Operator**](#111-entity-operator)
    - [Configuration](#configuration)
        - [Topic Operator](#topic-operator)
        - [User Operator](#user-operator)
     - [Configuring Entity Operator](#configuring-entity-operator)
        
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

Use an external listener to expose your **Strimzi** **Kafka** cluster to a client outside a **Kubernetes** environment.

By default, **Strimzi** tries to automatically determine the hostnames and ports that your **Kafka** cluster advertises 
to its clients. This is not sufficient in all situations, because the infrastructure on which **Strimzi** is running might 
not provide the right hostname or port through which **Kafka** can be accessed. You can customize the advertised hostname and 
port in the `overrides` property of the external listener. **Strimzi** will then automatically configure the advertised address 
in the **Kafka** brokers and add it to the broker certificates so it can be used for TLS hostname verification. Overriding the 
advertised host and ports is available for all types of external listeners.

Example of an external listener configured with overrides for advertised addresses:

```yaml
# ...
listeners:
  external:
    type: route
    authentication:
      type: tls
    overrides:
      brokers:
      - broker: 0
        advertisedHost: example.hostname.0
        advertisedPort: 12340
      - broker: 1
        advertisedHost: example.hostname.1
        advertisedPort: 12341
      - broker: 2
        advertisedHost: example.hostname.2
        advertisedPort: 12342
# ...
```

Additionally, you can specify the name of the bootstrap service. This name will be added to the broker certificates and 
can be used for TLS hostname verification. Adding the additional bootstrap address is available for all types of external 
listeners.

Example of an external listener configured with an additional bootstrap address:

```yaml
# ...
listeners:
  external:
    type: route
    authentication:
      type: tls
    overrides:
      bootstrap:
        address: example.hostname
```

##### Load balancer external listeners

External listeners of type `loadbalancer` expose **Kafka** by using `Loadbalancer` type `Services`.

###### Exposing Kafka using loadbalancers

When exposing **Kafka** using `Loadbalancer` type `Services`, a new `loadbalancer` service is created for every **Kafka** 
broker pod. An additional loadbalancer is created to serve as a **Kafka** bootstrap address. Loadbalancers listen to 
connections on port 9094.

By default, **TLS** encryption is enabled. To disable it, set the `tls` field to `false`.

Example of an external listener of type `loadbalancer`

```yaml
# ...
listeners:
  external:
    type: loadbalancer
    authentication:
      type: tls
# ...
```

###### Customizing the DNS names of external loadbalancer listeners

On `loadbalancer` listeners, you can use the `dnsAnnotations` property to add additional annotations to the loadbalancer 
services. You can use these annotations to instrument DNS tooling such as External DNS, which automatically assigns DNS 
names to the loadbalancer services.

Example of an external listener of type `loadbalancer` using `dnsAnnotations`

```yaml
# ...
listeners:
  external:
    type: loadbalancer
    authentication:
      type: tls
    overrides:
      bootstrap:
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: kafka-bootstrap.mydomain.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
      brokers:
      - broker: 0
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: kafka-broker-0.mydomain.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
      - broker: 1
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: kafka-broker-1.mydomain.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
      - broker: 2
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: kafka-broker-2.mydomain.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
# ...
```

###### Customizing the loadbalancer IP addresses`

On `loadbalancer` listeners, you can use the `loadBalancerIP` property to request a specific IP address when creating a 
loadbalancer. Use this property when you need to use a loadbalancer with a specific IP address. The `loadBalancerIP field 
is ignored if the cloud provider does not support the feature.

Example of an external listener of type `loadbalancer` with specific loadbalancer IP address requests

```yaml
# ...
listeners:
  external:
    type: loadbalancer
    authentication:
      type: tls
    overrides:
      bootstrap:
        loadBalancerIP: 172.29.3.10
      brokers:
      - broker: 0
        loadBalancerIP: 172.29.3.1
      - broker: 1
        loadBalancerIP: 172.29.3.2
      - broker: 2
        loadBalancerIP: 172.29.3.3
# ...
```

###### Accessing Kafka using loadbalancers

Prerequisites

- A **Kubernetes** cluster
- A running **Cluster Operator**

Procedure

1. Deploy **Kafka** cluster with an external listener enabled and configured to the type `loadbalancer`. 

An example configuration with an external listener configured to use loadbalancers:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
spec:
  kafka:
    # ...
    listeners:
      external:
        type: loadbalancer
        authentication:
          type: tls
        # ...
    # ...
  zookeeper:
    # ...
```

2. Create or update the resource
 
This can be done using `kubectl apply`.
   
    kubectl apply -f your-file
        
3. Find the hostname of the bootstrap loadbalancer.

This can be done using `kubectl get`.
    
    kubectl get service [cluster-name]-kafka-external-bootstrap -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}',
  
If no hostname was found (nothing was returned by the command), use the loadbalancer IP address. 

This can be done using `kubectl get`:

    kubectl get service [cluster-name]-kafka-external-bootstrap -o=jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}'
    
Use the hostname or IP address together with port 9094 in your **Kafka** client as the bootstrap address.

4. Unless **TLS** encryption was disabled, extract the public certificate of the broker certification authority.

This can be done using `kubectl get`:

    kubectl get secret [cluster-name]-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
    
Use the extracted certificate in your **Kafka** client to configure **TLS** connection. If you enabled any authentication, you
will also need to configure **SASL** or **TLS** authentication..

##### Node Port external listeners

External listeners of type `nodeport` expose **Kafka** by using `NodePort` type `Services`

###### Exposing Kafka using node ports

When exposing **Kafka** using `NodePort` type `Services`, **Kafka** clients connect directly to the nodes of **Kubernetes**.
You must enable access to the ports on the **Kubernetes** nodes for each client (for example, in firewalls or security groups).
Each **Kafka** broker pod is then accessible on a separate port. Additional `NodePort` type `Service` is created to serve
as a **Kafka** bootstrap address.

When configuring the advertised addresses for the **Kafka** broker pods, **Strimzi** uses the address of the node on which
the given pod is running. When selecting the node address, the different address types are used with the following priority:

1. ExternalDNS
2. ExternalIP
3. Hostname
4. InternalDNS
5. InternalIP

By default, **TLS** encryption is enabled. To disable it, set the `tls` field to `false`.

**!!! NOTE**

**TLS** hostname verification is not currently supported when exposing **Kafka** clusters using node ports.

By default, the port numbers used for the bootstrap and broker services are automatically assigned by **Kubernetes**.
However, you can override the assigned node ports by specifying the requested port numbers in the `overrides` property.
**Strimzi** does not perform any validation on the requested ports; you must ensure that they are free and available for use.

Example of an external listener configured with overrides for node ports.

```yaml
# ...
listeners:
  external:
    type: nodeport
    tls: true
    authentication:
      type: tls
    overrides:
      bootstrap:
        nodePort: 32100
      brokers:
      - broker: 0
        nodePort: 32000
      - broker: 1
        nodePort: 32001
      - broker: 2
        nodePort: 32002
# ...
```

###### Customizing the DNS names of external node port listeners

On `nodeport` listeners, you can use the `dnsAnnotations` property to add additional annotations to the nodeport services.
You can use these annotations to instrument DNS tooling such as **External DNS**, which automatically assigns DNS names to 
the cluster nodes.

Example of an external listener of type `nodeport` using `dnsAnnotations`. 

```yaml
# ...
listeners:
  external:
    type: nodeport
    tls: true
    authentication:
      type: tls
    overrides:
      bootstrap:
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: kafka-bootstrap.mydomain.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
      brokers:
      - broker: 0
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: kafka-broker-0.mydomain.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
      - broker: 1
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: kafka-broker-1.mydomain.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
      - broker: 2
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: kafka-broker-2.mydomain.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
# ...
```


###### Accessing Kafka using node ports

Prerequisites

- A **Kubernetes** cluster
- A running **Cluster Operator**

Procedure

1. Deploy **Kafka** cluster with an external listener enabled and configured to the type `nodeport`.

An example configuration with an external listener configured to use node ports:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
spec:
  kafka:
    # ...
    listeners:
      external:
        type: nodeport
        tls: true
        # ...
    # ...
  zookeeper:
    # ...
```

2. Create or update the resource.

This can be done using `kubectl apply`:

    kubectl apply -f your-file
    
3. Find the port number of the bootstrap service.

This can be done using `kubectl get`:

    kubectl get service [cluster-name]-kafka-external-bootstrap -o=jsonpath='{.spec.ports[0].nodePort}{"\n"}'
    
The port should be used in the **Kafka** bootstrap address.

4. Find the address of the Kubernetes node.

This can be done using `kubectl get`:

    kubectl get node node-name -o=jsonpath='{range .status.addresses[*]}{.type}{"\t"}{.address}{"\n"}'

If several different addresses are returned, select the address type you want based on the following order.

a. ExternalDNS
b. ExternalIP
c. Hostname
d. InternalDNS
e. InternalIP

Use the address with the port found in the previous step in the **Kafka** bootstrap address.

5. Unless **TLS** encryption was disabled, extract the public certificate of the broker certification authority. 

This can be done using `kubectl get`:

    kubectl get secret [cluster-name]-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
    
Use the extracted certificate in your **Kafka** client to configure **TLS** connection. If you enabled any authentication, you 
will need to configure **SASL** or **TLS** authentication.

##### Kubernetes Ingress external listeners

External listeners of type `ingress` exposes **Kafka** by using **Kubernetes** `Ingress` and the **NGINX Ingress Controller
for Kubernetes**.

###### Exposing Kafka using Kubernetes Ingress

When exposing **Kafka** using **Kubernetes** `Ingress` and the **NGINX Ingress Controller for Kubernetes**, a dedicated 
`Ingress` resource is created for every **Kafka** broker pod. An additional `Ingress` resource is created to server as a 
**Kafka** bootstrap address. **Kafka** clients can use these `Ingress` resources to connect to **Kafka** on port 443.

**!!! NOTE**
External listeners using `Ingress` have been currently tested only with **NGINX Ingress Controller for Kubernetes**.

**Strimzi** uses the **TLS passthrough** feature of **NGINX Ingress Controller for Kubernetes**. Make sure **TLS passthrough**
is enabled in your **NGINX Ingress Controller for Kubernetes** deployment. Because it is using the **TLS passthrough** 
functionality, **TLS** encryption cannot be disabled when exposing **Kafka** using `Ingress`.

The Ingress controller does not assign any hostnames automatically. You have to specify the hostnames which should be used
by the bootstrap and per-broker services in the `spec.kafka.listeners.external.configuration` section. You also have to
make sure that the hostnames resolve to the Ingress endpoints. **Strimzi** will not perform any validation that the
requested hosts are available and properly routed to the Ingress endpoints.

Example of an exteranl listener of type `ingress`:

```yaml
# ...
listeners:
  external:
    type: ingress
    authentication:
      type: tls
    configuration:
      bootstrap:
        host: bootstrap.myingress.com
      brokers:
      - broker: 0
        host: broker-0.myingress.com
      - broker: 1
        host: broker-1.myingress.com
      - broker: 2
        host: broker-2.myingress.com
# ...
```

###### Configuring the Ingress class

By default, the `Ingress` class is set to `nginx`. You can change the `Ingress` class using the `class` property.

Example of an external listener of type `ingress` using `Ingress` class `nginx-internal`.

```yaml
# ...
listeners:
  external:
    type: ingress
    class: nginx-internal
    # ...
# ...
```

###### Customizing the DNS names of external ingress listeners.

On `ingress` listeners, you can use the `dnsAnnotations` property to add additional annotations to the ingress resources.
You can use these annotations to instrument DNS tooling such as **External DNS**, which automatically assigns DNS names to
the ingress resources.

Example of an external listener of type `ingress` using `dnsAnnotations`.

```yaml
# ...
listeners:
  external:
    type: ingress
    authentication:
      type: tls
    configuration:
      bootstrap:
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: bootstrap.myingress.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
        host: bootstrap.myingress.com
      brokers:
      - broker: 0
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: broker-0.myingress.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
        host: broker-0.myingress.com
      - broker: 1
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: broker-1.myingress.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
        host: broker-1.myingress.com
      - broker: 2
        dnsAnnotations:
          external-dns.alpha.kubernetes.io/hostname: broker-2.myingress.com.
          external-dns.alpha.kubernetes.io/ttl: "60"
        host: broker-2.myingress.com
# ...
```

###### Accessing Kafka using Ingress

This procedure shows how to access **Strimzi** **Kafka** clusters from outside of **Kubernetes** using Ingress.

Prerequisites

- An **Kubernetes** cluster
- Deployed **NGINX Ingress Controller for Kubernetes** with **TLS passthrough** enabled.
- A running **Cluster Operator**

Procedure

1. Deploy **Kafka** cluster with an external listener enabled and configured to the type `ingress`.

An example configuration with an external listener configured to use `Ingress`:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
spec:
  kafka:
    # ...
    listeners:
      external:
        type: ingress
        authentication:
          type: tls
        configuration:
          bootstrap:
            host: bootstrap.myingress.com
          brokers:
          - broker: 0
            host: broker-0.myingress.com
          - broker: 1
            host: broker-1.myingress.com
          - broker: 2
            host: broker-2.myingress.com
    # ...
  zookeeper:
    # ...
```

2. Make sure the hosts in the `configuration` section properly resolve to the Ingress endpoints.

3. Create or update the resource

        kubectl apply -f your-file
        
4. Extract the public certificate of the broker certificate authority.

        kubectl get secret [cluster-name]-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt

5. Use the extracted certificate in your **Kafka** client to configure the **TLS** connection. If you enabled any
authentication, you will also need to configure **SASL** or **TLS** authentication. Connect with your client to the host
you specified in the configuration on port 443.

#### Network policies

**Strimzi** automatically creates a `NetworkPolicy` resource for every listener that is enabled on a **Kafka** broker. By
default, a `NetworkPolicy` grants access to a listener to all applications and namespaces.

If you want to restrict access to a listener at the network level to only selected applications or namespaces, use the 
`networkPolicyPeers` field.

Use network policies in conjuction with authentication and authorization.

Each listener can have a different `networkPolicyPeers` configuration.

##### Network policy configuration for a listener

The following example shows a `networkPolicyPeers` configuration for a `plain` and a `tls` listener:

```yaml
# ...
listeners:
  plain:
    authentication:
      type: scram-sha-512
    networkPolicyPeers:
      - podSelector:
          matchLabels:
            app: kafka-sasl-consumer
      - podSelector:
          matchLabels:
            app: kafka-sasl-producer
  tls:
    authentication:
      type: tls
    networkPolicyPeers:
      - namespaceSelector:
          matchLabels:
            project: myproject
      - namespaceSelector:
          matchLabels:
            project: myproject2
# ...
```

In the example

- Only application pods matching the labels `app: kafka-sasl-consumer` and `app: kafka-sasl-producer` can connect to the
`plain` listener. The application pods must be running in the same namespace as the **Kafka** broker.

- Only application pods running in namespaces matching the labels `project: myproject` and `project: myproject2` can connect 
to the `tls` listener.

**!!! NOTE**

Your configuration of **Kubernetes** must support ingress NetworkPolicies in order to use network policies 

##### Restricting access to Kafka listeners using networkPolicyPeers

You can restrict access to a listener to only selected applications by using `networkPolicyPeers` field. 

Prerequisites

- A **Kubernetes** cluster with support for Ingress NetworkPolicies.
- The **Cluster Operator** is running.

Procedure.

1. Open the `Kafka` resource.

2. In the `networkPolicyPeers` field, define the application pods or namespaces that will be allowed to access the **Kafka**
cluster.

For example, to configure a `tls` listener to allow connections only from application pods with the label `app` set to
`kafka-client`:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
spec:
  kafka:
    # ...
    listeners:
      tls:
        networkPolicyPeers:
          - podSelector:
              matchLabels:
                app: kafka-client
    # ...
  zookeeper:
    # ...
```

3. Create or update the resource:

Use `kubectl apply`:

    kubectl apply -f your-file

### 1.7 Authentication and Authorization

**Strimzi** supports authentication and authorization. Authentication can be configured independently for each listener.
Authorization is always configured for the whole **Kafka** cluster.

#### Authentication

Authentication is configured as part of the listener configuration in the `authentication` property. The authentication
mechanism is defined by the `type` field.

When the `authentication` property is missing, no authentication is enabled on a given listener. The listener will accept 
all connections without authentication.

Supported authentication mechanisms:

- TLS client authentication
- SASL SCRAM-SHA-512
- OAuth 2.0 token based authentication

##### TLS client authentication

**TLS Client** authentication is enabled by specifying the `type` as `tls`. The **TLS client** authentication is supported
only on the `tls` listener.

An example of `authenticatiom` with type `tls`

```yaml
# ...
authentication:
  type: tls
# ...
```

#### Configuring authentication in Kafka brokers

Prerequisites 

- A **Kubernetes** cluster is available.
- The **Cluster Operator** is running.

Procedure

1. Open the YAML configuration file that contains the `Kafka` resource specifying the cluster deployment.
2. In the `spec.kafka.listeners` property in `Kafka` resource add the `authentication` field to listeners for 
which you want to enable authentication. For example:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
spec:
  kafka:
    # ...
    listeners:
      tls:
        authentication:
          type: tls
    # ...
  zookeeper:
    # ...
```

3. Apply the new configuration to create or update the resource.

  Use `kubectl apply`:
  
  kubectl apply -f kafka.yaml
  
where `kafka.yaml` is the YAML configuration file for the resource that you want to configure.

#### Authorization

You can configure authorization for **Kafka** brokers using the `authorization` property in the `Kafka.spec.kafka` resource.
If the `authorization` property is missing, no authorization is enabled. When enabled, authorization is applied to all enabled
listeners. The authorization method is defined in the `type` field; only Simple authorization is currently supported.

You can optionally designate a list of super users in the `superUsers` field.

##### Simple authorization

Simple authorization in **Strimzi** uses the `SimpleAclAuthorizer` plugin, the default Access Control Lists (ACLs)
authorization plugin provided with **Apache Kafka**. ACLs allow you to define which users have access to which resources
at a granular level. To enable simple authorization, set the `type` field to `simple`.

An example of Simple authorization.

```yaml
# ...
authorization:
  type: simple
# ...
```

##### Super users

Super users can access all resources in your **Kafka** cluster regardless of any access restrictions defined in ACLs. To
designate super users for a **Kafka** cluster, enter a list of user principles in the `superUsers` field. If a user uses
TLS Client Authentication, the username will be the common name from their certificate subject prefixed with `CN=`.

An example of designating super users:

```yaml
# ...
authorization:
  type: simple
  superUsers:
    - CN=fred
    - sam
    - CN=edward
# ...
```

**!!! NOTE**
The `super.user` configuration option in the `config` property in `Kafka.spec.kafka` is ignored. Designate super users in
the `authorization` property instead.

#### Configuring authorization in Kafka brokers

Configure authorization and designate super users for a particular **Kafka** broker.

Prerequisites 

- A **Kubernetes** cluster
- The **Cluster Operator** is running 

Procedure

1. Add or edit the `authorization` property in the `Kafka.spec.kafka` resource. For example:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
spec:
  kafka:
    # ...
    authorization:
      type: simple
      superUsers:
        - CN=fred
        - sam
        - CN=edward
    # ...
  zookeeper:
    # ...
```

2. Create or update the resource

This can be done using `kubectl apply`:

    kubectl apply -f your-file

### 1.8 ZooKeeper replicas

**ZooKeeper** clusters or ensembles usually run with an **odd** number of nodes, typically three, five, or seven.

The majority of nodes must be available in order to maintain an effective quorum. If **ZooKeeper** cluster loses its
quorum, it will stop responding to clients and the **Kafka** brokers will stop working. Having a stable and highly available
**ZooKeeeper** cluster is crucial for **Strimzi**

Three-node cluster
A three-node **ZooKeeper** cluster requires at least two nodes to be up and running in order to maintain the quorum. It can 
tolerate only one node being unavailable.

Five-node cluster
A five-node **ZooKeeper** cluster requires at least three nodes to be up and running in order to maintain the quorum. It can 
tolerate two nodes being unavailable.

Seven-node-cluster
A seven-node ZooKeeper cluster require at least four nodes to be up and running in order to maintain the quorum. It can 
tolerate three nodes being unavailable.

Having more nodes does not necessarily mean better performance, as the costs to maintain the quorum will rise with the number
of nodes in the cluster. Depending on your availability requirements, you can decide for the number of nodes to use.

#### Number of ZooKeeper nodes

The number of **ZooKeeper** nodes can be configured using the `replicas` property in `Kafka.spec.zookeeper`.

An example showing replicas configuration.

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
  zookeeper:
    # ...
    replicas: 3
    # ...
```

#### Changing the number of ZooKeeper replicas

Prerequisites

- A **Kubernetes** cluster is available
- The **Cluster Operator** is running

Procedure. 

1. Open the YAML configuration file that contains the `Kafka` resource specifying the cluster deployment.
2. In the `spec.zookeeper.replicas` property in the `Kafka` resource, enter the number of replicated **ZooKeeper** servers.
For example:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
  zookeeper:
    # ...
    replicas: 3
    # ...
```

3. Apply the new configuration to create or update the resource:

Use `kubectl apply`:

    kubectl apply -f kafka.yaml
    
where `kafka.yaml` is the YAML configuration file for the resource that you want to configure.

### 1.9 ZooKeeper configuration

**Strimzi** allows you to customize the configuration of **Apache ZooKeeper** nodes. You can specify and 
configure most of the options listed in the **ZooKeeper** documentation.

Options which cannot be configured are those related to the following areas:

- Security (Encryption, Authentication, and Authorization)
- Listener configuration
- Configuration of data directories
- ZooKeeper cluster composition

These options are automatically configured by **Strimzi**

#### ZooKeeper configuration

**ZooKeeper** nodes are configured using the `config` property in `Kafka.spec.zookeeper`. This property contains the 
`ZooKeeper` configuration options as keys. The values can be described using one of the following JSON types: 

- String
- Number
- Boolean

Users can specify and configure the options listed in **ZooKeeper** documentation with the exception of those options 
which are managed directly by **Strimzi**. Specifically, all configuration options with keys equal to or starting with one 
of the following strings are forbidden:

- `server.`
- `dataDir`
- `dataLogDir`
- `clientPort`
- `authProvider`
- `quorum.auth`
- `requireClientAuthScheme`

When one of the forbidden options is present in the `config`, it is ignored and a warning message is printed to the 
**Cluster Operator** log file. All other options are passed to **ZooKeeper**.

**!!! IMPORTANT**

The **Cluster Operator** does not validate keys or values in the provided `config` object. When invalid configuration is 
provided, the **ZooKeeper** cluster might not start or might become unstable. In such cases, the configuration in the 
`Kafka.spec.zookeeper.config` object should be fixed and the **Cluster Operator** will roll out the new configuration to
all **ZooKeeper** nodes.

Selected options have default values.

- `timeTick` with default value `2000`
- `initLimit` with default value `5`
- `syncLimit` with default value `2`
- `autopurge.purgeInterval` with default value `1`

These options will be automatically configured when they are not present in the `Kafka.spec.zookeeper.config` property.

An example showing **ZooKeeper** configuration

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
spec:
  kafka:
    # ...
  zookeeper:
    # ...
    config:
      autopurge.snapRetainCount: 3
      autopurge.purgeInterval: 1
    # ...
```

#### Configuring ZooKeeper

Prerequisites

- A **Kubernetes** cluster is available
- The **Cluster Operator** is running.

Procedure

1. Open the **YAML** configuration file that contains the `Kafka` resource specifying the cluster deployment.

2. In the `spec.zookeeper.config` property in the `Kafka` resource, enter one or more **ZooKeeper** configuration settings.
For example:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
spec:
  kafka:
    # ...
  zookeeper:
    # ...
    config:
      autopurge.snapRetainCount: 3
      autopurge.purgeInterval: 1
    # ...
```

3. Apply the new configuration to create or update the resource.

Use `kubectl apply`:

    kubectl apply -f kafka.yaml
    
where `kafka.yaml` is the YAML configuration file for the resource that you want to configure.

### 1.10 ZooKeeper connection

**ZooKeeper** services are secured with encryption and authentication and are not intended to be used by external
applications that are not part of **Strimzi**

However, if you want to use **Kafka** CLI tools that require a connection to **ZooKeeper**, such as the `kafka-topics` tool,
you can use a terminal inside a **Kafka** container and connect to the local end of the TLS tunnel to **ZooKeeper** by using
`localhost:2181` as the **ZooKeeper** address.

#### Connecting to ZooKeeper from a terminal

Open a terminal inside a **Kafka** container to use **Kafka** CLI tools that require a **ZooKeeper** connection.

Prerequisites

- A **Kubernetes** cluster is available
- A **kafka** cluster is running
- The **Cluster Operator** is running.

Procedure

1. Open the terminal using the **Kubernetes** console or run the `exec` command from your CLI.

For example

    kubectl exec -it [cluster-name]-kafka-0 -- bin/kafka-topics.sh --list --zookeeper localhost:2181
  
Be sure to use `localhost:2181`.

### 1.11 Entity Operator

The **Entity Operator** is responsible for managing **Kafka**-related entities in a running **Kafka** cluster.

The **Entity Operator** comprises the:

- **Topic Operator** to manage **Kafka** topics
- **User Operator** to manage **Kafka** users

Through `Kafka` resource configuration, the **Cluster Operator** can deploy the **Entity Operator**, including one or both
operators, when deploying a **Kafka** cluster.

The operators are automatically configured to manage the topics and users of the **Kafka** cluster.

#### Configuration

The **Entity Operator** can be configured using the `entityOperator` property in `Kafka.spec`.

The `entityOperator` property supports several-sub properties:

- `tlsSidecar`
- `topicOperator`
- `userOperator`
- `template`

The `tlsSidecar` property can be used to configure the TLS sidecar container which is used to communicate with **ZooKeeper**.

The `template` property can be used to configure details of the **Entity Operator** pod, such as labels, annotations, affinity,
tolerations and so on.

The `topicOperator` property contains the configuration of the **Topic Operator**. When the option is missing, the **Entity
Operator** is deployed without the **Topic Operator**.

The `userOperator` property contains the configuration of the **User Operator**. When this option is missing, the **Entity
Operator** is deployed without the **User Operator**.

Example of basic configuration enabling both operators:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
  zookeeper:
    # ...
  entityOperator:
    topicOperator: {}
    userOperator: {}
```

When bot `topicOperator` and `userOperator` properties are missing, the **Entity Operator** will be not deployed.

##### Topic Operator

**Topic Operator** deployment can be configured using additional options inside `topicOperator` object. The following 
options are supported.

`watchedNamespace`

The **Kubernetes** namespace in which the topic operator watches for `KafkaTopics`. Default is the namespace where the 
**Kafka** cluster is deployed.

`reconciliationIntervalSeconds`

The interval between periodic reconciliations in seconds. Default `90`.

`zookeeperSessionTimeoutSeconds`

The **ZooKeeper** session timeout in seconds. Default `20`.

`topicMetadataMaxAttempts`

The number of attempts at getting topic metadata from **Kafka**. The time between each attempt is defined as an exponential
back-off. Consider increasing this value when topic creation could take more time due to the number of partitions or replicas.
Default `6`.

`resources`

The `resources` property configures the amount of resources allocated to the **Topic Operator**. 

`logging`

The `logging` property configures the logging of the **Topic Operator**.

The **Topic Operator** has its own configurable logger:

- `rootLogger.level`

Example of **Topic Operator** configuration:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
  zookeeper:
    # ...
  entityOperator:
    # ...
    topicOperator:
      watchedNamespace: my-topic-namespace
      reconciliationIntervalSeconds: 60
    # ...
```

##### User Operator

**User Operator** deployment can be configured using additional options inside the userOperator object. The following 
options are supported:

`watchedNamespace`
The **Kubernetes** namespace in which the topic operator watches for `KafkaUsers`. Default is the namespace where the 
**Kafka** cluster is deployed.

`reconciliationIntervalSeconds`
The interval between periodic reconciliations in seconds. Default `120.

`zookeeperSessionTimeoutSeconds`
The **ZooKeeper** session timeout in seconds. Default 6.

`resources`
The resources property configures the amount of resources allocated to the **User Operator**.

`logging`
The logging property configures the logging of the **User Operator**.

The **User Operator** has its own configurable logger:
- `rootLogger.level`

Example of **Topic Operator** configuration:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
  zookeeper:
    # ...
  entityOperator:
    # ...
    userOperator:
      watchedNamespace: my-user-namespace
      reconciliationIntervalSeconds: 60
    # ...
```

#### Configuring Entity Operator

Prerequisites

- A **Kubernetes** cluster
- A running **Cluster Operator**

Procedure

1. Edit the `entityOperator` property in the `Kafka` resource. For example:

```yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    # ...
  zookeeper:
    # ...
  entityOperator:
    topicOperator:
      watchedNamespace: my-topic-namespace
      reconciliationIntervalSeconds: 60
    userOperator:
      watchedNamespace: my-user-namespace
      reconciliationIntervalSeconds: 60
```

2. Create or update the resource:

This can be done using `kubectl apply`:

    kubectl apply -f your-file
    
