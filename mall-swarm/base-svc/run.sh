#!/bin/bash

sys_c(){
sudo yum -y install nfs-utils rpcbind
sudo systemctl enable rpcbind && sudo systemctl restart rpcbind
sudo systemctl enable nfs-server && sudo systemctl start nfs-server
grep '/data/apps/nfs/pub' /etc/exports
if [ $? != 0 ];then
    echo "/data/apps/nfs/pub *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    systemctl restart nfs-server
fi

kubectl create namespace dev
kubectl config set-context --current --namespace dev

master=$(cat /etc/hosts | grep 'cluster.local' | grep 'master' | awk '{print $NF}')
nodes=$(cat /etc/hosts | grep 'cluster.local' | grep -v 'master' | awk '{print $NF}')
for node_i in $nodes
do
    kubectl label nodes $node_i app=nacos
    kubectl label nodes $node_i minio=minio
done
}



yaml_c(){
for i in `find . -type f`
do
  if [[ $i =~ \.yaml$ || $i =~ \.yml$ ]];then
    kubectl apply -f ./$i
  fi
done
}
