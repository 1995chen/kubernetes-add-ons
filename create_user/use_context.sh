kubectl config set-credentials chenliang --embed-certs=true --client-certificate=/etc/kubernetes/pki/chenliang.crt --client-key=/etc/kubernetes/pki/chenliang.key
kubectl config set-context chenliang@test_users --cluster=kubernetes --user=chenliang
kubectl config use-context chenliang@test_users
