# kubernetes-docs
	
* Version: alpha
* Auther: renkeju
* Email: renkeju@gmail.com

## Docker 容器部署

1. 克隆目录

    ```
    git clone https://github.com/81192/kubernetes-docs.git
    cd ./kubernetes-docs/docker/
    ```

2. 执行脚本

    ```
    # 如果linux系统中已安装 Docker 与 docker-compose，请跳过此命令，否则执行。
    bash build.sh set
    # 构建镜像
    bash build.sh make
    ```

3. 启动容器

   ```
   docker-compose up -d
   ```

> 参考
  1. [kubespray][1]
  2. [ansible 权威指南][2]

[1]: https://github.com/kubernetes-incubator/kubespray
[2]: http://ansible-tran.readthedocs.io/en/latest/
