kubectl apply -f slurm-dependencies.yaml 
bash publish-keys.sh slurm
helm install slurm-cluster ./slurm-cluster-chart -f my-values.yaml --namespace slurm