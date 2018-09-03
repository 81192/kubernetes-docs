~~~~~~~~~~~~~~~~~~~~~
Ansible 变量
~~~~~~~~~~~~~~~~~~~~~

Inventory
^^^^^^^^^^^^^^^

inventory 由 3 组内容组成

* kube-master : 将运行 kubernetes 主组件（apiserver，scheduler，controller）的服务器列表。
* kube-node : 将运行 pod 的 kubernetes 节点列表。
* etcd : 组成 etcd 服务器的服务器列表。您应该至少有3台服务器用于故障转移。

.. note:: 

   不要修改 k8s-cluster 的子类，比如将 etcd 组放入 k8s-cluster 组中，除非你确定要这样做并且你完全包含在后者中：

.. code-block:: none

   k8s-cluster ⊂ etcd => kube-node ∩ etcd = etcd

当 kube-node 包含 etcd 时，您可以将您的 etcd 集群定义为可以为 Kubernetes 工作负载调度。 如果您想要它是独立的，请确保这些组不相交。 如果您希望服务器同时充当主服务器和节点，则必须在kube-master和kube-node两个组上定义服务器。 如果需要独立且不可调度的主服务器，则必须仅在 kube-master 而不是 kube-node 中定义服务器。

还有两个特殊的群组：

* calico-rr : 查看 `先进的 Calico 网络案例 <https://github.com/kubernetes-incubator/kubespray/blob/master/docs/calico.md>`_ 。
* bastion : 如果您的节点不可直接访问，请配置堡垒主机。

以下是完整的 inventory 示例:

.. code-block:: ini

   ## Configure 'ip' variable to bind kubernetes services on a
   ## different ip than the default iface
   node1 ansible_ssh_host=95.54.0.12 ip=10.3.0.1
   node2 ansible_ssh_host=95.54.0.13 ip=10.3.0.2
   node3 ansible_ssh_host=95.54.0.14 ip=10.3.0.3
   node4 ansible_ssh_host=95.54.0.15 ip=10.3.0.4
   node5 ansible_ssh_host=95.54.0.16 ip=10.3.0.5
   node6 ansible_ssh_host=95.54.0.17 ip=10.3.0.6
   
   [kube-master]
   node1
   node2
   
   [etcd]
   node1
   node2
   node3
   
   [kube-node]
   node2
   node3
   node4
   node5
   node6
   
   [k8s-cluster:children]
   kube-node
   kube-master

组变量和覆盖优先级变量
^^^^^^^^^^^^^^^^^^^^^^^^

用于控制主要部署选项的组变量位于目录 ``inventory/sample/group_vars`` 中。 可选变量位于 ``inventory/sample/group_vars/all.yml`` 中。 可以在 ``inventory/sample/group_vars/k8s-cluster.yml`` 中找到至少一个角色（或节点组）通用的强制变量。 还有 `docker`，`rkt`，`kubernetes preinstall` 和 `master` 角色的角色变量。 根据 ansible 文档，那些不能从组变量中覆盖。 为了覆盖，应该使用 ``-e`` 运行时标志（最简单的方法）或文档中描述的其他层。

Kubespray只使用几个层来覆盖事物（或者期望它们被替换为角色）：

+--------------------------------------+----------------------------------------------------------------------+
|                Layer                 |                               Comment                                |
+======================================+======================================================================+
|            role defaults             |    provides best UX to override things for Kubespray deployments     |
+--------------------------------------+----------------------------------------------------------------------+
|            inventory vars            |                                Unused                                |
+--------------------------------------+----------------------------------------------------------------------+
|         inventory group_vars         | Expects users to use all.yml,k8s-cluster.yml etc. to override things |
+--------------------------------------+----------------------------------------------------------------------+
|         inventory host_vars          |                                                                      |
+--------------------------------------+                                                                      +
|         playbook group_vars          |                                Unused                                |
+--------------------------------------+                                                                      +
|          playbook host_vars          |                                                                      |
+--------------------------------------+----------------------------------------------------------------------+
|              host facts              |   Kubespray overrides for internal roles' logic, like state flags    |
+--------------------------------------+----------------------------------------------------------------------+
|              play vars               |                                                                      |
+--------------------------------------+                                                                      +
|           play vars_prompt           |                                                                      |
+--------------------------------------+                                Unused                                +
|           play vars_files            |                                                                      |
+--------------------------------------+                                                                      +
|           registered vars            |                                                                      |
+--------------------------------------+----------------------------------------------------------------------+
|              set_facts               |              Kubespray overrides those, for some places              |
+--------------------------------------+----------------------------------------------------------------------+
|        role and include vars         |    Provides bad UX to override things! Use extra vars to enforce     |
+--------------------------------------+----------------------------------------------------------------------+
| block vars (only for tasks in block) |            Kubespray overrides for internal roles' logic             |
+--------------------------------------+----------------------------------------------------------------------+
|    task vars (only for the task)     |            Unused for roles, but only for helper scripts             |
+--------------------------------------+----------------------------------------------------------------------+
|  extra vars (always win precedence)  |              override with ansible-playbook -e @foo.yml              |
+--------------------------------------+----------------------------------------------------------------------+

Ansible 标签
^^^^^^^^^^^^^^^^

playbooks 定义了以下的标记：

