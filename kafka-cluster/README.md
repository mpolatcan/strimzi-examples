# Strimzi Kafka Cluster Configuration Documentation

**Credit**: https://strimzi.io/docs/0.15.0/#assembly-deployment-configuration-kafka-str
 
## 3.1. Kafka cluster configuration

### 3.1.1. Sample Kafka YAML configuration

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

### 3.1.2 Data storage considerations

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

### 3.1.3 Kafka and ZooKeeper storage types

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
    
