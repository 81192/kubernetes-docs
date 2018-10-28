入门
~~~~~~~~~~~

建立自己的 inventory
^^^^^^^^^^^^^^^^^^^^^^^^^

Ansible inventory 可以使用三种格式存储：YAML、JSON 或 INI-like。查看示例 inventory 点击 `这里 <https://github.com/kubernetes-incubator/kubespray/blob/master/inventory/sample/hosts.ini>`_ 。

你可以使用 `inventory generator <https://github.com/kubernetes-incubator/kubespray/blob/master/contrib/inventory_builder/inventory.py>`_ 去创建或修改 Ansible inventory。 目前，它的功能有限，仅用于配置基本的 Kubespray Cluster Inventory，但它也支持为大型集群创建 Inventory 文件。 如果大小超过某个阈值，它现在支持从节点角色分离 ETCD 和 Kubernetes Master 角色。 运行 `python3 contrib/inventory_builder/inventory.py help` 帮助获取更多信息。

inventory generator 使用示例：

.. code-block:: bash
   
   cp -r inventory/sample inventory/mycluster
   declare -a IPS=(10.10.1.3 10.10.1.4 10.10.1.5)
   CONFIG_FILE=inventory/mycluster/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]}


开始自定义部署
^^^^^^^^^^^^^^^^^^^^^^^^^

一旦你有了 Inventory 之后，你可能希望自定部署数据并开始部署。

.. note::
   
   通过编辑 ``my_inventory/groups_vars/*.yaml`` 来覆盖变量数据。

.. code-block:: bash

   ansible-playbook -i inventory/mycluster/hosts.ini cluster.yml -b -v \
     --private-key=~/.ssh/private_key

可以从 `Ansible 变量`_ 查看更多的细节。

添加节点
^^^^^^^^^^^^^^^^

你可能希望将 worker、master 或 etcd 节点添加到现有集群。这可以通过重新运行 ``cluster.yml`` playbook 来完成，或者你可以针对在 worker 上安装 kubelet 并从你的 master 计算出所需要的最低限制。在执行类似自动缩放的操作时，这尤为重要。

- 将新工作线程节点添加到相应组中的 invertory （或使用 `dynamic inventory <https://docs.ansible.com/ansible/intro_dynamic_inventory.html>`_ ）
- 运行 ansible-playbook 命名，把 `cluster.yml` 替换为 `scale.yml`。

    .. code-block:: bash

       ansible-playbook -i inventory/mycluster/hosts.ini scale.yml -b -v \
         --private-key=~/.ssh/private_key

删除节点
^^^^^^^^^^^^^^

你可能希望将 `worker` 节点从现有集群中移除。这可以通过重新运行 ``remove-node.yml`` playbook 来实现。首先，将排空所有节点，然后停止一些 kubernetes 服务并删除一些证书，最后执行 kubectl 命令删除这些节点。这可以与添加节点功能结合使用。这在执行自动缩放集群等操作时通常很有用。当然，如果节点不能工作，您可以删除该节点并再次安装它。

如果要删除 worker 节点（或使用 `dynamic inventory <https://docs.ansible.com/ansible/intro_dynamic_inventory.html>`_ ），请将 worker 节点添加到 kube-node 下的列表中。

.. code-block:: bash

   ansible-playbook -i inventory/mycluster/hosts.ini remove-node.yml -b -v \
     --private-key=~/.ssh/private_key


我们支持两种方式来选择节点：

- 使用 ``--extra-vars "node=<nodename>,<nodename2>"`` 选择要删除的节点

.. code-block:: bash

   ansible-playbook -i inventory/mycluster/hosts.ini remove-node.yml -b -v \
     --private-key=~/.ssh/private_key \
     --extra-vars "node=nodename,nodename2"

- 使用 ``--limit nodename,nodename2`` 选择要删除的节点

.. code-block:: bash

   ansible-playbook -i inventory/mycluster/hosts.ini remove-node.yml -b -v \
     --private-key=~/.ssh/private_key \
     --limit nodename,nodename2"


连接到 Kubernetes
^^^^^^^^^^^^^^^^^^^^^^^

默认情况下，Kubespray 通过 8080 端口配置对 kube-apiserver 不安全访问的 kube-master 主机。这种情况下，不需要 kubeconfig 文件，因为 kubectl 将使用 <http://localhost:8080> 进行连接。生成的 kubeconfig 文件将指向 localhost（在 kube-masters 上），并且 kube-node 主机将连接到 localhost nginx 代理或连接到负载均衡器（如果已配置）。[HA 指南](ha-mode.md) 中有关此过程的更多详细信息。

Kubespray 允许在端口 6443 上的任何 kube-master 主机的任何 IP 上远程连接到集群。但是，这需要身份验证。可以基于一个已安装 kube-master 主机（需要改进）生成 kubeconfig，或者使用用户名和密码进行连接。默认情况下，创建具有管理员权限的名为 kube 的用户。通过查看文件 ``PATH_TO_KUBESPRAY/kube_user.creds``，可以在部署后查看密码。这包含随机生成的密码。如果你想设置自己的密码，只需自己预先创建/修改此文件。

有关 kubeconfig 和访问 Kubernetes 集群的更多信息，请参阅 Kubernetes `文档 <https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/>`_ 。

访问 Kubernetes 仪表盘
^^^^^^^^^^^^^^^^^^^^^^^^^^

截止 kubernetes-dashboard v1.7.x:

- 默认情况下使用 token/basic/kubeconfig 的 apiserver auth 代理新的登录选项
- 在 authorization\_modes 中需要 RBAC
- 仅适用于 HTTPS
- 在使用 https 代理 URL 更新 apiserver 之前，<https://first_master:6443/ui> 不再可用。

如果设置了变量 dashboard_enabled（默认为 true），则可以通过以下 URL 访问 Kubernetes 仪表盘，系统将提示输入凭据：<https://first_master:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login>

或者你可以从本地计算机运行 "kubectl proxy" 以访问浏览器中的仪表盘：<http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login>

建议从强制执行身份验证令牌的网关（如 Ingress Controller）后面访问仪表盘。详细信息和其他访问选项：<https://github.com/kubernetes/dashboard/wiki/Accessing-Dashboard---1.7.X-and-above>

访问 Kubernetes API
^^^^^^^^^^^^^^^^^^^^^^^^^

Kubernetes 的主要客户是 ``kubectl``。它安装在每个 kube-master 主机上，可以选择在 ansible 主机上配置，方法是在配置中设置 ``kubectl_localhost: true`` 和 ``kubeconfig_localhost: true`` 。

-   如果开启 ``kubectl_localhost``， ``kubectl`` 将会下载到 ``/usr/local/bin/`` 并通过 bash 完成设置。 还使用以下 ``admin.conf`` 为安装程序创建了一个帮助程序脚本 ``inventory/mycluster/artifacts/kubectl.sh``
-   如果开启 ``kubectl_localhost``, ``admin.conf`` 将在部署后出现在 ``inventory/mycluster/artifacts/`` 目录中。

您可以通过运行以下命令来查看节点列表：

.. code-block:: bash

   cd inventory/mycluster/artifacts
   ./kubectl.sh get nodes

如果需要，请将 ``admin.conf`` 复制到 ``~/.kube/config`` 目录中。