+-------------------------+--------------------------------------------------+
|         Tag name        |                     User for                     |
+-------------------------+--------------------------------------------------+
|           apps          |                  K8s apps 定义                   |
+-------------------------+--------------------------------------------------+
|          azure          |               Cloud-provider Azure               |
+-------------------------+--------------------------------------------------+
|         bastion         |           Setup ssh config for bastion           |
+-------------------------+--------------------------------------------------+
|       bootstrap-os      |    Anything related to host OS configuration     |
+-------------------------+--------------------------------------------------+
|         network         |      Configuring networking plugins for K8s      |
+-------------------------+--------------------------------------------------+
|          calico         |              Network plugin Calico               |
+-------------------------+--------------------------------------------------+
|          canal          |               Network plugin Canal               |
+-------------------------+--------------------------------------------------+
|         flannel         |              Network plugin flannel              |
+-------------------------+--------------------------------------------------+
|          weave          |               Network plugin Weave               |
+-------------------------+--------------------------------------------------+
|      cloud-provider     |           Cloud-provider related tasks           |
+-------------------------+--------------------------------------------------+
|         dnsmasq         |   Configuring DNS stack for hosts and K8s apps   |
+-------------------------+--------------------------------------------------+
|          docker         |           Configuring docker for hosts           |
+-------------------------+--------------------------------------------------+
|         download        |   Fetching container images to a delegate host   |
+-------------------------+--------------------------------------------------+
|           etcd          |             Configuring etcd cluster             |
+-------------------------+--------------------------------------------------+
|     etcd-pre-upgrade    |              Upgrading etcd cluster              |
+-------------------------+--------------------------------------------------+
|       etcd-secrets      |           Configuring etcd certs/keys            |
+-------------------------+--------------------------------------------------+
|         etchosts        |     Configuring /etc/hosts entries for hosts     |
+-------------------------+--------------------------------------------------+
|          facts          |      Gathering facts and misc check results      |
+-------------------------+--------------------------------------------------+
|           gce           |                Cloud-provider GCP                |
+-------------------------+--------------------------------------------------+
|        hyperkube        |      Manipulations with K8s hyperkube image      |
+-------------------------+--------------------------------------------------+
|     k8s-pre-upgrade     |              Upgrading K8s cluster               |
+-------------------------+--------------------------------------------------+
|       k8s-secrets       |            Configuring K8s certs/keys            |
+-------------------------+--------------------------------------------------+
|      kube-apiserver     |      Configuring static pod kube-apiserver       |
+-------------------------+--------------------------------------------------+
| kube-controller-manager |  Configuring static pod kube-controller-manager  |
+-------------------------+--------------------------------------------------+
|         kubectl         |      Installing kubectl and bash completion      |
+-------------------------+--------------------------------------------------+
|         kubelet         |           Configuring kubelet service            |
+-------------------------+--------------------------------------------------+
|        kube-proxy       |        Configuring static pod kube-proxy         |
+-------------------------+--------------------------------------------------+
|      kube-scheduler     |      Configuring static pod kube-scheduler       |
+-------------------------+--------------------------------------------------+
|        localhost        | Special steps for the localhost (ansible runner) |
+-------------------------+--------------------------------------------------+
|          master         |         Configuring K8s master node role         |
+-------------------------+--------------------------------------------------+
|        netchecker       |          Installing netchecker K8s app           |
+-------------------------+--------------------------------------------------+
|          nginx          |   Configuring LB for kube-apiserver instances    |
+-------------------------+--------------------------------------------------+
|           node          |    Configuring K8s minion (compute) node role    |
+-------------------------+--------------------------------------------------+
|        openstack        |             Cloud-provider OpenStack             |
+-------------------------+--------------------------------------------------+
|        preinstall       |         Preliminary configuration steps          |
+-------------------------+--------------------------------------------------+
|        resolvconf       | Configuring ``/etc/resolv.conf`` for hosts/apps  |
+-------------------------+--------------------------------------------------+
|         upgrade         |    Upgrading, f.e. container images/binaries     |
+-------------------------+--------------------------------------------------+
|          upload         |    Distributing images/binaries across hosts     |
+-------------------------+--------------------------------------------------+

.. note:: 

   使用 ``bash scripts/gen_tags.sh`` 命令生成代码库中找到的所有标记的列表。将使用空的 `Used for` 字段列出新标签。

命令示例
^^^^^^^^^^^^

用于过滤和应用 DNS 配置任务并跳过与主机操作系统配置相关的所有其他内容以及下载容器映像的示例命令：

.. code-block:: none

   ansible-playbook -i inventory/sample/hosts.ini cluster.yml --tags preinstall,dnsmasq,facts --skip-tags=download,bootstrap-os

此 play 仅从主机的 ``/etc/resolv.conf`` 文件中删除K8s群集DNS解析器IP：

.. code-block:: none
  
   ansible-playbook -i inventory/sample/hosts.ini -e dnsmasq_dns_server='' cluster.yml --tags resolvconf

这样就可以在本地（在 ansible runner 节点）准备所有容器镜像，而无需安装或升级相关内容或尝试将容器上传到K8s集群节点：

.. code-block:: none

   ansible-playbook -i inventory/sample/hosts.ini cluster.yml \
     -e download_run_once=true -e download_localhost=true \
     --tags download --skip-tags upload,upgrade

.. note:: 

   只有当你100％确定自己在做什么时才使用 ``--tags`` 和 ``--skip-tags`` 。

堡垒主机
^^^^^^^^^

如果您不想公开访问节点（仅具有专用IP的节点），则可以使用所谓的堡垒主机连接到您的节点。 要指定和使用堡垒，只需在 inventory 中添加一行，您必须使用堡垒主机的公共IP替换 ``x.x.x.x`` 。

.. code-block:: none

   bastion ansible_ssh_host=x.x.x.x

有关Ansible和堡垒主机的更多信息，请阅读 `通过 ssh 堡垒主机运行 Ansible <http://blog.scottlowe.org/2015/12/24/running-ansible-through-ssh-bastion-host/>`_ 。


