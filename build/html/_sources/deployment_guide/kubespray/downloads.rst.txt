下载二进制文件和容器
~~~~~~~~~~~~~~~~~~~~~~~

支持多种 上传/下载 方式
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- 每个节点自己下载二进制文件和容器图像，即 ``download_run_once: False`` 。
- 对于K8s应用程序，拉取策略是如果不存在则拉取 ``k8s_image_pull_policy: IfNotPresent`` 。
- 对于系统管理的容器，如 kubelet 或 etcd，拉取策略是 ``download_always_pull: False`` ，如果只要有的 repo 和 `tag/sha256 digest` 与主机容器有所不同，就会拉取。

拉取一次 多次推送 模式
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- 更改为 ``download_run_once：True`` 仅下载容器映像一次，然后批量推送到群集节点，推送图像的默认委托节点是第一个 kube-master。
- 如果您的 `ansible runner` 节点（也称为admin节点）启用了无密码 sudo 和 docker，您可以定义 ``download_localhost：True`` ，这使得该节点成为在使用 ansible 运行部署时推送映像的委托。如果无法通过 ssh 访问到集群中的每个节点，或者您希望将本地 docker 镜像用作多个群集的缓存，则可能就是这种情况。

容器镜像和二进制文件由诸如 `foo_version`，`foo_download_url`，`foo_checksum`（用于二进制文件）和 `foo_image_repo`，`foo_image_tag` 或容器的可选 `foo_digest_checksum` 等变量描述。

容器图像可以通过其 repo 和 tag 来定义，例如：`andyshinn/dnsmasq:2.72`。或者通过 repo 和 tag 以及 sha256 digest：andyshinn/dnsmasq@sha256:7c883354f6ea9876d176fe1d30132515478b2859d6fc0cbf9223ffdc09168193。

请注意，sha256 digest 和镜像标记必须同时指定并相互对应。上面给出的示例由以下变量表示：

.. code-block:: none

   dnsmasq_digest_checksum: 7c883354f6ea9876d176fe1d30132515478b2859d6fc0cbf9223ffdc09168193
   dnsmasq_image_repo: andyshinn/dnsmasq
   dnsmasq_image_tag: '2.72'

可以在下载的 ansible roles 默认值中找到可用变量的完整列表。这些也允许为二进制文件和镜像图像指定自定义URL和本地存储库。另请参阅相关 Intranet 配置的 DNS 堆栈文档，以便主机可以解析这些 URL 和 repos。
