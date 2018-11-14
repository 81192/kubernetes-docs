架构简介
------------

Ceph 简介
~~~~~~~~~~~~~

Ceph 是一个统一的分布式存储系统，设计初衷是提供较好的性能、可靠性和可扩展性。

Ceph 项目最早起源于 Sage 就读博士期间的工作（最早的成功于 2004 年发表），并随后贡献给开源社区。
在经过数年的发展之后，项目已经得到众多云计算厂商的支持并被广泛应用。RedHat 及 OpenStack 都可与 Ceph 整合以支持虚拟机镜像的后端存储。


Ceph 特点
~~~~~~~~~~~~~

1. 高性能

   a. 摒弃了传统的集中式存储源数据寻址的方案，采用 CRUCH 算法，数据分布均衡，并行度高。
   b. 考虑了容灾域的隔离，能狗实现各类负载的副本防止规则，例如跨机房、机架感知等。
   c. 能够支持上千个存储节点的规模，支持TB到PB级别的数据。

2. 高可用性

   a. 副本数可以灵活控制
   b. 支持故障或分割，数据强一致性
   c. 多种故障场景自动进行修复自愈

3. 高可扩展性

   a. 去中心化
   b. 扩展灵活
   c. 多种故障场景自动进行修复自愈
   d. 没有单点故障，自动管理。

4. 特性丰富

   a. 支持三种存储接口：块存储、文件存储、对象存储
   b. 支持自定义接口，支持多种语言驱动

Ceph 架构
~~~~~~~~~~~~~

支持三种接口

* Object ：有原生的 API,而且也兼容 Swift 和 S3 的 API。
* Block ：支持精简配置、快照、克隆。
* File ：Posix 接口，支持快照。

.. image:: /images/ceph/ceph_architecture.png

Ceph 核心组建及概念介绍
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1. Monitor

   一个 Ceph 集群需要多个 Monitor 组成的小集群，他们通过 Paxos 同步数据，用来保存 OSD 的元数据。

2. OSD

   OSD 全称 Object Storage Device，也就是负责响应客户端请求返回具体数据的进程。一个 Ceph 集群一般都有很多个 OSD。

3. MDS

   MDS 全称 Ceph Metadata Server，是 CephFS 服务依赖的元数据服务。

4. Object

   Ceph 最底层的存储单元是 Object 对象，每个 Object 包含元数据和原始数据。

5. PG

   PG 全称 Placement Groups，是一个逻辑的概念，一个 PG 包含多个 OSD。引入 PG 这一层其实是为了更好的分配数据和定位数据。

6. RADOS

   RADOS 全称 Reliable Autonomic Distributed Object Store，是 Ceph 集群的精华，用户实现数据分配，Failover 等集群的操作。

7. Librados

   Librados 是 Rados 提供库，因为 RADOS 是协议很难直接访问，因此上层的 RBD、RGW 和 CephFS 都是通过 librados 访问的，目前提供 PHP、Ruby、Java、Python、C 和 C++ 支持。

8. CRUSH

   CRUSH 是 Ceph 使用的是数据分布算法，类似一致性哈希，让数据分配到预期的地方。

9. RBD

   RBD 全称 RADOS block device，是 Ceph 对外提供的块设备服务。

10. RGW

    RGW 全称 RADOS gateway，是 Ceph 对外提供的对象存储服务，接口与 S3 和 Swift 兼容。

11. CephFS

    CephFS 全称 Ceph File Syetem，是 Ceph 对外提供的文件系统服务

三种存储类型
~~~~~~~~~~~~~~~~

块存储
^^^^^^^^^^

* 典型设备：磁盘阵列，硬盘

   主要是将裸磁盘空间映射给主机使用

* 优点

  * 通过 Raid 与 LVM 等手段，对数据提供了保护。
  * 多块廉价的硬盘组合起来，提高容量。
  * 多块磁盘组合出来的逻辑卷，提升读写效率。

* 缺点

  * 采用 SAN 架构组网时，光纤交换机，造价成本高。
  * 主机之间无法共享数据。

* 使用场景

  * docker 容器、虚拟机磁盘存储分配。
  * 日志存储
  * 文件存储

文件存储
^^^^^^^^^^^^^^^

* 典型设备：FTP、NFS 服务器

  为了克服块存储文件无法共享的问题，所以有了文件存储。
  在服务器上架设 FTP 与 NFS 服务，就是文件存储。

