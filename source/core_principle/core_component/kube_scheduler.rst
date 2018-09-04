kube-scheduler
~~~~~~~~~~~~~~~~~~~~

kube-scheduler 负责分配调度 Pod 到集群内的节点上，它监听 kube-apiserver，查询还未分配 Node 的 Pod，然后根据调度策略为这些 Pod 分配节点（更新 Pod 的 `NodeName` 字段）。

调度器需要充分考虑诸多的因素：

* 公平调度
* 资源高效利用
* Qos
* affinity 和 anti-affinity
* 数据本地化（data locality）
* 内部负载干扰（inter-workload interference）
* deadlines

指定 Node 节点调度
^^^^^^^^^^^^^^^^^^^^^^

有三种方式指定 Pod 只运行在指定的 Node 节点上

* nodeSelector：只调度到匹配指定的 label 的 Node 上
* nodeAffinity：功能更丰富的 Node 选择器，比如支持集合操作
* podAffinity：调度到满足条件的 Pod 所在的 Node 上

nodeSelector 示例
^^^^^^^^^^^^^^^^^^^^^^

首先给 Node 打上标签

.. code-block:: none

   kubectl label nodes node-01 disktype=ssd

然后再 daemonset 中指定 nodeSelector 为 ``disktype=ssd``:

.. code-block:: none

    spec:
      nodeSelector:
        disktype: ssd

nodeAffinity 示例
^^^^^^^^^^^^^^^^^^^^^

nodeAffinity 目前支持两种：`requiredDuringSchedulingIgnoredDuringExecution` 和 `preferredDuringSchedulingIgnoredDuringExecution`，分别代表必须满足条件和优选条件。比如下面的例子代表调度到包含标签 ``kubernetes.io/e2e-az-name`` 并且值为 e2e-az1 或者 e2e-az2 的 Node 上，并且优选还带有标签 ``another-node-label-key=another-node-label-value`` 的 Node。

.. code-block:: yaml

   apiVersion: v1
   kind: Pod
   metadata:
     name: with-node-affinity
   spec:
     affinity:
       nodeAffinity:
         requiredDuringSchedulingIgnoredDuringExecution:
           nodeSelectorTerms:
           - matchExpressions:
             - key: kubernetes.io/e2e-az-name
               operator: In
               values:
               - e2e-az1
               - e2e-az2
         preferredDuringSchedulingIgnoredDuringExecution:
         - weight: 1
           preference:
             matchExpressions:
             - key: another-node-label-key
               operator: In
               values:
               - another-node-label-value
     containers:
     - name: with-node-affinity
       image: gcr.io/google_containers/pause:2.0

podAffinity 示例
^^^^^^^^^^^^^^^^^^^^^^^^^^

podAffinity 基于 Pod 的标签来选择 Node，仅调度到满足条件 Pod 所在的 Node 上，支持 podAffinity 和 PodAntiAffinity。这个功能比较绕，以下面的例子为例：

* 如果一个 “Node 所在 Zone 中包含至少一个带有 ``security=S1`` 标签且运行中的 Pod”，那么可以调度到该 Node
* 不调度到“包含至少一个带有 ``security=S2`` 标签且运行中 Pod” 的 Node 上。

.. code-block:: yaml

   apiVersion: v1
   kind: Pod
   metadata:
     name: with-pod-affinity
   spec:
     affinity:
       podAffinity:
         requiredDuringSchedulingIgnoredDuringExecution:
         - labelSelector:
             matchExpressions:
             - key: security
               operator: In
               values:
               - S1
           topologyKey: failure-domain.beta.kubernetes.io/zone
       podAntiAffinity:
         preferredDuringSchedulingIgnoredDuringExecution:
         - weight: 100
           podAffinityTerm:
             labelSelector:
               matchExpressions:
               - key: security
                 operator: In
                 values:
                 - S2
             topologyKey: kubernetes.io/hostname
     containers:
     - name: with-pod-affinity
       image: gcr.io/google_containers/pause:2.0

Taints 和 tolerations
^^^^^^^^^^^^^^^^^^^^^^^^^

Taints 和 tolerations 用于保证 Pod 不被调度到不合适的 Node 上，其中 Taint 应用于 Node 上，而 toleration 则应用于 Pod 上。

目前支持的 taint 类型

* NoSchedule：新的 Pod 不调度到该 Node 上，不影响正在运行的 Pod
* PreferNoSchedule：soft 版的 NodeSchedule，尽量不调度到该 Node 上
* NoExecute：新的 Pod 不调度到该 Node 上，并且删除（evict）已在运行的 Pod。Pod 可以增加一个时间（tolerationSeconds）
