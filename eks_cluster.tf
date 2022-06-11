# Terraform will use this provider to access the cluster and creates some resources. 
provider "kubernetes" {
        host = data.aws_eks_cluster.myapp-cluster.endpoint # Endpoint of k8s cluster(API Server) 
        token = data.aws_eks_cluster_auth.myapp-cluster.token
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.myapp-cluster.certificate_authority.0.data) 
        }

data "aws_eks_cluster" "myapp-cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "myapp-cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.23.0"

  cluster_name = "myapp-eks-cluster"
  cluster_version = "1.21" # k8s version

  subnet_ids = module.myapp-vpc.private_subnets # Array of private subnets Ids where our worker nodes will be deployed
  vpc_id = module.myapp-vpc.vpc_id

  tags = {
    "enviroment" = "development"
    "application" = "myapp"
  }

  # self managed EC2 instances  
  self_managed_node_groups =   { 
    one = {
        name = "worker-group-1"
        instance_type = "t2.micro"
        max_size = 2 
        asg_desired_capacity = 2
    }

    two = {
        name = "worker-group-2"
        instance_type = "t2.medium"
        max_size = 1
        asg_desired_capacity = 1
    }    

  }  
}