k8s HA 端点
~~~~~~~~~~~~~~~~~~~~

以下组件需要高可用性端点：

* etcd 集群
* kube-apiserver 服务实例

后者依赖于第三方反向代理，如 Nginx 或 HAProxy，以实现相同的目标。

Etcd
^^^^^^^^

``etcd_access_endpoint`` 实际上为客户端提供了访问模式。 并且 ``etcd_multiaccess``（默认为True）Ansible ``group_vars`` 控制该行为。它使部署的组件直接访问etcd集群成员： ``http://ip1:2379, http://ip2:2379,...``. 此模式假定客户端执行负载均衡并处理连接的HA。

Kube-apiserver
^^^^^^^^^^^^^^^^^^

k8s 组件需要负载均衡器通过反向代理访问 apiserver。Kubespray 包括对基于 nginx 的代理的支持，该代理驻留在每个非主kubernetses节点上。这称为 localhost 负载均衡。它比专用负载均衡器效率低，因为它在 Kubernetes apiserver 上创建了额外的运行状态监测，但对于外部LB或虚拟IP管理不方便的情况更为实用。``loadbalancer_apiserver_localhost`` 配置（默认为 True。如果定义了外部 ``loadbalancer_apiserver`` ，则为 False）。你还可以通过更改 ``nginx_kube_apiserver_port`` 来定义本地内部负载均衡器使用的端口。默认值为 ``kube_apiserver_port``。同样重要的注意Kubespray 将仅在非主节点上配置 kubelet 和 kube-proxy 以使用本地内部负载均衡器。

如果您选择不使用本地内部负载均衡器，则需要配置自己的负载均衡器以实现 HA。请注意，部署负载均衡器取决于用户，并且不受Kubespary 中 ansible 角色的影响。默认情况下，它仅配置非 HA 端点，该端点指向 `kube-master` 组中第一个第一个服务器节点的 ``access_ip`` 或 IP 地址。它还可以将客户端配置为使用给定负载均衡器类型的端点。下图显示了如何定向到apiserver的流量。

.. image:: /images/deployment_guide/kubespray/loadbalancer_localhost.png

.. attention::

   Kubernetes主节点仍然使用不安全的本地主机访问，因为在主角色服务上使用TLS身份验证时，`Kubernetes < 1.5.0` 中存在错误。 这使得后端接收未加密的流量，并且在互连不同节点时可能是安全问题，或者如果那些属于没有外部访问的隔离管理网络则可能是安全问题。

用户可以选择使用外部负载均衡器（LB）。外部LB为外部客户端提供访问权限，而内部LB仅接受客户端连接到本地主机。 给定前端 ``VIP`` 地址和后端的 `IP1,IP2` 地址，这里是作为外部 LB 的 HAProxy 服务的示例配置：

.. code-block:: none

   global
       log /dev/log    local0
       log /dev/log    local1 notice
       chroot /var/lib/haproxy
       stats socket /var/run/haproxy.pid mode 660 level admin
       stats timeout 30s
       user haproxy
       group haproxy
       daemon
       nbproc 1

   defaults
       log     global
       timeout connect 5000
       timeout client  10m
       timeout server  10m

   listen  admin_stats
       bind 0.0.0.0:8080
       mode http
       log 127.0.0.1 local0 err
       stats refresh 30s
       stats uri /status
       stats realm welcome login\ Haproxy
       stats auth admin:123456
       stats hide-version
       stats admin if TRUE

   listen kube-master
       bind <VIP>:8443
       mode tcp
       option ssl-hello-chk
       balance roundrobin
       server kube-master-1 <IP1>:6443 check inter 2000 fall 2 rise 2 weight 1
       server kube-master-1 <IP2>:6443 check inter 2000 fall 2 rise 2 weight 1

.. note::

   这是在Kubespray之外的其他地方管理的示例配置。

以及在Kubespray中配置集群API访问模式的“群集感知”外部LB的相应示例全局变量：

.. code-block:: none

   apiserver_loadbalancer_domain_name: "my-apiserver-lb.example.com"
   loadbalancer_apiserver:
     address: <VIP>
     port: 8443


.. attention::
   
   默认的 kubernetes apiserver 配置绑定到所有接口，因此您需要为API正在侦听的vip使用不同的端口，或者设置 `kube_apiserver_bind_address` 以便API仅侦听特定接口（以避免冲突）用haproxy绑定VIP地址上的端口

此域名或默认"lb-apiserver.kubernetes.local"将插入到 k8s-cluster 组中所有服务器的 `/etc/hosts` 文件中，并连接到生成的自签名 TLS/SSL 证书。请注意，HAProxy服务也应该是HA并且需要VIP管理，这超出了本文档的范围。

  .. attention::

     对于这种情况，Kubespray 不会生成外部访问的API端点的 TLS/SSL 证书。 确保您的外部LB提供它。 或者，您可以在 `supplement_addresses_in_ssl_keys` 列表中指定外部负载均衡的 VIP。 然后，kubespray 也会将它们添加到生成的集群证书中。

除了特定情况之外，`loadbalancer_apiserver` 被认为与 `loadbalancer_apiserver_localhost` 互斥的。

访问API端点会被自动评估，如下所示：

+------------------------------+----------------+---------------------+---------------------+
|        Endpoint type         |  kube-master   |      non-master     |       external      |
+==============================+================+=====================+=====================+
|      Local LB (default)      | https://bip:sp |    https://lc:nsp   | https://m[0].aip:sp |
+------------------------------+----------------+---------------------+---------------------+
| Local LB + Unmanaged here LB | https://bip:sp |    https://lc:nsp   |     https://ext     |
+------------------------------+----------------+---------------------+---------------------+
|   External LB, no internal   | https://bip:sp |    https://lb:lp    |    https://lb:lp    |
+------------------------------+----------------+---------------------+---------------------+
|        No ext/int LB         | https://bip:sp | https://m[0].aip:sp | https://m[0].aip:sp |
+------------------------------+----------------+---------------------+---------------------+

* ``m[0]`` - `kube-master` 组中第一个节点；
* ``lb`` - LB FQDN（全局限定域名）, `apiserver_loadbalancer_domain_name`；
* ``ext`` - Externally load balanced VIP:port and FQDN, not managed by Kubespray；
* ``lc`` - localhost；
* ``bip`` - 自定义绑定 IP 地址或 localhost 用于默认绑定IP '0.0.0.0'；
* ``nsp`` - nginx 安全端口, `nginx_kube_apiserver_port`, 默认与 `sp` 相同；
* ``sp`` - 安全端口, `kube_apiserver_port`；
* ``lp`` - LB 端口, `loadbalancer_apiserver.port`，遵循安全端口；
* ``ip`` - 节点IP，遵循 ansible inventory 文件中 IP 地址；
* ``aip`` - 遵循 `access_ip` 定义的 IP 地址。

第二列和第三列表示内部群集访问模式。最后一列说明了从外部访问集群API的示例URI。 Kubespray 与它无关，这只是信息性的。

如您所见，主服务器的内部API端点始终通过本地绑定IP联系，即 `https://bip:sp`。

.. note::

   对于某些情况，如 Kubespray 部署的应用程序的健康检查，主节点的 API 可通过不安全的端点访问，该端点由本地 ``kube_apiserver_insecure_bind_address`` 和 ``kube_apiserver_insecure_port``。