* 优点

  * 造价低廉，随便一台机器即可
  * 方便文件共享

* 缺点

  * 读写速率低
  * 传输速率慢

* 使用场景

  * 日志存储
  * 有目录结构的文件存储

对象存储
^^^^^^^^^^^^^

.. image:: /images/ceph/Ceph_RGW.png

* 典型设备：内置大容量硬盘的分布式服务器（Swift,S3）

  多台服务器内置大容量硬盘，安装上对象存储管理软件，对外提供读写访问功能。

* 优点

  * 具备块存储的读写速度
  * 具备文件存储的共享等特性

* 使用场景（适合更新变动较少的数据）

  * 图片存储
  * 视频存储


Ceph IO 流程及数据分布
--------------------------

.. image:: /images/ceph/Ceph_io_1.png

正常的IO流程图
~~~~~~~~~~~~~~~~~~~~~~

.. image:: /images/ceph/ceph_io_2.png

步骤：

1. client 创建 cluster handler
2. client 读取配置文件
3. client 连接上 monitor，获取集群 map 信息
4. client 读写 io 根据 cershmap 请求算法对应的主 osd 数据节点
5. 主 osd 数据节点同时写入另外两个副本节点数据
6. 等待主节点以及另外两个副本节点写完数据状态
7. 主节点及副本节点写入状态都成功后，返回给 client，io 写入完成

新主 IO 流程图
~~~~~~~~~~~~~~~~~~~~

* 说明

  如果新加入的 OSD4 取代了原有的 OSD1 成为 Primary OSD，由于 OSD4 上未创建 PG，不存在数据，那么 PG 上的 I/O 无法进程，怎样工作呢？

   .. image:: /images/ceph/ceph_io_3.png 

* 步骤

  a. client 连接 monitor 获取集群 map 信息
  b. 同时新主 osd4 由于没有 pg 数据会主动上报 monitor 告知 osd2 临时接替主
  c. 临时主 osd2 会把数据全量同步给新主 osd4
  d. client IO 读取直接连接临时主 osd2 进行读写
  e. osd2 收到读写 io，同时写入另外两副本节点
  f. 等待 osd2 以及另外两副本写入成功
  g. osd2 三份数据都写入成功返回给 client，此时 client io 读写完毕
  h. 如果 osd4 数据同步完毕，临时主 osd2 会交出主角色
  i. osd4 成为主节点，osd2 变成副本

Ceph IO 算法流程
~~~~~~~~~~~~~~~~~~~~

.. image:: /images/ceph/ceph_io_4.png

1. File 用户需要读写文件。File -> Object 映射：

   a. ino (File 的元数据，File 是唯一 id)
   b. ono（File 切分产生的某个 object 的序号，默认以 4M 切分一个块大小）
   c. oid（object id: ino + ono）

2. Object 是 RADOS 需要的对象。Ceph 指定一个静态 hash 函数计算 oid 的值，将 oid 映射成一个近似均匀分布的伪随机值，然后和 mask 按位相与，得到 pgid。Object -> PG 映射：

   a. hash(oid) & mask -> pgid
   b. mask = PG 总数m（m 为2的整数幂）-1

3. PG（Placement Group），用途是对 Object 的存储进行组织和位置映射，
   （类似于 redis cluster 里面的 solt 的概念）
   一个 PG 里面会有很多 object。此用 CRUSH 算法，将 pgid 带入其中，然后得到一组 OSD。
   PG -> OSD 映射：

   a. CRUSH(pgid) -> (osd1,osd2,osd3)

Ceph RBD IO 流程
~~~~~~~~~~~~~~~~~~~~~~~~

.. image:: /images/ceph/ceph_rbd_io.png

步骤：

a. 客户端创建一个 pool，需要为这个 pool 指定 pg 的数量
b. 创建 pool/image rbd 设备进行挂载
c. 用户写入的数据进行切块，每个块的大小默认为 4M，并且每个块都有一个名字，名字就是 object + 序号
d. 将每个 object 通过 pg 进行副本位置的分配
e. pg 根据 cursh 算法会寻找 3 个 osd，把这个 object 分别保存在这三个 osd 上
f. osd 上实际是把底层的 disk 进行了格式化操作，一般部署工具会将它格式化为 xfs 文件系统
g. object 的存储就变成了存储一个文件 rbd0.object1.file
