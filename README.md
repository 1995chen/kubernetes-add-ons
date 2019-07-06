# Kubeadm init Kubernetes on Centos

## Add Hosts

这里先查看hostname，这里假设hostname为master
``` shell
vim /etc/hosts
    192.168.xxx.xxx master
```

## install docker

yum install docker

## 修改docker的Cgroup Driver

查看docker的cgroup的driver是不是systemd，如果不是就修改
```shell
docker info |grep Group
```
vim /usr/lib/systemd/system/docker.service
``` shell
--exec-opt native.cgroupdriver=systemd
```

## Docker镜像加速

vim /etc/docker/daemon.json
```shell
{
  "registry-mirrors": [
       "https://wt4ixzht.mirror.aliyuncs.com"
  ]
}
或
{
  "registry-mirrors": [
       "http://b048ad76.m.daocloud.io"
  ]
}
```

## 重启Docker服务

```shell
sudo systemctl daemon-reload 
sudo systemctl restart docker
```

## 禁用Swap

    禁用 swap
    * 编辑/etc/fstab文件，注释掉引用swap的行
    * sudo swapoff -a
    * 测试：输入top 命令，若 KiB Swap一行中 total 显示 0 则关闭成功

    若想永久关闭：
    * sudo vim /etc/fstab
    注释掉swap那一行
 
## 禁用SELINUX

    setenforce 0 
    
## 解除防火墙限制
vim /etc/sysctl.conf
```shell
net.bridge.bridge-nf-call-ip6tables = 1 
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
```
sysctl -p

## 为yum添加kubernetes的阿里云源

```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
        http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

## 安装Kubeadm、Kubelet、Kubectl

```shell
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes 
systemctl enable kubelet
```

## 指定kubelet的docker driver

vim /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
```shell
加上如下配置
Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=systemd”
```

## 启动kubelet

这一步很重要，虽然会启动失败，但是kubeadm初始化时就会自动修复好
```shell
sudo systemctl daemon-reload 
sudo systemctl start kubelet
```


## 查看需要准备的镜像

这里我们准备的镜像是v1.14.3
```shell
kubeadm config images list --kubernetes-version=v1.14.3
```

## 下载镜像并tag到k8s.gcr.io

cat download_images.sh
```shell
#!/bin/bash
images=(
    etcd:3.3.10
    pause:3.1
    kubernetes-dashboard-amd64:v1.10.1
    coredns:1.3.1
    flannel:v0.11.0-amd64
    metrics-server-amd64:v0.3.3
    kube-scheduler:v1.14.3
    kube-controller-manager:v1.14.3
    kube-apiserver:v1.14.3
    kube-proxy:v1.14.3
)

for imageName in ${images[@]} ; do
    docker pull chenl2448365088/$imageName
    docker tag chenl2448365088/$imageName k8s.gcr.io/$imageName
    docker rmi chenl2448365088/$imageName
done
docker tag k8s.gcr.io/flannel:v0.11.0-amd64   quay.io/coreos/flannel:v0.11.0-amd64
```

## V1.14.3版本K8s镜像地址

```shell
docker pull chenl2448365088/etcd:3.3.10
docker pull chenl2448365088/pause:3.1
docker pull chenl2448365088/kubernetes-dashboard-amd64:v1.10.1
docker pull chenl2448365088/coredns:1.3.1
docker pull chenl2448365088/flannel:v0.11.0-amd64
docker pull chenl2448365088/metrics-server-amd64:v0.3.3
docker pull chenl2448365088/kube-scheduler:v1.14.3
docker pull chenl2448365088/kube-controller-manager:v1.14.3
docker pull chenl2448365088/kube-apiserver:v1.14.3
docker pull chenl2448365088/kube-proxy:v1.14.3
```

## 借助DockerHub构建镜像

简单步骤如下：
```shell

建立一个github仓库，其中一个文件内容如下：
etcd-amd64/Dockerfile
FROM gcr.io/google_containers/etcd-amd64:3.2.18
LABEL maintainer="yun_tofar@qq.com"
LABEL version="1.0"
LABEL description="kubernetes"

之后在镜像仓库中建立 auto build 类型的仓库，自动追踪github变动，更新镜像
```

## 初始化Kubeadm
这里使用的是flannel经典网络插件所以--pod-network-cidr=10.244.0.0/16
--apiserver-advertise-address 必须为ifconfig查到的，部分云不支持直接公网IP
```shell
kubeadm init --kubernetes-version=v1.14.3 --apiserver-advertise-address 192.168.39.79 --pod-network-cidr=10.244.0.0/16
```

## 后续处理

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## 测试

```shell
curl https://127.0.0.1:6443 -k

{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {
    
  },
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {
    
  },
  "code": 403
}
表示成功安装!
```

## 允许master作为负载节点

默认情况下由于安全原因你的cluster不会调度pods在你的master上。如果你想让你的master也参与调度，run:
```shell
kubectl taint nodes --all node-role.kubernetes.io/master-
或者
kubectl taint nodes k8s-node1 node-role.kubernetes.io/master-
```

## 查看所有节点状态

```shell
kubectl get nodes
```

## 安装Flannel网络插件

此时，Dns服务一直处于Pending，以及Master一直显示NotReady。安装网络插件就好了

## Add-ons

```shell
https://github.com/chenliang2505497150/kubernetes-add-ons
```
