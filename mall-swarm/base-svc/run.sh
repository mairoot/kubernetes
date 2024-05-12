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
sleep 30
}

svc_c(){
for i in `find nfs -type f \( -name *.yaml -o -name *.yml \)`
do
  if [[ $i =~ \.yaml$ || $i =~ \.yml$ ]];then                                                                                     
    kubectl apply -f ./$i                                                                                                         
  fi                                                                                                                              
done                                                                                                                              
sleep 30
}


prom_c(){                                                                                                                         
  cd prometheus/manifests/                                                                                                        
  kubectl delete -f  grafana-networkPolicy.yaml                                                                                   
  kubectl apply --server-side -f setup                                                                                            
  kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring                                  
  kubectl apply -f .                                                                                                              
  kubectl delete -f prometheus-networkPolicy.yaml                                                                                 
  kubectl delete -f alertmanager-networkPolicy.yaml                                                                               
  kubectl delete -f grafana-networkPolicy.yaml                                                                                    
  cd ../../                                                                                                                       
sleep 30
} 


svc_c(){
for i in `find . -type d \( -path ./prometheus -o -path ./nfs \) -prune -o -type f \( -name *.yaml -o -name *.yml \) -print`
do
  if [[ $i =~ \.yaml$ || $i =~ \.yml$ ]];then
    kubectl apply -f ./$i
  fi
done
sleep 30
}


sys_c
nfs_c
prom_c
svc_c
