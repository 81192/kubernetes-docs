Dockerfile
~~~~~~~~~~~~~~~~~

从上一小节的 volume 的介绍中，我们可以了解到，镜像的定制实际上就是定制每一层所添加的配置、文件。如果我们可以把每一层修改、安装、构建、操作的命令都写入一个脚本，用这个脚本来构建、定制镜像，那么之前提及的无法重复的问题、镜像构建透明性的问题、体积的问题就都会解决。这个脚本就是 Dockerfile。

Dockerfile 是一个文本文件，其内包含了一条条的指令（Instruction），每一条指令构建一层 ，因此每一条指令的内容，就是描述该层应当如何构建。

我们以定制 Nginx 镜像为例，我们使用 Dockerfile 来定制。在一个空白目录中，建立一个文本文件，并命名为 ``Dockerfile`` :

.. code-block:: bash

    $ mkdir mynginx
    $ cd mynginx
    $ touch Dockerfile

.. code-block:: none

    FROM nginx
    RUN echo '<h1>Hello, Docker!</h1>' > /usr/share/nginx/html/index.html

这个 Dockerfile 很简单，一共就两行。涉及到了两条指令，:guilabel:`FROM` 和 :guilabel:`RUN` 。

FROM 指定基础镜像
^^^^^^^^^^^^^^^^^^^^^^

所谓制定镜像，那一定是以一个镜像为基础，在其上进行定制。就像运行了一个 :guilabel:`nginx`，再进行修改一样，基础镜像是必须指定的。而 :guilabel:`RROM` 就是指定基础镜像，因此一个 :guilabel:`Dockerfile` 中 :guilabel:`FROM` 是必备的指令，并且必须是第一条指令。

在 `Docker Store <https://store.docker.com/>`_ 上有非常多的高质量的官方镜像，有可以直接拿来使用的服务类的镜像，如 `nginx <https://store.docker.com/images/nginx>`_/`redis <https://store.docker.com/images/redis>`_/`mongo <https://store.docker.com/images/mongo>`_/`mysql <https://store.docker.com/images/mysql>`_/`httpd <https://store.docker.com/images/httpd>`_/`php <https://store.docker.com/images/php>`_ `tomcat <https://store.docker.com/images/tomcat>`_ 等；也有一些方便开发、构建、运行各种语言应用的镜像，如 `node <https://store.docker.com/images/node>`_/`openjdk <https://store.docker.com/images/openjdk>`_/`python <https://store.docker.com/images/python>`_/`ruby <https://store.docker.com/images/ruby>`_/`golang <https://store.docker.com/images/golang>`_ 等。可以在其中寻找一个最符合我们最终目标的镜像为基础镜像进行定制。

如果没有找到对应服务的镜像，官方镜像中还提供了一些更为基础的操作系统镜像，如 `ubuntu <https://store.docker.com/images/ubuntu>`_/`debian <https://store.docker.com/images/debian>`_/`centos <https://store.docker.com/images/centos>`_/`fedora <https://store.docker.com/images/fedora>`_/`alpine <https://store.docker.com/images/alpine>`_ 等，这些操作系统的软件库为我们提供了更广阔的扩展空间。

除了选择现有的镜像为基础镜像外，Docker 还存在一个特殊的镜像，名为 :guilabel:`scratch` 。这个镜像是虚拟的概念，并不实际存在，它表示一个空白的镜像。

.. code-block:: none

    FROM scratch
    ...

