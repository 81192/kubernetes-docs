~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
在 Kubespary 中升级 Kubernetes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

描述
^^^^^^^^^

Kubespray 处理升级的方式与处理初始部署的方式相同。 也就是说，每个组件都按固定顺序放置。 
您应该可以毫无困难地在 Kubespray 把当前集群升级到 tags 2.0。 您还可以通过显式定义其版本来单独控制组件的版本。 

以下是每个组件的所有版本变量：

- docker_version
- kube_version
- etcd_version
- calico_version
- calico_cni_version
- weave_version
- flannel_version
- kubedns_version

不安全的升级示例
^^^^^^^^^^^^^^^^^^^

如果您只想将 kube_version 从 v1.4.3 升级到 v1.4.6，则可以采用以下方式进行部署：

.. code-block:: none

   ansible-playbook cluster.yml -i inventory/sample/hosts.ini -e kube_version=v1.4.3

然后重复用 v1.4.6 作为 kube_version：

.. code-block:: none

   ansible-playbook cluster.yml -i inventory/sample/hosts.ini -e kube_version=v1.4.6

优雅的升级
^^^^^^^^^^^^^^^^^

Kubespray还支持在执行群集升级时对节点进行锁定，排空和取消协调。有一个单独的 playbook 用于此目的。请务必注意，upgrade-cluster.yml 只能用于升级现有群集。这意味着必须至少部署了1个kube-master。

.. code-block:: bash

   git fetch origin
   git checkout origin/master
   ansible-playbook upgrade-cluster.yml -b -i inventory/sample/hosts.ini -e kube_version=v1.6.0

成功升级后，查看更新服务器版本：

.. code-block:: bash

    $ kubectl version
    Client Version: version.Info{Major:"1", Minor:"6", GitVersion:"v1.6.0", GitCommit:"fff5156092b56e6bd60fff75aad4dc9de6b6ef37", GitTreeState:"clean", BuildDate:"2017-03-28T19:15:41Z", GoVersion:"go1.8", Compiler:"gc", Platform:"darwin/amd64"}
    Server Version: version.Info{Major:"1", Minor:"6", GitVersion:"v1.6.0+coreos.0", GitCommit:"8031716957d697332f9234ddf85febb07ac6c3e3", GitTreeState:"clean", BuildDate:"2017-03-29T04:33:09Z", GoVersion:"go1.7.5", Compiler:"gc", Platform:"linux/amd64"}

升级管理
^^^^^^^^^^^^

如上所述，组件按照它们在Ansible playbook中的安装顺序进行升级。组件安装顺序如下：

- Docker
- etcd
- kubelet and kube-proxy
- network_plugin (such as Calico or Weave)
- kube-apiserver, kube-scheduler, and kube-controller-manager
- Add-ons (such as KubeDNS)

升级注意事项
^^^^^^^^^^^^^^^^^^^

Kubespray 支持用于etcd和Kubernetes 组件的轮换证书，但可能需要一些手动操作步骤。
如果您的 pod 需要使用服务令牌并部署在 kube-system 以外的命名空间中，则需要在轮换证书后手动删除受影响的pod。
这是因为所有服务帐户令牌都依赖于用于生成它们的 apiserver 令牌。
证书轮换时，所有服务帐户 token 也必须轮换。 在 kubernetes-apps/rotate_tokens 角色期间，只有 kube-system 中的 pod 被销毁并重新创建。
所有其他无效的服务帐户令牌都会自动清理，但是对于对用户部署的pod的影响，其他pod不会被删除。

基于组件的升级
^^^^^^^^^^^^^^^^^^^

部署者可能希望升级特定组件以最小化风险或节省时间。 
在撰写本文时，CI 不涵盖此策略，因此无法保证其正常运行。 

这些命令仅对升级完全部署的健康现有主机有用。
这对于未部署或部分部署的主机肯定不起作用。

Upgrade docker:

.. code-block:: bash

   ansible-playbook -b -i inventory/sample/hosts.ini cluster.yml --tags=docker

Upgrade etcd:

.. code-block:: bash

   ansible-playbook -b -i inventory/sample/hosts.ini cluster.yml --tags=etcd

Upgrade vault:

.. code-block:: bash

   ansible-playbook -b -i inventory/sample/hosts.ini cluster.yml --tags=vault

Upgrade kubelet:

.. code-block:: bash

   ansible-playbook -b -i inventory/sample/hosts.ini cluster.yml --tags=node --skip-tags=k8s-gen-certs,k8s-gen-tokens

Upgrade Kubernetes master components:

.. code-block:: bash

    ansible-playbook -b -i inventory/sample/hosts.ini cluster.yml --tags=master

Upgrade network plugins:

.. code-block:: bash

    ansible-playbook -b -i inventory/sample/hosts.ini cluster.yml --tags=network

Upgrade all add-ons:

.. code-block:: bash

    ansible-playbook -b -i inventory/sample/hosts.ini cluster.yml --tags=apps

仅升级 helm（假设 helm_enabled 为 true）：

.. code-block:: bash

    ansible-playbook -b -i inventory/sample/hosts.ini cluster.yml --tags=helm
