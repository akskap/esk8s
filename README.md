# **esk8s a.k.a Elastic Stack on K8S (Minikube)**

## **Automated provisioning of Elastic Stack on K8S (Backed by Minikube in AWS)**

This repository covers automated provisioning/testing of ElasticStack (*ElasticSearch/Filebeat/Kibana*) on Minikube. The setup includes provisoning an EC2 instance on AWS with Terraform and subsequently deploying *Docker, Minikube, Gitlab-CE (with runner)* inside the EC2 instance. CI/CD pipelines can then deploy ElasticStack on Minikube and run same basic tests.



### **Pre-requisites:**
- *Terraform* should be installed on your local machine
- AWS access-key/secret pair



### **Repository structure**
```
├── README.md
├── elasticstack                            (K8S templates for deployment)
│   ├── elasticsearch.yml
│   ├── filebeat-configmap.yml
│   ├── filebeat-daemonset.yml
│   ├── filebeat-role-binding.yml
│   ├── filebeat-role.yml
│   ├── filebeat-service-account.yml
│   ├── kibana.yml
│   └── test                                (Basic test scripts to check health of the ELK cluster)
│       ├── check_elasticsearch_data_flow
│       └── es_test_data.py
└── minikube-terraform                      (Terraform scripts)
    ├── main.tf
    ├── setup.sh
    └── variables.tf
```



### Basic Workflow:
![Basic Workflow](https://i.imgur.com/sOSpwx1.png)

## Steps

**1) Clone the repository in your local machine**
```
git clone https://github.com/akskap/esk8s.git
```


**2) Provision an EC2 instance on Terraform**

**Note**: Before triggering terraform, you will have to customize variable values in `minikube-terraform/variables.tf` file, because all defaults may not suit your requirements. Please note that you update your AWS key-pair name and ingress CIDR range to be able to access the instance later.

Once you have all the values in place, please run:
```
cd minikube-terraform; terraform apply;
```

This will start provisioning an EC2 instance with security group definition and corresponding ingress/egress rules

A cloud-init script is configured as part of EC2 instance creation. This takes care of setting up tools like:
- Gitlab-CE 
- Docker
- Minikube 
- Other system tools like jq, git, gitlab-runner etc.

Terraform run completes with an output like:
```
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

public_dns = ec2-xx-xxx-xxx-xxx.eu-central-1.compute.amazonaws.com
public_ip = xx.xxx.xxx.xxx
```
The public dns endpoint / ip-address will allow access to the EC2 instance. At this point if you try to access `http://ec2-xx-xxx-xxx-xxx.eu-central-1.compute.amazonaws.com` in your browser, you will be greeted by Gitlab-CE. Here, you can choose a password for the root user and create a repository that will host the contents of K8S manifests and CI/CI pipeline definition in later steps


**3) Setup Gitlab Runner**

Installation of Gitlab Runner is already taken care of in the cloud-init script in EC2. Next, we need to register the runner with the repository that we created in Step 2.

Visit `Repository page > Settings > CI/CD > Runners` and note down the details for Runner Registration token and Gitlab URL:

SSH into the EC2 instance with the following command:
```
ssh -i <path_to_aws_pem_file> ec2-user@ec2-xx-xxx-xxx-xxx.eu-central-1.compute.amazonaws.com
sudo su
sudo gitlab-runner register                             \
    --non-interactive                                   \
    --url "<GITLAB_URL>"                                \
    --registration-token "<GITLAB_RUNNER_REG_TOKEN>"    \
    --executor "shell"                                  \
    --description "Runner for esk8s project"            \
    --locked="true"                                     \
    --request-concurrency 4
```


**4) Push code from local machine to the new repository to enable pipeline execution and test**

```
git remote add esk8s http://<ec2-xx-xxx-xxx-xxx.eu-central-1.compute.amazonaws.com>/root/<repository_name>
git push esk8s master
```

Code push will trigger the Gitlab pipeline, run log for which can be seen @ http://ec2-xx-xxx-xxx-xxx.eu-central-1.compute.amazonaws.com/root/<repo_name>/pipelines


**5) Access Kibana on local machine**

In order to run Kibana on local machine, we will be tunnelling the traffic via SSH into the EC2 instance
Kibana is exposed as a NodePort service on Minikube. First, let's get the Node IP address exposed by Minikube by running a command in the EC2 instance
```
kubectl get services -o json --namespace=test -l service=kibana | jq -r '.items[0].spec.clusterIP'
```
Now, on your local machine, run the following command:
```
ssh -N -L 5601:<kibana_cluster_ip>:5601 -i <your_aws_key_pair>.pem ec2-user@ec2-xx-xxx-xxx-xxx.eu-central-1.compute.amazonaws.com
```

Kibana dashboard can now be accessed on your local machine under `http://localhost:5601`





