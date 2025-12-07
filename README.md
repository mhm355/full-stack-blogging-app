# Fullstack Blogging App on AWS EKS

![Terraform](https://img.shields.io/badge/Infrastructure-Terraform-purple?style=for-the-badge&logo=terraform)
![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-blue?style=for-the-badge&logo=kubernetes)
![Helm](https://img.shields.io/badge/Package_Manager-Helm-orange?style=for-the-badge&logo=helm)
![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-orange?style=for-the-badge&logo=argo)
![AWS](https://img.shields.io/badge/Cloud-AWS-232F3E?style=for-the-badge&logo=amazon-aws)
![Spring Boot](https://img.shields.io/badge/Backend-Spring_Boot-green?style=for-the-badge&logo=spring)
![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-e6522c?style=for-the-badge&logo=prometheus)

---

## 📖 Table of Contents

- [Project Overview](#-project-overview)
- [Folder Structure](#-folder-structure)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [🚀 Deployment Guide](#-deployment-guide)
  - [Prerequisites](#prerequisites)
  - [Step 1: Provision Infrastructure (Terraform)](#step-1-provision-infrastructure-terraform)
  - [Step 2: Connect to Cluster](#step-2-connect-to-cluster)
  - [Step 3: Install Ingress Controller](#step-3-install-ingress-controller)
  - [Step 4: Install ArgoCD (GitOps)](#step-4-install-argocd-gitops)
  - [Step 5: Deploy Application Stack (Helm)](#step-5-deploy-application-stack-helm)
- [Access & Credentials](#-access--credentials)
  - [1. ArgoCD Login](#1-argocd-login)
  - [2. Application Services](#2-application-services)
- [⚙️ Configuration](#️-configuration)
- [🧹 Cleanup](#-cleanup)


---

## 📁 Folder Structure

```
/
├───.dockerignore
├───.env
├───.gitignore
├───docker-compose.yml
├───Dockerfile
├───mvnw
├───mvnw.cmd
├───pom.xml
├───prometheus.yml
├───README.md
├───to-run
├───.github/
│   └───workflow/
│       └───CI.yaml
├───grafana/
│   └───provisioning/
│       └───datasource.yaml
├───Helm/
│   ├───.helmignore
│   ├───Chart.yaml
│   ├───values.yaml
│   └───templates/
│       ├───application.yaml
│       ├───gp3-storageclass.yaml
│       ├───mysqldb.yaml
│       ├───namespace.yaml
│       ├───roles.yaml
│       └───monitoring/
│           ├───grafana.yaml
│           ├───monitoring-ingress.yaml
│           └───prometheus.yaml
├───k8s/
│   ├───application.yaml
│   ├───gp3-storageclass.yaml
│   ├───kustomization.yaml
│   ├───mysqldb.yaml
│   ├───namespace.yaml
│   └───monitoring/
│       ├───grafana.yaml
│       ├───monitoring-ingress.yaml
│       ├───prometheus.yaml
│       └───roles.yaml
├───src/
│  
|
└───Terraform/
    ├───backend.tf
    ├───ekscluster.tf
    ├───iam.tf
    ├───output.tf
    ├───provider.tf
    ├───terraform.tfvars
    ├───variables.tf
    ├───vpc.tf
    └───.terraform/...
```

---

## 📝 Project Overview

This project demonstrates a production-grade deployment of a **Fullstack Spring Boot Application** on **AWS Elastic Kubernetes Service (EKS)**.

The infrastructure is provisioned using **Terraform** (IaC). The application release lifecycle is managed via **GitOps** principles using **ArgoCD**, ensuring that the state of the cluster always matches the code in the repository.

---

## 🏛️ Architecture

The system follows a modern GitOps workflow:

```mermaid
graph TD
    User((User)) -->|HTTPS| ALB[AWS Load Balancer]
    ALB -->|Route /| Ingress[NGINX Ingress Controller]
    
    subgraph EKS Cluster [AWS EKS Cluster]
        Ingress -->|/| AppSvc[Blogging App Service]
        Ingress -->|/grafana| GrafSvc[Grafana Service]
        
        subgraph GitOps [CD Pipeline]
            ArgoLB[ArgoCD Load Balancer] --> ArgoCD[ArgoCD Controller]
        end

        AppSvc --> Pod1[Spring Boot Pod]
        Pod1 -->|JDBC| MySQL[MySQL StatefulSet]
        
        PromSvc[Prometheus] -->|Scrape| Pod1
    end
    
    Dev[Developer] -->|Push Code| Git[GitHub Repo]
    ArgoCD -->|Sync/Pull| Git
    ArgoCD -->|Apply Manifests| EKS Cluster
```

---

## 🛠️ Tech Stack

| Category                | Technology                                                                                                                              |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Infrastructure & DevOps** | **Terraform:** Provisions VPC, EKS Cluster, and Networking.<br/>**AWS EKS:** Managed Kubernetes Cluster.<br/>**ArgoCD:** GitOps continuous delivery tool.<br/>**Helm:** Package management for the App and Monitoring stack. |
| **Application & Data**  | **Backend:** Java Spring Boot (REST API + Actuator).<br/>**Database:** MySQL 8.0.                                                          |
| **Observability**       | **Prometheus & Grafana:** Full stack monitoring and visualization.                                                                      |

---

## 🚀 Deployment Guide

### Prerequisites

- AWS CLI & Terraform installed.
- `kubectl` and `helm` installed.

### Step 1: Provision Infrastructure (Terraform)

<details>
<summary>Initialize and apply the Terraform configuration.</summary>

```bash
terraform init
terraform apply --auto-approve
```

</details>

### Step 2: Connect to Cluster

<details>
<summary>Update your kubeconfig to access the new EKS cluster.</summary>

```bash
aws eks update-kubeconfig --region us-east-1 --name <YOUR_CLUSTER_NAME>
```

</details>

### Step 3: Install Ingress Controller

<details>
<summary>Create the AWS Load Balancer to handle external traffic for the application.</summary>

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml
```

</details>

### Step 4: Install ArgoCD (GitOps)

<details>
<summary>We install ArgoCD and expose it via its own AWS Load Balancer.</summary>

```bash
# 1. Create Namespace
kubectl create namespace argocd

# 2. Install ArgoCD Stable Manifests
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Patch Service to use LoadBalancer (Exposes it to the Internet)
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

</details>

### Step 5: Deploy Application Stack (Helm)

<details>
<summary>You can let ArgoCD manage this, or deploy manually for initial setup.</summary>

```bash
helm upgrade --install blogging-stack ./helm
```

</details>

---

## 🔑 Access & Credentials

### 1. ArgoCD Login

Retrieve the ArgoCD URL and credentials.

- **Get URL:** Copy the `EXTERNAL-IP` from this command:
  ```bash
  kubectl get svc argocd-server -n argocd
  ```
- **Get Password:** Run this command to decrypt the initial admin password:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
  ```
- **Login:**
  - **User:** `admin`
  - **Password:** *(Output from command above)*

### 2. Application Services

Wait for the App Load Balancer URL:
`kubectl get service ingress-nginx-controller -n ingress-nginx`

| Service      | URL Path                                  | Credentials (Default) |
| :----------- | :---------------------------------------- | :-------------------- |
| **Blogging App** | `http://<APP_LOAD_BALANCER_URL>/`         | N/A                   |
| **Grafana**    | `http://<APP_LOAD_BALANCER_URL>/grafana`  | `admin` / `admin`     |
| **Prometheus** | `http://<APP_LOAD_BALANCER_URL>/prometheus` | N/A                   |

---

## ⚙️ Configuration

Customize the deployment in `helm/values.yaml`:

```yaml
app:
  replicas: 2
  image:
    repository: mhmdocker1/fullstack-blogging-app
    tag: v1.3
```

---

## 🧹 Cleanup

To destroy all resources and avoid AWS costs, you **MUST** delete the Load Balancers manually first, or Terraform will fail.

```bash
# 1. Delete ArgoCD Load Balancer
kubectl delete service argocd-server -n argocd

# 2. Delete App Ingress Load Balancer
kubectl delete service ingress-nginx-controller -n ingress-nginx

# 3. Destroy Infrastructure
terraform destroy --auto-approve
```